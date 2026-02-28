import Foundation

enum ConfigImportFormat {
    case appJSON
    case openSSH
}

struct ImportedConfigPayload {
    let data: PersistedData
    let format: ConfigImportFormat
}

enum OpenSSHConfigError: LocalizedError {
    case unsupportedFormat
    case emptyConfig

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "Unsupported file format. Expected app JSON or OpenSSH config."
        case .emptyConfig:
            return "OpenSSH config does not contain importable Host entries."
        }
    }
}

enum OpenSSHConfigCodec {
    static func decode(_ text: String) throws -> PersistedData {
        let parser = Parser(text: text)
        let hosts = parser.parseHosts()
        guard !hosts.isEmpty else {
            throw OpenSSHConfigError.emptyConfig
        }
        return PersistedData(groups: [], hosts: hosts, groupTemplates: [:])
    }

    static func encode(hosts: [HostEntry]) -> String {
        var usedAliases: Set<String> = []
        var blocks: [String] = []

        for host in hosts {
            let alias = uniqueAlias(for: host, usedAliases: &usedAliases)
            var lines: [String] = []
            lines.append("Host \(quoteIfNeeded(alias))")

            let displayName = host.displayName.trimmed
            if !displayName.isEmpty, displayName != alias {
                lines.append("    # Name: \(displayName)")
            }

            let hostName = host.host.trimmed
            if !hostName.isEmpty {
                lines.append("    HostName \(quoteIfNeeded(hostName))")
            }

            let username = host.username.trimmed
            if !username.isEmpty {
                lines.append("    User \(quoteIfNeeded(username))")
            }

            if host.port > 0 {
                lines.append("    Port \(host.port)")
            }

            if host.authMethod == .password {
                lines.append("    PubkeyAuthentication no")
                lines.append("    PasswordAuthentication yes")
            } else {
                lines.append("    PubkeyAuthentication \(sshBool(true))")
                let keyPath = host.keyPath.trimmed
                if !keyPath.isEmpty {
                    lines.append("    IdentityFile \(quoteIfNeeded(keyPath))")
                }
            }

            appendSSHSettings(host.sshSettings, to: &lines)
            blocks.append(lines.joined(separator: "\n"))
        }

        return blocks.joined(separator: "\n\n") + "\n"
    }

    private static func appendSSHSettings(_ settings: SSHSettings, to lines: inout [String]) {
        switch settings.requestTTY {
        case .force:
            lines.append("    RequestTTY force")
        case .auto:
            lines.append("    RequestTTY auto")
        case .disabled:
            lines.append("    RequestTTY no")
        }

        lines.append("    StrictHostKeyChecking \(strictHostKeyValue(settings.strictHostKeyChecking))")
        lines.append("    TCPKeepAlive \(sshBool(settings.tcpKeepAlive))")
        lines.append("    ForwardAgent \(sshBool(settings.forwardAgent))")
        lines.append("    KbdInteractiveAuthentication \(sshBool(settings.enableKeyboardInteractiveAuth))")
        lines.append("    PasswordAuthentication \(sshBool(settings.enablePasswordAuth))")
        lines.append("    PubkeyAuthentication \(sshBool(settings.enablePublicKeyAuth))")
        lines.append("    GSSAPIAuthentication \(sshBool(settings.enableGSSAPIAuth))")
        lines.append("    GSSAPIDelegateCredentials \(sshBool(settings.gssapiDelegateCredentials))")
        lines.append("    Compression \(sshBool(settings.compression))")
        lines.append("    ForwardX11 \(sshBool(settings.x11Forwarding))")

        if settings.connectTimeoutSeconds > 0 {
            lines.append("    ConnectTimeout \(settings.connectTimeoutSeconds)")
        }
        if settings.keepAliveIntervalSeconds > 0 {
            lines.append("    ServerAliveInterval \(settings.keepAliveIntervalSeconds)")
            lines.append("    ServerAliveCountMax \(settings.keepAliveCountMax)")
        }
        if let addressFamily = addressFamilyValue(settings.addressFamily) {
            lines.append("    AddressFamily \(addressFamily)")
        }

        appendIfNonEmpty("UserKnownHostsFile", settings.userKnownHostsFile, to: &lines)
        appendIfNonEmpty("BindAddress", settings.bindAddress, to: &lines)
        appendIfNonEmpty("KexAlgorithms", settings.kexAlgorithms, to: &lines)
        appendIfNonEmpty("Ciphers", settings.ciphers, to: &lines)
        appendIfNonEmpty("MACs", settings.macs, to: &lines)
        appendIfNonEmpty("HostKeyAlgorithms", settings.hostKeyAlgorithms, to: &lines)
        appendIfNonEmpty("RekeyLimit", settings.rekeyLimit, to: &lines)
        appendIfNonEmpty("RemoteCommand", settings.remoteCommand, to: &lines)
        appendIfNonEmpty("ProxyCommand", settings.proxyCommandValue, to: &lines)
        appendIfNonEmpty("SetEnv", normalizedSetEnv(settings.setEnvironment), to: &lines)
        appendRepeated("SendEnv", values: splitNonEmptyLines(settings.sendEnvPatterns), to: &lines)
        appendRepeated("LocalForward", values: splitNonEmptyLines(settings.localPortForwards), to: &lines)
        appendRepeated("RemoteForward", values: splitNonEmptyLines(settings.remotePortForwards), to: &lines)
        appendRepeated("DynamicForward", values: splitNonEmptyLines(settings.dynamicPortForwards), to: &lines)

        if settings.loggingEnabled || settings.logVerbosity != .none {
            lines.append("    LogLevel \(logLevelValue(settings.logVerbosity))")
        }
        if settings.noShell && settings.remoteCommand.trimmed.isEmpty {
            lines.append("    SessionType none")
        }
    }

