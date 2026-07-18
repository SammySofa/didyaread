//
//  ContentView.swift
//  didyaread
//
//  Created by Samuel Couch on 7/18/26.
//

import Network
import SwiftUI
import UserNotifications

enum Reader: String, CaseIterable, Identifiable {
    case sam = "Sam"
    case liana = "Liana"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .sam:
            return .yellow
        case .liana:
            return .blue
        }
    }

    var textColor: Color {
        self == .sam ? .black : .white
    }

    var otherReader: Reader {
        self == .sam ? .liana : .sam
    }
}

enum ReadingDay: Int, CaseIterable, Identifiable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .sunday:
            return "Sunday"
        case .monday:
            return "Monday"
        case .tuesday:
            return "Tuesday"
        case .wednesday:
            return "Wednesday"
        case .thursday:
            return "Thursday"
        case .friday:
            return "Friday"
        case .saturday:
            return "Saturday"
        }
    }
}

enum ReadingGoalType: String, CaseIterable, Identifiable {
    case minutes = "Minutes"
    case pages = "Pages"

    var id: String { rawValue }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

struct ContentView: View {
    @AppStorage("selectedReader") private var selectedReaderRawValue = ""
    @AppStorage("samSelectedReadingDays") private var samSelectedReadingDaysRawValue = "1,2,3,4,5,6,7"
    @AppStorage("samReadingGoalType") private var samReadingGoalTypeRawValue = ReadingGoalType.minutes.rawValue
    @AppStorage("samReadingGoalAmount") private var samReadingGoalAmount = 20
    @AppStorage("samHasConfiguredReadingPlan") private var samHasConfiguredReadingPlan = false
    @AppStorage("samAppearance") private var samAppearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("lianaSelectedReadingDays") private var lianaSelectedReadingDaysRawValue = "1,2,3,4,5,6,7"
    @AppStorage("lianaReadingGoalType") private var lianaReadingGoalTypeRawValue = ReadingGoalType.minutes.rawValue
    @AppStorage("lianaReadingGoalAmount") private var lianaReadingGoalAmount = 20
    @AppStorage("lianaHasConfiguredReadingPlan") private var lianaHasConfiguredReadingPlan = false
    @AppStorage("lianaAppearance") private var lianaAppearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("samCurrentStreak") private var samCurrentStreak = 0
    @AppStorage("samLastReadDate") private var samLastReadDateTimestamp = 0.0
    @AppStorage("samLastPokeDate") private var samLastPokeDateTimestamp = 0.0
    @AppStorage("lianaCurrentStreak") private var lianaCurrentStreak = 0
    @AppStorage("lianaLastReadDate") private var lianaLastReadDateTimestamp = 0.0
    @AppStorage("lianaLastPokeDate") private var lianaLastPokeDateTimestamp = 0.0

    @State private var didReadToday = false
    @State private var showingSettings = false
    @State private var fireworksTrigger = 0
    @State private var isConnected = true
    @State private var monitor: NWPathMonitor?

    private var selectedReader: Reader? {
        Reader(rawValue: selectedReaderRawValue)
    }

    private func selectedReadingDays(for reader: Reader) -> Set<Int> {
        let rawValue = reader == .sam ? samSelectedReadingDaysRawValue : lianaSelectedReadingDaysRawValue
        let values = rawValue
            .split(separator: ",")
            .compactMap { Int($0) }
            .filter { 1...7 ~= $0 }

        return Set(values)
    }

    private func setSelectedReadingDays(_ days: Set<Int>, for reader: Reader) {
        let rawValue = days.sorted().map(String.init).joined(separator: ",")

        switch reader {
        case .sam:
            samSelectedReadingDaysRawValue = rawValue
        case .liana:
            lianaSelectedReadingDaysRawValue = rawValue
        }
    }

    private func toggleReadingDay(_ day: ReadingDay, for reader: Reader) {
        var selectedDays = selectedReadingDays(for: reader)

        if selectedDays.contains(day.rawValue) {
            selectedDays.remove(day.rawValue)
        } else {
            selectedDays.insert(day.rawValue)
        }

        setSelectedReadingDays(selectedDays, for: reader)
    }

    private func readingDaysSummary(for reader: Reader) -> String {
        let selectedDays = selectedReadingDays(for: reader)

        if selectedDays.isEmpty {
            return "no days selected"
        }

        if selectedDays.count == ReadingDay.allCases.count {
            return "every day"
        }

        return ReadingDay.allCases
            .filter { selectedDays.contains($0.rawValue) }
            .map(\.name)
            .joined(separator: ", ")
    }

    private func readingGoalType(for reader: Reader) -> ReadingGoalType {
        let rawValue = reader == .sam ? samReadingGoalTypeRawValue : lianaReadingGoalTypeRawValue
        return ReadingGoalType(rawValue: rawValue) ?? .minutes
    }

