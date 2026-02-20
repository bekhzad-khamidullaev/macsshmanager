import SwiftUI
import Foundation
import Security
import AppKit
import SwiftTerm
import UniformTypeIdentifiers

enum AuthMethod: String, Codable, CaseIterable, Identifiable {
    case key
    case password

    var id: String { rawValue }

    var title: String {
        switch self {
        case .key: return "Key"
        case .password: return "Password"
        }
    }
}

enum TerminalBellMode: String, Codable, CaseIterable, Identifiable {
    case audible
    case visual
    case none

    var id: String { rawValue }

    var title: String {
        switch self {
        case .audible: return "Audible"
        case .visual: return "Visual"
        case .none: return "Disabled"
        }
    }
}

fileprivate struct ConsoleThemePalette {
    let background: NSColor
    let foreground: NSColor
    let caret: NSColor
}

enum ConsoleTheme: String, Codable, CaseIterable, Identifiable {
    case system
    case midnight
    case graphite
    case matrix
    case solarizedDark
    case amber

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .midnight: return "Midnight"
        case .graphite: return "Graphite"
        case .matrix: return "Matrix"
        case .solarizedDark: return "Solarized Dark"
        case .amber: return "Amber"
        }
    }

    fileprivate var palette: ConsoleThemePalette? {
        switch self {
        case .system:
            return nil
        case .midnight:
            return ConsoleThemePalette(
                background: NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.11, alpha: 1),
                foreground: NSColor(calibratedRed: 0.83, green: 0.88, blue: 0.96, alpha: 1),
                caret: NSColor(calibratedRed: 0.46, green: 0.66, blue: 0.96, alpha: 1)
            )
        case .graphite:
            return ConsoleThemePalette(
                background: NSColor(calibratedRed: 0.10, green: 0.11, blue: 0.12, alpha: 1),
                foreground: NSColor(calibratedRed: 0.86, green: 0.87, blue: 0.88, alpha: 1),
                caret: NSColor(calibratedRed: 0.66, green: 0.70, blue: 0.76, alpha: 1)
            )
        case .matrix:
            return ConsoleThemePalette(
                background: NSColor(calibratedRed: 0.01, green: 0.07, blue: 0.03, alpha: 1),
                foreground: NSColor(calibratedRed: 0.55, green: 0.95, blue: 0.59, alpha: 1),
                caret: NSColor(calibratedRed: 0.75, green: 1.00, blue: 0.78, alpha: 1)
            )
        case .solarizedDark:
            return ConsoleThemePalette(
                background: NSColor(calibratedRed: 0.00, green: 0.17, blue: 0.21, alpha: 1),
                foreground: NSColor(calibratedRed: 0.51, green: 0.58, blue: 0.59, alpha: 1),
                caret: NSColor(calibratedRed: 0.71, green: 0.54, blue: 0.00, alpha: 1)
            )
        case .amber:
            return ConsoleThemePalette(
                background: NSColor(calibratedRed: 0.09, green: 0.05, blue: 0.00, alpha: 1),
                foreground: NSColor(calibratedRed: 0.98, green: 0.78, blue: 0.38, alpha: 1),
                caret: NSColor(calibratedRed: 1.00, green: 0.86, blue: 0.56, alpha: 1)
            )
        }
    }
}

enum RequestTTYMode: String, Codable, CaseIterable, Identifiable {
    case force
    case auto
    case disabled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .force: return "Force"
        case .auto: return "Auto"
        case .disabled: return "Disabled"
        }
    }

    var sshArgs: [String] {
        switch self {
        case .force: return ["-tt"]
        case .auto: return ["-t"]
        case .disabled: return ["-T"]
        }
    }
}

enum StrictHostKeyMode: String, Codable, CaseIterable, Identifiable {
    case acceptNew
    case strict
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .acceptNew: return "Accept New"
        case .strict: return "Strict"
        case .off: return "Off"
        }
    }

    var sshValue: String {
        switch self {
        case .acceptNew: return "accept-new"
        case .strict: return "yes"
        case .off: return "no"
        }
    }
}

enum IPVersionPreference: String, Codable, CaseIterable, Identifiable {
    case auto
    case ipv4
    case ipv6

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Auto"
        case .ipv4: return "IPv4"
        case .ipv6: return "IPv6"
        }
    }

    var sshValue: String? {
        switch self {
        case .auto: return nil
        case .ipv4: return "inet"
        case .ipv6: return "inet6"
        }
    }
}

enum ProxyType: String, Codable, CaseIterable, Identifiable {
    case none
    case socks4
    case socks5
    case http
    case command

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "None"
        case .socks4: return "SOCKS4"
        case .socks5: return "SOCKS5"
        case .http: return "HTTP CONNECT"
        case .command: return "Custom Command"
        }
    }
}

enum SSHLogVerbosity: String, Codable, CaseIterable, Identifiable {
    case none
    case verbose
    case debug2
    case debug3

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "Normal"
        case .verbose: return "Verbose"
        case .debug2: return "Debug 2"
        case .debug3: return "Debug 3"
        }
    }

    var sshFlags: [String] {
        switch self {
        case .none: return []
        case .verbose: return ["-v"]
        case .debug2: return ["-vv"]
        case .debug3: return ["-vvv"]
        }
    }
}

enum HostSettingsSection: String, CaseIterable, Identifiable {
    case terminal = "Terminal"
    case connection = "Connection"
    case auth = "Auth"
    case ssh = "SSH"
    case tunnels = "Tunnels"
    case proxy = "Proxy"
    case environment = "Environment"
    case logging = "Logging"

    var id: String { rawValue }
}

enum HostEditorMode {
    case host
    case group

    var title: String {
        switch self {
        case .host: return "Host Editor"
        case .group: return "Group Host Settings"
        }
    }

    var saveTitle: String {
        switch self {
        case .host: return "Save"
        case .group: return "Apply to Group"
        }
    }

    var allowsConnect: Bool {
        switch self {
        case .host: return true
        case .group: return false
        }
    }
}

enum ConnectionProtocol: String, Codable, CaseIterable, Identifiable {
    case ssh
    case telnet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ssh: return "SSH"
        case .telnet: return "Telnet"
        }
    }
}

enum TerminalLaunchMode: String, Codable, CaseIterable, Identifiable {
    case embedded
    case systemTerminal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .embedded: return "Embedded TTY"
        case .systemTerminal: return "System Terminal"
        }
    }
}

struct PuttySettings: Codable, Equatable {
    var terminalType: String = "xterm-256color"
    var localeCharset: String = "UTF-8"
    var terminalColumns: Int = 120
    var terminalRows: Int = 34
    var scrollbackLines: Int = 10_000
    var fontSize: Int = 13
    var optionIsMeta: Bool = false
    var allowMouseReporting: Bool = true
    var backspaceSendsControlH: Bool = false
    var deleteSendsDEL: Bool = true
    var disableRemoteTitle: Bool = false
    var bellMode: TerminalBellMode = .audible
    var consoleTheme: ConsoleTheme = .system

    var requestTTY: RequestTTYMode = .force
    var connectTimeoutSeconds: Int = 15
    var keepAliveIntervalSeconds: Int = 0
    var keepAliveCountMax: Int = 3
    var tcpKeepAlive: Bool = true
    var addressFamily: IPVersionPreference = .auto
    var bindAddress: String = ""
    var strictHostKeyChecking: StrictHostKeyMode = .acceptNew
    var userKnownHostsFile: String = ""

    var enablePublicKeyAuth: Bool = true
    var enablePasswordAuth: Bool = true
    var enableKeyboardInteractiveAuth: Bool = true
    var enableGSSAPIAuth: Bool = true
    var forwardAgent: Bool = false
    var gssapiDelegateCredentials: Bool = false
    var compression: Bool = false
    var x11Forwarding: Bool = false
    var x11Display: String = ""

    var kexAlgorithms: String = ""
    var ciphers: String = ""
    var macs: String = ""
    var hostKeyAlgorithms: String = ""
    var rekeyLimit: String = ""
    var remoteCommand: String = ""
    var noShell: Bool = false

    var localPortForwards: String = ""
    var remotePortForwards: String = ""
    var dynamicPortForwards: String = ""

    var sendEnvPatterns: String = ""
    var setEnvironment: String = ""

    var proxyType: ProxyType = .none
    var proxyHost: String = ""
    var proxyPort: Int = 0
    var proxyUsername: String = ""
    var proxyPassword: String = ""
    var proxyCommand: String = ""

    var loggingEnabled: Bool = false
    var logFilePath: String = ""
    var logVerbosity: SSHLogVerbosity = .none
}

enum AppPage: String, CaseIterable, Identifiable, Hashable {
    case hosts = "Hosts"
    case sessions = "TTY"
    case files = "Files"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hosts: return "folder"
        case .sessions: return "terminal"
        case .files: return "folder.badge.gearshape"
        }
    }
}

enum SystemMenuAction {
    case newHost
    case newGroup
    case importConfig
    case exportConfig
    case openSettings
    case viewTTY
    case viewFiles
    case viewSettings
    case toggleSidebar
    case connectSelected
    case openFiles
    case previousHost
    case nextHost
    case deleteSelection
    case manageShortcuts
    case saveSettings
    case closeAllSessions
    case refreshFiles
}

extension Notification.Name {
    static let macSSHSystemMenuAction = Notification.Name("MacSSHManager.SystemMenuAction")
}

private func sendSystemMenuAction(_ action: SystemMenuAction) {
    NotificationCenter.default.post(name: .macSSHSystemMenuAction, object: action)
}

struct ShortcutBinding: Codable, Equatable {
    var keyToken: String
    var command: Bool
    var option: Bool
    var shift: Bool
    var control: Bool

    init(
        keyToken: String,
        command: Bool = false,
        option: Bool = false,
        shift: Bool = false,
        control: Bool = false
    ) {
        self.keyToken = ShortcutKeyCatalog.normalizedToken(keyToken)
        self.command = command
        self.option = option
        self.shift = shift
        self.control = control
    }

    var keyEquivalent: KeyEquivalent {
        ShortcutKeyCatalog.keyEquivalent(for: keyToken)
    }

    var modifiers: EventModifiers {
        var value: EventModifiers = []
        if command { value.insert(.command) }
        if option { value.insert(.option) }
        if shift { value.insert(.shift) }
        if control { value.insert(.control) }
        return value
    }

    var displayValue: String {
        var parts: [String] = []
        if control { parts.append("⌃") }
        if option { parts.append("⌥") }
        if shift { parts.append("⇧") }
        if command { parts.append("⌘") }
        parts.append(ShortcutKeyCatalog.symbol(for: keyToken))
        return parts.joined()
    }

    var signature: String {
        "\(ShortcutKeyCatalog.normalizedToken(keyToken))|\(command)|\(option)|\(shift)|\(control)"
    }
}

struct ShortcutKeyOption: Identifiable, Hashable {
    let token: String
    let title: String
    var id: String { token }
}

enum ShortcutKeyCatalog {
    static let keyOptions: [ShortcutKeyOption] = {
        var options: [ShortcutKeyOption] = []

        for letter in "abcdefghijklmnopqrstuvwxyz" {
            let token = String(letter)
            options.append(ShortcutKeyOption(token: token, title: token.uppercased()))
        }

        for digit in "0123456789" {
            let token = String(digit)
            options.append(ShortcutKeyOption(token: token, title: token))
        }

        options.append(contentsOf: [
            ShortcutKeyOption(token: "comma", title: "Comma (,)"),
            ShortcutKeyOption(token: "slash", title: "Slash (/)"),
            ShortcutKeyOption(token: "return", title: "Return"),
            ShortcutKeyOption(token: "upArrow", title: "Up Arrow"),
            ShortcutKeyOption(token: "downArrow", title: "Down Arrow"),
            ShortcutKeyOption(token: "delete", title: "Delete")
        ])

        return options
    }()

    static func normalizedToken(_ token: String) -> String {
        let value = token.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch value {
        case ",", "comma":
            return "comma"
        case "/", "slash":
            return "slash"
        case "return", "enter":
            return "return"
        case "up", "uparrow", "up_arrow":
            return "upArrow"
        case "down", "downarrow", "down_arrow":
            return "downArrow"
        case "delete", "del", "backspace":
            return "delete"
        default:
            if value.count == 1, let scalar = value.unicodeScalars.first, CharacterSet.alphanumerics.contains(scalar) {
                return value
            }
            return "n"
        }
    }

    static func keyEquivalent(for token: String) -> KeyEquivalent {
        let normalized = normalizedToken(token)
        switch normalized {
        case "comma":
            return ","
        case "slash":
            return "/"
        case "return":
            return .return
        case "upArrow":
            return .upArrow
        case "downArrow":
            return .downArrow
        case "delete":
            return .delete
        default:
            guard let char = normalized.first else { return "n" }
            return KeyEquivalent(char)
        }
    }

    static func symbol(for token: String) -> String {
        switch normalizedToken(token) {
        case "comma":
            return ","
        case "slash":
            return "/"
        case "return":
            return "↩"
        case "upArrow":
            return "↑"
        case "downArrow":
            return "↓"
        case "delete":
            return "⌫"
        default:
            return normalizedToken(token).uppercased()
        }
    }

