//
//  main.swift
//  SubZen
//
//  Created by Star on 2025/7/15.
//

@_exported import Foundation
@_exported import UIKit

#if !DEBUG
    fclose(stdout)
    fclose(stderr)
#endif

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
