import AppKit
import Combine
import CoreText
import CryptoKit
import Foundation
import SwiftUI

enum PreviewMode: String, Codable, CaseIterable {
    case single
    case compare
}

enum ThemePreference: String, Codable, CaseIterable {
    case system
    case light
    case dark

    var appearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}

enum SortMode: String, Codable, CaseIterable {
    case nameAsc
    case nameDesc
}

enum LanguageSupportFilter: String, Codable, CaseIterable, Hashable, Identifiable {
    case traditionalChinese
    case simplifiedChinese
    case japanese
    case korean

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .traditionalChinese:
            return "language.traditionalChinese"
        case .simplifiedChinese:
            return "language.simplifiedChinese"
        case .japanese:
            return "language.japanese"
        case .korean:
            return "language.korean"
        }
    }

    var sampleText: String {
        switch self {
        case .traditionalChinese:
            return "體齒龍灣畫學廣"
        case .simplifiedChinese:
            return "体齿龙湾画学广"
        case .japanese:
            return "あア日語漢字"
        case .korean:
            return "한글한국어"
        }
    }
}

enum FontSource: String, Codable {
    case system
    case user
    case local
}

struct FontRecord: Codable, Hashable, Identifiable {
    let id: String
    let family: String
    let postScriptName: String
    let style: String
    let weight: Int
    let source: FontSource
    let filePath: String?

    var fileURL: URL? {
        guard let filePath else { return nil }
        return URL(fileURLWithPath: filePath)
    }
}

struct FontCollectionRecord: Codable, Hashable, Identifiable {
    static let allFontsID = "__all_fonts__"
    static let userID = NSFontCollection.Name.user.rawValue
    static let hiddenCollectionIDs: Set<String> = [
        NSFontCollection.Name.favorites.rawValue,
        NSFontCollection.Name.recentlyUsed.rawValue
    ]

    let id: String
    let displayName: String
    let postScriptNames: Set<String>

    var isAllFonts: Bool {
        id == Self.allFontsID
    }

    static let allFonts = FontCollectionRecord(
        id: allFontsID,
        displayName: Localizer.text("collection.allFonts"),
        postScriptNames: []
    )
}

struct PreviewSettings: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case text
        case useDefaultText
        case quickFamilyPeekEnabled
        case fontSize
        case lineHeight
        case letterSpacing
        case mode
        case compareFontIDs
        case selectedCollectionID
        case languageFilters
        case themePreference
        case sortMode
    }

    static let defaultText = "事情無解決，原諒沒可能#228massacre"
    static let compareFontLimit = 8

    var text: String
    var useDefaultText: Bool
    var quickFamilyPeekEnabled: Bool
    var fontSize: Double
    var lineHeight: Double
    var letterSpacing: Double
    var mode: PreviewMode
    var compareFontIDs: [String]
    var selectedCollectionID: String
    var languageFilters: [LanguageSupportFilter]
    var themePreference: ThemePreference
    var sortMode: SortMode

    static let `default` = PreviewSettings(
        text: defaultText,
        useDefaultText: false,
        quickFamilyPeekEnabled: true,
        fontSize: 56,
        lineHeight: 1.15,
        letterSpacing: 0,
        mode: .single,
        compareFontIDs: [],
        selectedCollectionID: FontCollectionRecord.allFontsID,
        languageFilters: [],
        themePreference: .system,
        sortMode: .nameAsc
    )

    var activePreviewText: String {
        useDefaultText ? Self.defaultText : text
    }

    init(
        text: String,
        useDefaultText: Bool,
        quickFamilyPeekEnabled: Bool,
        fontSize: Double,
        lineHeight: Double,
        letterSpacing: Double,
        mode: PreviewMode,
        compareFontIDs: [String],
        selectedCollectionID: String,
        languageFilters: [LanguageSupportFilter],
        themePreference: ThemePreference,
        sortMode: SortMode
    ) {
        self.text = text
        self.useDefaultText = useDefaultText
        self.quickFamilyPeekEnabled = quickFamilyPeekEnabled
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.letterSpacing = letterSpacing
        self.mode = mode
        self.compareFontIDs = compareFontIDs
        self.selectedCollectionID = selectedCollectionID
        self.languageFilters = languageFilters
        self.themePreference = themePreference
        self.sortMode = sortMode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.text = try container.decodeIfPresent(String.self, forKey: .text) ?? Self.default.text
        self.useDefaultText = try container.decodeIfPresent(Bool.self, forKey: .useDefaultText) ?? Self.default.useDefaultText
        self.quickFamilyPeekEnabled = try container.decodeIfPresent(Bool.self, forKey: .quickFamilyPeekEnabled) ?? Self.default.quickFamilyPeekEnabled
        self.fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize) ?? Self.default.fontSize
        self.lineHeight = try container.decodeIfPresent(Double.self, forKey: .lineHeight) ?? Self.default.lineHeight
        self.letterSpacing = try container.decodeIfPresent(Double.self, forKey: .letterSpacing) ?? Self.default.letterSpacing
        self.mode = try container.decodeIfPresent(PreviewMode.self, forKey: .mode) ?? Self.default.mode
        self.compareFontIDs = try container.decodeIfPresent([String].self, forKey: .compareFontIDs) ?? Self.default.compareFontIDs
        self.selectedCollectionID = try container.decodeIfPresent(String.self, forKey: .selectedCollectionID) ?? Self.default.selectedCollectionID
        self.languageFilters = try container.decodeIfPresent([LanguageSupportFilter].self, forKey: .languageFilters) ?? Self.default.languageFilters
        self.themePreference = try container.decodeIfPresent(ThemePreference.self, forKey: .themePreference) ?? Self.default.themePreference
        self.sortMode = try container.decodeIfPresent(SortMode.self, forKey: .sortMode) ?? Self.default.sortMode
    }
}

struct WindowState: Codable, Equatable {
    var originX: Double
    var originY: Double
    var width: Double
    var height: Double

    static let `default` = WindowState(originX: 100, originY: 120, width: 1500, height: 920)
}

struct Localizer {
    static func text(_ key: String) -> String {
        NSLocalizedString(key, bundle: .appModule, comment: "")
    }
}

struct BrowserGridLayoutMetrics: Equatable {
    let columns: Int
    let cardWidth: CGFloat
    let sideInset: CGFloat
    let availableWidth: CGFloat
}

struct BrowserGridLayoutCalculator {
    let minimumCardWidth: CGFloat
    let horizontalPadding: CGFloat
    let columnSpacing: CGFloat

    func metrics(for availableWidth: CGFloat) -> BrowserGridLayoutMetrics {
        let usableWidth = max(minimumCardWidth, availableWidth - (horizontalPadding * 2))
        let columns = max(1, Int((usableWidth + columnSpacing) / (minimumCardWidth + columnSpacing)))
        let contentWidth = usableWidth - (CGFloat(columns - 1) * columnSpacing)
        let cardWidth = floor(contentWidth / CGFloat(columns))
        let occupiedWidth = (CGFloat(columns) * cardWidth) + (CGFloat(columns - 1) * columnSpacing)
        let sideInset = max(horizontalPadding, floor((availableWidth - occupiedWidth) / 2))
        return BrowserGridLayoutMetrics(
            columns: columns,
            cardWidth: cardWidth,
            sideInset: sideInset,
            availableWidth: availableWidth
        )
    }
}

extension Bundle {
    static let appModule: Bundle = {
#if SWIFT_PACKAGE
        Bundle.module
#else
        Bundle.main
#endif
    }()
}

extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension String {
    func localizedCaseInsensitiveContains(_ other: String) -> Bool {
        range(of: other, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive]) != nil
    }

    func graphemeClusters() -> [String] {
        var graphemes: [String] = []
        enumerateSubstrings(in: startIndex..<endIndex, options: .byComposedCharacterSequences) { substring, _, _, _ in
            if let substring {
                graphemes.append(substring)
            }
        }
        return graphemes
    }
}