    private func setReadingGoalType(_ goalType: ReadingGoalType, for reader: Reader) {
        switch reader {
        case .sam:
            samReadingGoalTypeRawValue = goalType.rawValue
        case .liana:
            lianaReadingGoalTypeRawValue = goalType.rawValue
        }
    }

    private func readingGoalAmount(for reader: Reader) -> Int {
        reader == .sam ? samReadingGoalAmount : lianaReadingGoalAmount
    }

    private func setReadingGoalAmount(_ amount: Int, for reader: Reader) {
        switch reader {
        case .sam:
            samReadingGoalAmount = amount
        case .liana:
            lianaReadingGoalAmount = amount
        }
    }

    private func hasConfiguredReadingPlan(for reader: Reader) -> Bool {
        reader == .sam ? samHasConfiguredReadingPlan : lianaHasConfiguredReadingPlan
    }

    private func setHasConfiguredReadingPlan(_ isConfigured: Bool, for reader: Reader) {
        switch reader {
        case .sam:
            samHasConfiguredReadingPlan = isConfigured
        case .liana:
            lianaHasConfiguredReadingPlan = isConfigured
        }
    }

    private func appearance(for reader: Reader) -> AppAppearance {
        let rawValue = reader == .sam ? samAppearanceRawValue : lianaAppearanceRawValue
        return AppAppearance(rawValue: rawValue) ?? .system
    }

    private func setAppearance(_ appearance: AppAppearance, for reader: Reader) {
        switch reader {
        case .sam:
            samAppearanceRawValue = appearance.rawValue
        case .liana:
            lianaAppearanceRawValue = appearance.rawValue
        }
    }

    private func currentStreak(for reader: Reader) -> Int {
        switch reader {
        case .sam:
            return samCurrentStreak
        case .liana:
            return lianaCurrentStreak
        }
    }

    private func setCurrentStreak(_ streak: Int, for reader: Reader) {
        switch reader {
        case .sam:
            samCurrentStreak = streak
        case .liana:
            lianaCurrentStreak = streak
        }
    }

