//
//  wakeLock.swift
//  Runner
//
//  Created by Godwin Asuquo on 1/21/22.
//

import Foundation
import UIKit

func enableWakeScreen() -> String {
    UIApplication.shared.isIdleTimerDisabled = true

    return "screen wake turned ON"
}

func disableWakeScreen() -> String{
    UIApplication.shared.isIdleTimerDisabled = false
    return "screen wake turned OFF"
}
