//
//  NSAppleEventDescriptor+MusicPlayerPopup.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 02/06/2021.
//

import SwiftUI

extension NSAppleEventDescriptor {
	func listItems() -> [Int: String] {
		guard numberOfItems > 0 else {
			return [:]
		}
		
		var items = [Int: String]()
		
		for i in 1...numberOfItems {
			items[i] = atIndex(i)?.stringValue ?? ""
		}
		
		return items
	}
}