    private func lastReadDate(for reader: Reader) -> Date? {
        let timestamp: Double
        switch reader {
        case .sam:
            timestamp = samLastReadDateTimestamp
        case .liana:
            timestamp = lianaLastReadDateTimestamp
        }

        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    private func setLastReadDate(_ date: Date, for reader: Reader) {
        switch reader {
        case .sam:
            samLastReadDateTimestamp = date.timeIntervalSince1970
        case .liana:
            lianaLastReadDateTimestamp = date.timeIntervalSince1970
        }
    }

    private func hasReadToday(_ reader: Reader) -> Bool {
        guard let lastReadDate = lastReadDate(for: reader) else { return false }
        return Calendar.current.isDateInToday(lastReadDate)
    }

    private func lastPokeDate(for reader: Reader) -> Date? {
        let timestamp: Double
        switch reader {
        case .sam:
            timestamp = samLastPokeDateTimestamp
        case .liana:
            timestamp = lianaLastPokeDateTimestamp
        }

        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }

    private func setLastPokeDate(_ date: Date, for reader: Reader) {
        switch reader {
        case .sam:
            samLastPokeDateTimestamp = date.timeIntervalSince1970
        case .liana:
            lianaLastPokeDateTimestamp = date.timeIntervalSince1970
        }
    }

    private func hasPokedToday(_ reader: Reader) -> Bool {
        guard let lastPokeDate = lastPokeDate(for: reader) else { return false }
        return Calendar.current.isDateInToday(lastPokeDate)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let selectedReader {
                    dashboard(for: selectedReader)
                } else {
                    loginView
                }
            }
            .navigationTitle("Did Ya Read?")
            .toolbar {
                if selectedReader != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                        }
                        .accessibilityLabel("Reading settings")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                if let selectedReader {
                    settingsView(for: selectedReader)
                        .presentationDetents([.large])
                }
            }
        }
        .preferredColorScheme(selectedReader.map { appearance(for: $0).colorScheme } ?? nil)
        .onAppear {
            requestNotificationPermission()
            startNetworkMonitor()

            if let selectedReader {
                refreshDailyState(for: selectedReader)

                if !hasConfiguredReadingPlan(for: selectedReader) {
                    showingSettings = true
                }
            }
        }
        .task(id: selectedReaderRawValue) {
            await refreshDailyStateAtMidnight()
        }
    }

    private var loginView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose your account:")
                    .font(.largeTitle.bold())
            }

            VStack(spacing: 14) {
                ForEach(Reader.allCases) { reader in
                    Button {
                        selectedReaderRawValue = reader.rawValue
                        refreshDailyState(for: reader)

                        if !hasConfiguredReadingPlan(for: reader) {
                            showingSettings = true
                        }
                    } label: {
                        HStack {
                            Text(reader.rawValue)
                                .font(.title2.bold())
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .foregroundStyle(reader.textColor)
                        .background(reader.color, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding(24)
    }

    private func dashboard(for reader: Reader) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                connectionBanner

                VStack(alignment: .leading, spacing: 10) {
                    Text("Hi, \(reader.rawValue)")
                        .font(.largeTitle.bold())
                    Text("Your plan: \(readingDaysSummary(for: reader)), \(readingGoalAmount(for: reader)) \(readingGoalType(for: reader).rawValue.lowercased()).")
                        .foregroundStyle(.secondary)
                }

                streakPanel(for: reader)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Today")
                        .font(.title2.bold())

                    Button {
                        didReadToday.toggle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: didReadToday ? "checkmark.square.fill" : "square")
                                .font(.title2)
                                .foregroundStyle(didReadToday ? .green : .secondary)
                                .frame(width: 28, height: 28)

                            Text("I read!")
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(hasReadToday(reader))

                    let submitDisabled = !didReadToday || hasReadToday(reader) || !isConnected

                    Button {
                        submitReading(for: reader)
                    } label: {
                        Label(hasReadToday(reader) ? "Nice!" : "Tell \(reader.otherReader.rawValue) you read!", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .padding(.vertical, 12)
                            .foregroundStyle(submitDisabled ? Color.secondary : reader.textColor)
                            .background(submitDisabled ? Color(.tertiarySystemFill) : reader.color, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(submitDisabled)
                }
                .padding(18)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .center) {
                    FireworksBurst(trigger: fireworksTrigger)
                        .allowsHitTesting(false)
                }

                let pokeDisabled = hasPokedToday(reader) || !isConnected

                Button {
                    pokeOtherReader(from: reader)
                } label: {
                    Label(hasPokedToday(reader) ? "Poked \(reader.otherReader.rawValue) today" : "Poke \(reader.otherReader.rawValue)", systemImage: "hand.tap.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, 10)
                        .foregroundStyle(pokeDisabled ? Color.secondary : reader.textColor)
                        .background(pokeDisabled ? Color(.tertiarySystemFill) : reader.color, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(pokeDisabled)

                Button(role: .destructive) {
                    selectedReaderRawValue = ""
                    didReadToday = false
                } label: {
                    Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
        }
        .refreshable {
            refreshDailyState(for: reader)
        }
    }

    private var connectionBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: isConnected ? "wifi" : "wifi.slash")
            Text(isConnected ? "Connected" : "Internet connection required")
                .font(.subheadline.weight(.medium))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isConnected ? Color.green.opacity(0.16) : Color.red.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(isConnected ? .green : .red)
    }

    private func streakPanel(for reader: Reader) -> some View {
        let streak = currentStreak(for: reader)

        return HStack(spacing: 18) {
            Image(systemName: "flame.fill")
                .font(.system(size: 38))
                .foregroundStyle(.orange)
                .frame(width: 54, height: 54)
                .background(Color.orange.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("\(streak)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text(streak == 1 ? "day reading streak" : "days reading streak")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func settingsView(for reader: Reader) -> some View {
        NavigationStack {
            Form {
                Section("Reading days") {
                    ForEach(ReadingDay.allCases) { day in
                        Button {
                            toggleReadingDay(day, for: reader)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedReadingDays(for: reader).contains(day.rawValue) ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundStyle(selectedReadingDays(for: reader).contains(day.rawValue) ? .green : .secondary)
                                    .frame(width: 24, height: 24)

                                Text(day.name)
                                    .foregroundStyle(.primary)

                                Spacer()
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Reading goal") {
                    Picker("Goal type", selection: Binding(
                        get: { readingGoalType(for: reader) },
                        set: { setReadingGoalType($0, for: reader) }
                    )) {
                        ForEach(ReadingGoalType.allCases) { goalType in
                            Text(goalType.rawValue).tag(goalType)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Goal: \(readingGoalAmount(for: reader)) \(readingGoalType(for: reader).rawValue.lowercased())")
                            .foregroundStyle(.secondary)

                        Picker("Goal amount", selection: Binding(
                            get: { readingGoalAmount(for: reader) },
                            set: { setReadingGoalAmount($0, for: reader) }
                        )) {
                            ForEach(1...300, id: \.self) { amount in
                                Text("\(amount)")
                                    .tag(amount)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 150)
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: Binding(
                        get: { appearance(for: reader) },
                        set: { setAppearance($0, for: reader) }
                    )) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.rawValue).tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("\(reader.rawValue)'s Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        setHasConfiguredReadingPlan(true, for: reader)
                        showingSettings = false
                    }
                }
            }
        }
        .preferredColorScheme(appearance(for: reader).colorScheme)
    }

    private func submitReading(for reader: Reader) {
        let now = Date()
        let lastReadDate = lastReadDate(for: reader)

        if let lastReadDate, Calendar.current.isDateInYesterday(lastReadDate) {
            setCurrentStreak(currentStreak(for: reader) + 1, for: reader)
        } else if !hasReadToday(reader) {
            setCurrentStreak(1, for: reader)
        }

        setLastReadDate(now, for: reader)
        didReadToday = true
        fireworksTrigger += 1
        sendLocalAccountabilityNotification(from: reader)
    }

    private func pokeOtherReader(from reader: Reader) {
        setLastPokeDate(Date(), for: reader)
        sendLocalPokeNotification(from: reader)
    }

    private func refreshDailyState(for reader: Reader) {
        didReadToday = hasReadToday(reader)
        if !didReadToday {
            fireworksTrigger = 0
        }

        guard let lastReadDate = lastReadDate(for: reader) else { return }
        if !Calendar.current.isDateInToday(lastReadDate) && !Calendar.current.isDateInYesterday(lastReadDate) {
            setCurrentStreak(0, for: reader)
        }
    }

    private func refreshDailyStateAtMidnight() async {
        while !Task.isCancelled {
            guard selectedReader != nil else { return }

            let now = Date()
            guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) else { return }
            let midnight = Calendar.current.startOfDay(for: tomorrow)
            let secondsUntilMidnight = max(1, Int(ceil(midnight.timeIntervalSince(now))))

            try? await Task.sleep(for: .seconds(secondsUntilMidnight))

            guard !Task.isCancelled, let selectedReader else { return }
            refreshDailyState(for: selectedReader)
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    private func sendLocalAccountabilityNotification(from reader: Reader) {
        let content = UNMutableNotificationContent()
        content.title = "\(reader.rawValue) just finished reading!"
        content.body = "Nice. \(reader.otherReader.rawValue), your turn to keep the streak alive."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "reading-\(reader.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func sendLocalPokeNotification(from reader: Reader) {
        let content = UNMutableNotificationContent()
        content.title = "\(reader.rawValue) poked you"
        content.body = "A little reading nudge from \(reader.rawValue)."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "poke-\(reader.rawValue)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func startNetworkMonitor() {
        guard monitor == nil else { return }

        let newMonitor = NWPathMonitor()
        newMonitor.pathUpdateHandler = { path in
            Task { @MainActor in
                isConnected = path.status == .satisfied
            }
        }
        newMonitor.start(queue: DispatchQueue(label: "didyaread.network"))
        monitor = newMonitor
    }
}

struct FireworksBurst: View {
    let trigger: Int

    @State private var isVisible = false
    @State private var progress: CGFloat = 0

    private let sparks: [(angle: Double, distance: CGFloat, size: CGFloat, color: Color)] = [
        (0, 106, 7, .yellow),
        (24, 86, 5, .orange),
        (47, 116, 6, .pink),
        (72, 94, 5, .cyan),
        (96, 122, 7, .blue),
        (123, 82, 5, .green),
        (148, 112, 6, .mint),
        (172, 92, 5, .red),
        (196, 120, 7, .purple),
        (222, 88, 5, .yellow),
        (248, 108, 6, .orange),
        (274, 98, 5, .cyan),
        (302, 126, 7, .pink),
        (328, 84, 5, .green)
    ]

    var body: some View {
        ZStack {
            if isVisible {
                Circle()
                    .stroke(.yellow.opacity(1 - progress), lineWidth: 2)
                    .frame(width: 34 + (progress * 170), height: 34 + (progress * 170))
                    .scaleEffect(0.75 + progress)
                    .opacity(1 - progress)

                ForEach(sparks.indices, id: \.self) { index in
                    let spark = sparks[index]
                    let radians = spark.angle * .pi / 180
                    let distance = spark.distance * progress
                    let x = cos(radians) * distance
                    let y = sin(radians) * distance

                    RoundedRectangle(cornerRadius: 2)
                        .fill(spark.color)
                        .frame(width: spark.size, height: spark.size * 2.1)
                        .rotationEffect(.degrees(spark.angle + Double(progress * 120)))
                        .offset(x: x, y: y)
                        .opacity(1 - progress)
                        .shadow(color: spark.color.opacity(0.55), radius: 5)
                        .animation(
                            .easeOut(duration: 0.82),
                            value: progress
                        )
                }
            }
        }
        .frame(width: 260, height: 180)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }

            isVisible = false
            progress = 0

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(20))
                isVisible = true
                try? await Task.sleep(for: .milliseconds(20))
                progress = 1
                try? await Task.sleep(for: .milliseconds(980))
                isVisible = false
                progress = 0
            }
        }
    }
}

#Preview {
    ContentView()
}