    static func title(for token: String) -> String {
        let normalized = normalizedToken(token)
        return keyOptions.first(where: { $0.token == normalized })?.title ?? normalized.uppercased()
    }
}

enum ShortcutAction: String, CaseIterable, Identifiable {
    case newHost
    case newGroup
    case importConfig
    case exportConfig
    case openSettings
    case toggleSidebar
    case viewTTY
    case viewFiles
    case viewSettings
    case connectSelected
    case openFiles
    case previousHost
    case nextHost
    case deleteSelection
    case saveSettings
    case closeAllSessions
    case refreshFiles
    case manageShortcuts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newHost: return "New Host"
        case .newGroup: return "New Group"
        case .importConfig: return "Import Config"
        case .exportConfig: return "Export Config"
        case .openSettings: return "Open Settings"
        case .toggleSidebar: return "Toggle Sidebar"
        case .viewTTY: return "View TTY"
        case .viewFiles: return "View Files"
        case .viewSettings: return "View Settings"
        case .connectSelected: return "Connect Selected"
        case .openFiles: return "Open Files"
        case .previousHost: return "Previous Host"
        case .nextHost: return "Next Host"
        case .deleteSelection: return "Delete Selected"
        case .saveSettings: return "Save Settings"
        case .closeAllSessions: return "Close All Sessions"
        case .refreshFiles: return "Refresh Files"
        case .manageShortcuts: return "Keyboard Shortcuts"
        }
    }

    var menuSection: String {
        switch self {
        case .newHost, .newGroup, .importConfig, .exportConfig, .openSettings:
            return "File"
        case .toggleSidebar, .viewTTY, .viewFiles, .viewSettings:
            return "View"
        case .connectSelected, .openFiles, .previousHost, .nextHost, .deleteSelection:
            return "Navigate"
        case .saveSettings, .closeAllSessions, .refreshFiles, .manageShortcuts:
            return "Tools"
        }
    }

    var defaultBinding: ShortcutBinding {
        switch self {
        case .newHost: return ShortcutBinding(keyToken: "n", command: true)
        case .newGroup: return ShortcutBinding(keyToken: "n", command: true, shift: true)
        case .importConfig: return ShortcutBinding(keyToken: "i", command: true, shift: true)
        case .exportConfig: return ShortcutBinding(keyToken: "e", command: true, shift: true)
        case .openSettings: return ShortcutBinding(keyToken: "comma", command: true)
        case .toggleSidebar: return ShortcutBinding(keyToken: "s", command: true, option: true)
        case .viewTTY: return ShortcutBinding(keyToken: "1", command: true)
        case .viewFiles: return ShortcutBinding(keyToken: "2", command: true)
        case .viewSettings: return ShortcutBinding(keyToken: "3", command: true)
        case .connectSelected: return ShortcutBinding(keyToken: "return", command: true)
        case .openFiles: return ShortcutBinding(keyToken: "f", command: true, option: true)
        case .previousHost: return ShortcutBinding(keyToken: "upArrow", command: true, option: true)
        case .nextHost: return ShortcutBinding(keyToken: "downArrow", command: true, option: true)
        case .deleteSelection: return ShortcutBinding(keyToken: "delete")
        case .saveSettings: return ShortcutBinding(keyToken: "s", command: true)
        case .closeAllSessions: return ShortcutBinding(keyToken: "w", command: true, shift: true)
        case .refreshFiles: return ShortcutBinding(keyToken: "r", command: true, option: true)
        case .manageShortcuts: return ShortcutBinding(keyToken: "slash", command: true)
        }
    }

    var systemAction: SystemMenuAction {
        switch self {
        case .newHost: return .newHost
        case .newGroup: return .newGroup
        case .importConfig: return .importConfig
        case .exportConfig: return .exportConfig
        case .openSettings: return .openSettings
        case .toggleSidebar: return .toggleSidebar
        case .viewTTY: return .viewTTY
        case .viewFiles: return .viewFiles
        case .viewSettings: return .viewSettings
        case .connectSelected: return .connectSelected
        case .openFiles: return .openFiles
        case .previousHost: return .previousHost
        case .nextHost: return .nextHost
        case .deleteSelection: return .deleteSelection
        case .saveSettings: return .saveSettings
        case .closeAllSessions: return .closeAllSessions
        case .refreshFiles: return .refreshFiles
        case .manageShortcuts: return .manageShortcuts
        }
    }
}

@MainActor
final class ShortcutStore: ObservableObject {
    private static let storageKey = "MacSSHManager.Shortcuts.v1"

    @Published private(set) var bindings: [ShortcutAction: ShortcutBinding] = ShortcutStore.defaultBindings()

    init() {
        load()
    }

    func binding(for action: ShortcutAction) -> ShortcutBinding {
        bindings[action] ?? action.defaultBinding
    }

    func update(_ value: ShortcutBinding, for action: ShortcutAction) {
        var sanitized = value
        sanitized.keyToken = ShortcutKeyCatalog.normalizedToken(value.keyToken)
        bindings[action] = sanitized
        save()
    }

    func resetToDefaults() {
        bindings = Self.defaultBindings()
        save()
    }

    func conflicts(for action: ShortcutAction) -> [ShortcutAction] {
        let target = binding(for: action).signature
        return ShortcutAction.allCases.filter { candidate in
            candidate != action && binding(for: candidate).signature == target
        }
    }

    private static func defaultBindings() -> [ShortcutAction: ShortcutBinding] {
        var result: [ShortcutAction: ShortcutBinding] = [:]
        for action in ShortcutAction.allCases {
            result[action] = action.defaultBinding
        }
        return result
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([String: ShortcutBinding].self, from: data) else {
            bindings = Self.defaultBindings()
            return
        }

        var loaded = Self.defaultBindings()
        for action in ShortcutAction.allCases {
            if let value = decoded[action.rawValue] {
                loaded[action] = ShortcutBinding(
                    keyToken: value.keyToken,
                    command: value.command,
                    option: value.option,
                    shift: value.shift,
                    control: value.control
                )
            }
        }
        bindings = loaded
    }

    private func save() {
        let payload = Dictionary(uniqueKeysWithValues: bindings.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}

enum SidebarSelection: Hashable {
    case page(AppPage)
    case group(UUID)
    case host(UUID)
    case ungrouped
}

struct HostGroup: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var parentId: UUID?
}

struct HostEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String = "New Host"
    var host: String = ""
    var port: Int = 22
    var connectionProtocol: ConnectionProtocol = .ssh
    var terminalLaunchMode: TerminalLaunchMode = .embedded
    var username: String = ""
    var authMethod: AuthMethod = .key
    var keyPath: String = "~/.ssh/id_rsa"
    var groupId: UUID?
    var putty: PuttySettings = PuttySettings()
    var fileTransfer: FileTransferSettings = FileTransferSettings()

    init(
        id: UUID = UUID(),
        name: String = "New Host",
        host: String = "",
        port: Int = 22,
        connectionProtocol: ConnectionProtocol = .ssh,
        terminalLaunchMode: TerminalLaunchMode = .embedded,
        username: String = "",
        authMethod: AuthMethod = .key,
        keyPath: String = "~/.ssh/id_rsa",
        groupId: UUID? = nil,
        putty: PuttySettings = PuttySettings(),
        fileTransfer: FileTransferSettings = FileTransferSettings()
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.connectionProtocol = connectionProtocol
        self.terminalLaunchMode = terminalLaunchMode
        self.username = username
        self.authMethod = authMethod
        self.keyPath = keyPath
        self.groupId = groupId
        self.putty = putty
        self.fileTransfer = fileTransfer
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case host
        case port
        case connectionProtocol
        case terminalLaunchMode
        case username
        case authMethod
        case keyPath
        case groupId
        case putty
        case fileTransfer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "New Host"
        host = try container.decodeIfPresent(String.self, forKey: .host) ?? ""
        port = try container.decodeIfPresent(Int.self, forKey: .port) ?? 22
        connectionProtocol = try container.decodeIfPresent(ConnectionProtocol.self, forKey: .connectionProtocol) ?? .ssh
        terminalLaunchMode = try container.decodeIfPresent(TerminalLaunchMode.self, forKey: .terminalLaunchMode) ?? .embedded
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        authMethod = try container.decodeIfPresent(AuthMethod.self, forKey: .authMethod) ?? .key
        keyPath = try container.decodeIfPresent(String.self, forKey: .keyPath) ?? "~/.ssh/id_rsa"
        groupId = try container.decodeIfPresent(UUID.self, forKey: .groupId)
        putty = try container.decodeIfPresent(PuttySettings.self, forKey: .putty) ?? PuttySettings()
        fileTransfer = try container.decodeIfPresent(FileTransferSettings.self, forKey: .fileTransfer) ?? FileTransferSettings()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(connectionProtocol, forKey: .connectionProtocol)
        try container.encode(terminalLaunchMode, forKey: .terminalLaunchMode)
        try container.encode(username, forKey: .username)
        try container.encode(authMethod, forKey: .authMethod)
        try container.encode(keyPath, forKey: .keyPath)
        try container.encodeIfPresent(groupId, forKey: .groupId)
        try container.encode(putty, forKey: .putty)
        try container.encode(fileTransfer, forKey: .fileTransfer)
    }

    var displayName: String {
        let n = name.trimmed
        if !n.isEmpty { return n }
        let h = host.trimmed
        if !h.isEmpty { return h }
        return "Unnamed Host"
    }

    var subtitle: String {
        let u = username.trimmed
        let h = host.trimmed
        if u.isEmpty && h.isEmpty { return "" }
        if h.isEmpty { return u }
        if u.isEmpty { return "\(h):\(port)" }
        return "\(u)@\(h):\(port)"
    }
}

struct PersistedData: Codable {
    var groups: [HostGroup]
    var hosts: [HostEntry]
}

struct SidebarNode: Identifiable, Hashable {
    let id: String
    let selection: SidebarSelection
    let title: String
    let subtitle: String?
    let isGroup: Bool
    var children: [SidebarNode]?
}

struct GroupOption: Identifiable, Hashable {
    let id: String
    let groupId: UUID?
    let label: String
}

private struct RenameGroupTarget: Identifiable {
    let groupID: UUID
    var id: UUID { groupID }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
final class HostStore: ObservableObject {
    @Published var groups: [HostGroup] = []
    @Published var hosts: [HostEntry] = []

    private let dataURL: URL
    private let legacyHostsURL: URL

    init() {
        let fm = FileManager.default
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = support.appendingPathComponent("MacSSHManager", isDirectory: true)
        try? fm.createDirectory(at: appDir, withIntermediateDirectories: true)
        dataURL = appDir.appendingPathComponent("data.json")
        legacyHostsURL = appDir.appendingPathComponent("hosts.json")
        load()
    }

    func load() {
        if let data = try? Data(contentsOf: dataURL),
           let decoded = try? JSONDecoder().decode(PersistedData.self, from: data) {
            groups = decoded.groups
            hosts = decoded.hosts
            return
        }

        if let legacyData = try? Data(contentsOf: legacyHostsURL),
           let decodedHosts = try? JSONDecoder().decode([HostEntry].self, from: legacyData) {
            groups = []
            hosts = decodedHosts
            save()
        }
    }

