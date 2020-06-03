//
//  SimDevice.swift
//  SimDirs
//
//  Created by Casey Fleser on 4/30/16.
//  Copyright © 2016 Quiet Spark. All rights reserved.
//

import Foundation

class SimDevice: OutlineProvider, PropertyProvider {
    let name			: String
    let type			: String
    let udid			: String
    let baseURL			: URL
    var platformName	= "Unknown"
    var platformVersion	= ""
    var platformBuild	= ""
    var apps			= [SimApp]()
    
    init(name: String, type: String, udid: String, baseURL: URL) {
        self.name = name
        self.type = type
        self.udid = udid
        self.baseURL = baseURL
        
        self.gatherBuildInfo()
        
        self.gatherAppInfoFromLastLaunchMap()
        self.gatherAppInfoFromAppState()
        //		self.gatherAppInfoFromCaches()	obsolete
        self.gatherAppInfoFromInstallLogs()
    }
    
    func completeScan(_ platformName: String) {
        self.platformName = platformName
        self.apps = self.apps.filter { return $0.hasValidPaths }
        
        for app in self.apps {
            app.completeScan()
        }
        self.apps.sort { $0.displayName < $1.displayName }
    }
    
    func gatherBuildInfo() {
        let buildInfoURL	= self.baseURL.appendingPathComponent("data/Library/MobileInstallation/LastBuildInfo.plist")
        guard let buildInfo	= PropertyListSerialization.propertyListWithURL(buildInfoURL) else { return }
        
        self.platformVersion = buildInfo["ProductVersion"] as? String ?? ""
        self.platformBuild = buildInfo["ProductBuildVersion"] as? String ?? ""
    }
    
    // LastLaunchServicesMap.plist seems to be the most reliable location to gather app info
    func gatherAppInfoFromLastLaunchMap() {
        let launchMapInfoURL	= self.baseURL.appendingPathComponent("data/Library/MobileInstallation/LastLaunchServicesMap.plist")
        guard let launchInfo	= PropertyListSerialization.propertyListWithURL(launchMapInfoURL) else { return }
        guard let userInfo		= launchInfo["User"] as? [String : AnyObject] else { return }
        
        for (bundleID, bundleInfo) in userInfo {
            guard let bundleInfo	= bundleInfo as? [String : AnyObject] else { continue }
            let simApp				= self.apps.match({ $0.bundleID == bundleID }, orMake: { SimApp(bundleID: bundleID) })
            
            simApp.updateFromLastLaunchMapInfo(bundleInfo)
        }
    }
    
    // applicationState.plist sometimes has info that LastLaunchServicesMap.plist doesn't
    func gatherAppInfoFromAppState() {
        for pathComponent in ["data/Library/FrontBoard/applicationState.plist", "data/Library/BackBoard/applicationState.plist"] {
            let appStateInfoURL		= self.baseURL.appendingPathComponent(pathComponent)
            guard let stateInfo		= PropertyListSerialization.propertyListWithURL(appStateInfoURL) else { continue }
            
            for (bundleID, bundleInfo) in stateInfo {
                if !bundleID.contains("com.apple") {
                    guard let bundleInfo	= bundleInfo as? [String : AnyObject] else { continue }
                    let simApp				= self.apps.match({ $0.bundleID == bundleID }, orMake: { SimApp(bundleID: bundleID) })
                    
                    simApp.updateFromAppStateInfo(bundleInfo)
                }
            }
        }
    }
    
    // mobile_installation.log.0 is my least favorite, most fragile way to scan for app installations
    // try this after everything else
    func gatherAppInfoFromInstallLogs() {
        let installLogURL	= self.baseURL.appendingPathComponent("data/Library/Logs/MobileInstallation/mobile_installation.log.0")
        
        if let installLog = try? String(contentsOf: installLogURL) {
            let lines	= installLog.components(separatedBy: CharacterSet.newlines)
            
            for line in lines.reversed() {
                if !line.contains("com.apple") {
                    if line.contains("makeContainerLiveReplacingContainer") {
                        self.extractBundleLocationFromLogEntry(line)
                    }
                    if line.contains("_refreshUUIDForContainer") {
                        self.extractSandboxLocationFromLogEntry(line)
                    }
                }
            }
        }
    }
    
    func extractBundleLocationFromLogEntry(_ line: String) {
        let logComponents = line.components(separatedBy: " ")
        
        if let bundlePath = logComponents.last {
            if let bundleID = logComponents[safe: logComponents.count - 3] {
                let simApp	= self.apps.match({ $0.bundleID == bundleID }, orMake: { SimApp(bundleID: bundleID) })
                
                simApp.bundlePath = bundlePath
            }
        }
    }
    
    func extractSandboxLocationFromLogEntry(_ line: String) {
        let logComponents = line.components(separatedBy: " ")
        
        if let sandboxPath = logComponents.last {
            if let bundleID = logComponents[safe: logComponents.count - 5] {
                let simApp	= self.apps.match({ $0.bundleID == bundleID }, orMake: { SimApp(bundleID: bundleID) })
                
                simApp.sandboxPath = sandboxPath
            }
        }
    }
    
    // MARK: - OutlineProvider -
    
    var outlineTitle	: String { return self.name }
    var outlineImage	: NSImage? { return nil }
    var childCount		: Int { return self.apps.count  }
    
    func childAtIndex(_ index: Int) -> OutlineProvider? {
        return self.apps[index]
    }
    
    // MARK: - PropertyProvider -
    var header		: String { return "Device Information" }
    var image		: NSImage? { return nil }
    var properties	: [SimProperty] {
        return [
            SimProperty(title: "Name", value: .text(text: self.name)),
            SimProperty(title: "Simulated Model", value: .text(text: self.type)),
            SimProperty(title: self.platformName, value: .text(text: "\(self.platformVersion) (\(self.platformBuild))")),
            SimProperty(title: "Identifier", value: .text(text: self.udid)),
            SimProperty(title: "Location", value: .location(url: self.baseURL))
        ]
    }
}
