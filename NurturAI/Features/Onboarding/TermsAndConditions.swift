//
//  TermsAndConditions.swift
//  NurturAI
//
//  Created by Scott Leonard on 4/25/26.
//

import SwiftUI

struct TermsAndConditions: View {
	@Binding var showTermsAndConditions: Bool
	@Environment(\.appContainer) private var container 
	var hideDoneButton: Bool = false

	var body: some View {
		NavigationStack {
			ScrollView {
				GlassEffectContainer(spacing: 20) {
					VStack(alignment: .leading, spacing: 20) {
						header

						ForEach(Strings.TermsString.sections) { section in
							sectionView(section)
						}

						contactBlock
					}
				}
				.padding(.horizontal, 20)
				.padding(.vertical, 24)
			}
			.nurturScreenBackground()
			.navigationTitle(Strings.Common.termsTitle)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				if !hideDoneButton {
					ToolbarItem(placement: .topBarTrailing) {
						Button(Strings.Common.done) {
							showTermsAndConditions = false
						}
						.font(NurturTypography.bodyMedium)
						.foregroundStyle(NurturColors.accent)
					}
				}
			}
			.onAppear {
				container?.analyticsService.logPageView("termsAndConditions")
			}
		}
	}

	// MARK: - Header

	private var header: some View {
		HStack(alignment: .top, spacing: 14) {
			GlassIconBadge(icon: "doc.text.fill", color: NurturColors.accent, size: 40)

			VStack(alignment: .leading, spacing: 6) {
				Text(Strings.TermsString.documentTitle)
					.font(NurturTypography.title2)
					.foregroundStyle(NurturColors.textPrimary)
					.fixedSize(horizontal: false, vertical: true)

				Text(Strings.TermsString.lastUpdated)
					.font(NurturTypography.caption)
					.foregroundStyle(NurturColors.textFaint)
			}

			Spacer(minLength: 0)
		}
		.padding(20)
		.frame(maxWidth: .infinity, alignment: .leading)
		.nurturGlassCard(cornerRadius: 28)
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
					.background(NurturGradients.accent, in: Capsule())

				Text(section.title)
					.font(NurturTypography.title3)
					.foregroundStyle(NurturColors.textPrimary)
					.fixedSize(horizontal: false, vertical: true)
			}

			if let lead = section.lead {
				leadCallout(lead, isCritical: section.id == "2")
			}

			VStack(alignment: .leading, spacing: 10) {
				ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
					Text(attributed(paragraph))
						.font(NurturTypography.subheadline)
						.foregroundStyle(NurturColors.textSecondary)
						.fixedSize(horizontal: false, vertical: true)
				}
			}

			// Section 8 ("Data and Privacy") gets a push link to the full
			// Privacy Policy. Lives here rather than in the data model so
			// the structured Section type stays a pure value type.
			if section.id == "8" {
				privacyPolicyLink
			}
		}
		.padding(18)
		.frame(maxWidth: .infinity, alignment: .leading)
		.nurturGlassCard(cornerRadius: 22)
	}

	// MARK: - Privacy policy link

	private var privacyPolicyLink: some View {
		NavigationLink {
			PrivacyPolicy()
		} label: {
			HStack(spacing: 10) {
				GlassIconBadge(icon: "lock.shield", color: NurturColors.accent, size: 30)
				Text(Strings.Common.viewPrivacyPolicy)
					.font(NurturTypography.bodyMedium)
				Spacer()
				Image(systemName: "chevron.right")
					.font(.system(size: 12, weight: .semibold))
					.foregroundStyle(NurturColors.textFaint)
			}
			.foregroundStyle(NurturColors.accent)
			.padding(.horizontal, 12)
			.padding(.vertical, 10)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(
				NurturColors.accent.opacity(0.10),
				in: RoundedRectangle(cornerRadius: 14, style: .continuous)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.strokeBorder(NurturColors.accent.opacity(0.22), lineWidth: 1)
			)
		}
		.buttonStyle(.plain)
		.nurturPressable()
		.padding(.top, 4)
	}

	// MARK: - Lead callout

	@ViewBuilder
	private func leadCallout(_ text: String, isCritical: Bool) -> some View {
		if isCritical {
			HStack(alignment: .top, spacing: 10) {
				Image(systemName: "exclamationmark.triangle.fill")
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(NurturColors.danger)
					.padding(.top, 1)

				Text(attributed(text))
					.font(NurturTypography.bodyMedium)
					.foregroundStyle(NurturColors.danger)
					.fixedSize(horizontal: false, vertical: true)
			}
			.padding(14)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(
				NurturColors.danger.opacity(0.08),
				in: RoundedRectangle(cornerRadius: 16, style: .continuous)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.strokeBorder(NurturColors.danger.opacity(0.30), lineWidth: 1)
			)
		} else {
			Text(attributed(text))
				.font(NurturTypography.bodyMedium)
				.foregroundStyle(NurturColors.textPrimary)
				.fixedSize(horizontal: false, vertical: true)
		}
	}

	// MARK: - Contact block

	private var contactBlock: some View {
		HStack(alignment: .top, spacing: 14) {
			GlassIconBadge(icon: "envelope.fill", color: NurturColors.info, size: 34)

			VStack(alignment: .leading, spacing: 6) {
				Text(Strings.Common.contactHeading)
					.font(NurturTypography.headline)
					.foregroundStyle(NurturColors.textPrimary)

				Text(Strings.TermsString.contact.entity)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)

				Text(Strings.TermsString.contact.address)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.textSecondary)

				Text(Strings.TermsString.contact.email)
					.font(NurturTypography.subheadline)
					.foregroundStyle(NurturColors.accent)
			}

			Spacer(minLength: 0)
		}
		.padding(18)
		.frame(maxWidth: .infinity, alignment: .leading)
		.nurturGlassCard(cornerRadius: 22)
	}

	// MARK: - Markdown

	/// Parses simple inline `**bold**` / `*italic*` markdown so paragraph
	/// emphasis renders as styled runs instead of literal asterisks. Falls
	/// back to a plain AttributedString if parsing fails (it shouldn't).
	private func attributed(_ markdown: String) -> AttributedString {
		(try? AttributedString(
			markdown: markdown,
			options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
		)) ?? AttributedString(markdown)
	}
}

#Preview {
	TermsAndConditions(showTermsAndConditions: .constant(true))
}