protocol FontCatalogServiceProtocol {
    func scanFonts() async throws -> [FontRecord]
    func scanFontCollections() async throws -> [FontCollectionRecord]
}

protocol GlyphCoverageServiceProtocol {
    func supportedGraphemes(for font: FontRecord, text: String) -> [Bool]
    func previewString(for font: FontRecord, text: String) -> String
    func supportsText(_ text: String, for font: FontRecord) -> Bool
}

protocol SettingsStoreProtocol {
    func loadSettings() -> PreviewSettings
    func saveSettings(_ settings: PreviewSettings)
}

protocol WindowStateStoreProtocol {
    func loadWindowState() -> WindowState
    func saveWindowState(_ state: WindowState)
}

@MainActor
final class SharedCatalogState: @preconcurrency ObservableObject {
    enum LoadingState {
        case idle
        case loading
        case loaded
        case failed(String)

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }
    }

    let objectWillChange = ObservableObjectPublisher()

    private(set) var fonts: [FontRecord] = [] { didSet { publish() } }
    private(set) var fontCollections: [FontCollectionRecord] = [.allFonts] { didSet { publish() } }
    private(set) var loadingState: LoadingState = .idle { didSet { publish() } }

    private let fontCatalogService: FontCatalogServiceProtocol
    private var fontCollectionObserver: NSObjectProtocol?

    init(fontCatalogService: FontCatalogServiceProtocol) {
        self.fontCatalogService = fontCatalogService
        fontCollectionObserver = NotificationCenter.default.addObserver(
            forName: NSFontCollection.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadFonts(force: true)
            }
        }
    }

    deinit {
        if let fontCollectionObserver {
            NotificationCenter.default.removeObserver(fontCollectionObserver)
        }
    }

    func loadFonts(force: Bool = false) {
        if case .loading = loadingState { return }
        if !force, !fonts.isEmpty, case .loaded = loadingState { return }

        loadingState = .loading
        Task { @MainActor in
            do {
                let loadedFonts = try await fontCatalogService.scanFonts()
                let loadedCollections = try await fontCatalogService.scanFontCollections()
                fonts = loadedFonts
                fontCollections = loadedCollections
                loadingState = .loaded
            } catch {
                loadingState = .failed(error.localizedDescription)
            }
        }
    }

    private func publish() {
        objectWillChange.send()
    }
}

final class FontCatalogService: FontCatalogServiceProtocol {
    func scanFonts() async throws -> [FontRecord] {
        let names = CTFontManagerCopyAvailablePostScriptNames() as? [String] ?? []
        var records: [String: FontRecord] = [:]

        for postScriptName in names {
            autoreleasepool {
                guard let record = makeRecord(postScriptName: postScriptName) else { return }
                records["\(record.family)|\(record.style)|\(record.postScriptName)"] = record
            }
        }

        return records.values.sorted { left, right in
            let familyCompare = left.family.localizedStandardCompare(right.family)
            if familyCompare != .orderedSame {
                return familyCompare == .orderedAscending
            }
            let styleCompare = left.style.localizedStandardCompare(right.style)
            if styleCompare != .orderedSame {
                return styleCompare == .orderedAscending
            }
            return left.postScriptName.localizedStandardCompare(right.postScriptName) == .orderedAscending
        }
    }

    func scanFontCollections() async throws -> [FontCollectionRecord] {
        let names = NSFontCollection.allFontCollectionNames
            .filter { $0 != .allFonts }
            .sorted { localizedCollectionName(for: $0).localizedStandardCompare(localizedCollectionName(for: $1)) == .orderedAscending }

        var records = [FontCollectionRecord.allFonts]

        for name in names {
            autoreleasepool {
                guard let collection = NSFontCollection(name: name) else { return }
                let postScriptNames = Set(
                    (collection.matchingDescriptors ?? [])
                        .compactMap { descriptor in
                            descriptor.postscriptName
                                ?? descriptor.object(forKey: .name) as? String
                                ?? descriptor.fontAttributes[.name] as? String
                        }
                        .filter { !$0.isEmpty }
                )

                records.append(
                    FontCollectionRecord(
                        id: name.rawValue,
                        displayName: localizedCollectionName(for: name),
                        postScriptNames: postScriptNames
                    )
                )
            }
        }

        return records
    }

    private func makeRecord(postScriptName: String) -> FontRecord? {
        let attributes = [kCTFontNameAttribute: postScriptName] as CFDictionary
        let descriptor = CTFontDescriptorCreateWithAttributes(attributes)
        let font = CTFontCreateWithFontDescriptor(descriptor, 16, nil)
        let family = CTFontCopyFamilyName(font) as String
        guard !family.isEmpty, !family.hasPrefix(".") else { return nil }

        let style = (CTFontCopyName(font, kCTFontStyleNameKey) as String?)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedStyle = style?.isEmpty == false ? style! : Localizer.text("style.regular")
        let resolvedPostScriptName = CTFontCopyPostScriptName(font) as String
        guard !resolvedPostScriptName.hasPrefix(".") else { return nil }

        let descriptorURL = CTFontDescriptorCopyAttribute(CTFontCopyFontDescriptor(font), kCTFontURLAttribute) as? URL
        let source = classifySource(url: descriptorURL)

        return FontRecord(
            id: Self.hashID("\(descriptorURL?.path ?? "local"):\(resolvedPostScriptName)"),
            family: family,
            postScriptName: resolvedPostScriptName,
            style: resolvedStyle,
            weight: numericWeight(for: font),
            source: source,
            filePath: descriptorURL?.path
        )
    }

    private static func hashID(_ raw: String) -> String {
        let digest = SHA256.hash(data: Data(raw.utf8))
        return digest.prefix(12).map { String(format: "%02x", $0) }.joined()
    }

    private func classifySource(url: URL?) -> FontSource {
        guard let path = url?.path else { return .local }
        if path.hasPrefix("/System/Library/Fonts") || path.hasPrefix("/System/Applications") {
            return .system
        }
        if path.hasPrefix(NSHomeDirectory()) {
            return .user
        }
        return .local
    }

    private func numericWeight(for font: CTFont) -> Int {
        let traits = CTFontCopyTraits(font) as NSDictionary
        let value = traits[kCTFontWeightTrait] as? Double ?? 0
        return Int((value + 1) * 500)
    }

    private func localizedCollectionName(for name: NSFontCollection.Name) -> String {
        switch name {
        case .favorites:
            Localizer.text("collection.favorites")
        case .recentlyUsed:
            Localizer.text("collection.recentlyUsed")
        case .user:
            Localizer.text("collection.user")
        default:
            name.rawValue
        }
    }
}

final class GlyphCoverageService: GlyphCoverageServiceProtocol {
    private let tofuGlyph = "□"
    private var supportCache: [String: [Bool]] = [:]
    private var fontCache: [String: CTFont] = [:]

    func supportedGraphemes(for font: FontRecord, text: String) -> [Bool] {
        let cacheKey = "\(font.id)|\(text)"
        if let cached = supportCache[cacheKey] {
            return cached
        }

        let ctFont = resolvedFont(for: font)
        let results = text.graphemeClusters().map { grapheme in
            if grapheme.isEmpty {
                return true
            }
            return grapheme.unicodeScalars.allSatisfy { scalar in
                Self.font(ctFont, supportsScalar: scalar)
            }
        }
        supportCache[cacheKey] = results
        return results
    }

    func previewString(for font: FontRecord, text: String) -> String {
        let graphemes = text.graphemeClusters()
        let support = supportedGraphemes(for: font, text: text)
        return zip(graphemes, support).map { $0.1 ? $0.0 : tofuGlyph }.joined()
    }

    func supportsText(_ text: String, for font: FontRecord) -> Bool {
        supportedGraphemes(for: font, text: text).allSatisfy { $0 }
    }