    func save() {
        let payload = PersistedData(groups: groups, hosts: hosts)
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: dataURL, options: .atomic)
        }
    }

    func currentData() -> PersistedData {
        PersistedData(groups: groups, hosts: hosts)
    }

    func replaceAll(groups newGroups: [HostGroup], hosts newHosts: [HostEntry]) {
        let normalized = Self.normalize(groups: newGroups, hosts: newHosts)
        let removedHostIDs = Set(hosts.map(\.id)).subtracting(Set(normalized.hosts.map(\.id)))
        for id in removedHostIDs {
            KeychainHelper.deletePassword(for: id)
        }

        groups = normalized.groups
        hosts = normalized.hosts
        save()
    }

    private static func normalize(groups: [HostGroup], hosts: [HostEntry]) -> PersistedData {
        var normalizedGroups: [HostGroup] = []
        var usedGroupIDs: Set<UUID> = []

        for group in groups {
            var normalized = group
            if usedGroupIDs.contains(normalized.id) {
                normalized.id = UUID()
            }
            usedGroupIDs.insert(normalized.id)
            normalizedGroups.append(normalized)
        }

        var parentByID = Dictionary(uniqueKeysWithValues: normalizedGroups.map { ($0.id, $0.parentId) })
        let validGroupIDs = Set(parentByID.keys)

        for idx in normalizedGroups.indices {
            let groupID = normalizedGroups[idx].id
            if let parentID = normalizedGroups[idx].parentId,
               (parentID == groupID || !validGroupIDs.contains(parentID)) {
                normalizedGroups[idx].parentId = nil
                parentByID[groupID] = nil
            }
        }

        for idx in normalizedGroups.indices {
            let groupID = normalizedGroups[idx].id
            if hasGroupCycle(start: groupID, parentByID: parentByID) {
                normalizedGroups[idx].parentId = nil
                parentByID[groupID] = nil
            }
        }

        let allowedGroupIDs = Set(normalizedGroups.map(\.id))
        var normalizedHosts: [HostEntry] = []
        var usedHostIDs: Set<UUID> = []

        for host in hosts {
            var normalized = host
            if usedHostIDs.contains(normalized.id) {
                normalized.id = UUID()
            }
            usedHostIDs.insert(normalized.id)

            if let groupID = normalized.groupId, !allowedGroupIDs.contains(groupID) {
                normalized.groupId = nil
            }

            normalizedHosts.append(normalized)
        }

        return PersistedData(groups: normalizedGroups, hosts: normalizedHosts)
    }

    private static func hasGroupCycle(start: UUID, parentByID: [UUID: UUID?]) -> Bool {
        var seen: Set<UUID> = [start]
        var current = parentByID[start] ?? nil

        while let id = current {
            if !seen.insert(id).inserted {
                return true
            }
            current = parentByID[id] ?? nil
        }

        return false
    }

    func sortedGroups(parentId: UUID?) -> [HostGroup] {
        groups
            .filter { $0.parentId == parentId }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func sortedHosts(groupId: UUID?) -> [HostEntry] {
        hosts
            .filter { $0.groupId == groupId }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func group(by id: UUID?) -> HostGroup? {
        guard let id else { return nil }
        return groups.first(where: { $0.id == id })
    }

    func host(by id: UUID?) -> HostEntry? {
        guard let id else { return nil }
        return hosts.first(where: { $0.id == id })
    }

    func addGroup(name: String = "New Group", parentId: UUID? = nil) -> HostGroup {
        let group = HostGroup(name: name, parentId: parentId)
        groups.append(group)
        save()
        return group
    }

    func updateGroup(id: UUID, name: String) {
        guard let idx = groups.firstIndex(where: { $0.id == id }) else { return }
        groups[idx].name = name
        save()
    }

    func removeGroup(id: UUID) {
        var toRemove = Set<UUID>()
        collectDescendants(from: id, into: &toRemove)

        groups.removeAll { toRemove.contains($0.id) }

        for idx in hosts.indices {
            if let gid = hosts[idx].groupId, toRemove.contains(gid) {
                hosts[idx].groupId = nil
            }
        }

        save()
    }

    private func collectDescendants(from id: UUID, into set: inout Set<UUID>) {
        guard set.insert(id).inserted else { return }
        for child in groups where child.parentId == id {
            collectDescendants(from: child.id, into: &set)
        }
    }

    func addHost(in groupId: UUID?) -> HostEntry {
        let host = HostEntry(groupId: groupId)
        hosts.append(host)
        save()
        return host
    }

    func updateHost(_ host: HostEntry) {
        guard let idx = hosts.firstIndex(where: { $0.id == host.id }) else { return }
        hosts[idx] = host
        save()
    }

    func moveHost(id: UUID, to groupId: UUID?) {
        guard let idx = hosts.firstIndex(where: { $0.id == id }) else { return }
        if let groupId, group(by: groupId) == nil {
            return
        }
        if hosts[idx].groupId == groupId {
            return
        }
        hosts[idx].groupId = groupId
        save()
    }

    func removeHost(_ id: UUID) {
        hosts.removeAll { $0.id == id }
        KeychainHelper.deletePassword(for: id)
        save()
    }
}

enum KeychainHelper {
    private static let service = "MacSSHManager"

    @discardableResult
    static func savePassword(_ password: String, for id: UUID) -> Bool {
        let account = id.uuidString
        let data = Data(password.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        SecItemDelete(query as CFDictionary)

        var item = query
        item[kSecValueData as String] = data
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }

    static func loadPassword(for id: UUID) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var out: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &out)
        guard status == errSecSuccess, let data = out as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    static func deletePassword(for id: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum ToolResolver {
    private static let telnetCandidates = [
        "/usr/bin/telnet",
        "/opt/homebrew/bin/telnet",
        "/usr/local/bin/telnet"
    ]

    static func telnetExecutable() -> String? {
        for path in telnetCandidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
        return nil
    }
}

@MainActor
final class TerminalRuntime: NSObject, ObservableObject, @preconcurrency LocalProcessTerminalViewDelegate {
    let terminalView: LocalProcessTerminalView
    private let host: HostEntry

    @Published var isRunning: Bool = false
    @Published var statusLine: String = "Starting..."

    init(host: HostEntry) {
        self.host = host
        terminalView = LocalProcessTerminalView(frame: .zero)
        super.init()

        terminalView.processDelegate = self
        configureTerminalFromSettings()

        start()
    }

    private func configureTerminalFromSettings() {
        let settings = host.putty
        let size = max(9, min(30, settings.fontSize))
        terminalView.font = NSFont.monospacedSystemFont(ofSize: CGFloat(size), weight: .regular)
        terminalView.optionAsMetaKey = settings.optionIsMeta
        terminalView.allowMouseReporting = settings.allowMouseReporting
        terminalView.terminal.resize(cols: max(40, settings.terminalColumns), rows: max(10, settings.terminalRows))
        terminalView.terminal.changeHistorySize(settings.scrollbackLines <= 0 ? nil : max(0, settings.scrollbackLines))
        applyConsoleTheme(settings.consoleTheme)
    }

    private func applyConsoleTheme(_ theme: ConsoleTheme) {
        if let palette = theme.palette {
            terminalView.nativeBackgroundColor = palette.background
            terminalView.nativeForegroundColor = palette.foreground
            terminalView.caretColor = palette.caret
        } else {
            terminalView.configureNativeColors()
            terminalView.caretColor = terminalView.nativeForegroundColor
        }
    }

    private func expanded(_ path: String) -> String {
        if path.hasPrefix("~/") {
            return NSHomeDirectory() + "/" + path.dropFirst(1)
        }
        return path
    }

    private func sshBool(_ value: Bool) -> String {
        value ? "yes" : "no"
    }

    private func nonEmptyLines(_ text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmed }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }

    private func addOption(_ args: inout [String], _ key: String, _ value: String) {
        args.append("-o")
        args.append("\(key)=\(value)")
    }

    private func authList(for settings: PuttySettings) -> [String] {
        let usePublicKey = host.authMethod == .key ? true : settings.enablePublicKeyAuth
        let usePassword = host.authMethod == .password ? true : settings.enablePasswordAuth
        var methods: [String] = []
        if usePublicKey { methods.append("publickey") }
        if settings.enableKeyboardInteractiveAuth { methods.append("keyboard-interactive") }
        if usePassword { methods.append("password") }
        if settings.enableGSSAPIAuth { methods.append("gssapi-with-mic") }
        return methods
    }

    private func proxyCommand(for settings: PuttySettings) -> String? {
        if settings.proxyType == .command {
            let user = settings.proxyUsername.trimmed
            let pass = settings.proxyPassword
            let command = settings.proxyCommand
                .trimmed
                .replacingOccurrences(of: "%proxy_user%", with: user)
                .replacingOccurrences(of: "%proxy_password%", with: pass)
            return command.isEmpty ? nil : command
        }

        let proxyHost = settings.proxyHost.trimmed
        let proxyPort = settings.proxyPort
        guard settings.proxyType != .none, !proxyHost.isEmpty, proxyPort > 0 else { return nil }

        let endpoint = "\(proxyHost):\(proxyPort)"
        let user = settings.proxyUsername.trimmed
        let userArg = user.isEmpty ? "" : " -P \(user)"

        switch settings.proxyType {
        case .socks4:
            return "nc -x \(endpoint) -X 4\(userArg) %h %p"
        case .socks5:
            return "nc -x \(endpoint) -X 5\(userArg) %h %p"
        case .http:
            return "nc -x \(endpoint) -X connect %h %p"
        case .none, .command:
            return nil
        }
    }

    private func buildEnvironment() -> [String] {
        let settings = host.putty
        let termName = settings.terminalType.trimmed.isEmpty ? "xterm-256color" : settings.terminalType.trimmed
        var env = Terminal.getEnvironmentVariables(termName: termName)

        let charset = settings.localeCharset.trimmed
        if !charset.isEmpty {
            env.append("LC_CTYPE=en_US.\(charset)")
        }

        let display = settings.x11Display.trimmed
        if !display.isEmpty {
            env.append("DISPLAY=\(display)")
        }

        for item in nonEmptyLines(settings.setEnvironment) where item.contains("=") {
            env.append(item)
        }

        return env
    }

    private func buildSSHArgs(hostName: String, user: String) -> [String]? {
        let settings = host.putty
        let usePublicKey = host.authMethod == .key ? true : settings.enablePublicKeyAuth
        let usePassword = host.authMethod == .password ? true : settings.enablePasswordAuth
        var args: [String] = []

        args.append(contentsOf: settings.requestTTY.sshArgs)
        args.append(contentsOf: ["-p", String(host.port)])

        if settings.compression {
            args.append("-C")
        }

        addOption(&args, "StrictHostKeyChecking", settings.strictHostKeyChecking.sshValue)
        addOption(&args, "TCPKeepAlive", sshBool(settings.tcpKeepAlive))
        addOption(&args, "Compression", sshBool(settings.compression))
        addOption(&args, "ForwardAgent", sshBool(settings.forwardAgent))
        addOption(&args, "PubkeyAuthentication", sshBool(usePublicKey))
        addOption(&args, "PasswordAuthentication", sshBool(usePassword))
        addOption(&args, "KbdInteractiveAuthentication", sshBool(settings.enableKeyboardInteractiveAuth))
        addOption(&args, "GSSAPIAuthentication", sshBool(settings.enableGSSAPIAuth))
        addOption(&args, "GSSAPIDelegateCredentials", sshBool(settings.gssapiDelegateCredentials))

        let timeout = max(0, settings.connectTimeoutSeconds)
        if timeout > 0 {
            addOption(&args, "ConnectTimeout", String(timeout))
        }

        let keepalive = max(0, settings.keepAliveIntervalSeconds)
        if keepalive > 0 {
            addOption(&args, "ServerAliveInterval", String(keepalive))
            addOption(&args, "ServerAliveCountMax", String(max(1, settings.keepAliveCountMax)))
        }

        if let family = settings.addressFamily.sshValue {
            addOption(&args, "AddressFamily", family)
        }

        let knownHosts = expanded(settings.userKnownHostsFile.trimmed)
        if !knownHosts.isEmpty {
            addOption(&args, "UserKnownHostsFile", knownHosts)
        }

        let bindAddress = settings.bindAddress.trimmed
        if !bindAddress.isEmpty {
            args.append(contentsOf: ["-b", bindAddress])
        }

        if settings.x11Forwarding {
            args.append("-X")
        }

        let auth = authList(for: settings)
        if !auth.isEmpty {
            addOption(&args, "PreferredAuthentications", auth.joined(separator: ","))
        }

        let kex = settings.kexAlgorithms.trimmed
        if !kex.isEmpty {
            addOption(&args, "KexAlgorithms", kex)
        }
        let ciphers = settings.ciphers.trimmed
        if !ciphers.isEmpty {
            addOption(&args, "Ciphers", ciphers)
        }
        let macs = settings.macs.trimmed
        if !macs.isEmpty {
            addOption(&args, "MACs", macs)
        }
        let hostKeys = settings.hostKeyAlgorithms.trimmed
        if !hostKeys.isEmpty {
            addOption(&args, "HostKeyAlgorithms", hostKeys)
        }
        let rekeyLimit = settings.rekeyLimit.trimmed
        if !rekeyLimit.isEmpty {
            addOption(&args, "RekeyLimit", rekeyLimit)
        }

        for pattern in nonEmptyLines(settings.sendEnvPatterns) {
            addOption(&args, "SendEnv", pattern)
        }

        for assignment in nonEmptyLines(settings.setEnvironment) where assignment.contains("=") {
            addOption(&args, "SetEnv", assignment)
        }

        for forward in nonEmptyLines(settings.localPortForwards) {
            args.append(contentsOf: ["-L", forward])
        }
        for forward in nonEmptyLines(settings.remotePortForwards) {
            args.append(contentsOf: ["-R", forward])
        }
        for forward in nonEmptyLines(settings.dynamicPortForwards) {
            args.append(contentsOf: ["-D", forward])
        }

        if let proxy = proxyCommand(for: settings) {
            addOption(&args, "ProxyCommand", proxy)
        }

        if settings.loggingEnabled {
            args.append(contentsOf: settings.logVerbosity.sshFlags)
            let logPath = expanded(settings.logFilePath.trimmed)
            if !logPath.isEmpty {
                args.append(contentsOf: ["-E", logPath])
            }
        } else if settings.logVerbosity != .none {
            args.append(contentsOf: settings.logVerbosity.sshFlags)
        }

        if host.authMethod == .key {
            let keyPath = expanded(host.keyPath.trimmed)
            guard !keyPath.isEmpty else {
                fail("Private key path is empty")
                return nil
            }

            addOption(&args, "IdentitiesOnly", "yes")
            args.append(contentsOf: ["-i", keyPath])
        }

        if settings.noShell && settings.remoteCommand.trimmed.isEmpty {
            args.append("-N")
        }

        args.append("\(user)@\(hostName)")

        let remoteCommand = settings.remoteCommand.trimmed
        if !remoteCommand.isEmpty {
            args.append(remoteCommand)
        }

        return args
    }

    private func buildTelnetArgs(hostName: String) -> [String] {
        var args: [String] = []
        let user = host.username.trimmed
        if !user.isEmpty {
            args.append(contentsOf: ["-l", user])
        }
        args.append(hostName)
        args.append(String(max(1, host.port)))
        return args
    }

    private func fail(_ message: String) {
        statusLine = "Error: \(message)"
        isRunning = false
        terminalView.feed(text: "\r\n[error] \(message)\r\n")
    }

    private func start() {
        let hostName = host.host.trimmed

        guard !hostName.isEmpty else {
            fail("Host is empty")
            return
        }

        switch host.connectionProtocol {
        case .ssh:
            let user = host.username.trimmed
            guard !user.isEmpty else {
                fail("Username is empty")
                return
            }

            guard let sshArgs = buildSSHArgs(hostName: hostName, user: user) else {
                return
            }

            statusLine = "Connecting SSH \(user)@\(hostName):\(host.port)"
            isRunning = true
            let baseEnvironment = buildEnvironment()

            if host.authMethod == .password {
                let password = KeychainHelper.loadPassword(for: host.id)
                guard !password.isEmpty else {
                    fail("Password is empty in Keychain")
                    return
                }

                let expectScript = """
                set timeout -1
                set pass $env(SSH_PASSWORD)
                set program [lindex $argv 0]
                set argv [lrange $argv 1 end]
                spawn -noecho -- $program {*}$argv
                expect {
                  -re "(?i)(password|passphrase).*:" { send -- "$pass\\r"; exp_continue }
                  eof
                }
                interact
                """

                var env = baseEnvironment
                env.append("SSH_PASSWORD=\(password)")

                terminalView.startProcess(
                    executable: "/usr/bin/expect",
                    args: ["-c", expectScript, "/usr/bin/ssh"] + sshArgs,
                    environment: env
                )
            } else {
                terminalView.startProcess(
                    executable: "/usr/bin/ssh",
                    args: sshArgs,
                    environment: baseEnvironment
                )
            }

        case .telnet:
            statusLine = "Connecting Telnet \(hostName):\(host.port)"
            isRunning = true
            let env = buildEnvironment()
            let telnetArgs = buildTelnetArgs(hostName: hostName)
            guard let telnetExecutable = ToolResolver.telnetExecutable() else {
                fail("Telnet client not found (install telnet via Homebrew or switch to SSH)")
                return
            }
            terminalView.startProcess(
                executable: telnetExecutable,
                args: telnetArgs,
                environment: env
            )
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.terminalView.window?.makeFirstResponder(self.terminalView)
        }
    }

    func stop() {
        terminalView.terminate()
    }

    func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}

    func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        if host.putty.disableRemoteTitle {
            return
        }
        let t = title.trimmed
        if !t.isEmpty {
            statusLine = t
        }
    }

    func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}

    func processTerminated(source: TerminalView, exitCode: Int32?) {
        isRunning = false
        if let exitCode {
            statusLine = "Session ended: \(exitCode)"
        } else {
            statusLine = "Session ended"
        }
    }
}

