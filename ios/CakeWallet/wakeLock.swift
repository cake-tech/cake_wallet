//
//  wakeLock.swift
//  Runner
//
//  Created by Godwin Asuquo on 1/21/22.
//

import Foundation
import UIKit

func enableWakeScreen() -> Bool{
    UIApplication.shared.isIdleTimerDisabled = true

    return true
}

func disableWakeScreen() -> Bool{
    UIApplication.shared.isIdleTimerDisabled = false
    return true
}