    private static func appendIfNonEmpty(_ key: String, _ value: String, to lines: inout [String]) {
        let trimmed = value.trimmed
        guard !trimmed.isEmpty else { return }
        lines.append("    \(key) \(quoteIfNeeded(trimmed))")
    }

    private static func appendRepeated(_ key: String, values: [String], to lines: inout [String]) {
        for value in values {
            lines.append("    \(key) \(quoteIfNeeded(value))")
        }
    }

    private static func splitNonEmptyLines(_ text: String) -> [String] {
        text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmed }
            .filter { !$0.isEmpty }
    }

    private static func normalizedSetEnv(_ text: String) -> String {
        splitNonEmptyLines(text).joined(separator: " ")
    }

    private static func uniqueAlias(for host: HostEntry, usedAliases: inout Set<String>) -> String {
        let fallbackHost = host.host.trimmed.isEmpty ? "host" : host.host.trimmed
        let base = sanitizedAlias(from: host.displayName, fallback: fallbackHost)
        var candidate = base
        var suffix = 2

        while !usedAliases.insert(candidate).inserted {
            candidate = "\(base)-\(suffix)"
            suffix += 1
        }

        return candidate
    }

    private static func sanitizedAlias(from name: String, fallback: String) -> String {
        let source = name.trimmed.isEmpty ? fallback : name.trimmed
        let pieces = source
            .lowercased()
            .split { !$0.isLetter && !$0.isNumber && $0 != "-" && $0 != "_" && $0 != "." }
            .map(String.init)
            .filter { !$0.isEmpty }

        let joined = pieces.joined(separator: "-")
        return joined.isEmpty ? "host" : joined
    }

    private static func quoteIfNeeded(_ value: String) -> String {
        guard value.contains(where: { $0.isWhitespace || $0 == "#" || $0 == "\"" }) else {
            return value
        }
        let escaped = value.replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static func sshBool(_ value: Bool) -> String {
        value ? "yes" : "no"
    }

    private static func strictHostKeyValue(_ mode: StrictHostKeyMode) -> String {
        switch mode {
        case .acceptNew:
            return "accept-new"
        case .strict:
            return "yes"
        case .off:
            return "no"
        }
    }

    private static func addressFamilyValue(_ value: IPVersionPreference) -> String? {
        switch value {
        case .auto:
            return nil
        case .ipv4:
            return "inet"
        case .ipv6:
            return "inet6"
        }
    }

    private static func logLevelValue(_ value: SSHLogVerbosity) -> String {
        switch value {
        case .none:
            return "INFO"
        case .verbose:
            return "VERBOSE"
        case .debug2:
            return "DEBUG2"
        case .debug3:
            return "DEBUG3"
        }
    }

    private struct Parser {
        let text: String

        func parseHosts() -> [HostEntry] {
            var currentAliases: [String] = []
            var currentOptions: [String: [String]] = [:]
            var hostEntries: [HostEntry] = []

            func flushCurrent() {
                guard !currentAliases.isEmpty else { return }
                hostEntries.append(contentsOf: buildHosts(aliases: currentAliases, options: currentOptions))
                currentAliases = []
                currentOptions = [:]
            }

            for rawLine in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
                let line = stripInlineComment(String(rawLine)).trimmed
                if line.isEmpty { continue }

                let parts = splitDirective(line)
                guard let keyword = parts.first?.lowercased() else { continue }
                let values = Array(parts.dropFirst())

                if keyword == "match" || keyword == "include" {
                    continue
                }

                if keyword == "host" {
                    flushCurrent()
                    currentAliases = values
                        .map(unquote)
                        .filter { alias in
                            !alias.isEmpty && !alias.contains("*") && !alias.contains("?") && !alias.hasPrefix("!")
                        }
                    continue
                }

                guard !currentAliases.isEmpty else { continue }
                currentOptions[keyword, default: []].append(values.map(unquote).joined(separator: " "))
            }

            flushCurrent()
            return hostEntries
        }

        private func buildHosts(aliases: [String], options: [String: [String]]) -> [HostEntry] {
            aliases.map { alias in
                var host = HostEntry()
                host.name = alias
                host.host = firstValue("hostname", options) ?? alias
                host.username = firstValue("user", options) ?? ""
                host.port = Int(firstValue("port", options) ?? "") ?? 22

                let identityFile = firstValue("identityfile", options) ?? ""
                if !identityFile.trimmed.isEmpty {
                    host.authMethod = .key
                    host.keyPath = identityFile
                } else if let passwordAuth = parseBool(firstValue("passwordauthentication", options)),
                          passwordAuth,
                          parseBool(firstValue("pubkeyauthentication", options)) == false {
                    host.authMethod = .password
                    host.keyPath = ""
                } else {
                    host.authMethod = .key
                    host.keyPath = ""
                }

                applyOptions(options, to: &host)
                return host
            }
        }

        private func applyOptions(_ options: [String: [String]], to host: inout HostEntry) {
            if let value = firstValue("stricthostkeychecking", options) {
                host.sshSettings.strictHostKeyChecking = parseStrictHostKey(value)
            }
            if let value = firstValue("requesttty", options) {
                host.sshSettings.requestTTY = parseRequestTTY(value)
            }
            if let value = firstValue("addressfamily", options) {
                host.sshSettings.addressFamily = parseAddressFamily(value)
            }
            if let value = firstValue("connecttimeout", options), let intValue = Int(value) {
                host.sshSettings.connectTimeoutSeconds = intValue
            }
            if let value = firstValue("serveraliveinterval", options), let intValue = Int(value) {
                host.sshSettings.keepAliveIntervalSeconds = intValue
            }
            if let value = firstValue("serveralivecountmax", options), let intValue = Int(value) {
                host.sshSettings.keepAliveCountMax = intValue
            }

            host.sshSettings.userKnownHostsFile = firstValue("userknownhostsfile", options) ?? ""
            host.sshSettings.bindAddress = firstValue("bindaddress", options) ?? ""
            host.sshSettings.kexAlgorithms = firstValue("kexalgorithms", options) ?? ""
            host.sshSettings.ciphers = firstValue("ciphers", options) ?? ""
            host.sshSettings.macs = firstValue("macs", options) ?? ""
            host.sshSettings.hostKeyAlgorithms = firstValue("hostkeyalgorithms", options) ?? ""
            host.sshSettings.rekeyLimit = firstValue("rekeylimit", options) ?? ""
            host.sshSettings.remoteCommand = firstValue("remotecommand", options) ?? ""
            host.sshSettings.proxyCommand = firstValue("proxycommand", options) ?? ""

            if let value = firstValue("loglevel", options) {
                host.sshSettings.logVerbosity = parseLogLevel(value)
                host.sshSettings.loggingEnabled = host.sshSettings.logVerbosity != .none
            }

            if let value = parseBool(firstValue("forwardagent", options)) {
                host.sshSettings.forwardAgent = value
            }
            if let value = parseBool(firstValue("tcpkeepalive", options)) {
                host.sshSettings.tcpKeepAlive = value
            }
            if let value = parseBool(firstValue("pubkeyauthentication", options)) {
                host.sshSettings.enablePublicKeyAuth = value
            }
            if let value = parseBool(firstValue("passwordauthentication", options)) {
                host.sshSettings.enablePasswordAuth = value
            }
            if let value = parseBool(firstValue("kbdinteractiveauthentication", options) ?? firstValue("challengeresponseauthentication", options)) {
                host.sshSettings.enableKeyboardInteractiveAuth = value
            }
            if let value = parseBool(firstValue("gssapiauthentication", options)) {
                host.sshSettings.enableGSSAPIAuth = value
            }
            if let value = parseBool(firstValue("gssapidelegatecredentials", options)) {
                host.sshSettings.gssapiDelegateCredentials = value
            }
            if let value = parseBool(firstValue("compression", options)) {
                host.sshSettings.compression = value
            }
            if let value = parseBool(firstValue("forwardx11", options)) {
                host.sshSettings.x11Forwarding = value
            }

            if firstValue("sessiontype", options)?.lowercased() == "none" {
                host.sshSettings.noShell = true
            }

            host.sshSettings.sendEnvPatterns = joinedValues("sendenv", options)
            host.sshSettings.setEnvironment = normalizedSetEnv(joinedValues("setenv", options))
            host.sshSettings.localPortForwards = joinedValues("localforward", options)
            host.sshSettings.remotePortForwards = joinedValues("remoteforward", options)
            host.sshSettings.dynamicPortForwards = joinedValues("dynamicforward", options)
        }

        private func firstValue(_ key: String, _ options: [String: [String]]) -> String? {
            options[key]?.first?.trimmed
        }

        private func joinedValues(_ key: String, _ options: [String: [String]]) -> String {
            options[key]?.map(\.trimmed).filter { !$0.isEmpty }.joined(separator: "\n") ?? ""
        }

        private func stripInlineComment(_ line: String) -> String {
            var result = ""
            var inSingle = false
            var inDouble = false

            for char in line {
                if char == "\"" && !inSingle {
                    inDouble.toggle()
                } else if char == "'" && !inDouble {
                    inSingle.toggle()
                } else if char == "#" && !inSingle && !inDouble {
                    break
                }
                result.append(char)
            }

            return result
        }

        private func splitDirective(_ line: String) -> [String] {
            var tokens: [String] = []
            var current = ""
            var inSingle = false
            var inDouble = false

            for char in line {
                if char == "\"" && !inSingle {
                    inDouble.toggle()
                    current.append(char)
                    continue
                }
                if char == "'" && !inDouble {
                    inSingle.toggle()
                    current.append(char)
                    continue
                }

                if char.isWhitespace && !inSingle && !inDouble {
                    if !current.isEmpty {
                        tokens.append(current)
                        current = ""
                    }
                    continue
                }

                current.append(char)
            }

            if !current.isEmpty {
                tokens.append(current)
            }
            return tokens
        }

        private func unquote(_ value: String) -> String {
            guard value.count >= 2 else { return value }
            if (value.hasPrefix("\"") && value.hasSuffix("\"")) || (value.hasPrefix("'") && value.hasSuffix("'")) {
                return String(value.dropFirst().dropLast())
            }
            return value
        }

        private func normalizedSetEnv(_ text: String) -> String {
            text
                .split(whereSeparator: \.isWhitespace)
                .map(String.init)
                .joined(separator: "\n")
        }

        private func parseBool(_ value: String?) -> Bool? {
            guard let value else { return nil }
            switch value.lowercased() {
            case "yes", "true", "on":
                return true
            case "no", "false", "off":
                return false
            default:
                return nil
            }
        }

        private func parseStrictHostKey(_ value: String) -> StrictHostKeyMode {
            switch value.lowercased() {
            case "accept-new":
                return .acceptNew
            case "no", "off":
                return .off
            default:
                return .strict
            }
        }

        private func parseRequestTTY(_ value: String) -> RequestTTYMode {
            switch value.lowercased() {
            case "force":
                return .force
            case "no":
                return .disabled
            default:
                return .auto
            }
        }

        private func parseAddressFamily(_ value: String) -> IPVersionPreference {
            switch value.lowercased() {
            case "inet":
                return .ipv4
            case "inet6":
                return .ipv6
            default:
                return .auto
            }
        }

        private func parseLogLevel(_ value: String) -> SSHLogVerbosity {
            switch value.uppercased() {
            case "VERBOSE":
                return .verbose
            case "DEBUG2":
                return .debug2
            case "DEBUG3":
                return .debug3
            default:
                return .none
            }
        }
    }
}

private extension SSHSettings {
    var proxyCommandValue: String {
        if proxyType == .command {
            return proxyCommand.trimmed
        }

        let proxyHost = proxyHost.trimmed
        guard proxyType != .none, !proxyHost.isEmpty, proxyPort > 0 else { return "" }

        let endpoint = "\(proxyHost):\(proxyPort)"
        let userArg = proxyUsername.trimmed.isEmpty ? "" : " -P \(proxyUsername.trimmed)"

        switch proxyType {
        case .socks4:
            return "nc -x \(endpoint) -X 4\(userArg) %h %p"
        case .socks5:
            return "nc -x \(endpoint) -X 5\(userArg) %h %p"
        case .http:
            return "nc -x \(endpoint) -X connect %h %p"
        case .none, .command:
            return ""
        }
    }
}
