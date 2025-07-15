//
//  main.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

@_exported import Combine
@_exported import Foundation
@_exported import UIKit

#if !DEBUG
    fclose(stdout)
    fclose(stderr)
#endif

import os

let logger = Logger(subsystem: "SubZen", category: "finance")
logger.info("SubZen application starting...")

_ = CurrencyTotalService.shared
_ = ExchangeRateService.shared
_ = NotificationPermissionService.shared

logger.info("Core services initialized")

DispatchQueue.global().async {
    let tempCleanup = FileManager.default
        .temporaryDirectory
        .appendingPathComponent("SubZenTemp")
    try? FileManager.default.removeItem(at: tempCleanup)
}

_ = UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