enum SessionOpenResult {
    case embedded
    case external
    case failed(String)
}

enum SystemTerminalLauncher {
    private enum CommandBuildError: LocalizedError {
        case message(String)

        var errorDescription: String? {
            switch self {
            case .message(let text):
                return text
            }
        }
    }

    private static func expanded(_ path: String) -> String {
        if path.hasPrefix("~/") {
            return NSHomeDirectory() + "/" + path.dropFirst(2)
        }
        return path
    }

    private static func shellQuote(_ value: String) -> String {
        if value.isEmpty { return "''" }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func appleScriptQuote(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static func runProcess(_ executable: String, _ args: [String]) -> (code: Int32, out: String, err: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            return (-1, "", error.localizedDescription)
        }
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        return (
            process.terminationStatus,
            String(decoding: outData, as: UTF8.self),
            String(decoding: errData, as: UTF8.self)
        )
    }

    private static func buildSSHCommand(host: HostEntry) -> Result<String, CommandBuildError> {
        let hostName = host.host.trimmed
        let user = host.username.trimmed
        guard !hostName.isEmpty, !user.isEmpty else {
            return .failure(.message("Host and username are required"))
        }

        if host.authMethod == .password {
            return .failure(.message("System Terminal mode supports only key auth. Switch to key auth or Embedded TTY."))
        }

        var sshArgs: [String] = [
            "-p", String(max(1, host.port)),
            "-o", "StrictHostKeyChecking=\(host.putty.strictHostKeyChecking.sshValue)"
        ]

        let keyPath = expanded(host.keyPath.trimmed)
        guard !keyPath.isEmpty else {
            return .failure(.message("Private key path is required for System Terminal mode"))
        }
        sshArgs.append(contentsOf: ["-o", "IdentitiesOnly=yes", "-i", keyPath])

        sshArgs.append("\(user)@\(hostName)")

        let remoteCommand = host.putty.remoteCommand.trimmed
        if !remoteCommand.isEmpty {
            sshArgs.append(remoteCommand)
        }

        return .success((["/usr/bin/ssh"] + sshArgs).map(shellQuote).joined(separator: " "))
    }

    private static func buildTelnetCommand(host: HostEntry) -> Result<String, CommandBuildError> {
        let hostName = host.host.trimmed
        guard !hostName.isEmpty else {
            return .failure(.message("Host is required"))
        }
        guard let telnetExecutable = ToolResolver.telnetExecutable() else {
            return .failure(.message("Telnet client not found (install telnet via Homebrew or use Embedded TTY)"))
        }

        var parts: [String] = [telnetExecutable]
        let user = host.username.trimmed
        if !user.isEmpty {
            parts.append(contentsOf: ["-l", user])
        }
        parts.append(hostName)
        parts.append(String(max(1, host.port)))
        return .success(parts.map(shellQuote).joined(separator: " "))
    }

    private static func buildConnectCommand(host: HostEntry) -> Result<String, CommandBuildError> {
        switch host.connectionProtocol {
        case .ssh:
            return buildSSHCommand(host: host)
        case .telnet:
            return buildTelnetCommand(host: host)
        }
    }

    static func open(host: HostEntry) -> SessionOpenResult {
        let connectCommand: String
        switch buildConnectCommand(host: host) {
        case .success(let command):
            connectCommand = command
        case .failure(let error):
            return .failed(error.localizedDescription)
        }

        let scriptURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("macssh-\(UUID().uuidString).command")
        let script = """
        #!/bin/zsh
        \(connectCommand)
        """

        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)
        } catch {
            return .failed("Failed to create temporary launch script")
        }

        let runLine = "/bin/zsh \(shellQuote(scriptURL.path)); rm -f \(shellQuote(scriptURL.path))"
        let appleScript = """
        tell application "Terminal"
          activate
          do script \(appleScriptQuote(runLine))
        end tell
        """

        let result = runProcess("/usr/bin/osascript", ["-e", appleScript])
        if result.code != 0 {
            try? FileManager.default.removeItem(at: scriptURL)
            let errorText = result.err.trimmed.isEmpty ? result.out.trimmed : result.err.trimmed
            return .failed(errorText.isEmpty ? "Failed to launch Terminal.app" : errorText)
        }

        return .external
    }
}

@MainActor
final class SessionTab: ObservableObject, Identifiable {
    let id: UUID = UUID()
    let title: String
    let host: HostEntry
    let runtime: TerminalRuntime

    init(host: HostEntry) {
        self.host = host
        title = host.displayName
        runtime = TerminalRuntime(host: host)
    }

    func stop() {
        runtime.stop()
    }
}

@MainActor
final class SessionManager: ObservableObject {
    @Published var tabs: [SessionTab] = []
    @Published var selectedID: UUID?

    @Published var displayMode: SessionDisplayMode = .tty
    @Published var gridColumns: Int = 2
    @Published var gridMinTileWidth: Double = 320
    @Published var gridTileHeight: Double = 280

    var activeTab: SessionTab? {
        if let id = selectedID, let tab = tabs.first(where: { $0.id == id }) {
            return tab
        }
        return tabs.first
    }

    func open(for host: HostEntry) -> SessionOpenResult {
        if host.connectionProtocol == .ssh, host.terminalLaunchMode == .systemTerminal {
            return SystemTerminalLauncher.open(host: host)
        }

        let tab = SessionTab(host: host)
        tabs.append(tab)
        selectedID = tab.id
        return .embedded
    }

    func close(_ id: UUID) {
        guard let idx = tabs.firstIndex(where: { $0.id == id }) else { return }
        tabs[idx].stop()
        tabs.remove(at: idx)
        selectedID = tabs.last?.id
    }

    func closeOthers(keeping id: UUID) {
        for tab in tabs where tab.id != id {
            tab.stop()
        }
        tabs.removeAll { $0.id != id }
        selectedID = tabs.first?.id
    }

    func closeAll() {
        for tab in tabs {
            tab.stop()
        }
        tabs.removeAll()
        selectedID = nil
    }
}

struct TerminalContainerView: NSViewRepresentable {
    let terminalView: LocalProcessTerminalView

    func makeNSView(context: Context) -> NSView {
        terminalView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        terminalView.needsDisplay = true
    }
}

struct HorizontalScrollLock: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = nsView.enclosingScrollView else { return }
            scrollView.hasHorizontalScroller = false
            scrollView.horizontalScrollElasticity = .none

            var origin = scrollView.contentView.bounds.origin
            guard origin.x != 0 else { return }
            origin.x = 0
            scrollView.contentView.setBoundsOrigin(origin)
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
}

struct HostEditorPane: View {
    @Binding var host: HostEntry
    @Binding var password: String
    @State private var selectedSettingsSection: HostSettingsSection = .terminal

    let mode: HostEditorMode
    let scopeDescription: String?
    let groupOptions: [GroupOption]
    let message: String?
    let onBrowseKey: () -> Void
    let onSave: () -> Void
    let onConnect: () -> Void
    let canConnect: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(mode.title)
                .font(.title3.weight(.semibold))

