//
//  Animation.swift
//  mmpsp
//
//  Created by Camille Scholtz on 19/07/2021.
//

import SwiftUI

extension Animation {
    func `repeat`(while expression: Bool, autoreverses: Bool = true) -> Animation {
        if expression {
            repeatForever(autoreverses: autoreverses)
        } else {
            self
        }
    }
}
