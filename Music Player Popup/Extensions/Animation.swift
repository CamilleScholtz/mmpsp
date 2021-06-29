//
//  Animation.swift
//  Music Player Popup
//
//  Created by Camille Scholtz on 28/06/2021.
//

import SwiftUI

extension Animation {
	func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
		if expression {
			return self.repeatForever(autoreverses: autoreverses)
		} else {
			return self
		}
	}
}