            if let scopeDescription, !scopeDescription.isEmpty {
                Text(scopeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            basicEditorGrid
            puttySettingsTabs

            if let message, !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button(mode.saveTitle, action: onSave)
                    .keyboardShortcut("s", modifiers: [.command])
                if mode.allowsConnect {
                    Button("Connect", action: onConnect)
                        .disabled(!canConnect)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
        .onAppear {
            if host.connectionProtocol == .ssh, host.authMethod == .password, host.terminalLaunchMode == .systemTerminal {
                host.terminalLaunchMode = .embedded
            }
        }
        .onChange(of: host.connectionProtocol) { mode in
            switch mode {
            case .ssh:
                if host.port == 23 {
                    host.port = 22
                }
            case .telnet:
                host.terminalLaunchMode = .embedded
                if host.port == 22 {
                    host.port = 23
                }
            }
        }
        .onChange(of: host.authMethod) { method in
            if method == .password, host.terminalLaunchMode == .systemTerminal {
                host.terminalLaunchMode = .embedded
            }
        }
    }

    private var basicEditorGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 10) {
            if mode == .host {
                GridRow {
                    label("Name")
                    TextField("Production", text: $host.name)
                        .textFieldStyle(.roundedBorder)
                }
                GridRow {
                    label("Host")
                    TextField("example.com", text: $host.host)
                        .textFieldStyle(.roundedBorder)
                }
            }
            GridRow {
                label("Username")
                TextField("root", text: $host.username)
                    .textFieldStyle(.roundedBorder)
            }
            GridRow {
                label("Port")
                HStack(spacing: 8) {
                    TextField("22", value: $host.port, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 110)
                    Stepper("", value: $host.port, in: 1...65535)
                        .labelsHidden()
                }
            }
            GridRow {
                label("Protocol")
                Picker("", selection: $host.connectionProtocol) {
                    ForEach(ConnectionProtocol.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
            GridRow {
                label("Terminal")
                if host.connectionProtocol == .ssh {
                    Picker("", selection: $host.terminalLaunchMode) {
                        ForEach(terminalLaunchModeOptions) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 240)
                } else {
                    Text("Embedded TTY")
                        .foregroundStyle(.secondary)
                }
            }
            if mode == .host {
                GridRow {
                    label("Group")
                    Picker("", selection: $host.groupId) {
                        ForEach(groupOptions) { option in
                            Text(option.label).tag(option.groupId as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 280)
                }
            }
            if host.connectionProtocol == .ssh {
                GridRow {
                    label("Auth")
                    Picker("", selection: $host.authMethod) {
                        ForEach(AuthMethod.allCases) { method in
                            Text(method.title).tag(method)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }

                if host.authMethod == .key {
                    GridRow {
                        label("Key")
                        HStack(spacing: 8) {
                            TextField("~/.ssh/id_rsa", text: $host.keyPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse", action: onBrowseKey)
                        }
                    }
                } else {
                    GridRow {
                        label("Password")
                        SecureField("Stored in Keychain", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            } else {
                GridRow {
                    label("Telnet")
                    Text("Credentials are entered in terminal login prompt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var terminalLaunchModeOptions: [TerminalLaunchMode] {
        if host.connectionProtocol == .ssh, host.authMethod == .password {
            return [.embedded]
        }
        return TerminalLaunchMode.allCases
    }

    private var puttySettingsTabs: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PuTTY Compatibility Settings")
                .font(.headline)

            TabView(selection: $selectedSettingsSection) {
                terminalTab
                    .tag(HostSettingsSection.terminal)
                    .tabItem { Text("Terminal") }

                connectionTab
                    .tag(HostSettingsSection.connection)
                    .tabItem { Text("Connection") }

                authTab
                    .tag(HostSettingsSection.auth)
                    .tabItem { Text("Auth") }

                sshTab
                    .tag(HostSettingsSection.ssh)
                    .tabItem { Text("SSH") }

                tunnelsTab
                    .tag(HostSettingsSection.tunnels)
                    .tabItem { Text("Tunnels") }

                proxyTab
                    .tag(HostSettingsSection.proxy)
                    .tabItem { Text("Proxy") }

                environmentTab
                    .tag(HostSettingsSection.environment)
                    .tabItem { Text("Environment") }

                loggingTab
                    .tag(HostSettingsSection.logging)
                    .tabItem { Text("Logging") }
            }
            .frame(minHeight: 360)
        }
    }

    private var terminalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                row("TERM") {
                    TextField("xterm-256color", text: $host.putty.terminalType)
                        .textFieldStyle(.roundedBorder)
                }
                row("Charset") {
                    TextField("UTF-8", text: $host.putty.localeCharset)
                        .textFieldStyle(.roundedBorder)
                }
                row("Columns / Rows") {
                    HStack(spacing: 8) {
                        TextField("120", value: $host.putty.terminalColumns, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                        TextField("34", value: $host.putty.terminalRows, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                    }
                }
                row("Scrollback") {
                    TextField("10000", value: $host.putty.scrollbackLines, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                row("Font size") {
                    TextField("13", value: $host.putty.fontSize, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                row("Bell mode") {
                    Picker("", selection: $host.putty.bellMode) {
                        ForEach(TerminalBellMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }
                row("Console theme") {
                    Picker("", selection: $host.putty.consoleTheme) {
                        ForEach(ConsoleTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }
                row("Alt as Meta") {
                    Toggle("", isOn: $host.putty.optionIsMeta)
                        .labelsHidden()
                }
                row("Mouse reporting") {
                    Toggle("", isOn: $host.putty.allowMouseReporting)
                        .labelsHidden()
                }
                row("Remote title") {
                    Toggle("Allow updates", isOn: Binding(
                        get: { !host.putty.disableRemoteTitle },
                        set: { host.putty.disableRemoteTitle = !$0 }
                    ))
                }
                row("Backspace key") {
                    Toggle("Send Ctrl+H", isOn: $host.putty.backspaceSendsControlH)
                }
                row("Delete key") {
                    Toggle("Send DEL", isOn: $host.putty.deleteSendsDEL)
                }
            }
            .padding(.top, 6)
        }
    }

    private var connectionTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                row("TTY mode") {
                    Picker("", selection: $host.putty.requestTTY) {
                        ForEach(RequestTTYMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                row("Host key policy") {
                    Picker("", selection: $host.putty.strictHostKeyChecking) {
                        ForEach(StrictHostKeyMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                row("Known hosts file") {
                    TextField("~/.ssh/known_hosts", text: $host.putty.userKnownHostsFile)
                        .textFieldStyle(.roundedBorder)
                }
                row("Connect timeout") {
                    TextField("15", value: $host.putty.connectTimeoutSeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                row("Keepalive sec") {
                    TextField("0", value: $host.putty.keepAliveIntervalSeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                row("Keepalive count") {
                    TextField("3", value: $host.putty.keepAliveCountMax, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                row("TCP keepalive") {
                    Toggle("", isOn: $host.putty.tcpKeepAlive)
                        .labelsHidden()
                }
                row("IP version") {
                    Picker("", selection: $host.putty.addressFamily) {
                        ForEach(IPVersionPreference.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                row("Bind address") {
                    TextField("Optional", text: $host.putty.bindAddress)
                        .textFieldStyle(.roundedBorder)
                }
                row("File protocol") {
                    Picker("", selection: $host.fileTransfer.protocolMode) {
                        ForEach(FileTransferProtocolMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                row("Remote root") {
                    TextField(".", text: $host.fileTransfer.remoteRootPath)
                        .textFieldStyle(.roundedBorder)
                }
                row("Refresh sec") {
                    TextField("3", value: $host.fileTransfer.autoRefreshSeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 140)
                }
                row("Live preview") {
                    Toggle("", isOn: $host.fileTransfer.livePreview)
                        .labelsHidden()
                }
            }
            .padding(.top, 6)
        }
    }

    private var authTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                row("Public key auth") {
                    Toggle("", isOn: $host.putty.enablePublicKeyAuth)
                        .labelsHidden()
                }
                row("Password auth") {
                    Toggle("", isOn: $host.putty.enablePasswordAuth)
                        .labelsHidden()
                }
                row("Keyboard-interactive") {
                    Toggle("", isOn: $host.putty.enableKeyboardInteractiveAuth)
                        .labelsHidden()
                }
                row("GSSAPI auth") {
                    Toggle("", isOn: $host.putty.enableGSSAPIAuth)
                        .labelsHidden()
                }
                row("Forward agent") {
                    Toggle("", isOn: $host.putty.forwardAgent)
                        .labelsHidden()
                }
                row("GSSAPI delegate creds") {
                    Toggle("", isOn: $host.putty.gssapiDelegateCredentials)
                        .labelsHidden()
                }
                row("Compression") {
                    Toggle("", isOn: $host.putty.compression)
                        .labelsHidden()
                }
                row("X11 forwarding") {
                    Toggle("", isOn: $host.putty.x11Forwarding)
                        .labelsHidden()
                }
                if host.putty.x11Forwarding {
                    row("X11 display") {
                        TextField("localhost:0", text: $host.putty.x11Display)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    private var sshTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                row("KEX algorithms") {
                    TextField("curve25519-sha256,...", text: $host.putty.kexAlgorithms)
                        .textFieldStyle(.roundedBorder)
                }
                row("Ciphers") {
                    TextField("chacha20-poly1305@openssh.com,...", text: $host.putty.ciphers)
                        .textFieldStyle(.roundedBorder)
                }
                row("MACs") {
                    TextField("hmac-sha2-256-etm@openssh.com,...", text: $host.putty.macs)
                        .textFieldStyle(.roundedBorder)
                }
                row("Host key algos") {
                    TextField("ssh-ed25519,ecdsa-sha2-nistp256,...", text: $host.putty.hostKeyAlgorithms)
                        .textFieldStyle(.roundedBorder)
                }
                row("Rekey limit") {
                    TextField("1G 1h", text: $host.putty.rekeyLimit)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }
                row("Remote command") {
                    TextField("Optional", text: $host.putty.remoteCommand)
                        .textFieldStyle(.roundedBorder)
                }
                row("No shell") {
                    Toggle("Use -N when no command", isOn: $host.putty.noShell)
                }
            }
            .padding(.top, 6)
        }
    }

    private var tunnelsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                multiline(title: "Local (-L)", text: $host.putty.localPortForwards, hint: "One per line, e.g. 127.0.0.1:8080:10.0.0.12:80")
                multiline(title: "Remote (-R)", text: $host.putty.remotePortForwards, hint: "One per line, e.g. 9090:127.0.0.1:9090")
                multiline(title: "Dynamic (-D)", text: $host.putty.dynamicPortForwards, hint: "One per line, e.g. 1080 or 127.0.0.1:1080")
            }
            .padding(.top, 6)
        }
    }

    private var proxyTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                row("Proxy type") {
                    Picker("", selection: $host.putty.proxyType) {
                        ForEach(ProxyType.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }

                if host.putty.proxyType == .command {
                    row("Proxy command") {
                        TextField("nc -x proxy:1080 -X 5 %h %p", text: $host.putty.proxyCommand)
                            .textFieldStyle(.roundedBorder)
                    }
                } else if host.putty.proxyType != .none {
                    row("Proxy host") {
                        TextField("proxy.example.com", text: $host.putty.proxyHost)
                            .textFieldStyle(.roundedBorder)
                    }
                    row("Proxy port") {
                        TextField("1080", value: $host.putty.proxyPort, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    row("Proxy user") {
                        TextField("Optional", text: $host.putty.proxyUsername)
                            .textFieldStyle(.roundedBorder)
                    }
                    row("Proxy password") {
                        SecureField("Optional", text: $host.putty.proxyPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    private var environmentTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                multiline(title: "SendEnv", text: $host.putty.sendEnvPatterns, hint: "One pattern per line, e.g. LANG LC_*")
                multiline(title: "SetEnv", text: $host.putty.setEnvironment, hint: "One KEY=VALUE per line")
            }
            .padding(.top, 6)
        }
    }

    private var loggingTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                row("Enable logging") {
                    Toggle("", isOn: $host.putty.loggingEnabled)
                        .labelsHidden()
                }
                row("Verbosity") {
                    Picker("", selection: $host.putty.logVerbosity) {
                        ForEach(SSHLogVerbosity.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }
                row("Log file") {
                    TextField("~/Library/Logs/mac-ssh-manager-session.log", text: $host.putty.logFilePath)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding(.top, 6)
        }
    }

    private func label(_ title: String) -> some View {
        Text(title)
            .foregroundStyle(.secondary)
            .frame(width: 120, alignment: .leading)
    }

    private func row<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 170, alignment: .leading)
            content()
        }
    }

    private func multiline(title: String, text: Binding<String>, hint: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            TextEditor(text: text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
                )
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct SessionTerminalView: View {
    @ObservedObject var runtime: TerminalRuntime

    var body: some View {
        TerminalContainerView(terminalView: runtime.terminalView)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: runtime.terminalView.nativeBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

enum SessionDisplayMode: String, CaseIterable, Identifiable {
    case tty = "TTY"
    case grid = "Grid"

    var id: String { rawValue }
}

struct SessionTileView: View {
    let tab: SessionTab

    @ObservedObject var runtime: TerminalRuntime

    init(tab: SessionTab) {
        self.tab = tab
        self.runtime = tab.runtime
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(tab.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Text(runtime.isRunning ? "LIVE" : "STOPPED")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(runtime.isRunning ? .green : .secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))
            .overlay(
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 0.8),
                alignment: .bottom
            )

            TerminalContainerView(terminalView: runtime.terminalView)
                .frame(minHeight: 220, maxHeight: .infinity)
                .background(Color(nsColor: runtime.terminalView.nativeBackgroundColor))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct BrowserTabShape: Shape {
    var cornerRadius: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, rect.height / 2, rect.width / 2)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + r, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + r),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

struct SessionsPane: View {
    @ObservedObject var sessions: SessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabHeaderControls
            tabHeaderRow

            if sessions.tabs.isEmpty {
                Text("No active sessions")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                Group {
                    switch sessions.displayMode {
                    case .tty:
                        if let active = sessions.activeTab {
                            SessionTerminalView(runtime: active.runtime)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    case .grid:
                        ScrollView {
                            LazyVGrid(
                                columns: Array(
                                    repeating: GridItem(.flexible(minimum: CGFloat(sessions.gridMinTileWidth)), spacing: 8),
                                    count: max(1, min(6, sessions.gridColumns))
                                ),
                                spacing: 8
                            ) {
                                ForEach(sessions.tabs) { tab in
                                    SessionTileView(tab: tab)
                                        .frame(minHeight: CGFloat(sessions.gridTileHeight))
                                }
                            }
                            .padding(8)
                        }
                    }
                }
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
    }

    private var tabHeaderRow: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(sessions.tabs) { tab in
                        tabHeader(tab)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.top, 4)
            }
            Spacer()
        }
        .frame(height: 42)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 0.8),
            alignment: .bottom
        )
    }

    private var tabHeaderControls: some View {
        EmptyView()
    }

    private func tabHeader(_ tab: SessionTab) -> some View {
        let selected = sessions.selectedID == tab.id
        let activeFill = Color(nsColor: .controlBackgroundColor)
        let inactiveFill = Color(nsColor: .underPageBackgroundColor).opacity(0.45)

        return HStack(spacing: 8) {
            Button(tab.title) {
                sessions.selectedID = tab.id
                sessions.displayMode = .tty
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .semibold))
            .lineLimit(1)

            Button {
                sessions.close(tab.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minWidth: 128, alignment: .leading)
        .background(
            BrowserTabShape(cornerRadius: 7)
                .fill(
                    selected
                        ? activeFill
                        : inactiveFill
                )
        )
        .overlay(
            BrowserTabShape(cornerRadius: 7)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
        .overlay(alignment: .bottom) {
            if selected {
                Rectangle()
                    .fill(activeFill)
                    .frame(height: 1.6)
                    .offset(y: 0.5)
            }
        }
        .contextMenu {
            Button("Open") {
                sessions.selectedID = tab.id
                sessions.displayMode = .tty
            }
            Button("Open In Grid") {
                sessions.selectedID = tab.id
                sessions.displayMode = .grid
            }
            Button("Duplicate") {
                _ = sessions.open(for: tab.host)
            }
            Divider()
            Button("Close") {
                sessions.close(tab.id)
            }
            Button("Close Others") {
                sessions.closeOthers(keeping: tab.id)
            }
            Button("Close All", role: .destructive) {
                sessions.closeAll()
            }
        }
    }
}

struct ShortcutRowEditor: View {
    @ObservedObject var store: ShortcutStore
    let action: ShortcutAction

    var body: some View {
        let baseBinding = binding(for: action)
        let conflicts = store.conflicts(for: action)

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(action.title)
                    .frame(width: 180, alignment: .leading)

                Picker("", selection: Binding(
                    get: { baseBinding.wrappedValue.keyToken },
                    set: { token in
                        var value = baseBinding.wrappedValue
                        value.keyToken = token
                        baseBinding.wrappedValue = value
                    }
                )) {
                    ForEach(ShortcutKeyCatalog.keyOptions) { option in
                        Text(option.title).tag(option.token)
                    }
                }
                .frame(width: 130)

                Toggle("Cmd", isOn: boolBinding(baseBinding, \.command))
                    .toggleStyle(.checkbox)
                    .frame(width: 58)
                Toggle("Opt", isOn: boolBinding(baseBinding, \.option))
                    .toggleStyle(.checkbox)
                    .frame(width: 58)
                Toggle("Shift", isOn: boolBinding(baseBinding, \.shift))
                    .toggleStyle(.checkbox)
                    .frame(width: 70)
                Toggle("Ctrl", isOn: boolBinding(baseBinding, \.control))
                    .toggleStyle(.checkbox)
                    .frame(width: 62)

                Text(baseBinding.wrappedValue.displayValue)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 70, alignment: .leading)
            }

            if !conflicts.isEmpty {
                Text("Conflict with: \(conflicts.map(\.title).joined(separator: ", "))")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
    }

    private func binding(for action: ShortcutAction) -> Binding<ShortcutBinding> {
        Binding(
            get: { store.binding(for: action) },
            set: { store.update($0, for: action) }
        )
    }

    private func boolBinding(
        _ base: Binding<ShortcutBinding>,
        _ keyPath: WritableKeyPath<ShortcutBinding, Bool>
    ) -> Binding<Bool> {
        Binding(
            get: { base.wrappedValue[keyPath: keyPath] },
            set: { flag in
                var value = base.wrappedValue
                value[keyPath: keyPath] = flag
                base.wrappedValue = value
            }
        )
    }
}

struct ShortcutManagerSheet: View {
    @ObservedObject var store: ShortcutStore
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcuts")
                .font(.headline)
            Text("Change key and modifiers for actions from File/View/Navigate/Tools menus.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ShortcutAction.allCases) { action in
                        ShortcutRowEditor(store: store, action: action)
                    }
                }
                .padding(.vertical, 2)
            }

            HStack {
                Button("Reset Defaults") {
                    store.resetToDefaults()
                }
                Spacer()
                Button("Close") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(minWidth: 920, minHeight: 620)
    }
}

struct ContentView: View {
    @EnvironmentObject private var shortcutStore: ShortcutStore
    @StateObject private var store = HostStore()
    @StateObject private var sessions = SessionManager()
    @StateObject private var fileBrowser = RemoteFileService()

    @State private var selectedPage: AppPage = .sessions
    @State private var sidebarSelection: SidebarSelection?

    @State private var selectedHostID: UUID?
    @State private var selectedGroupID: UUID?
    @State private var filesHostID: UUID?

    @State private var hostDraft: HostEntry?
    @State private var passwordDraft: String = ""
    @State private var statusMessage: String = ""
    @State private var sessionStatusMessage: String = ""
    @State private var sessionStatusIsError: Bool = false
    @State private var groupTemplates: [UUID: HostEntry] = [:]
    @State private var groupTemplatePasswords: [UUID: String] = [:]
    @State private var hostEditorMode: HostEditorMode = .host
    @State private var editingGroupSettingsID: UUID?
    @State private var isSidebarHidden: Bool = false
    @State private var renameGroupTarget: RenameGroupTarget?
    @State private var renameGroupDraft: String = ""
    @State private var renameGroupError: String = ""
    @State private var isShortcutManagerPresented: Bool = false
    private let hostDragPrefix = "macssh-host:"

    private struct PartialPersistedData: Decodable {
        var groups: [HostGroup]?
        var hosts: [HostEntry]?
    }

    private enum ImportPayloadError: LocalizedError {
        case unsupportedFormat

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat:
                return "Unsupported file format. Expected JSON with groups/hosts or host list."
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            workspaceTopBar
            if isSidebarHidden {
                workspacePane
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    connectionsPane
                        .frame(minWidth: 250, idealWidth: 280, maxWidth: 360)
                    workspacePane
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .frame(minWidth: 1380, minHeight: 860)
        .onAppear {
            if store.hosts.isEmpty, store.groups.isEmpty {
                _ = store.addGroup(name: "Default", parentId: nil)
            }
            if sidebarSelection == nil {
                ensureFilesHostSelection()
                if let id = filesHostID {
                    sidebarSelection = .host(id)
                }
            }
            ensureFilesHostSelection()
            reloadDraftsFromSelection()
        }
        .onChange(of: sidebarSelection) { selection in
            handleSidebarSelection(selection)
        }
        .onChange(of: filesHostID) { _ in
            if selectedPage == .files {
                fileBrowser.activate(host: selectedFilesHost)
            }
        }
        .onChange(of: store.hosts.map(\.id)) { _ in
            ensureFilesHostSelection()
            if selectedPage == .files {
                fileBrowser.activate(host: selectedFilesHost)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .macSSHSystemMenuAction)) { notification in
            guard let action = notification.object as? SystemMenuAction else { return }
            handleSystemMenuAction(action)
        }
        .sheet(item: $renameGroupTarget) { target in
            renameGroupSheet(for: target.groupID)
        }
        .sheet(isPresented: $isShortcutManagerPresented) {
            ShortcutManagerSheet(store: shortcutStore, isPresented: $isShortcutManagerPresented)
        }
    }

    private var workspaceTopBar: some View {
        HStack(spacing: 8) {
            Button(action: { toggleSidebar() }) {
                Image(systemName: isSidebarHidden ? "sidebar.left" : "sidebar.left")
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .help(isSidebarHidden ? "Show Menu" : "Hide Menu")

            Text("Workspace")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Picker("", selection: $selectedPage) {
                Text("TTY").tag(AppPage.sessions)
                Text("Files").tag(AppPage.files)
                if selectedPage == .hosts {
                    Text("Settings").tag(AppPage.hosts)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 150)

            if selectedPage == .sessions {
                Divider().frame(height: 16)
                
                Picker("", selection: $sessions.displayMode) {
                    ForEach(SessionDisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 100)

                if sessions.displayMode == .grid {
                    Stepper("Cols: \(sessions.gridColumns)", value: $sessions.gridColumns, in: 1...6)
                        .frame(width: 90)
                    HStack(spacing: 4) {
                        Text("W")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $sessions.gridMinTileWidth, in: 220...620, step: 10)
                            .frame(width: 80)
                    }
                    HStack(spacing: 4) {
                        Text("H")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $sessions.gridTileHeight, in: 180...540, step: 10)
                            .frame(width: 80)
                    }
                }
                
                Button("Close All") {
                    sessions.closeAll()
                }
                .disabled(sessions.tabs.isEmpty)
                .controlSize(.small)
            }

            Spacer(minLength: 8)

            if let host = selectedHostForActions {
                Text(host.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color(nsColor: .separatorColor))
                .frame(height: 0.8),
            alignment: .bottom
        )
    }

    private func renameGroupSheet(for groupID: UUID) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rename Group")
                .font(.headline)

            TextField("Group name", text: $renameGroupDraft)
                .textFieldStyle(.roundedBorder)

            if !renameGroupError.isEmpty {
                Text(renameGroupError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 10) {
                Spacer()
                Button("Cancel") {
                    cancelRenameGroup()
                }
                Button("Rename") {
                    applyRenameGroup(groupID: groupID)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 420)
    }

    private var connectionsPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Connections")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                toolbarIcon("folder.badge.plus", action: { addGroup(parentId: selectedGroupContext()) })
                toolbarIcon("plus.square", action: { addHost(in: selectedGroupContext()) })
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(nsColor: .windowBackgroundColor))
            .overlay(
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 0.8),
                alignment: .bottom
            )

            List(selection: $sidebarSelection) {
                OutlineGroup(treeRoots, children: \.children) { node in
                    draggableTreeRow(node)
                        .tag(node.selection)
                        .contextMenu { treeContextMenu(node) }
                        .onDrop(of: [UTType.text], isTargeted: nil) { providers in
                            handleHostDrop(on: node.selection, providers: providers)
                        }
                }
            }
            .listStyle(.sidebar)
            .environment(\.defaultMinListRowHeight, 20)
            .background(HorizontalScrollLock())
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
        )
        .padding(6)
    }

    private var workspacePane: some View {
        Group {
            switch selectedPage {
            case .sessions:
                sessionsPage
            case .hosts:
                hostsPage
            case .files:
                filesPage
            }
        }
        .padding(
            selectedPage == .sessions
                ? EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8)
                : EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        )
    }

    private var hostsPage: some View {
        VStack(alignment: .leading, spacing: 12) {
            hostsHeader
            hostsContent

            Spacer(minLength: 0)
        }
    }

    private var hostsHeader: some View {
        HStack {
            Text("Settings")
                .font(.title2.weight(.semibold))
            Spacer()
            if hostEditorMode == .group {
                Text("Scope: group and subgroups")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var hostsContent: some View {
        if hostDraft != nil {
            HostEditorPane(
                host: hostBinding,
                password: $passwordDraft,
                mode: hostEditorMode,
                scopeDescription: groupScopeDescription,
                groupOptions: groupOptions,
                message: statusMessage,
                onBrowseKey: browseKeyFile,
                onSave: saveHostDraft,
                onConnect: connectFromHostDraft,
                canConnect: canConnectHost
            )
        } else {
            emptyHostsSelectionView
        }
    }

    private var emptyHostsSelectionView: some View {
        Text("Use right-click on a host or group and choose Open Settings")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
            )
    }

    private var sessionsPage: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !sessionStatusMessage.isEmpty {
                Text(sessionStatusMessage)
                    .font(.caption)
                    .foregroundStyle(sessionStatusIsError ? Color.red : Color.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
                    )
            }
            SessionsPane(sessions: sessions)
        }
    }

    private var filesPage: some View {
        FileTransferPane(
            service: fileBrowser,
            hosts: sortedHostsForFiles,
            selectedHostID: $filesHostID
        )
        .onAppear {
            ensureFilesHostSelection()
            fileBrowser.activate(host: selectedFilesHost)
        }
    }

    private func pageRow(_ page: AppPage) -> some View {
        HStack(spacing: 8) {
            Image(systemName: page.icon)
                .frame(width: 16)
            Text(page.rawValue)
        }
        .tag(SidebarSelection.page(page))
    }

    private func toolbarIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 20, height: 18)
                .background(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.8)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func draggableTreeRow(_ node: SidebarNode) -> some View {
        switch node.selection {
        case .host(let id):
            treeRow(node)
                .onTapGesture(count: 2) {
                    guard let host = store.host(by: id) else { return }
                    let result = sessions.open(for: host)
                    applySessionOpenResult(result, host: host)
                }
                .onDrag {
                    NSItemProvider(object: "\(hostDragPrefix)\(id.uuidString)" as NSString)
                }
        default:
            treeRow(node)
        }
    }

    private func treeRow(_ node: SidebarNode) -> some View {
        HStack(spacing: 8) {
            Image(systemName: node.isGroup ? "folder" : "desktopcomputer")
                .frame(width: 16)
                .foregroundStyle(node.isGroup ? .secondary : .primary)
            VStack(alignment: .leading, spacing: 1) {
                Text(node.title)
                    .lineLimit(1)
                if let subtitle = node.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private enum HostDropTarget {
        case valid(UUID?)
        case invalid
    }

    private func hostDropTarget(for selection: SidebarSelection) -> HostDropTarget {
        switch selection {
        case .group(let id):
            return .valid(id)
        case .ungrouped:
            return .valid(nil)
        case .host(let id):
            guard let host = store.host(by: id) else { return .invalid }
            return .valid(host.groupId)
        case .page:
            return .invalid
        }
    }

    private func parseDraggedHostID(from providers: [NSItemProvider], completion: @escaping @Sendable (UUID?) -> Void) {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }) else {
            completion(nil)
            return
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.text.identifier) { data, _ in
            guard let data,
                  let value = String(data: data, encoding: .utf8)?.trimmed,
                  value.hasPrefix(hostDragPrefix) else {
                completion(nil)
                return
            }

            let idString = String(value.dropFirst(hostDragPrefix.count))
            completion(UUID(uuidString: idString))
        }
    }

    private func handleHostDrop(on selection: SidebarSelection, providers: [NSItemProvider]) -> Bool {
        guard case .valid(let targetGroupID) = hostDropTarget(for: selection) else {
            return false
        }

        let hasTextProvider = providers.contains { $0.hasItemConformingToTypeIdentifier(UTType.text.identifier) }
        guard hasTextProvider else {
            return false
        }

        parseDraggedHostID(from: providers) { hostID in
            guard let hostID else { return }
            DispatchQueue.main.async {
                guard let existing = store.host(by: hostID) else { return }
                if existing.groupId == targetGroupID {
                    return
                }

                store.moveHost(id: hostID, to: targetGroupID)
                selectedHostID = hostID
                filesHostID = hostID
                loadHostDraft(hostID)
                statusMessage = "Host moved"
            }
        }

        return true
    }

    @ViewBuilder
    private func treeContextMenu(_ node: SidebarNode) -> some View {
        switch node.selection {
        case .group(let id):
            Button("Open Settings") { openGroupSettings(id) }
            Button("Rename Group") { beginRenameGroup(id) }
            Divider()
            Button("Add Host") { addHost(in: id) }
            Button("Add Subgroup") { addGroup(parentId: id) }
            Button("Delete Group", role: .destructive) {
                deleteGroup(id)
            }
        case .ungrouped:
            Button("Add Host") { addHost(in: nil) }
        case .host(let id):
            Button("Open Settings") { openHostSettings(id) }
            Divider()
            Button("Delete Host", role: .destructive) {
                deleteHost(id)
            }
        case .page:
            EmptyView()
        }
    }

    private var treeRoots: [SidebarNode] {
        var roots = buildGroupNodes(parentId: nil)

        let ungroupedHosts = store.sortedHosts(groupId: nil)
        if !ungroupedHosts.isEmpty {
            let children = ungroupedHosts.map(hostNode)
            roots.append(
                SidebarNode(
                    id: "ungrouped",
                    selection: .ungrouped,
                    title: "Ungrouped",
                    subtitle: nil,
                    isGroup: true,
                    children: children
                )
            )
        }

        return roots
    }

    private func buildGroupNodes(parentId: UUID?) -> [SidebarNode] {
        store.sortedGroups(parentId: parentId).map { group in
            let groupChildren = buildGroupNodes(parentId: group.id)
            let hostChildren = store.sortedHosts(groupId: group.id).map(hostNode)
            let allChildren = groupChildren + hostChildren

            return SidebarNode(
                id: "group-\(group.id.uuidString)",
                selection: .group(group.id),
                title: group.name,
                subtitle: nil,
                isGroup: true,
                children: allChildren.isEmpty ? nil : allChildren
            )
        }
    }

    private func hostNode(_ host: HostEntry) -> SidebarNode {
        SidebarNode(
            id: "host-\(host.id.uuidString)",
            selection: .host(host.id),
            title: host.displayName,
            subtitle: host.subtitle,
            isGroup: false,
            children: nil
        )
    }

    private var groupOptions: [GroupOption] {
        var options: [GroupOption] = [
            GroupOption(id: "ungrouped-option", groupId: nil, label: "Ungrouped")
        ]

        func append(parentId: UUID?, depth: Int) {
            for group in store.sortedGroups(parentId: parentId) {
                let prefix = String(repeating: "  ", count: depth)
                options.append(
                    GroupOption(
                        id: group.id.uuidString,
                        groupId: group.id,
                        label: "\(prefix)\(group.name)"
                    )
                )
                append(parentId: group.id, depth: depth + 1)
            }
        }

        append(parentId: nil, depth: 0)
        return options
    }

    private var sortedHostsForFiles: [HostEntry] {
        store.hosts.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    private var selectedFilesHost: HostEntry? {
        if let id = filesHostID, let host = store.host(by: id) {
            return host
        }
        return sortedHostsForFiles.first
    }

    private var selectedHostForActions: HostEntry? {
        if let id = selectedHostID, let host = store.host(by: id) {
            return host
        }
        if let host = selectedFilesHost {
            return host
        }
        return sortedHostsForFiles.first
    }

    private func ensureFilesHostSelection() {
        if let id = filesHostID, store.host(by: id) != nil {
            return
        }
        if let selectedHostID, store.host(by: selectedHostID) != nil {
            filesHostID = selectedHostID
            return
        }
        filesHostID = sortedHostsForFiles.first?.id
    }

    private var groupScopeDescription: String? {
        guard hostEditorMode == .group, let groupId = editingGroupSettingsID else { return nil }
        let count = hostIDsInGroupTree(groupId).count
        return "Changes will be applied to \(count) host(s)"
    }

    private func hostIDsInGroupTree(_ groupId: UUID) -> [UUID] {
        var groupIDs: Set<UUID> = []
        collectGroupDescendants(groupId, into: &groupIDs)

        return store.hosts
            .filter { host in
                if let gid = host.groupId {
                    return groupIDs.contains(gid)
                }
                return false
            }
            .map(\.id)
    }

    private func collectGroupDescendants(_ id: UUID, into set: inout Set<UUID>) {
        guard set.insert(id).inserted else { return }
        for group in store.groups where group.parentId == id {
            collectGroupDescendants(group.id, into: &set)
        }
    }

    private func removeGroupTemplates(_ groupID: UUID) {
        var ids: Set<UUID> = []
        collectGroupDescendants(groupID, into: &ids)
        for id in ids {
            groupTemplates.removeValue(forKey: id)
            groupTemplatePasswords.removeValue(forKey: id)
        }
    }

    private func deleteSelectionFromKeyboard() {
        if NSApp.keyWindow?.firstResponder is NSTextView {
            return
        }
        deleteCurrentSelection()
    }

    private func deleteCurrentSelection() {
        switch sidebarSelection {
        case .group(let id):
            deleteGroup(id)
        case .host(let id):
            deleteHost(id)
        default:
            break
        }
    }

    private func deleteGroup(_ groupID: UUID) {
        var removedGroupIDs: Set<UUID> = []
        collectGroupDescendants(groupID, into: &removedGroupIDs)

        guard !removedGroupIDs.isEmpty else { return }

        removeGroupTemplates(groupID)
        store.removeGroup(id: groupID)

        if let currentGroupID = selectedGroupID, removedGroupIDs.contains(currentGroupID) {
            selectedGroupID = nil
        }
        if case .group(let currentSelection) = sidebarSelection, removedGroupIDs.contains(currentSelection) {
            sidebarSelection = .ungrouped
        }
        if hostEditorMode == .group,
           let editingGroupSettingsID,
           removedGroupIDs.contains(editingGroupSettingsID) {
            hostEditorMode = .host
            self.editingGroupSettingsID = nil
            hostDraft = nil
            passwordDraft = ""
            if selectedPage == .hosts {
                selectedPage = .sessions
            }
        }

        ensureFilesHostSelection()
        if selectedPage == .files {
            fileBrowser.activate(host: selectedFilesHost)
        }
        statusMessage = "Group deleted"
    }

    private func deleteHost(_ hostID: UUID) {
        guard store.host(by: hostID) != nil else { return }
        store.removeHost(hostID)

        if selectedHostID == hostID {
            selectedHostID = nil
        }
        if filesHostID == hostID {
            filesHostID = nil
        }
        if hostDraft?.id == hostID {
            hostDraft = nil
            passwordDraft = ""
            hostEditorMode = .host
            editingGroupSettingsID = nil
            if selectedPage == .hosts {
                selectedPage = .sessions
            }
        }
        if case .host(let selected) = sidebarSelection, selected == hostID {
            sidebarSelection = .ungrouped
        }

        ensureFilesHostSelection()
        if selectedPage == .files {
            fileBrowser.activate(host: selectedFilesHost)
        }
        statusMessage = "Host deleted"
    }

    private func openHostSettings(_ hostID: UUID) {
        guard store.host(by: hostID) != nil else { return }
        selectedHostID = hostID
        selectedGroupID = store.host(by: hostID)?.groupId
        filesHostID = hostID
        sidebarSelection = .host(hostID)
        hostEditorMode = .host
        editingGroupSettingsID = nil
        selectedPage = .hosts
        loadHostDraft(hostID)
    }

    private func openGroupSettings(_ groupID: UUID) {
        selectedGroupID = groupID
        selectedHostID = nil
        hostEditorMode = .group
        editingGroupSettingsID = groupID
        selectedPage = .hosts

        let targetHostIDs = hostIDsInGroupTree(groupID)
        if let firstID = targetHostIDs.first, let baseHost = store.host(by: firstID) {
            hostDraft = baseHost
            passwordDraft = KeychainHelper.loadPassword(for: baseHost.id)
        } else {
            if var template = groupTemplates[groupID] {
                template.groupId = groupID
                hostDraft = template
                passwordDraft = groupTemplatePasswords[groupID] ?? ""
            } else {
                hostDraft = HostEntry(groupId: groupID)
                passwordDraft = ""
            }
        }
        sidebarSelection = .group(groupID)
        statusMessage = ""
    }

    private func openSettingsFromCurrentSelection() {
        switch sidebarSelection {
        case .host(let id):
            openHostSettings(id)
        case .group(let id):
            openGroupSettings(id)
        case .ungrouped:
            selectedPage = .hosts
            hostDraft = nil
            hostEditorMode = .host
            editingGroupSettingsID = nil
            statusMessage = ""
        case .page(_), .none:
            if let host = selectedHostForActions {
                openHostSettings(host.id)
            } else {
                selectedPage = .hosts
                hostDraft = nil
                hostEditorMode = .host
                editingGroupSettingsID = nil
                statusMessage = ""
            }
        }
    }

    private func connectSelectedHost() {
        guard let host = selectedHostForActions else { return }
        let result = sessions.open(for: host)
        applySessionOpenResult(result, host: host)
    }

    private func navigateHost(by offset: Int) {
        let hosts = sortedHostsForFiles
        guard !hosts.isEmpty else { return }

        let currentID = selectedHostForActions?.id
        guard let currentID,
              let currentIndex = hosts.firstIndex(where: { $0.id == currentID }) else {
            let fallback = hosts[0]
            sidebarSelection = .host(fallback.id)
            return
        }

        let nextIndex = (currentIndex + offset + hosts.count) % hosts.count
        sidebarSelection = .host(hosts[nextIndex].id)
    }

    private func applySessionOpenResult(_ result: SessionOpenResult, host: HostEntry) {
        selectedHostID = host.id
        filesHostID = host.id

        switch result {
        case .embedded:
            selectedPage = .sessions
            statusMessage = "Session opened"
            sessionStatusMessage = "Session opened: \(host.displayName)"
            sessionStatusIsError = false
        case .external:
            statusMessage = "Opened in System Terminal"
            sessionStatusMessage = "Opened in System Terminal: \(host.displayName)"
            sessionStatusIsError = false
        case .failed(let error):
            statusMessage = "Open failed: \(error)"
            sessionStatusMessage = "Open failed: \(error)"
            sessionStatusIsError = true
        }
    }

    private func toggleSidebar() {
        isSidebarHidden.toggle()
    }

    private func updateStatus(_ message: String, isError: Bool = false) {
        statusMessage = message
        sessionStatusMessage = message
        sessionStatusIsError = isError
    }

    private func decodeImportPayload(from data: Data) throws -> PersistedData {
        let decoder = JSONDecoder()

        if let payload = try? decoder.decode(PersistedData.self, from: data) {
            return payload
        }

        if let partial = try? decoder.decode(PartialPersistedData.self, from: data),
           let hosts = partial.hosts {
            return PersistedData(groups: partial.groups ?? [], hosts: hosts)
        }

        if let hostsOnly = try? decoder.decode([HostEntry].self, from: data) {
            return PersistedData(groups: [], hosts: hostsOnly)
        }

        throw ImportPayloadError.unsupportedFormat
    }

    private func reselectAfterImport() {
        groupTemplates.removeAll()
        groupTemplatePasswords.removeAll()
        hostEditorMode = .host
        editingGroupSettingsID = nil
        hostDraft = nil
        passwordDraft = ""
        selectedGroupID = nil
        selectedHostID = nil

        ensureFilesHostSelection()

        if let hostID = filesHostID {
            selectedHostID = hostID
            sidebarSelection = .host(hostID)
        } else if let firstGroup = store.sortedGroups(parentId: nil).first {
            selectedGroupID = firstGroup.id
            sidebarSelection = .group(firstGroup.id)
        } else {
            sidebarSelection = .ungrouped
        }

        reloadDraftsFromSelection()
        fileBrowser.activate(host: selectedFilesHost)
    }

    private func importConfig() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.prompt = "Import"

        guard panel.runModal() == .OK, let fileURL = panel.url else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let payload = try decodeImportPayload(from: data)
            store.replaceAll(groups: payload.groups, hosts: payload.hosts)
            reselectAfterImport()
            updateStatus("Imported \(store.groups.count) group(s), \(store.hosts.count) host(s)")
        } catch {
            updateStatus("Import failed: \(error.localizedDescription)", isError: true)
        }
    }

    private func exportConfig() {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "mac-ssh-manager-export.json"
        panel.prompt = "Export"

        guard panel.runModal() == .OK, let fileURL = panel.url else { return }

        do {
            let payload = store.currentData()
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(payload)
            try data.write(to: fileURL, options: .atomic)
            updateStatus("Exported \(payload.groups.count) group(s), \(payload.hosts.count) host(s)")
        } catch {
            updateStatus("Export failed: \(error.localizedDescription)", isError: true)
        }
    }

    private func handleSystemMenuAction(_ action: SystemMenuAction) {
        switch action {
        case .newHost:
            addHost(in: selectedGroupContext())
        case .newGroup:
            addGroup(parentId: selectedGroupContext())
        case .importConfig:
            importConfig()
        case .exportConfig:
            exportConfig()
        case .openSettings:
            openSettingsFromCurrentSelection()
        case .viewTTY:
            selectedPage = .sessions
        case .viewFiles:
            selectedPage = .files
        case .viewSettings:
            openSettingsFromCurrentSelection()
        case .toggleSidebar:
            toggleSidebar()
        case .connectSelected:
            connectSelectedHost()
        case .openFiles:
            selectedPage = .files
        case .previousHost:
            navigateHost(by: -1)
        case .nextHost:
            navigateHost(by: 1)
        case .deleteSelection:
            deleteSelectionFromKeyboard()
        case .manageShortcuts:
            isShortcutManagerPresented = true
        case .saveSettings:
            saveHostDraft()
        case .closeAllSessions:
            sessions.closeAll()
        case .refreshFiles:
            fileBrowser.refresh()
        }
    }

    private var hostBinding: Binding<HostEntry> {
        Binding(
            get: { hostDraft ?? HostEntry() },
            set: { newValue in
                hostDraft = newValue
                statusMessage = ""
            }
        )
    }

    private var canConnectHost: Bool {
        guard hostEditorMode == .host else { return false }
        guard let host = hostDraft else { return false }
        let hasHost = !host.host.trimmed.isEmpty
        guard hasHost else { return false }

        if host.connectionProtocol == .telnet {
            return true
        }

        let hasUser = !host.username.trimmed.isEmpty
        guard hasUser else { return false }

        if host.authMethod == .key {
            return !host.keyPath.trimmed.isEmpty
        }
        return !passwordDraft.isEmpty
    }

    private func selectedGroupContext() -> UUID? {
        switch sidebarSelection {
        case .group(let id):
            return id
        case .host(let hostId):
            return store.host(by: hostId)?.groupId
        case .ungrouped:
            return nil
        case .page, .none:
            return selectedGroupID
        }
    }

    private func handleSidebarSelection(_ selection: SidebarSelection?) {
        guard let selection else { return }

        switch selection {
        case .page(let page):
            selectedPage = page
            statusMessage = ""
            if selectedPage == .files {
                ensureFilesHostSelection()
                fileBrowser.activate(host: selectedFilesHost)
            }
        case .host(let hostId):
            selectedHostID = hostId
            selectedGroupID = store.host(by: hostId)?.groupId
            filesHostID = hostId
            loadHostDraft(hostId)
            if selectedPage == .files {
                fileBrowser.activate(host: store.host(by: hostId))
            }
            statusMessage = ""
        case .group(let groupId):
            if hostEditorMode == .group, editingGroupSettingsID == groupId, selectedPage == .hosts, hostDraft != nil {
                selectedGroupID = groupId
                statusMessage = ""
                return
            }
            selectedGroupID = groupId
            selectedHostID = nil
            hostDraft = nil
            hostEditorMode = .host
            editingGroupSettingsID = nil
            statusMessage = ""
        case .ungrouped:
            selectedGroupID = nil
            selectedHostID = nil
            hostDraft = nil
            hostEditorMode = .host
            editingGroupSettingsID = nil
            statusMessage = ""
        }
    }

    private func reloadDraftsFromSelection() {
        if let hostId = selectedHostID {
            loadHostDraft(hostId)
            return
        }
    }

    private func loadHostDraft(_ id: UUID) {
        guard let host = store.host(by: id) else {
            hostDraft = nil
            return
        }

        hostDraft = host
        passwordDraft = KeychainHelper.loadPassword(for: host.id)
        hostEditorMode = .host
        editingGroupSettingsID = nil
        statusMessage = ""
    }

    private func addGroup(parentId: UUID?) {
        let group = store.addGroup(parentId: parentId)
        selectedGroupID = group.id
        selectedHostID = nil
        hostDraft = nil
        hostEditorMode = .host
        editingGroupSettingsID = nil
        sidebarSelection = .group(group.id)
        statusMessage = ""
        beginRenameGroup(group.id)
    }

    private func beginRenameGroup(_ groupID: UUID) {
        guard let group = store.group(by: groupID) else { return }
        renameGroupDraft = group.name
        renameGroupError = ""
        renameGroupTarget = RenameGroupTarget(groupID: groupID)
    }

    private func cancelRenameGroup() {
        renameGroupTarget = nil
        renameGroupError = ""
    }

    private func applyRenameGroup(groupID: UUID) {
        let trimmed = renameGroupDraft.trimmed
        guard !trimmed.isEmpty else {
            renameGroupError = "Group name is required"
            return
        }
        guard store.group(by: groupID) != nil else {
            cancelRenameGroup()
            return
        }

        store.updateGroup(id: groupID, name: trimmed)
        statusMessage = "Group renamed"
        cancelRenameGroup()
    }

    private func addHost(in groupId: UUID?) {
        let host = store.addHost(in: groupId)
        var preparedHost = host

        if let groupId, let template = groupTemplates[groupId] {
            applyManagedSettings(from: template, to: &preparedHost)
            preparedHost.groupId = groupId
            store.updateHost(preparedHost)

            if shouldPersistKeychainPassword(for: preparedHost) {
                let templatePassword = groupTemplatePasswords[groupId] ?? ""
                if templatePassword.isEmpty {
                    KeychainHelper.deletePassword(for: preparedHost.id)
                } else {
                    _ = KeychainHelper.savePassword(templatePassword, for: preparedHost.id)
                }
            } else {
                KeychainHelper.deletePassword(for: preparedHost.id)
            }
        }

        selectedHostID = preparedHost.id
        filesHostID = preparedHost.id
        selectedGroupID = groupId
        hostDraft = preparedHost
        passwordDraft = KeychainHelper.loadPassword(for: preparedHost.id)
        hostEditorMode = .host
        editingGroupSettingsID = nil
        selectedPage = .hosts
        sidebarSelection = .host(preparedHost.id)
        statusMessage = ""
    }

    private func browseKeyFile() {
        guard hostDraft != nil else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let path = panel.url?.path {
            hostDraft?.keyPath = path
            statusMessage = ""
        }
    }

    private func sanitizeHostDraft(_ host: inout HostEntry) {
        host.name = host.name.trimmed
        host.host = host.host.trimmed
        host.username = host.username.trimmed
        host.keyPath = host.keyPath.trimmed
        host.port = max(1, min(65535, host.port))
        if host.connectionProtocol == .telnet {
            host.terminalLaunchMode = .embedded
        }
        if host.connectionProtocol == .ssh, host.authMethod == .password {
            host.terminalLaunchMode = .embedded
        }

        host.putty.terminalType = host.putty.terminalType.trimmed
        host.putty.localeCharset = host.putty.localeCharset.trimmed
        host.putty.userKnownHostsFile = host.putty.userKnownHostsFile.trimmed
        host.putty.bindAddress = host.putty.bindAddress.trimmed
        host.putty.x11Display = host.putty.x11Display.trimmed
        host.putty.kexAlgorithms = host.putty.kexAlgorithms.trimmed
        host.putty.ciphers = host.putty.ciphers.trimmed
        host.putty.macs = host.putty.macs.trimmed
        host.putty.hostKeyAlgorithms = host.putty.hostKeyAlgorithms.trimmed
        host.putty.rekeyLimit = host.putty.rekeyLimit.trimmed
        host.putty.remoteCommand = host.putty.remoteCommand.trimmed
        host.putty.proxyHost = host.putty.proxyHost.trimmed
        host.putty.proxyUsername = host.putty.proxyUsername.trimmed
        host.putty.proxyPassword = host.putty.proxyPassword.trimmed
        host.putty.proxyCommand = host.putty.proxyCommand.trimmed
        host.putty.logFilePath = host.putty.logFilePath.trimmed

        host.putty.terminalColumns = max(40, min(400, host.putty.terminalColumns))
        host.putty.terminalRows = max(10, min(200, host.putty.terminalRows))
        host.putty.scrollbackLines = max(0, min(1_000_000, host.putty.scrollbackLines))
        host.putty.fontSize = max(9, min(30, host.putty.fontSize))
        host.putty.connectTimeoutSeconds = max(0, min(600, host.putty.connectTimeoutSeconds))
        host.putty.keepAliveIntervalSeconds = max(0, min(3600, host.putty.keepAliveIntervalSeconds))
        host.putty.keepAliveCountMax = max(1, min(20, host.putty.keepAliveCountMax))
        host.putty.proxyPort = max(0, min(65535, host.putty.proxyPort))

        host.fileTransfer.remoteRootPath = host.fileTransfer.remoteRootPath.trimmed
        if host.fileTransfer.remoteRootPath.isEmpty {
            host.fileTransfer.remoteRootPath = "."
        }
        host.fileTransfer.autoRefreshSeconds = max(1, min(60, host.fileTransfer.autoRefreshSeconds))
    }

    private func shouldPersistKeychainPassword(for host: HostEntry) -> Bool {
        if host.connectionProtocol == .ssh, host.authMethod == .password {
            return true
        }
        if host.fileTransfer.protocolMode == .ftp {
            return true
        }
        return false
    }

    private func applyManagedSettings(from template: HostEntry, to host: inout HostEntry) {
        host.connectionProtocol = template.connectionProtocol
        host.terminalLaunchMode = template.terminalLaunchMode
        host.username = template.username
        host.port = template.port
        host.authMethod = template.authMethod
        host.keyPath = template.keyPath
        host.putty = template.putty
        host.fileTransfer = template.fileTransfer
    }

    private func applyHostDraftToGroup(_ template: HostEntry, groupID: UUID) {
        let targetIDs = hostIDsInGroupTree(groupID)

        var savedTemplate = template
        savedTemplate.groupId = groupID
        groupTemplates[groupID] = savedTemplate
        if shouldPersistKeychainPassword(for: template), !passwordDraft.isEmpty {
            groupTemplatePasswords[groupID] = passwordDraft
        } else {
            groupTemplatePasswords.removeValue(forKey: groupID)
        }

        guard !targetIDs.isEmpty else {
            statusMessage = "Template saved for new hosts in selected group"
            return
        }

        for hostID in targetIDs {
            guard var current = store.host(by: hostID) else { continue }
            applyManagedSettings(from: template, to: &current)
            store.updateHost(current)

            if shouldPersistKeychainPassword(for: template) {
                if passwordDraft.isEmpty {
                    KeychainHelper.deletePassword(for: hostID)
                } else {
                    _ = KeychainHelper.savePassword(passwordDraft, for: hostID)
                }
            } else {
                KeychainHelper.deletePassword(for: hostID)
            }
        }

        statusMessage = "Applied to \(targetIDs.count) host(s)"
    }

    private func saveHostDraft() {
        guard var host = hostDraft else { return }
        sanitizeHostDraft(&host)

        if hostEditorMode == .group, let groupID = editingGroupSettingsID {
            hostDraft = host
            applyHostDraftToGroup(host, groupID: groupID)
            return
        }

        store.updateHost(host)
        hostDraft = host

        if shouldPersistKeychainPassword(for: host) {
            if passwordDraft.isEmpty {
                KeychainHelper.deletePassword(for: host.id)
            } else {
                _ = KeychainHelper.savePassword(passwordDraft, for: host.id)
            }
        } else {
            KeychainHelper.deletePassword(for: host.id)
        }

        statusMessage = "Saved"
    }

    private func connectFromHostDraft() {
        guard hostEditorMode == .host else { return }
        guard canConnectHost else {
            statusMessage = "Fill required fields"
            return
        }

        saveHostDraft()

        guard let host = hostDraft else { return }
        let result = sessions.open(for: host)
        applySessionOpenResult(result, host: host)
        sidebarSelection = .host(host.id)
    }
}

struct MacSSHManagerCommands: Commands {
    @ObservedObject var shortcutStore: ShortcutStore

    var body: some Commands {
        CommandMenu("File") {
            menuButton("New Host", shortcut: .newHost)
            menuButton("New Group", shortcut: .newGroup)

            Divider()

            menuButton("Import Config...", shortcut: .importConfig)
            menuButton("Export Config...", shortcut: .exportConfig)

            Divider()

            menuButton("Open Settings", shortcut: .openSettings)
        }

        CommandMenu("View") {
            menuButton("Toggle Sidebar", shortcut: .toggleSidebar)

            Divider()

            menuButton("TTY", shortcut: .viewTTY)
            menuButton("Files", shortcut: .viewFiles)
            menuButton("Settings", shortcut: .viewSettings)
        }

        CommandMenu("Navigate") {
            menuButton("Connect Selected", shortcut: .connectSelected)
            menuButton("Open Files", shortcut: .openFiles)

            Divider()

            menuButton("Previous Host", shortcut: .previousHost)
            menuButton("Next Host", shortcut: .nextHost)

            Divider()

            menuButton("Delete Selected", shortcut: .deleteSelection)
        }

        CommandMenu("Tools") {
            menuButton("Save Settings", shortcut: .saveSettings)
            menuButton("Close All Sessions", shortcut: .closeAllSessions)

            Divider()

            menuButton("Refresh Files", shortcut: .refreshFiles)
            menuButton("Keyboard Shortcuts...", shortcut: .manageShortcuts)
        }
    }

    private func menuButton(_ title: String, shortcut action: ShortcutAction) -> some View {
        let shortcut = shortcutStore.binding(for: action)
        return Button(title) {
            sendSystemMenuAction(action.systemAction)
        }
        .keyboardShortcut(shortcut.keyEquivalent, modifiers: shortcut.modifiers)
    }
}

struct MacSSHManagerApp: App {
    @StateObject private var shortcutStore = ShortcutStore()

    var body: some Scene {
        WindowGroup("Mac SSH Manager") {
            ContentView()
                .environmentObject(shortcutStore)
        }
        .commands {
            MacSSHManagerCommands(shortcutStore: shortcutStore)
        }
    }
}

MacSSHManagerApp.main()
