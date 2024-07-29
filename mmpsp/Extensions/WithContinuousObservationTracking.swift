//
//  withContinuousObservationTracking.swift
//  mmpsp
//
//  Created by Camille Scholtz on 29/07/2024.
//

import SwiftUI

// TODO: Kinda hacky? Maybe swift 5.10 will have a native function.
func withContinuousObservationTracking<T: Equatable>(of value: @escaping @autoclosure () -> T, execute: @escaping (T) -> Void) {
    let currentValue = value()

    withObservationTracking {
        _ = value()
    } onChange: {
        Task { @MainActor in
            if currentValue != value() {
                execute(value())
            }
            
            withContinuousObservationTracking(of: value(), execute: execute)
        }
    }
}
