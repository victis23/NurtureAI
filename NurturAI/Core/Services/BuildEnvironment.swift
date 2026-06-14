//
//  BuildEnvironment.swift
//  NurturAI
//
//  Distinguishes App Store builds from Xcode (debug) and TestFlight builds so
//  analytics can be suppressed everywhere except production.
//

import Foundation

enum BuildEnvironment {
	/// True for Xcode Debug builds (Simulator + device) — the Debug
	/// configuration defines the `DEBUG` compilation flag.
	static var isDebug: Bool {
		#if DEBUG
		return true
		#else
		return false
		#endif
	}

	/// True for TestFlight builds. App Store receipts are named `receipt`,
	/// TestFlight receipts are `sandboxReceipt`, and Xcode/Simulator builds
	/// have no receipt at all.
	static var isTestFlight: Bool {
		Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
	}

	/// True only for real App Store builds. Analytics should fire here and
	/// nowhere else.
	static var isProduction: Bool {
		!isDebug && !isTestFlight
	}
}
