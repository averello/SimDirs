//
//  SimOSVersion.swift
//  SimDirs
//
//  Created by Casey Fleser on 4/30/16.
//  Copyright © 2016 Quiet Spark. All rights reserved.
//

import Foundation

class SimOSVersion: OutlineProvider {
    let name			: String
    var devices			= [SimDevice]()
    
    init(name: String, deviceInfo: [String : AnyObject]) {
        self.name = name
    }
    
    func completeScan(_ platformName: String) {
        for device in self.devices {
            device.completeScan(platformName)
        }
        self.devices.sort { $0.name < $1.name }
    }
    
    func updateWithDeviceInfo(_ deviceInfo: [String : AnyObject], baseURL: URL) {
        guard let deviceName	= deviceInfo["name"] as? String else { return }
        guard let deviceUDID	= deviceInfo["UDID"] as? String else { return }
        guard var deviceType	= deviceInfo["deviceType"] as? String else { return }
        
        deviceType = deviceType.replacingOccurrences(of: "com.apple.CoreSimulator.SimDeviceType.", with: "")
        deviceType = deviceType.replacingOccurrences(of: "-", with: " ")
        
        self.devices.append(SimDevice(name: deviceName, type: deviceType, udid: deviceUDID, baseURL: baseURL))
    }
    
    // MARK: - OutlineProvider -
    
    var outlineTitle	: String { return self.name }
    var outlineImage	: NSImage? { return nil }
    var childCount		: Int { return self.devices.count }
    
    func childAtIndex(_ index: Int) -> OutlineProvider? {
        return self.devices[index]
    }
}
