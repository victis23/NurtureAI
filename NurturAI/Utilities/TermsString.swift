//
//  TermsString.swift
//  NurturAI
//
//  Created by Scott Leonard on 4/25/26.
//

import Foundation

extension Strings {

	/// Structured Terms of Use content. Rendered by `TermsAndConditions`.
	///
	/// We keep the terms broken into typed sections (instead of one big
	/// triple-quoted string) so the view can style headings, body, and the
	/// medical-disclaimer callout separately — and so updating one paragraph
	/// can't accidentally re-indent the whole document.
	enum TermsString {

		// MARK: - Document metadata

		static let documentTitle = "Nurtur: AI Baby Assistant — Terms of Use"
		static let lastUpdated   = "Last updated: April 25, 2026"

		// MARK: - Section model

		struct Section: Identifiable {
			/// Section number used as the badge ("1", "2", …) and identity.
			let id: String
			let title: String
			/// Optional bold lead-in rendered as a callout (e.g. the medical
			/// disclaimer warning).
			var lead: String? = nil
			/// Paragraph bodies. Each preserves its inline number ("2.1 …")
			/// and may use **bold** / *italic* markdown — the view parses it
			/// via AttributedString.
			var paragraphs: [String] = []
		}

		// MARK: - Contact block

		struct Contact {
			let entity:  String
			let address: String
			let email:   String
		}

		static let contact = Contact(
			entity:  "Michael Wells",
			address: "",
			email:   "support@trynurtur.com"
		)

		// MARK: - Sections