    private func resolvedFont(for font: FontRecord) -> CTFont {
        if let cached = fontCache[font.id] {
            return cached
        }
        let resolved = CTFontCreateWithName(font.postScriptName as CFString, 16, nil)
        fontCache[font.id] = resolved
        return resolved
    }

    private static func font(_ font: CTFont, supportsScalar scalar: UnicodeScalar) -> Bool {
        let utf16 = String(scalar).utf16.map { UniChar($0) }
        guard !utf16.isEmpty else { return true }
        var glyphs = Array(repeating: CGGlyph(), count: utf16.count)
        let success = CTFontGetGlyphsForCharacters(font, utf16, &glyphs, utf16.count)
        return success && glyphs.allSatisfy { $0 != 0 }
    }
}

final class SettingsStore: SettingsStoreProtocol {
    private let fileManager = FileManager.default
    private let settingsURL: URL

    init() {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("party.piyan.FontDeck", isDirectory: true)
        settingsURL = directory.appendingPathComponent("settings.json")
    }

    func loadSettings() -> PreviewSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(PreviewSettings.self, from: data) else {
            return .default
        }
        return normalize(settings)
    }

    func saveSettings(_ settings: PreviewSettings) {
        do {
            try fileManager.createDirectory(at: settingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.pretty.encode(normalize(settings))
            try data.write(to: settingsURL, options: .atomic)
        } catch {
            NSLog("Failed to save settings: \(error.localizedDescription)")
        }
    }

    private func normalize(_ settings: PreviewSettings) -> PreviewSettings {
        var normalized = settings
        normalized.compareFontIDs = Array(NSOrderedSet(array: settings.compareFontIDs)) as? [String] ?? settings.compareFontIDs
        normalized.languageFilters = Array(NSOrderedSet(array: settings.languageFilters)) as? [LanguageSupportFilter] ?? settings.languageFilters
        normalized.selectedCollectionID = settings.selectedCollectionID.isEmpty ? FontCollectionRecord.allFontsID : settings.selectedCollectionID
        normalized.themePreference = .system
        if normalized.mode != .single && normalized.mode != .compare {
            normalized.mode = .single
        }
        return normalized
    }
}

final class WindowStateStore: WindowStateStoreProtocol {
    private let fileManager = FileManager.default
    private let stateURL: URL

    init() {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("party.piyan.FontDeck", isDirectory: true)
        stateURL = directory.appendingPathComponent("window-state.json")
    }

    func loadWindowState() -> WindowState {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(WindowState.self, from: data) else {
            return .default
        }
        return state
    }

    func saveWindowState(_ state: WindowState) {
        do {
            try fileManager.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder.pretty.encode(state)
            try data.write(to: stateURL, options: .atomic)
        } catch {
            NSLog("Failed to save window state: \(error.localizedDescription)")
        }
    }
}

