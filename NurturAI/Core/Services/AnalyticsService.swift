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

	func logPurchaseEvent(transaction: Transaction) {
		let price = transaction.price as? NSDecimalNumber
		let currency = transaction.currency
		facebookAnalytics.logPurchase(amount: price?.doubleValue ?? 0, currency: "\(currency ?? "n/a")")
		Analytics.logTransaction(transaction)
	}
}
