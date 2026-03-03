import SwiftUI

struct SetupWizardView: View {
    @Bindable var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var step: Int = 1
    private let totalSteps = 7

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            TabView(selection: $step) {
                languageStep.tag(1)
                locationStep.tag(2)
                calculationStep.tag(3)
                iqamaStep.tag(4)
                jumuahStep.tag(5)
                themeStep.tag(6)
                doneStep.tag(7)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            navigationButtons
        }
        .navigationTitle("Setup Wizard")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color(.systemGray5))
                Rectangle()
                    .fill(
                        LinearGradient(colors: [DSTokens.Palette.deepBlue, DSTokens.Palette.accent], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(width: geo.size.width * CGFloat(step) / CGFloat(totalSteps))
                    .animation(.spring, value: step)
            }
        }
        .frame(height: 4)
    }

    private var navigationButtons: some View {
        HStack {
            if step > 1 {
                Button { withAnimation { step -= 1 } } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
            Spacer()
            if step < totalSteps {
                Button {
                    withAnimation { step += 1 }
                } label: {
                    Label("Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(DS.Spacing.md)
    }

    private var languageStep: some View {
        VStack(spacing: DS.Spacing.lg) {
            stepHeader(icon: "globe", title: "Language", subtitle: "Choose display language")

            ForEach(AppLanguage.allCases, id: \.self) { lang in
                Button {
                    store.display.language = lang
                } label: {
                    HStack {
                        Text(lang.displayName)
                            .font(.title3.weight(.medium))
                        Spacer()
                        if store.display.language == lang {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(DS.Spacing.md)
                    .background(store.display.language == lang ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: DS.Radius.md))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
    }

    private var locationStep: some View {
        VStack(spacing: DS.Spacing.lg) {
            stepHeader(icon: "location.fill", title: "Location", subtitle: "Select mosque location")

            ForEach(LocationConfig.presets, id: \.cityName) { preset in
                Button {
                    store.location = preset
                    store.regenerateSchedule()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.cityName)
                                .font(.headline)
                            Text(preset.timezone)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.location.cityName == preset.cityName {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(DS.Spacing.md)
                    .background(store.location.cityName == preset.cityName ? Color.blue.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: DS.Radius.md))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(DS.Spacing.md)
    }

    private var calculationStep: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                stepHeader(icon: "function", title: "Calculation", subtitle: "Prayer calculation method")

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Method")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(CalculationMethod.allCases, id: \.self) { method in
                        Button {
                            store.calculation.method = method
                        } label: {
                            HStack {
                                Text(method.displayName)
                                    .font(.body)
                                Spacer()
                                if store.calculation.method == method {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(DS.Spacing.sm)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: DS.Radius.sm))
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    Text("Madhab")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Madhab", selection: $store.calculation.madhab) {
                        ForEach(Madhab.allCases, id: \.self) { m in
                            Text(m.displayName).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(DS.Spacing.md)
        }
    }

    private var iqamaStep: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                stepHeader(icon: "bell.fill", title: "Iqama", subtitle: "Configure iqama wait times")

                Toggle("Enable Iqama", isOn: $store.iqama.enabled)
                    .padding(DS.Spacing.md)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: DS.Radius.md))

                if store.iqama.enabled {
                    VStack(spacing: DS.Spacing.sm) {
                        iqamaRow(prayer: .fajr, value: $store.iqama.iqamaMinutes.fajr)
                        iqamaRow(prayer: .dhuhr, value: $store.iqama.iqamaMinutes.dhuhr)
                        iqamaRow(prayer: .asr, value: $store.iqama.iqamaMinutes.asr)
                        iqamaRow(prayer: .maghrib, value: $store.iqama.iqamaMinutes.maghrib)
                        iqamaRow(prayer: .isha, value: $store.iqama.iqamaMinutes.isha)
                    }
                }
            }
            .padding(DS.Spacing.md)
        }
    }

    private func iqamaRow(prayer: Prayer, value: Binding<Int>) -> some View {
        HStack {
            Image(systemName: prayer.iconName)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(prayer.displayName)
                .font(.body)
            Spacer()
            Stepper("\(value.wrappedValue) min", value: value, in: 3...60, step: prayer == .maghrib ? 1 : 5)
                .fixedSize()
        }
        .padding(DS.Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: DS.Radius.sm))
    }

    private var jumuahStep: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                stepHeader(icon: "building.columns.fill", title: "Jumu'ah", subtitle: "Friday prayer settings")

                Toggle("Enable Jumu'ah Mode", isOn: $store.jumuah.enabled)
                    .padding(DS.Spacing.md)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: DS.Radius.md))

                if store.jumuah.enabled {
                    VStack(spacing: DS.Spacing.sm) {
                        HStack {
                            Label("Jumu'ah Time", systemImage: "clock")
                            Spacer()
                            TextField("HH:mm", text: $store.jumuah.jumuahTime)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numbersAndPunctuation)
                                .frame(width: 80)
                                .foregroundStyle(.secondary)
                        }
                        .padding(DS.Spacing.sm)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: DS.Radius.sm))

                        HStack {
                            Label("Iqama Wait", systemImage: "bell")
                            Spacer()
                            Stepper("\(store.jumuah.jumuahIqamaMinutes) min", value: $store.jumuah.jumuahIqamaMinutes, in: 5...60, step: 5)
                                .fixedSize()
                        }
                        .padding(DS.Spacing.sm)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: DS.Radius.sm))

                        Toggle("Second Jumu'ah", isOn: $store.jumuah.secondJumuahEnabled)
                            .padding(DS.Spacing.sm)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: DS.Radius.sm))

                        if store.jumuah.secondJumuahEnabled {
                            HStack {
                                Label("Second Time", systemImage: "clock.badge.checkmark")
                                Spacer()
                                TextField("HH:mm", text: $store.jumuah.secondJumuahTime)
                                    .multilineTextAlignment(.trailing)
                                    .keyboardType(.numbersAndPunctuation)
                                    .frame(width: 80)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(DS.Spacing.sm)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: DS.Radius.sm))
                        }
                    }

                    Text("On Fridays, Dhuhr will be replaced with Jumu'ah prayer time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(DS.Spacing.md)
        }
    }

    private var themeStep: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                stepHeader(icon: "paintpalette.fill", title: "Theme", subtitle: "Choose display theme")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.sm) {
                    ForEach(ThemeDefinition.allThemes) { theme in
                        Button {
                            store.selectedTheme = theme.id
                        } label: {
                            ThemeThumbnailCard(theme: theme, isSelected: store.selectedTheme == theme.id)
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Layout")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Picker("Layout", selection: $store.display.layout) {
                        ForEach(LayoutPreset.allCases, id: \.self) { l in
                            Text(l.displayName).tag(l)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(DS.Spacing.md)
        }
    }

    private var doneStep: some View {
        VStack(spacing: DS.Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .symbolEffect(.bounce)

            Text("Setup Complete!")
                .font(.title.bold())

            Text("Your Masjid display is configured. Preview the display or push settings to your Raspberry Pi.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.lg)

            Button {
                store.hasCompletedSetup = true
                store.save()
                dismiss()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, DS.Spacing.lg)

            Spacer()
        }
    }

    private func stepHeader(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.blue)
            Text(title)
                .font(.title2.bold())
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, DS.Spacing.xs)
    }
}

struct ThemeThumbnailCard: View {
    let theme: ThemeDefinition
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.palette.background)
                .frame(height: 80)
                .overlay {
                    VStack(spacing: 4) {
                        Text("12:30")
                            .font(.system(size: 20, weight: theme.typography.timeWeight, design: theme.typography.timeFontDesign))
                            .foregroundStyle(theme.palette.textPrimary)
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(theme.palette.primary.opacity(0.5))
                                    .frame(width: 24, height: 6)
                            }
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )

            Text(theme.nameEn)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}