@MainActor
final class AppState: @preconcurrency ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    var onThemeChange: ((ThemePreference) -> Void)?
    var onTransientNotice: ((String) -> Void)?

    private(set) var settings: PreviewSettings { didSet { settingsStore.saveSettings(settings); publish() } }
    private var recentIDs: [String] = [] { didSet { publish() } }
    private(set) var isQuickFamilyPeekActive = false { didSet { publish() } }
    var selectedFontID: String? { didSet { publish() } }
    var searchText = "" { didSet { publish() } }

    private let sharedCatalog: SharedCatalogState
    private let glyphCoverageService: GlyphCoverageServiceProtocol
    private let settingsStore: SettingsStoreProtocol
    private var sharedCatalogObserver: AnyCancellable?

    var fonts: [FontRecord] { sharedCatalog.fonts }
    var fontCollections: [FontCollectionRecord] { sharedCatalog.fontCollections }
    var loadingState: SharedCatalogState.LoadingState { sharedCatalog.loadingState }

    init(sharedCatalog: SharedCatalogState, glyphCoverageService: GlyphCoverageServiceProtocol, settingsStore: SettingsStoreProtocol) {
        self.sharedCatalog = sharedCatalog
        self.glyphCoverageService = glyphCoverageService
        self.settingsStore = settingsStore
        var loadedSettings = settingsStore.loadSettings()
        loadedSettings.themePreference = .system
        self.settings = loadedSettings
        sharedCatalogObserver = sharedCatalog.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in
                self?.handleSharedCatalogChange()
                self?.publish()
            }
        }
    }

    convenience init(fontCatalogService: FontCatalogServiceProtocol, glyphCoverageService: GlyphCoverageServiceProtocol, settingsStore: SettingsStoreProtocol) {
        self.init(
            sharedCatalog: SharedCatalogState(fontCatalogService: fontCatalogService),
            glyphCoverageService: glyphCoverageService,
            settingsStore: settingsStore
        )
    }

    var statusText: String {
        switch sharedCatalog.loadingState {
        case .idle:
            return Localizer.text("status.idle")
        case .loading:
            return Localizer.text("status.loading")
        case .loaded:
            return fonts.isEmpty ? Localizer.text("status.empty") : Localizer.text("status.loaded")
        case .failed(let message):
            return message
        }
    }

    var visibleFonts: [FontRecord] {
        sortedFonts(
            matching: sharedCatalog.fonts.filter { font in
                matchesSelectedCollection(font)
                    && matchesSearch(font)
                    && matchesLanguageFilters(font, filters: settings.languageFilters)
                    && matchesQuickFamilyPeek(font)
            }
        )
    }

    func totalCount(for filter: LanguageSupportFilter) -> Int {
        sharedCatalog.fonts.reduce(into: 0) { count, font in
            guard matchesSelectedCollection(font) else { return }
            if matchesLanguageFilters(font, filters: [filter]) {
                count += 1
            }
        }
    }

    var selectedFontCollection: FontCollectionRecord {
        sharedCatalog.fontCollections.first(where: { $0.id == settings.selectedCollectionID }) ?? .allFonts
    }

    var standardFontCollections: [FontCollectionRecord] {
        let collectionsByID = Dictionary(uniqueKeysWithValues: sharedCatalog.fontCollections.map { ($0.id, $0) })
        return [FontCollectionRecord.allFonts, collectionsByID[FontCollectionRecord.userID]].compactMap { $0 }
    }

    var customFontCollections: [FontCollectionRecord] {
        sharedCatalog.fontCollections
            .filter { collection in
                !collection.isAllFonts
                    && collection.id != FontCollectionRecord.userID
                    && !FontCollectionRecord.hiddenCollectionIDs.contains(collection.id)
            }
            .sorted { left, right in
                left.displayName.localizedStandardCompare(right.displayName) == .orderedAscending
            }
    }

    var visibleFontCollections: [FontCollectionRecord] {
        let collections = standardFontCollections + customFontCollections
        return collections.isEmpty ? [.allFonts] : collections
    }

    private func sortedFonts(matching fonts: [FontRecord]) -> [FontRecord] {
        fonts.sorted { left, right in
            let familyCompare = left.family.localizedStandardCompare(right.family)
            if familyCompare != .orderedSame {
                return settings.sortMode == .nameAsc ? familyCompare == .orderedAscending : familyCompare == .orderedDescending
            }
            let styleCompare = left.style.localizedStandardCompare(right.style)
            if styleCompare != .orderedSame {
                return styleCompare == .orderedAscending
            }
            return left.postScriptName.localizedStandardCompare(right.postScriptName) == .orderedAscending
        }
    }

    private func matchesSearch(_ font: FontRecord) -> Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty
            || font.family.localizedCaseInsensitiveContains(trimmed)
            || font.style.localizedCaseInsensitiveContains(trimmed)
            || font.postScriptName.localizedCaseInsensitiveContains(trimmed)
    }

    private func matchesLanguageFilters(_ font: FontRecord, filters: [LanguageSupportFilter]) -> Bool {
        filters.allSatisfy { filter in
            glyphCoverageService.supportsText(filter.sampleText, for: font)
        }
    }

    private func matchesSelectedCollection(_ font: FontRecord) -> Bool {
        let collection = selectedFontCollection
        return collection.isAllFonts || collection.postScriptNames.contains(font.postScriptName)
    }

    private func matchesQuickFamilyPeek(_ font: FontRecord) -> Bool {
        guard let family = quickFamilyPeekFamily else { return true }
        return font.family == family
    }

    var compareFonts: [FontRecord] {
        settings.compareFontIDs.compactMap { id in sharedCatalog.fonts.first(where: { $0.id == id }) }
    }

    var recentFonts: [FontRecord] {
        recentIDs.compactMap { id in sharedCatalog.fonts.first(where: { $0.id == id }) }
    }

    var selectedFont: FontRecord? {
        guard let selectedFontID else { return nil }
        return sharedCatalog.fonts.first(where: { $0.id == selectedFontID })
    }

    var quickFamilyPeekFamily: String? {
        guard settings.quickFamilyPeekEnabled, isQuickFamilyPeekActive else { return nil }
        return selectedFont?.family
    }

    func loadFonts(force: Bool = false) {
        sharedCatalog.loadFonts(force: force)
    }

    func setPreviewText(_ text: String) {
        settings.text = text
    }

    func setUseDefaultText(_ value: Bool) {
        settings.useDefaultText = value
    }

    func setQuickFamilyPeekEnabled(_ value: Bool) {
        settings.quickFamilyPeekEnabled = value
        if !value {
            isQuickFamilyPeekActive = false
        }
    }

    func setFontSize(_ value: Double) {
        settings.fontSize = max(12, min(144, value))
    }

    func setLineHeight(_ value: Double) {
        settings.lineHeight = max(0.8, min(2.4, value))
    }

    func setLetterSpacing(_ value: Double) {
        settings.letterSpacing = max(-2, min(12, value))
    }

    func setSortMode(_ value: SortMode) {
        settings.sortMode = value
    }

    func setSelectedCollectionID(_ value: String) {
        settings.selectedCollectionID = value
        if !visibleFonts.contains(where: { $0.id == selectedFontID }) {
            selectedFontID = visibleFonts.first?.id
        }
    }

    func toggleLanguageFilter(_ filter: LanguageSupportFilter) {
        if settings.languageFilters.contains(filter) {
            settings.languageFilters.removeAll { $0 == filter }
        } else {
            settings.languageFilters.append(filter)
        }
    }

    func clearLanguageFilters() {
        settings.languageFilters.removeAll()
    }

    func showCompareView() {
        guard !compareFonts.isEmpty else { return }
        settings.mode = .compare
    }

    func showLibraryView() {
        settings.mode = .single
    }

    func setThemePreference(_ value: ThemePreference) {
        settings.themePreference = value
        onThemeChange?(value)
    }

    func selectFont(id: String?) {
        selectedFontID = id
        if let id { markRecent(id) }
    }

    func activateFontCard(_ font: FontRecord) {
        selectFont(id: font.id)
        copyFontName(for: font)
    }

    func setQuickFamilyPeekActive(_ value: Bool) {
        let shouldActivate = value && settings.quickFamilyPeekEnabled && selectedFont != nil
        guard isQuickFamilyPeekActive != shouldActivate else { return }
        isQuickFamilyPeekActive = shouldActivate
    }

    func toggleCompare(for fontID: String) {
        if settings.compareFontIDs.contains(fontID) {
            settings.compareFontIDs.removeAll { $0 == fontID }
            if settings.compareFontIDs.isEmpty, settings.mode == .compare {
                settings.mode = .single
            }
        } else if settings.compareFontIDs.count < PreviewSettings.compareFontLimit {
            settings.compareFontIDs.append(fontID)
            markRecent(fontID)
        } else {
            onTransientNotice?(Localizer.text("notice.compare.limit"))
        }
    }

    func clearCompareFonts() {
        settings.compareFontIDs.removeAll()
        if settings.mode == .compare {
            settings.mode = .single
        }
    }

    func clearRecentFonts() {
        recentIDs.removeAll()
    }

    func copySelectedFontName() {
        guard let font = selectedFont else { return }
        copyFontName(for: font)
    }

    func copyFontName(for font: FontRecord) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(font.postScriptName, forType: .string)
        markRecent(font.id)
        onTransientNotice?(String(format: Localizer.text("notice.copied"), font.postScriptName))
    }

    func revealSelectedFont() {
        guard let url = selectedFont?.fileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    func renderedPreviewString(for font: FontRecord) -> String {
        glyphCoverageService.previewString(for: font, text: settings.activePreviewText)
    }

    private func markRecent(_ fontID: String) {
        recentIDs.removeAll { $0 == fontID }
        recentIDs.insert(fontID, at: 0)
        recentIDs = Array(recentIDs.prefix(20))
    }

    private func pruneStoredFontIDs(validFonts: [FontRecord]) {
        let validIDs = Set(validFonts.map(\.id))
        settings.compareFontIDs = settings.compareFontIDs.filter { validIDs.contains($0) }
        recentIDs = recentIDs.filter { validIDs.contains($0) }
    }

    private func pruneSelectedCollection(validCollections: [FontCollectionRecord]) {
        let validIDs = Set(validCollections.map(\.id))
        if !validIDs.contains(settings.selectedCollectionID) {
            settings.selectedCollectionID = FontCollectionRecord.allFontsID
        }
    }

    private func publish() {
        objectWillChange.send()
    }

    private func handleSharedCatalogChange() {
        let loadedFonts = sharedCatalog.fonts
        let loadedCollections = sharedCatalog.fontCollections
        pruneStoredFontIDs(validFonts: loadedFonts)
        pruneSelectedCollection(validCollections: loadedCollections)

        if selectedFontID == nil || !loadedFonts.contains(where: { $0.id == selectedFontID }) {
            selectedFontID = visibleFonts.first?.id
        } else if !visibleFonts.contains(where: { $0.id == selectedFontID }) {
            selectedFontID = visibleFonts.first?.id
        }
    }
}

