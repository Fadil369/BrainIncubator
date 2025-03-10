import XCTest
@testable import BrainIncubator

class AppStoreValidationTests: XCTestCase {
    func testScreenshotDimensions() throws {
        let screenshotPath = Bundle.main.resourcePath! + "/Screenshots"
        let fileManager = FileManager.default
        
        let requiredSizes = [
            "iPhone": [
                CGSize(width: 1242, height: 2688), // 6.5" display
                CGSize(width: 1242, height: 2208)  // 5.5" display
            ],
            "iPad": [
                CGSize(width: 2048, height: 2732)  // 12.9" display
            ]
        ]
        
        guard let items = try? fileManager.contentsOfDirectory(atPath: screenshotPath) else {
            XCTFail("Screenshots directory not found")
            return
        }
        
        for item in items where item.hasSuffix(".png") {
            let path = (screenshotPath as NSString).appendingPathComponent(item)
            guard let image = NSImage(contentsOfFile: path) else {
                XCTFail("Failed to load image: \(item)")
                continue
            }
            
            let size = image.size
            var validSize = false
            
            for (_, sizes) in requiredSizes {
                if sizes.contains(where: { CGSize(width: size.width, height: size.height) == $0 }) {
                    validSize = true
                    break
                }
            }
            
            XCTAssertTrue(validSize, "Screenshot \(item) has invalid dimensions: \(size)")
        }
    }
    
    func testLocalizationCoverage() throws {
        let locales = ["en", "es", "fr", "de", "ja"]
        let requiredScreenshots = ["Home", "Training", "Assessment"]
        
        for locale in locales {
            for screenshot in requiredScreenshots {
                let fileName = "\(locale)_\(screenshot).png"
                let path = Bundle.main.path(forResource: fileName, ofType: nil, inDirectory: "Screenshots")
                XCTAssertNotNil(path, "Missing screenshot for locale \(locale): \(screenshot)")
            }
        }
    }
    
    func testMetadataCompleteness() throws {
        let bundle = Bundle.main
        
        // Check Info.plist requirements
        let infoPlist = bundle.infoDictionary!
        XCTAssertNotNil(infoPlist["CFBundleDisplayName"])
        XCTAssertNotNil(infoPlist["CFBundleShortVersionString"])
        XCTAssertNotNil(infoPlist["CFBundleVersion"])
        XCTAssertNotNil(infoPlist["LSRequiresIPhoneOS"])
        XCTAssertNotNil(infoPlist["UILaunchStoryboardName"])
        XCTAssertNotNil(infoPlist["UISupportedInterfaceOrientations"])
        
        // Verify privacy descriptions
        let privacyKeys = [
            "NSCameraUsageDescription",
            "NSPhotoLibraryUsageDescription",
            "NSMicrophoneUsageDescription",
            "NSLocationWhenInUseUsageDescription"
        ]
        
        for key in privacyKeys {
            XCTAssertNotNil(infoPlist[key], "Missing privacy description for \(key)")
        }
    }
    
    func testAccessibilityCompliance() throws {
        let screens = [HomeView(), TrainingView(), AssessmentView()]
        
        for screen in screens {
            // Check accessibility labels
            let mirror = Mirror(reflecting: screen)
            for child in mirror.children {
                if let view = child.value as? View {
                    XCTAssertNotNil(view.accessibilityLabel, "Missing accessibility label in \(type(of: screen))")
                }
            }
        }
    }
}