//
//  AnalyticsService.swift
//  NurturAI
//
//  Created by Scott Leonard on 5/27/26.
//

import FacebookCore
import FirebaseAnalytics

class AnalyticsService {
	let facebookAnalytics = AppEvents.shared

	func logPageView(_ page: String, parameters: [String: Any] = [:]) {
		let eventName = "pageView_\(page)"
		logEvent(eventName, parameters: parameters)
	}

	func logEvent(_ event: String, parameters: [String: Any] = [:], transaction: Transaction? = nil) {
		Analytics.logEvent(event, parameters: parameters)

		let eventName = AppEvents.Name(event)

		let fbParameters = parameters
			.reduce(into: [AppEvents.ParameterName: Any]()) { partialResult, genericDictionary in
				partialResult[AppEvents.ParameterName(genericDictionary.key)] = genericDictionary.value
			}

		facebookAnalytics.logEvent(eventName, parameters: fbParameters)

		guard let transaction = transaction else { return }
		logPurchaseEvent(transaction: transaction)
	}

	/// Meta **standard** funnel events. These map to FBSDK's predefined
	/// `AppEvents.Name` constants so Meta recognises them as optimisation-eligible
	/// (powering ad delivery + funnel reporting). Modelled as a NurturAI-owned
	/// enum so call sites don't need to import FacebookCore. Logged *in addition*
	/// to the existing custom `logEvent`/`logPageView` calls — never in place of them.
	enum FunnelEvent {
		case completedRegistration
		case completedTutorial
		case startTrial
		case subscribe

		var fbName: AppEvents.Name {
			switch self {
			case .completedRegistration: return .completedRegistration
			case .completedTutorial:     return .completedTutorial
			case .startTrial:            return .startTrial
			case .subscribe:             return .subscribe
			}
		}
	}

	func logFunnelEvent(_ event: FunnelEvent, valueToSum: Double? = nil, currency: String? = nil) {
		var parameters: [AppEvents.ParameterName: Any] = [:]
		if let currency {
			parameters[AppEvents.ParameterName("fb_currency")] = currency
		}
		if let valueToSum {
			facebookAnalytics.logEvent(event.fbName, valueToSum: valueToSum, parameters: parameters)
		} else {
			facebookAnalytics.logEvent(event.fbName, parameters: parameters)
		}
	}

	func logPurchaseEvent(transaction: Transaction) {
		let price = transaction.price as? NSDecimalNumber
		let currency = transaction.currency
		facebookAnalytics.logPurchase(amount: price?.doubleValue ?? 0, currency: "\(currency ?? "n/a")")
		Analytics.logTransaction(transaction)
	}
}