final class FontCardViewItem: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("FontCardViewItem")

    private let titleLabel = PassthroughTextField.label()
    private let previewLabel = PassthroughTextField.wrappingLabel()
    private let metaLabel = PassthroughTextField.label()
    private let compareButton = NSButton(title: "+", target: nil, action: nil)

    var onCompare: (() -> Void)?
    var onSelect: (() -> Void)?
    private var showsSelectedStyle = false
    private var showsPressedStyle = false
    private var compareMenuTitle = ""

    override func loadView() {
        let containerView = FontCardContainerView()
        containerView.owner = self
        view = containerView
        view.wantsLayer = true
        view.layer?.cornerRadius = 16
        view.layer?.masksToBounds = false
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.separatorColor.cgColor
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        ])

        let header = NSStackView()
        header.orientation = .horizontal
        header.alignment = .top
        header.distribution = .fill
        header.spacing = 12

        let titleStack = NSStackView()
        titleStack.orientation = .vertical
        titleStack.alignment = .leading
        titleStack.spacing = 4

        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .centerY
        buttonStack.spacing = 8

        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        compareButton.bezelStyle = .texturedRounded
        compareButton.target = self
        compareButton.action = #selector(handleCompare)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        metaLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        metaLabel.lineBreakMode = .byTruncatingTail
        titleStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        buttonStack.setContentHuggingPriority(.required, for: .horizontal)
        buttonStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(metaLabel)
        buttonStack.addArrangedSubview(compareButton)

        header.addArrangedSubview(titleStack)
        header.addArrangedSubview(spacer)
        header.addArrangedSubview(buttonStack)

        previewLabel.maximumNumberOfLines = 0
        previewLabel.lineBreakMode = .byWordWrapping
        previewLabel.alignment = .left
        previewLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        previewLabel.setContentHuggingPriority(.defaultLow, for: .vertical)

        metaLabel.font = .systemFont(ofSize: 11)
        metaLabel.textColor = .secondaryLabelColor
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        let previewMinHeight = previewLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 96)
        previewMinHeight.priority = .defaultHigh

        stack.addArrangedSubview(header)
        stack.addArrangedSubview(previewLabel)
        NSLayoutConstraint.activate([previewMinHeight])
    }

    func configure(font: FontRecord, state: AppState) {
        titleLabel.stringValue = font.family
        updateCompareState(isCompared: state.settings.compareFontIDs.contains(font.id))
        metaLabel.stringValue = "\(font.style) • \(font.source.rawValue) • \(font.postScriptName)"
        view.menu = makeContextMenu()

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = max(0, CGFloat((state.settings.lineHeight - 1.0) * state.settings.fontSize))
        let resolvedFont = NSFont(name: font.postScriptName, size: CGFloat(state.settings.fontSize))
            ?? .systemFont(ofSize: CGFloat(state.settings.fontSize))

        previewLabel.attributedStringValue = NSAttributedString(
            string: state.renderedPreviewString(for: font),
            attributes: [
                .font: resolvedFont,
                .kern: state.settings.letterSpacing,
                .paragraphStyle: paragraph
            ]
        )

        setSelected(state.selectedFontID == font.id)
    }

    func updateCompareState(isCompared: Bool) {
        compareButton.title = isCompared ? "−" : "+"
        compareButton.contentTintColor = isCompared ? .controlAccentColor : .secondaryLabelColor
        compareButton.font = .systemFont(ofSize: 16, weight: .semibold)
        compareMenuTitle = Localizer.text(isCompared ? "action.remove.compare" : "action.add.compare")
        view.menu = makeContextMenu()
    }

    @objc private func handleCompare() { onCompare?() }

    @objc fileprivate func handleSelect() { onSelect?() }

    func setSelected(_ selected: Bool) {
        showsSelectedStyle = selected
        updateSelectionAppearance()
    }

    func setPressed(_ pressed: Bool, animated: Bool) {
        showsPressedStyle = pressed

        let updates = { [self] in
            updateSelectionAppearance()
            view.layer?.setAffineTransform(
                pressed
                    ? CGAffineTransform(scaleX: 0.965, y: 0.965)
                    : .identity
            )
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = pressed ? 0.08 : 0.16
                context.timingFunction = CAMediaTimingFunction(name: pressed ? .easeInEaseOut : .easeOut)
                updates()
            }
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            updates()
            CATransaction.commit()
        }
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        let compareItem = NSMenuItem(title: compareMenuTitle, action: #selector(handleCompare), keyEquivalent: "")
        compareItem.target = self
        menu.addItem(compareItem)
        return menu
    }

    private func updateSelectionAppearance() {
        guard let layer = view.layer else { return }
        layer.shadowColor = NSColor.controlAccentColor.withAlphaComponent(0.28).cgColor
        layer.shadowOffset = CGSize(width: 0, height: showsPressedStyle ? 4 : 8)
        layer.shadowOpacity = showsPressedStyle ? 0.28 : 0.12
        layer.shadowRadius = showsPressedStyle ? 8 : 14
        if showsSelectedStyle {
            layer.borderColor = NSColor.controlAccentColor.cgColor
            layer.borderWidth = 2
            layer.backgroundColor = NSColor.selectedContentBackgroundColor
                .withAlphaComponent(showsPressedStyle ? 0.4 : 0.18)
                .cgColor
        } else {
            layer.borderColor = NSColor.separatorColor.cgColor
            layer.borderWidth = 1
            layer.backgroundColor = NSColor.controlBackgroundColor
                .blended(withFraction: showsPressedStyle ? 0.28 : 0, of: .selectedContentBackgroundColor)?
                .cgColor
                ?? NSColor.controlBackgroundColor.cgColor
        }
    }

    func animateReleaseFeedback() {
        setPressed(false, animated: false)
        guard let layer = view.layer else { return }

        let spring = CASpringAnimation(keyPath: "transform.scale")
        spring.mass = 0.9
        spring.stiffness = 320
        spring.damping = 22
        spring.initialVelocity = 0
        spring.fromValue = layer.presentation()?.value(forKeyPath: "transform.scale") ?? 0.965
        spring.toValue = 1.0
        spring.duration = spring.settlingDuration
        spring.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.add(spring, forKey: "card-release-scale")
    }
}

private final class FontCardContainerView: NSView {
    weak var owner: FontCardViewItem?
    private var isTrackingCardPress = false
    private var shouldActivateOnMouseUp = false

    override func mouseDown(with event: NSEvent) {
        if let currentView = hitTest(convert(event.locationInWindow, from: nil)),
           let button = containingButton(startingAt: currentView) {
            button.performClick(nil)
            return
        }

        isTrackingCardPress = true
        shouldActivateOnMouseUp = true
        owner?.setPressed(true, animated: true)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isTrackingCardPress else {
            super.mouseDragged(with: event)
            return
        }

        let isInside = bounds.contains(convert(event.locationInWindow, from: nil))
        guard isInside != shouldActivateOnMouseUp else { return }

        shouldActivateOnMouseUp = isInside
        owner?.setPressed(isInside, animated: true)
    }

    override func mouseUp(with event: NSEvent) {
        guard isTrackingCardPress else {
            super.mouseUp(with: event)
            return
        }

        isTrackingCardPress = false
        let shouldActivate = shouldActivateOnMouseUp && bounds.contains(convert(event.locationInWindow, from: nil))
        shouldActivateOnMouseUp = false

        if shouldActivate {
            owner?.handleSelect()
        }

        owner?.animateReleaseFeedback()
    }

    private func containingButton(startingAt view: NSView) -> NSButton? {
        var currentView: NSView? = view
        while let view = currentView {
            if let button = view as? NSButton {
                return button
            }
            currentView = view.superview
        }
        return nil
    }
}

private final class PassthroughTextField: NSTextField {
    static func label() -> PassthroughTextField {
        let field = PassthroughTextField(frame: .zero)
        field.isEditable = false
        field.isBordered = false
        field.drawsBackground = false
        field.isSelectable = false
        field.lineBreakMode = .byTruncatingTail
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    static func wrappingLabel() -> PassthroughTextField {
        let field = label()
        field.usesSingleLineMode = false
        field.cell?.wraps = true
        field.lineBreakMode = .byWordWrapping
        return field
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func menu(for event: NSEvent) -> NSMenu? { nil }
}

final class SkeletonOverlayView: NSView {
    private let cardsContainerLayer = CALayer()
    private var cardLayers: [CALayer] = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        cardsContainerLayer.frame = bounds
        rebuildCards()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        layer?.addSublayer(cardsContainerLayer)
    }

    private func rebuildCards() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        cardLayers.forEach { $0.removeFromSuperlayer() }
        cardLayers.removeAll()

        let horizontalInset: CGFloat = 18
        let topInset: CGFloat = 20
        let bottomInset: CGFloat = 24
        let cardHeight: CGFloat = 188
        let spacing: CGFloat = 18
        let width = max(220, bounds.width - (horizontalInset * 2))
        let usableHeight = max(0, bounds.height - topInset - bottomInset)
        let cardCount = max(3, Int(ceil(usableHeight / (cardHeight + spacing))))

        for index in 0..<cardCount {
            let y = bounds.height - topInset - cardHeight - CGFloat(index) * (cardHeight + spacing)
            guard y + cardHeight >= 0 else { continue }

            let cardLayer = makeCardLayer(
                frame: CGRect(x: horizontalInset, y: y, width: width, height: cardHeight),
                delay: CFTimeInterval(index) * 0.12
            )
            cardsContainerLayer.addSublayer(cardLayer)
            cardLayers.append(cardLayer)
        }
    }

    private func makeCardLayer(frame: CGRect, delay: CFTimeInterval) -> CALayer {
        let cardLayer = CALayer()
        cardLayer.frame = frame
        cardLayer.cornerRadius = 18
        cardLayer.masksToBounds = true
        cardLayer.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.12).cgColor
        cardLayer.borderWidth = 1
        cardLayer.borderColor = NSColor.separatorColor.withAlphaComponent(0.10).cgColor

