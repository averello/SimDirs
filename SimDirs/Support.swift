//
//  Support.swift
//  SimDirs
//
//  Created by Casey Fleser on 4/30/16.
//  Copyright © 2016 Quiet Spark. All rights reserved.
//
//	Assorted convenience extensions

import Foundation

extension Array {
	mutating func match(_ predicate: (Element) -> Bool, orMake: () -> Element) -> Element {
		let element	: Element
		
        if let index = self.firstIndex(where: predicate) {
			element = self[index]
		}
		else {
			element = orMake()
			self.append(element)
		}
		
		return element
	}
}

extension Collection {
    subscript (safe index: Index) -> Iterator.Element? {
        return self[index]
    }
}

extension String {
	var validPath	: Bool { return FileManager.default.fileExists(atPath: self) }
}

extension URL {
    var validPath	: Bool { return FileManager.default.fileExists(atPath: self.path) }
}

extension PropertyListSerialization {
	class func propertyListWithURL(_ url: URL) -> [String : AnyObject]? {
		guard let plistData	= try? Data(contentsOf: url) else { return nil }
		let plist			: [String : AnyObject]?
		
		do {
			plist = try PropertyListSerialization.propertyList(from: plistData, options: PropertyListSerialization.MutabilityOptions(), format: nil) as? [String : AnyObject]
		} catch {
			plist = nil
		}
		
		return plist
	}
}

