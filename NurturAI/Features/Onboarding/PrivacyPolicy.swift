//
//  PrivacyPolicy.swift
//  NurturAI
//
//  Created by Scott Leonard on 4/25/26.
//

import SwiftUI

// MARK: - Privacy Policy strings (structured)

extension Strings {

	/// Structured Privacy Policy content. Mirrors the shape of `TermsString`
	/// so the same view styling primitives apply (numbered chip, lead
	/// callout, paragraphs, divider).
	enum PrivacyString {

		static let documentTitle = "Nurtur: AI Baby Assistant — Privacy Policy"
		static let lastUpdated   = "Last updated: April 25, 2026"

		typealias Section = Strings.TermsString.Section

		static let sections: [Section] = [
			Section(
				id: "1",
				title: "Introduction",
				lead: "We take your family's privacy seriously. This Privacy Policy explains what we collect, why we collect it, and the choices you have.",
				paragraphs: [
					"1.1 This Privacy Policy applies to your use of Nurtur: AI Baby Assistant (\"Nurtur,\" \"the App,\" \"we,\" \"us,\" or \"our\") and is incorporated into our Terms of Use by reference.",
					"1.2 By using the App you agree to the collection and use of information in accordance with this Policy. If you do not agree, please do not use the App."
				]
			),

			Section(
				id: "2",
				title: "Information We Collect",
				paragraphs: [
					"2.1 **Account information.** When you sign in with Apple we receive a stable, anonymous identifier and (if you choose to share them) your name and email address. We do not receive your Apple ID password.",
					"2.2 **Baby and care data.** Information you enter about your baby — including name, birthday, feeding method, and logged events such as feeds, sleep sessions, diaper changes, and mood — is stored on your device and synchronised to your private account in our cloud database.",
					"2.3 **AI queries.** When you ask the AI assistant a question, your question and the relevant context (such as recent log summaries) are transmitted to our backend for processing.",
					"2.4 **Subscription data.** Apple processes your purchases. We receive a record of your active entitlement (whether you are subscribed and to which product), but we do not receive or store your payment-card details.",
					"2.5 **Diagnostic data.** We collect anonymised crash reports and performance metrics so we can fix bugs. These reports do not include your baby's data or your AI questions."
				]
			),

			Section(
				id: "3",
				title: "How We Use Your Information",
				paragraphs: [
					"3.1 To provide and maintain the App, including syncing your data across your devices and any caregivers you have invited.",
					"3.2 To generate AI responses tailored to your baby's logged patterns.",
					"3.3 To process subscriptions and provide customer support.",
					"3.4 To detect, prevent, and address technical issues, abuse, and security threats.",
					"3.5 To comply with legal obligations and enforce our Terms of Use."
				]
			),

			Section(
				id: "4",
				title: "How AI Queries Are Processed",
				paragraphs: [
					"4.1 AI queries are sent to our backend, which forwards them to OpenAI for response generation. We configure these transmissions to omit directly identifying information (such as your name or email) wherever possible.",
					"4.2 OpenAI processes the request under their own data handling policies. We do not permit them to use your queries to train their general-purpose models.",
					"4.3 The AI's response, your original query, and the resulting parsed insight are saved to your private account so you can revisit past advice."
				]
			),

			Section(
				id: "5",
				title: "Data Sharing",
				paragraphs: [
					"5.1 **We do not sell your personal data or your child's data to third parties.**",
					"5.2 We share data only with the service providers that operate the App on our behalf — Apple (sign-in and payments), Firebase / Google (authentication and database hosting), and OpenAI (AI response generation).",
					"5.3 Caregivers you explicitly invite through the in-app sharing feature can read and write your baby's data until you revoke their access.",
					"5.4 We may disclose information if required to do so by law, by valid legal process, or to protect the safety of any person."
				]
			),

			Section(
				id: "6",
				title: "Data Storage and Security",
				paragraphs: [
					"6.1 Your data is stored on your device and in cloud infrastructure operated by Firebase (Google Cloud) in secure, access-controlled environments.",
					"6.2 All data is transmitted between your device and our servers over encrypted connections (HTTPS / TLS).",
					"6.3 Access to your account data is gated by your Sign in with Apple credential and short-lived authentication tokens. We never store your Apple ID password.",
					"6.4 No method of transmission or storage is 100% secure. While we use commercially reasonable safeguards, we cannot guarantee absolute security."
				]
			),

			Section(
				id: "7",
				title: "Data Retention",
				paragraphs: [
					"7.1 We retain your account data for as long as your account is active.",
					"7.2 You may export or delete your data at any time through the App's Settings screen, or by contacting us at the address below.",
					"7.3 When you delete your account, we permanently remove your data from our active systems within 30 days. Backup copies may persist for an additional limited period before being overwritten."
				]
			),

			Section(
				id: "8",
				title: "Your Rights and Choices",
				paragraphs: [
					"8.1 **Access.** You can view your baby's data at any time within the App.",
					"8.2 **Correction.** You can edit or remove individual log entries and profile fields from within the App.",
					"8.3 **Deletion.** You can delete your account and associated data through Settings, or by emailing us.",
					"8.4 **Portability.** On request, we will provide a machine-readable export of your data.",
					"8.5 Depending on where you live (including the EU/UK and California), additional rights may apply under laws such as GDPR, UK GDPR, and the CCPA. To exercise these rights, contact us at the address below."
				]
			),

			Section(
				id: "9",
				title: "Children's Privacy",
				paragraphs: [
					"9.1 The App is intended for use by parents and caregivers who are at least 18 years old.",
					"9.2 The App is not directed at children under the age of 13, and we do not knowingly collect personal information directly from children. Information about a baby that you enter into the App is treated as your own account data.",
					"9.3 If you believe we have inadvertently collected information directly from a child under 13, please contact us and we will delete it."
				]
			),

			Section(
				id: "10",
				title: "International Users",
				paragraphs: [
					"10.1 Nurtur is operated from the United States. If you access the App from outside the United States, your data will be transferred to, stored, and processed in the United States.",
					"10.2 By using the App you consent to such transfer and processing in the United States, which may have data-protection laws different from those in your country."
				]
			),

			Section(
				id: "11",
				title: "Third-Party Services",
				paragraphs: [
					"11.1 The App relies on services provided by Apple, Google (Firebase), and OpenAI. Your use of these services through the App is also subject to their respective privacy policies.",
					"11.2 We are not responsible for the privacy practices of any third-party service we do not control."
				]
			),

			Section(
				id: "12",
				title: "Changes to This Policy",
				paragraphs: [
					"12.1 We may update this Privacy Policy from time to time. We will notify you of material changes through the App or by email and update the \"Last updated\" date above.",
					"12.2 Your continued use of the App after changes become effective constitutes your acceptance of the revised Policy."
				]
			),

			Section(
				id: "13",
				title: "Contact Us",
				paragraphs: [
					"13.1 If you have questions about this Privacy Policy or wish to exercise any of your data rights, contact us using the information below."
				]
			)
		]
	}
}