        let previewBar = CALayer()
        previewBar.frame = CGRect(x: 18, y: frame.height - 110, width: frame.width - 36, height: 58)
        previewBar.cornerRadius = 10
        previewBar.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.10).cgColor

        let titleBar = CALayer()
        titleBar.frame = CGRect(x: 18, y: 28, width: min(frame.width * 0.34, 170), height: 18)
        titleBar.cornerRadius = 9
        titleBar.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.14).cgColor

        let metaBar = CALayer()
        metaBar.frame = CGRect(x: 18, y: 54, width: min(frame.width * 0.58, 260), height: 14)
        metaBar.cornerRadius = 7
        metaBar.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.09).cgColor

        let badgeBar = CALayer()
        badgeBar.frame = CGRect(x: frame.width - 78, y: 28, width: 42, height: 20)
        badgeBar.cornerRadius = 10
        badgeBar.backgroundColor = NSColor.separatorColor.withAlphaComponent(0.12).cgColor

        let shimmerLayer = CAGradientLayer()
        shimmerLayer.frame = CGRect(x: -frame.width, y: 0, width: frame.width * 1.35, height: frame.height)
        shimmerLayer.colors = [
            NSColor.clear.cgColor,
            NSColor.white.withAlphaComponent(0.04).cgColor,
            NSColor.white.withAlphaComponent(0.12).cgColor,
            NSColor.white.withAlphaComponent(0.04).cgColor,
            NSColor.clear.cgColor
        ]
        shimmerLayer.locations = [0, 0.35, 0.5, 0.65, 1]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = 0
        animation.toValue = frame.width * 1.85
        animation.duration = 1.45
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = CACurrentMediaTime() + delay
        shimmerLayer.add(animation, forKey: "shimmer")

        cardLayer.addSublayer(previewBar)
        cardLayer.addSublayer(titleBar)
        cardLayer.addSublayer(metaBar)
        cardLayer.addSublayer(badgeBar)
        cardLayer.addSublayer(shimmerLayer)
        return cardLayer
    }
}

@MainActor
final class ContentViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private struct RenderSnapshot: Equatable {
        let mode: PreviewMode
        let visibleFontIDs: [String]
        let compareDisplayFontIDs: [String]
        let activePreviewText: String
        let fontSize: Double
        let lineHeight: Double
        let letterSpacing: Double
    }

    private let state: AppState
    private let headerView = NSView()
    private let backButton = NSButton(title: "", target: nil, action: nil)
    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()
    private let compareStack = NSStackView()
    private let emptyLabel = NSTextField(wrappingLabelWithString: "")
    private let skeletonOverlayView = SkeletonOverlayView(frame: .zero)
    private let gridLayoutCalculator = BrowserGridLayoutCalculator(
        minimumCardWidth: 320,
        horizontalPadding: 16,
        columnSpacing: 16
    )
    private let horizontalPadding: CGFloat = 16
    private let columnSpacing: CGFloat = 16
    private var headerTopConstraint: NSLayoutConstraint?
    private var scrollTopConstraint: NSLayoutConstraint?
    private var compareTopConstraint: NSLayoutConstraint?
    private var lastRenderSnapshot: RenderSnapshot?
    private var lastGridLayoutMetrics: BrowserGridLayoutMetrics?

    init(state: AppState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false

        headerView.translatesAutoresizingMaskIntoConstraints = false

        backButton.title = Localizer.text("action.back")
        backButton.bezelStyle = .rounded
        backButton.image = NSImage(named: NSImage.goBackTemplateName)
        backButton.imagePosition = .imageLeading
        backButton.target = self
        backButton.action = #selector(handleBack)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(backButton)

        let layout = NSCollectionViewFlowLayout()
        layout.minimumLineSpacing = 18
        layout.minimumInteritemSpacing = columnSpacing
        collectionView.collectionViewLayout = layout
        collectionView.register(FontCardViewItem.self, forItemWithIdentifier: FontCardViewItem.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isSelectable = false
        collectionView.backgroundColors = [.clear]

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        compareStack.orientation = .vertical
        compareStack.spacing = 14
        compareStack.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.alignment = .center
        emptyLabel.textColor = .secondaryLabelColor
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        skeletonOverlayView.translatesAutoresizingMaskIntoConstraints = false
        skeletonOverlayView.isHidden = true

        view.addSubview(headerView)
        view.addSubview(scrollView)
        view.addSubview(compareStack)
        view.addSubview(emptyLabel)
        view.addSubview(skeletonOverlayView)

        headerTopConstraint = headerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12)
        scrollTopConstraint = scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12)
        compareTopConstraint = compareStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20)

        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            headerTopConstraint!,

            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            backButton.topAnchor.constraint(equalTo: headerView.topAnchor),
            backButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor),

            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scrollTopConstraint!,
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            compareStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            compareStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            compareTopConstraint!,

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            skeletonOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skeletonOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skeletonOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            skeletonOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        refreshUI()
    }

    override func viewDidLayout() {
        super.viewDidLayout()

        guard state.settings.mode != .compare else { return }

        let metrics = currentGridLayout()
        guard metrics != lastGridLayoutMetrics else { return }

        lastGridLayoutMetrics = metrics
        collectionView.collectionViewLayout?.invalidateLayout()
    }

    func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        state.visibleFonts.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: FontCardViewItem.identifier, for: indexPath)
        guard let fontItem = item as? FontCardViewItem else { return item }
        let font = state.visibleFonts[indexPath.item]
        fontItem.configure(font: font, state: state)
        fontItem.onCompare = { [weak self] in self?.state.toggleCompare(for: font.id) }
        fontItem.onSelect = { [weak self] in self?.state.activateFontCard(font) }
        return fontItem
    }

    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let layout = currentGridLayout()
        return NSSize(width: layout.cardWidth, height: 200)
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        insetForSectionAt section: Int
    ) -> NSEdgeInsets {
        let layout = currentGridLayout()
        return NSEdgeInsets(top: 0, left: layout.sideInset, bottom: 0, right: layout.sideInset)
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        layout collectionViewLayout: NSCollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        columnSpacing
    }

    func refreshUI() {
        let isCompare = state.settings.mode == .compare
        let isLoading = state.loadingState.isLoading
        let snapshot = RenderSnapshot(
            mode: state.settings.mode,
            visibleFontIDs: state.visibleFonts.map(\.id),
            compareDisplayFontIDs: isCompare ? state.settings.compareFontIDs : [],
            activePreviewText: state.settings.activePreviewText,
            fontSize: state.settings.fontSize,
            lineHeight: state.settings.lineHeight,
            letterSpacing: state.settings.letterSpacing
        )

        headerView.isHidden = !isCompare
        scrollView.isHidden = isCompare
        compareStack.isHidden = !isCompare
        skeletonOverlayView.isHidden = !(isLoading && !isCompare)
        headerTopConstraint?.constant = isCompare ? 12 : 0
        scrollTopConstraint?.constant = isCompare ? 12 : 0
        compareTopConstraint?.constant = isCompare ? 20 : 0

        if snapshot != lastRenderSnapshot {
            if isCompare {
                rebuildCompareStack()
            } else {
                collectionView.reloadData()
            }
            lastRenderSnapshot = snapshot
        }

        syncCardSelectionAppearance()
        syncCardCompareAppearance()

        let showEmpty = state.visibleFonts.isEmpty && !isCompare
        emptyLabel.isHidden = !showEmpty || isLoading
        emptyLabel.stringValue = showEmpty ? Localizer.text("state.empty.search") : ""
    }

    @objc private func handleBack() {
        state.showLibraryView()
    }

    private func rebuildCompareStack() {
        compareStack.arrangedSubviews.forEach {
            compareStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        if state.compareFonts.isEmpty {
            let label = NSTextField(wrappingLabelWithString: Localizer.text("state.empty.compare"))
            label.textColor = .secondaryLabelColor
            compareStack.addArrangedSubview(label)
            return
        }

        for font in state.compareFonts {
            let card = NSView()
            card.wantsLayer = true
            card.layer?.cornerRadius = 16
            card.layer?.borderWidth = 1
            card.layer?.borderColor = NSColor.separatorColor.cgColor
            card.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

            let stack = NSStackView()
            stack.orientation = .vertical
            stack.spacing = 10
            stack.translatesAutoresizingMaskIntoConstraints = false

            let title = NSTextField(labelWithString: "\(font.family) · \(font.style)")
            title.font = .systemFont(ofSize: 15, weight: .semibold)

            let preview = NSTextField(wrappingLabelWithString: state.renderedPreviewString(for: font))
            preview.maximumNumberOfLines = 0
            preview.font = NSFont(name: font.postScriptName, size: CGFloat(state.settings.fontSize))
                ?? .systemFont(ofSize: CGFloat(state.settings.fontSize))

            let removeButton = NSButton(title: Localizer.text("action.remove.compare"), target: self, action: #selector(removeCompareFont(_:)))
            removeButton.identifier = NSUserInterfaceItemIdentifier(font.id)

            stack.addArrangedSubview(title)
            stack.addArrangedSubview(preview)
            stack.addArrangedSubview(removeButton)
            card.addSubview(stack)

            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
                stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
            ])
            compareStack.addArrangedSubview(card)
        }
    }

    @objc private func removeCompareFont(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        state.toggleCompare(for: id)
    }

    private func syncCardSelectionAppearance() {
        for item in collectionView.visibleItems() {
            guard let fontItem = item as? FontCardViewItem,
                  let indexPath = collectionView.indexPath(for: item),
                  state.visibleFonts.indices.contains(indexPath.item) else { continue }
            let font = state.visibleFonts[indexPath.item]
            fontItem.setSelected(state.selectedFontID == font.id)
        }
    }

    private func syncCardCompareAppearance() {
        for item in collectionView.visibleItems() {
            guard let fontItem = item as? FontCardViewItem,
                  let indexPath = collectionView.indexPath(for: item),
                  state.visibleFonts.indices.contains(indexPath.item) else { continue }
            let font = state.visibleFonts[indexPath.item]
            fontItem.updateCompareState(isCompared: state.settings.compareFontIDs.contains(font.id))
        }
    }

    private func currentGridLayout() -> BrowserGridLayoutMetrics {
        gridLayoutCalculator.metrics(for: scrollView.contentSize.width)
    }
}

