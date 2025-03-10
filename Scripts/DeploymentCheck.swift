import Foundation

enum DeploymentError: Error {
    case invalidMetadata(String)
    case missingAsset(String)
    case configurationError(String)
    case validationFailed(String)
}

struct DeploymentCheck {
    static func main() {
        guard CommandLine.arguments.count > 1 else {
            printUsage()
            exit(1)
        }
        
        let command = CommandLine.arguments[1]
        
        do {
            switch command {
            case "validate-metadata":
                try validateMetadata()
            case "verify-privacy-manifest":
                try verifyPrivacyManifest()
            case "verify-export-compliance":
                try verifyExportCompliance()
            case "verify-iap-configuration":
                try verifyIAPConfiguration()
            default:
                printUsage()
                exit(1)
            }
        } catch {
            print("❌ Error: \(error)")
            exit(1)
        }
    }
    
    static func validateMetadata() throws {
        print("📝 Validating App Store metadata...")
        
        let metadataPath = "../appstore_metadata.json"
        guard let data = FileManager.default.contents(atPath: metadataPath),
              let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw DeploymentError.invalidMetadata("Failed to read metadata file")
        }
        
        // Required fields
        let requiredFields = ["name", "description", "privacy_url", "support_url"]
        for field in requiredFields {
            guard metadata[field] != nil else {
                throw DeploymentError.invalidMetadata("Missing required field: \(field)")
            }
        }
        
        // Check screenshots
        let screenshotsPath = "../Screenshots"
        let requiredScreenshots = [
            "iPhone": ["6.5", "5.5"],
            "iPad": ["12.9"]
        ]
        
        for (device, sizes) in requiredScreenshots {
            for size in sizes {
                let path = "\(screenshotsPath)/\(device)_\(size)"
                if !FileManager.default.fileExists(atPath: path) {
                    throw DeploymentError.missingAsset("Missing screenshots for \(device) \(size)\"")
                }
            }
        }
        
        print("✅ Metadata validation passed")
    }
    
    static func verifyPrivacyManifest() throws {
        print("🔒 Verifying privacy manifest...")
        
        let manifestPath = "../Sources/App/PrivacyInfo.xcprivacy"
        guard FileManager.default.fileExists(atPath: manifestPath) else {
            throw DeploymentError.configurationError("Privacy manifest file not found")
        }
        
        guard let data = FileManager.default.contents(atPath: manifestPath),
              let manifest = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw DeploymentError.invalidMetadata("Invalid privacy manifest format")
        }
        
        // Required privacy descriptions
        let requiredDescriptions = [
            "NSCameraUsageDescription",
            "NSPhotoLibraryUsageDescription",
            "NSMicrophoneUsageDescription"
        ]
        
        for description in requiredDescriptions {
            guard manifest[description] != nil else {
                throw DeploymentError.configurationError("Missing privacy description: \(description)")
            }
        }
        
        print("✅ Privacy manifest verification passed")
    }
    
    static func verifyExportCompliance() throws {
        print("📦 Verifying export compliance...")
        
        let infoPlistPath = "../Sources/App/Info.plist"
        guard let data = FileManager.default.contents(atPath: infoPlistPath),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw DeploymentError.configurationError("Failed to read Info.plist")
        }
        
        // Check encryption export compliance
        guard let encryptionUsage = plist["ITSAppUsesNonExemptEncryption"] as? Bool else {
            throw DeploymentError.configurationError("Missing encryption usage declaration")
        }
        
        if encryptionUsage {
            guard plist["ITSEncryptionExportComplianceCode"] != nil else {
                throw DeploymentError.configurationError("Missing encryption compliance code")
            }
        }
        
        print("✅ Export compliance verification passed")
    }
    
    static func verifyIAPConfiguration() throws {
        print("💰 Verifying In-App Purchase configuration...")
        
        let configPath = "../StoreKit/Configuration.storekit"
        guard FileManager.default.fileExists(atPath: configPath) else {
            throw DeploymentError.configurationError("StoreKit configuration file not found")
        }
        
        // Verify StoreKit configuration
        guard let data = FileManager.default.contents(atPath: configPath),
              let config = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw DeploymentError.configurationError("Invalid StoreKit configuration")
        }
        
        // Check required IAP configuration
        guard let products = config["products"] as? [[String: Any]] else {
            throw DeploymentError.configurationError("No products configured")
        }
        
        for product in products {
            guard let identifier = product["identifier"] as? String,
                  let type = product["type"] as? String,
                  let price = product["price"] as? Double else {
                throw DeploymentError.configurationError("Invalid product configuration")
            }
            
            // Validate product configuration
            if type == "subscription" {
                guard let subscriptionGroup = product["subscriptionGroup"] as? String else {
                    throw DeploymentError.configurationError("Missing subscription group for \(identifier)")
                }
            }
        }
        
        print("✅ In-App Purchase configuration verified")
    }
    
    static func printUsage() {
        print("""
        Usage: deployment-check <command>
        
        Commands:
          validate-metadata         Validate App Store metadata
          verify-privacy-manifest   Verify privacy manifest
          verify-export-compliance Check export compliance
          verify-iap-configuration Verify In-App Purchase configuration
        """)
    }
}

DeploymentCheck.main()