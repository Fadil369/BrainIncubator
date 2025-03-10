#!/usr/bin/env swift

import Foundation

struct Version {
    let major: Int
    let minor: Int
    let patch: Int
    
    var string: String {
        return "\(major).\(minor).\(patch)"
    }
    
    static func parse(_ string: String) -> Version? {
        let components = string.split(separator: ".").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return Version(major: components[0], minor: components[1], patch: components[2])
    }
}

struct ReleasePreparation {
    let currentVersion: Version
    let nextVersion: Version
    let updateFiles: [(path: String, searchPattern: String)]
    
    func execute() throws {
        // Update version in Info.plist
        try updateVersion(in: "../Sources/App/Info.plist", 
                        searchKey: "CFBundleShortVersionString",
                        newVersion: nextVersion.string)
        
        // Update version in Package.swift
        try updateVersion(in: "../Package.swift",
                        searchPattern: "version: \"\\d+\\.\\d+\\.\\d+\"",
                        newVersion: "version: \"\(nextVersion.string)\"")
        
        // Update version in appstore_metadata.json
        try updateVersion(in: "../appstore_metadata.json",
                        searchPattern: "\"version\": \"\\d+\\.\\d+\\.\\d+\"",
                        newVersion: "\"version\": \"\(nextVersion.string)\"")
        
        print("✅ Version updated to \(nextVersion.string)")
        print("📝 Don't forget to:")
        print("1. Update changelog")
        print("2. Create git tag")
        print("3. Push changes")
    }
    
    private func updateVersion(in file: String, searchKey: String? = nil, searchPattern: String? = nil, newVersion: String) throws {
        let path = (file as NSString).expandingTildeInPath
        var content = try String(contentsOfFile: path, encoding: .utf8)
        
        if let key = searchKey {
            // Update plist style
            let pattern = "<key>\(key)</key>\\s*<string>\\d+\\.\\d+\\.\\d+</string>"
            let replacement = "<key>\(key)</key>\\n\\t<string>\(newVersion)</string>"
            content = content.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        } else if let pattern = searchPattern {
            // Update based on pattern
            content = content.replacingOccurrences(of: pattern, with: newVersion, options: .regularExpression)
        }
        
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }
}

// Parse arguments
let args = CommandLine.arguments
guard args.count == 2 else {
    print("Usage: prepare_release.swift <version>")
    print("Example: prepare_release.swift 1.2.0")
    exit(1)
}

guard let nextVersion = Version.parse(args[1]) else {
    print("Invalid version format. Use semantic versioning (major.minor.patch)")
    exit(1)
}

// Execute version update
do {
    let preparation = ReleasePreparation(
        currentVersion: Version(major: 1, minor: 0, patch: 0),
        nextVersion: nextVersion,
        updateFiles: []
    )
    try preparation.execute()
} catch {
    print("❌ Error: \(error)")
    exit(1)
}