private struct BrowserRepresentable: NSViewControllerRepresentable {
    @ObservedObject var state: AppState

    func makeNSViewController(context: Context) -> ContentViewController {
        ContentViewController(state: state)
    }

    func updateNSViewController(_ nsViewController: ContentViewController, context: Context) {
        nsViewController.refreshUI()
    }
}

private struct SidebarView: View {
    @ObservedObject var state: AppState
    @State private var showsPreviewEditor = false
    @State private var previewDraft = ""
    @State private var compareTrayHeight: CGFloat = 60
    private let languageChipColumns = [GridItem(.adaptive(minimum: 72), spacing: 8, alignment: .leading)]

    var body: some View {
        ZStack(alignment: .bottom) {
            Form {
                Section(Localizer.text("section.collection")) {
                    Menu {
                        ForEach(state.standardFontCollections) { collection in
                            Button {
                                state.setSelectedCollectionID(collection.id)
                            } label: {
                                collectionMenuLabel(for: collection)
                            }
                        }

                        if !state.customFontCollections.isEmpty {
                            Divider()
                            ForEach(state.customFontCollections) { collection in
                                Button {
                                    state.setSelectedCollectionID(collection.id)
                                } label: {
                                    collectionMenuLabel(for: collection)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(state.selectedFontCollection.displayName)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section {
                    ZStack {
                        LazyVGrid(
                            columns: languageChipColumns,
                            alignment: .leading,
                            spacing: 8
                        ) {
                            ForEach(LanguageSupportFilter.allCases) { filter in
                                LanguageFilterChip(
                                    title: Localizer.text(filter.localizationKey),
                                    count: state.totalCount(for: filter),
                                    isSelected: state.settings.languageFilters.contains(filter)
                                ) {
                                    state.toggleLanguageFilter(filter)
                                }
                            }
                        }
                        .opacity(state.loadingState.isLoading ? 0 : 1)
                        .allowsHitTesting(!state.loadingState.isLoading)

                        if state.loadingState.isLoading {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.secondary.opacity(0.08))
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                } header: {
                    HStack {
                        Text(Localizer.text("section.language"))
                        Spacer()
                        if !state.settings.languageFilters.isEmpty && !state.loadingState.isLoading {
                            Button(Localizer.text("action.clear")) {
                                state.clearLanguageFilters()
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                } footer: {
                    Text(Localizer.text("section.language.hint"))
                }

                Section(Localizer.text("section.preview.text")) {
                    Toggle(Localizer.text("toggle.use.default"), isOn: Binding(
                        get: { state.settings.useDefaultText },
                        set: { state.setUseDefaultText($0) }
                    ))

                    Button(Localizer.text("action.edit.preview")) {
                        previewDraft = state.settings.text
                        showsPreviewEditor = true
                    }
                    .disabled(state.settings.useDefaultText)
                }

                Section(Localizer.text("section.preview.size")) {
                    HStack(spacing: 12) {
                        Slider(
                            value: Binding(
                                get: { state.settings.fontSize },
                                set: { state.setFontSize($0.rounded()) }
                            ),
                            in: 12...144
                        ) {
                            EmptyView()
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        Text(String(format: "%.0f pt", state.settings.fontSize))
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 52, alignment: .trailing)
                    }
                }

                Section {
                    ForEach(state.recentFonts) { font in
                        Button {
                            state.selectFont(id: font.id)
                        } label: {
                            HStack(spacing: 8) {
                                Text(font.family)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text(font.style)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text(Localizer.text("section.recent"))
                        Spacer()
                        if !state.recentFonts.isEmpty {
                            Button(Localizer.text("action.clear")) {
                                state.clearRecentFonts()
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding(.bottom, compareTrayHeight + 12)

            CompareTrayView(state: state)
                .measureHeight { compareTrayHeight = $0 }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .navigationTitle("Font Deck · \(state.visibleFonts.count)")
        .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        .sheet(isPresented: $showsPreviewEditor) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Localizer.text("sheet.preview.title"))
                    .font(.headline)

                TextEditor(text: $previewDraft)
                    .frame(minWidth: 420, minHeight: 220)

                HStack {
                    Spacer()
                    Button(Localizer.text("action.cancel")) {
                        showsPreviewEditor = false
                    }
                    Button(Localizer.text("action.done")) {
                        state.setPreviewText(previewDraft)
                        showsPreviewEditor = false
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
        }
    }

    @ViewBuilder
    private func collectionMenuLabel(for collection: FontCollectionRecord) -> some View {
        HStack(spacing: 8) {
            if state.settings.selectedCollectionID == collection.id {
                Image(systemName: "checkmark")
                    .frame(width: 12)
            } else {
                Color.clear
                    .frame(width: 12, height: 12)
            }
            Text(collection.displayName)
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension View {
    func measureHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HeightPreferenceKey.self, value: proxy.size.height)
            }
        )
        .onPreferenceChange(HeightPreferenceKey.self, perform: onChange)
    }
}

private struct LanguageFilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text("\(count)")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(isSelected ? Color.white.opacity(0.88) : Color.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.85) : Color.secondary.opacity(0.16), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct CompareTrayView: View {
    @ObservedObject var state: AppState
    private let trayShape = RoundedRectangle(
        cornerRadius: 18,
        style: .continuous
    )

    var body: some View {
        let isExpanded = !state.compareFonts.isEmpty

        VStack(alignment: .leading, spacing: isExpanded ? 14 : 0) {
            CompareTrayHeader(
                count: state.compareFonts.count,
                limit: PreviewSettings.compareFontLimit
            )

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(state.compareFonts) { font in
                        HStack(alignment: .top, spacing: 10) {
                            Button {
                                state.toggleCompare(for: font.id)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption.weight(.semibold))
                                    .frame(width: 18, height: 18)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.borderless)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(font.family)
                                    .lineLimit(1)
                                Text(font.style)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }

                HStack {
                    Button(Localizer.text("action.compare.fonts")) {
                        state.showCompareView()
                    }
                    .buttonStyle(.borderedProminent)

                    Button(Localizer.text("action.clear")) {
                        state.clearCompareFonts()
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 44, alignment: .top)
        .background(.regularMaterial, in: trayShape)
        .clipShape(trayShape)
        .overlay(
            trayShape
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.10), radius: 18, x: 0, y: -2)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: isExpanded)
    }
}

private struct CompareTrayHeader: View {
    let count: Int
    let limit: Int

    var body: some View {
        HStack(spacing: 8) {
            Text(Localizer.text("section.compare"))
                .font(.subheadline.weight(.semibold))

            CompareCountBadge(count: count, limit: limit)

            Spacer(minLength: 0)
        }
        .frame(height: 22)
        .transaction { transaction in
            transaction.animation = nil
        }
    }
}

private struct CompareCountBadge: View {
    let count: Int
    let limit: Int

    var body: some View {
        Text("\(count)/\(limit)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.12))
            )
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

private struct RootView: View {
    @ObservedObject var state: AppState
    @State private var visibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            SidebarView(state: state)
        } detail: {
            BrowserRepresentable(state: state)
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: Binding(
            get: { state.searchText },
            set: { state.searchText = $0 }
        ), placement: .toolbar, prompt: Text(Localizer.text("search.placeholder")))
        .frame(minWidth: 550, minHeight: 650)
    }
}

@MainActor
final class WindowCoordinator: NSObject, NSWindowDelegate {
    private let store: WindowStateStoreProtocol
    private let state: AppState
    private weak var window: NSWindow?
    private var flagsMonitor: Any?

    init(store: WindowStateStoreProtocol, state: AppState, window: NSWindow) {
        self.store = store
        self.state = state
        self.window = window
        flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak state] event in
            guard window.isKeyWindow else { return event }
            state?.setQuickFamilyPeekActive(event.modifierFlags.contains(.option))
            return event
        }
    }

    deinit {
        if let flagsMonitor {
            NSEvent.removeMonitor(flagsMonitor)
        }
    }

    func windowDidMove(_ notification: Notification) { persist(notification) }
    func windowDidResize(_ notification: Notification) { persist(notification) }
    func windowWillClose(_ notification: Notification) {
        state.setQuickFamilyPeekActive(false)
        persist(notification)
    }
    func windowDidResignKey(_ notification: Notification) {
        state.setQuickFamilyPeekActive(false)
    }
    func windowDidBecomeKey(_ notification: Notification) {
        state.setQuickFamilyPeekActive(NSEvent.modifierFlags.contains(.option))
    }

    private func persist(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        let frame = window.frame
        store.saveWindowState(
            WindowState(originX: frame.origin.x, originY: frame.origin.y, width: frame.width, height: frame.height)
        )
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    private let disabledTabActionNames: Set<String> = [
        "newTab:",
        "toggleTabBar:",
        "showNextTab:",
        "showPreviousTab:",
        "moveTabToNewWindow:",
        "mergeAllWindows:"
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        NSApp.windowsMenu = NSMenu(title: "Window")
        DispatchQueue.main.async { [weak self] in
            self?.disableTabMenuCommands()
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        guard let action = menuItem.action else { return true }
        return !disabledTabActionNames.contains(NSStringFromSelector(action))
    }

    private func disableTabMenuCommands() {
        guard let mainMenu = NSApp.mainMenu else { return }
        applyDisabledTabTargets(in: mainMenu)
    }

    private func applyDisabledTabTargets(in menu: NSMenu) {
        for item in menu.items {
            if let action = item.action,
               disabledTabActionNames.contains(NSStringFromSelector(action)) {
                item.target = self
            }

            if let submenu = item.submenu {
                applyDisabledTabTargets(in: submenu)
            }
        }
    }
}

private struct WindowRootView: View {
    @StateObject private var state: AppState
    private let windowStateStore: WindowStateStoreProtocol

    init(sharedCatalog: SharedCatalogState, windowStateStore: WindowStateStoreProtocol) {
        _state = StateObject(wrappedValue: AppState(
            sharedCatalog: sharedCatalog,
            glyphCoverageService: GlyphCoverageService(),
            settingsStore: SettingsStore()
        ))
        self.windowStateStore = windowStateStore
    }

    var body: some View {
        RootView(state: state)
            .focusedSceneObject(state)
            .background(WindowAccessor(state: state, store: windowStateStore))
    }
}

private struct AppCommands: Commands {
    @FocusedObject private var state: AppState?
    let sharedCatalog: SharedCatalogState

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(Localizer.text("menu.about")) {
                NSApp.orderFrontStandardAboutPanel(nil)
            }
        }
        CommandGroup(after: .toolbar) {
            Button {
                sharedCatalog.loadFonts(force: true)
            }
            label: {
                Label(Localizer.text("action.refresh"), systemImage: "arrow.clockwise")
            }
            .keyboardShortcut("r")

            Divider()

            Picker(selection: Binding(
                get: { state?.settings.sortMode ?? .nameAsc },
                set: { state?.setSortMode($0) }
            )) {
                Text(Localizer.text("sort.asc")).tag(SortMode.nameAsc)
                Text(Localizer.text("sort.desc")).tag(SortMode.nameDesc)
            } label: {
                Label(Localizer.text("menu.sortMode"), systemImage: "arrow.up.arrow.down")
            }
            .disabled(state == nil)

            Divider()

            Toggle(
                Localizer.text("menu.quickFamilyPeek"),
                isOn: Binding(
                    get: { state?.settings.quickFamilyPeekEnabled ?? false },
                    set: { state?.setQuickFamilyPeekEnabled($0) }
                )
            )
            .disabled(state == nil)
        }
    }
}

@main
struct FontDeckApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var sharedCatalog: SharedCatalogState

    private let windowStateStore = WindowStateStore()

    init() {
        let sharedCatalog = SharedCatalogState(fontCatalogService: FontCatalogService())
        _sharedCatalog = StateObject(wrappedValue: sharedCatalog)
        sharedCatalog.loadFonts()
    }

    var body: some Scene {
        WindowGroup {
            WindowRootView(sharedCatalog: sharedCatalog, windowStateStore: windowStateStore)
        }
        .commands {
            AppCommands(sharedCatalog: sharedCatalog)
        }
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let state: AppState
    let store: WindowStateStoreProtocol

    final class Coordinator {
        var configuredWindowNumber: Int?
        var windowCoordinator: WindowCoordinator?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window: window, coordinator: context.coordinator)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                configure(window: window, coordinator: context.coordinator)
            }
        }
    }

    private func configure(window: NSWindow, coordinator: Coordinator) {
        guard coordinator.configuredWindowNumber != window.windowNumber else { return }

        if coordinator.configuredWindowNumber == nil {
            let saved = store.loadWindowState()
            window.setFrame(
                NSRect(x: saved.originX, y: saved.originY, width: saved.width, height: saved.height),
                display: true
            )
        }

        let windowCoordinator = WindowCoordinator(store: store, state: state, window: window)
        window.delegate = windowCoordinator
        coordinator.windowCoordinator = windowCoordinator
        coordinator.configuredWindowNumber = window.windowNumber

        NSApp.appearance = state.settings.themePreference.appearance
        state.onThemeChange = { theme in
            NSApp.appearance = theme.appearance
        }
        state.onTransientNotice = { text in
            window.subtitle = text
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                if window.subtitle == text {
                    window.subtitle = ""
                }
            }
        }
    }
}