// MARK: - View

struct PrivacyPolicy: View {

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 28) {
				header

				ForEach(Strings.PrivacyString.sections) { section in
					sectionView(section)
				}

				contactBlock
			}
			.padding(.horizontal, 20)
			.padding(.vertical, 24)
		}
		.background(NurturColors.background.ignoresSafeArea())
		.navigationTitle(Strings.Common.privacyTitle)
		.navigationBarTitleDisplayMode(.inline)
	}

	// MARK: - Header

	private var header: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(Strings.PrivacyString.documentTitle)
				.font(NurturTypography.title2)
				.foregroundStyle(NurturColors.textPrimary)
				.fixedSize(horizontal: false, vertical: true)

			Text(Strings.PrivacyString.lastUpdated)
				.font(NurturTypography.caption)
				.foregroundStyle(NurturColors.textFaint)
		}
		.padding(.bottom, 4)
	}

	// MARK: - Section

	private func sectionView(_ section: Strings.TermsString.Section) -> some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack(alignment: .firstTextBaseline, spacing: 10) {
				Text(section.id)
					.font(NurturTypography.captionMedium)
					.foregroundStyle(.white)
					.padding(.horizontal, 9)
					.padding(.vertical, 3)
					.background(NurturColors.accent, in: Capsule())

				Text(section.title)
					.font(NurturTypography.title3)
					.foregroundStyle(NurturColors.textPrimary)
					.fixedSize(horizontal: false, vertical: true)
			}

			if let lead = section.lead {
				Text(attributed(lead))
					.font(NurturTypography.bodyMedium)
					.foregroundStyle(NurturColors.textPrimary)
					.fixedSize(horizontal: false, vertical: true)
			}

			VStack(alignment: .leading, spacing: 10) {
				ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
					Text(attributed(paragraph))
						.font(NurturTypography.subheadline)
						.foregroundStyle(NurturColors.textSecondary)
						.fixedSize(horizontal: false, vertical: true)
				}
			}

			Divider()
				.background(NurturColors.textFaint.opacity(0.25))
				.padding(.top, 4)
		}
	}

	// MARK: - Contact block (re-uses Terms contact info)

	private var contactBlock: some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(Strings.Common.contactHeading)
				.font(NurturTypography.headline)
				.foregroundStyle(NurturColors.textPrimary)

			if !Strings.TermsString.contact.entity.isEmpty {
				Text(Strings.TermsString.contact.entity)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)
			}

			if !Strings.TermsString.contact.address.isEmpty {
				Text(Strings.TermsString.contact.address)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)
			}

			Text(Strings.TermsString.contact.email)
				.font(NurturTypography.subheadline)
				.foregroundStyle(NurturColors.accent)
		}
		.padding(16)
		.frame(maxWidth: .infinity, alignment: .leading)
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(NurturColors.surfaceWarm)
		)
	}

	// MARK: - Markdown

	private func attributed(_ markdown: String) -> AttributedString {
		(try? AttributedString(
			markdown: markdown,
			options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
		)) ?? AttributedString(markdown)
	}
}

#Preview {
	NavigationStack {
		PrivacyPolicy()
	}
}