		static let sections: [Section] = [
			Section(
				id: "1",
				title: "Acceptance of Terms",
				paragraphs: [
					"By downloading, installing, or using Nurtur: AI Baby Assistant (\"Nurtur,\" \"the App,\" \"we,\" \"us,\" or \"our\"), you (\"User,\" \"you,\" or \"Parent/Caregiver\") agree to be bound by these Terms of Use (\"Terms\"). If you do not agree to these Terms, do not use the App.",
					"These Terms constitute a legally binding agreement between you and Nurtur (operated by NurturAI, a FLORIDA corporation)."
				]
			),

			Section(
				id: "2",
				title: "Critical Medical Disclaimer — Read Carefully",
				lead: "NURTUR IS NOT A MEDICAL DEVICE, MEDICAL SERVICE, OR SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE.",
				paragraphs: [
					"2.1 The App provides general parenting information and AI-generated suggestions for informational and organizational purposes only. Nothing in the App constitutes medical advice, diagnosis, or treatment.",
					"2.2 The AI-generated responses in the App are not reviewed by a licensed medical professional in real time and may not account for your child's specific medical history, conditions, or individual circumstances.",
					"2.3 **Always seek the advice of your child's pediatrician or qualified healthcare provider** with any questions you have regarding your child's health, development, symptoms, or medical condition. Never disregard professional medical advice or delay seeking it because of something you read or received from the App.",
					"2.4 **In any medical emergency — including but not limited to difficulty breathing, seizures, loss of consciousness, high fever in a newborn, or any situation where you believe your child's life may be at risk — call 911 or your local emergency services immediately.** Do not use this App during a medical emergency.",
					"2.5 Reliance on any information provided by the App is solely at your own risk."
				]
			),

			Section(
				id: "3",
				title: "Eligibility",
				paragraphs: [
					"3.1 You must be at least 18 years of age to use the App.",
					"3.2 By using the App, you represent and warrant that you are at least 18 years old and have the legal capacity to enter into these Terms.",
					"3.3 The App is intended for use by parents and caregivers of infants and young children. The App is not directed at children under the age of 13, and we do not knowingly collect personal information from children under 13."
				]
			),

			Section(
				id: "4",
				title: "Description of Service",
				paragraphs: [
					"4.1 Nurtur provides an AI-powered baby care assistant that helps parents and caregivers track feeding, sleep, and diaper patterns; receive contextual AI-generated suggestions based on logged data; monitor developmental milestones; and organize care information.",
					"4.2 The App uses third-party artificial intelligence technology (including OpenAI's API) to generate responses. These responses are probabilistic suggestions, not facts, diagnoses, or medical determinations.",
					"4.3 We reserve the right to modify, suspend, or discontinue any part of the Service at any time with or without notice."
				]
			),

			Section(
				id: "5",
				title: "Subscriptions and Payments",
				paragraphs: [
					"5.1 Nurtur offers a free tier with limited features and paid subscription plans (\"Nurtur Pro,\" \"Nurtur Family\") as described in the App at the time of purchase.",
					"5.2 Subscriptions are billed through Apple's App Store and are subject to Apple's payment terms. We do not directly process or store your payment information.",
					"5.3 Subscription fees are charged at the beginning of each billing period. All fees are non-refundable except as required by applicable law or Apple's refund policies.",
					"5.4 Free trials, where offered, automatically convert to paid subscriptions at the end of the trial period unless cancelled before the trial ends. You may cancel at any time through your Apple ID Account Settings.",
					"5.5 We reserve the right to change subscription pricing with reasonable advance notice."
				]
			),

			Section(
				id: "6",
				title: "User Accounts",
				paragraphs: [
					"6.1 You may be required to create an account to access certain features. You are responsible for maintaining the confidentiality of your account credentials and for all activity that occurs under your account.",
					"6.2 You agree to provide accurate and complete information when creating your account and to update it as necessary.",
					"6.3 You must notify us immediately of any unauthorized use of your account at \(contact.email).",
					"6.4 We reserve the right to terminate accounts that violate these Terms."
				]
			),

			Section(
				id: "7",
				title: "Caregiver Sharing",
				paragraphs: [
					"7.1 The App allows you to share access to your baby's data with designated caregivers (\"Shared Users\").",
					"7.2 You are responsible for ensuring that any Shared Users you invite have agreed to these Terms.",
					"7.3 You represent that you have the legal authority to share the child's information with the designated Shared Users.",
					"7.4 You may revoke caregiver access at any time through the App settings."
				]
			),

			Section(
				id: "8",
				title: "Data and Privacy",
				paragraphs: [
					"8.1 Your use of the App is also governed by our Privacy Policy, which is incorporated into these Terms by reference. You can review our Privacy Policy by tapping the button below.",
					"8.2 You retain ownership of all personal data you enter into the App, including your baby's health and care information.",
					"8.3 By using the App, you grant us a limited, non-exclusive license to process your data solely for the purpose of providing the Service to you.",
					"8.4 We do not sell your personal data or your child's data to third parties.",
					"8.5 AI queries submitted through the App may be transmitted to third-party AI providers (including OpenAI) for processing. These providers have their own data handling policies. We configure these transmissions to minimize personally identifiable information where possible.",
					"8.6 You may request deletion of your account and associated data at any time by contacting us at \(contact.email). Deletion requests will be processed within 30 days."
				]
			),

			Section(
				id: "9",
				title: "Acceptable Use",
				lead: "You agree not to:",
				paragraphs: [
					"9.1 Use the App for any unlawful purpose or in violation of these Terms.",
					"9.2 Attempt to reverse engineer, decompile, or extract the source code of the App.",
					"9.3 Use the App to transmit any harmful, offensive, or inappropriate content.",
					"9.4 Attempt to gain unauthorized access to any part of the App or its infrastructure.",
					"9.5 Use the App in any way that could damage, disable, or impair the Service.",
					"9.6 Share your account credentials with anyone other than designated caregivers using the App's built-in sharing feature.",
					"9.7 Rely on the App as your sole source of guidance in any medical or emergency situation."
				]
			),

			Section(
				id: "10",
				title: "Intellectual Property",
				paragraphs: [
					"10.1 The App and all of its content, features, and functionality — including but not limited to text, graphics, logos, icons, and software — are owned by [YOUR LEGAL ENTITY NAME] and are protected by applicable intellectual property laws.",
					"10.2 These Terms do not grant you any right, title, or interest in the App beyond a limited, revocable license to use the App in accordance with these Terms.",
					"10.3 The AI-generated responses produced by the App are provided for your personal, non-commercial use only and may not be reproduced or redistributed."
				]
			),

			Section(
				id: "11",
				title: "Third-Party Services",
				paragraphs: [
					"11.1 The App integrates with third-party services including but not limited to Apple (authentication and payments), Firebase/Google (data storage and authentication), and OpenAI (AI response generation).",
					"11.2 Your use of these third-party services is subject to their respective terms of service and privacy policies. We are not responsible for the practices of any third-party service providers.",
					"11.3 We are not responsible for the availability, accuracy, or content of any third-party services."
				]
			),

			Section(
				id: "12",
				title: "Disclaimer of Warranties",
				paragraphs: [
					"12.1 THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED.",
					"12.2 TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, WE DISCLAIM ALL WARRANTIES INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, AND NON-INFRINGEMENT.",
					"12.3 WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF VIRUSES OR OTHER HARMFUL COMPONENTS.",
					"12.4 WE DO NOT WARRANT THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY AI-GENERATED CONTENT IN THE APP. AI RESPONSES ARE PROBABILISTIC SUGGESTIONS AND MAY BE INCORRECT."
				]
			),

			Section(
				id: "13",
				title: "Limitation of Liability",
				paragraphs: [
					"13.1 TO THE FULLEST EXTENT PERMITTED BY APPLICABLE LAW, [YOUR LEGAL ENTITY NAME] AND ITS OFFICERS, DIRECTORS, EMPLOYEES, AND AGENTS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO YOUR USE OF THE APP.",
					"13.2 IN NO EVENT SHALL OUR TOTAL LIABILITY TO YOU EXCEED THE GREATER OF (A) THE AMOUNT YOU PAID US IN THE 12 MONTHS PRECEDING THE CLAIM, OR (B) $100.",
					"13.3 SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OR LIMITATION OF CERTAIN DAMAGES. IN SUCH JURISDICTIONS, OUR LIABILITY SHALL BE LIMITED TO THE GREATEST EXTENT PERMITTED BY LAW.",
					"13.4 YOU ACKNOWLEDGE THAT THE LIMITATIONS OF LIABILITY IN THIS SECTION ARE A FUNDAMENTAL ELEMENT OF THE BASIS OF THE BARGAIN BETWEEN YOU AND US, AND THAT THE APP WOULD NOT BE PROVIDED WITHOUT SUCH LIMITATIONS."
				]
			),

			Section(
				id: "14",
				title: "Indemnification",
				paragraphs: [
					"You agree to indemnify, defend, and hold harmless [YOUR LEGAL ENTITY NAME] and its officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, and expenses (including reasonable attorneys' fees) arising out of or in any way connected with your access to or use of the App, your violation of these Terms, or your violation of any rights of another party."
				]
			),

			Section(
				id: "15",
				title: "Governing Law and Dispute Resolution",
				paragraphs: [
					"15.1 These Terms shall be governed by the laws of the State of [YOUR STATE], without regard to its conflict of law provisions.",
					"15.2 Any dispute arising out of or relating to these Terms or the App shall be resolved by binding arbitration in [YOUR CITY, STATE] under the rules of the American Arbitration Association, except that either party may seek injunctive relief in any court of competent jurisdiction.",
					"15.3 YOU WAIVE YOUR RIGHT TO A JURY TRIAL AND TO PARTICIPATE IN CLASS ACTION LITIGATION.",
					"15.4 Notwithstanding the foregoing, you agree that we may seek injunctive or other equitable relief in any court of competent jurisdiction to protect our intellectual property rights."
				]
			),

			Section(
				id: "16",
				title: "Changes to Terms",
				paragraphs: [
					"16.1 We reserve the right to modify these Terms at any time. We will notify you of material changes through the App or by email.",
					"16.2 Your continued use of the App after changes become effective constitutes your acceptance of the revised Terms.",
					"16.3 If you do not agree to the revised Terms, you must stop using the App."
				]
			),

			Section(
				id: "17",
				title: "Termination",
				paragraphs: [
					"17.1 We may terminate or suspend your access to the App at any time, with or without cause, with or without notice.",
					"17.2 Upon termination, your right to use the App ceases immediately.",
					"17.3 You may request export of your data prior to termination by contacting \(contact.email).",
					"17.4 Provisions of these Terms that by their nature should survive termination shall survive, including Sections 2, 10, 12, 13, 14, and 15."
				]
			),

			Section(
				id: "18",
				title: "Miscellaneous",
				paragraphs: [
					"18.1 **Entire Agreement.** These Terms and our Privacy Policy constitute the entire agreement between you and us regarding the App.",
					"18.2 **Severability.** If any provision of these Terms is found to be unenforceable, the remaining provisions will remain in full force and effect.",
					"18.3 **No Waiver.** Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights.",
					"18.4 **Assignment.** You may not assign these Terms or any rights hereunder without our prior written consent. We may assign these Terms without restriction."
				]
			)
		]
	}
}
