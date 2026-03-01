import SwiftUI
import Foundation
import AppKit

enum FileTransferProtocolMode: String, Codable, CaseIterable, Identifiable {
    case sftp
    case scp
    case ftp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sftp: return "SFTP"
        case .scp: return "SCP"
        case .ftp: return "FTP"
        }
    }
}

struct FileTransferSettings: Codable, Equatable {
    var protocolMode: FileTransferProtocolMode = .sftp
    var remoteRootPath: String = "."
    var autoRefreshSeconds: Int = 3
    var livePreview: Bool = true
    var ftpUseTLS: Bool = false
    var ftpPassiveMode: Bool = true
}

struct RemoteFileItem: Identifiable, Hashable {
    var id: String { fullPath }
    let name: String
    let fullPath: String
    let isDirectory: Bool
    let sizeText: String
    let modifiedText: String
}

private struct RemoteCommandResult {
    let exitCode: Int32
    let stdout: String
    let stderr: String

    var combinedOutput: String {
        let out = stdout.trimmed
        let err = stderr.trimmed

        if out.isEmpty { return err }
        if err.isEmpty { return out }
        return "\(out)\n\(err)"
    }

    var succeeded: Bool {
        exitCode == 0
    }
}

private struct TransferError: Error, ExpressibleByStringLiteral {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    init(stringLiteral value: String) {
        self.message = value
    }
}

private typealias TransferResult<T> = Result<T, TransferError>

private enum RemoteTransferCommand {
    static func listDirectory(host: HostEntry, path: String) -> TransferResult<[RemoteFileItem]> {
        switch host.fileTransfer.protocolMode {
        case .sftp:
            return listWithSFTP(host: host, path: path)
        case .scp:
            return listWithSCP(host: host, path: path)
        case .ftp:
            return listWithFTP(host: host, path: path)
        }
    }

    static func previewFile(host: HostEntry, remotePath: String, maxBytes: Int = 65_536) -> TransferResult<String> {
        switch host.fileTransfer.protocolMode {
        case .ftp:
            let credentials = ftpCredentials(for: host)
            switch credentials {
            case .failure(let error):
                return .failure(error)
            case .success(let creds):
                let url = ftpURL(host: host, remotePath: remotePath)
                let rangeEnd = max(0, maxBytes - 1)
                switch runFTPCurl(
                    host: host,
                    credentials: creds,
                    extraArgs: ["--range", "0-\(rangeEnd)", url]
                ) {
                case .failure(let error):
                    return .failure(error)
                case .success(let result):
                    guard result.succeeded else {
                        return .failure(TransferError(result.combinedOutput.ifEmpty("Failed to read remote file")))
                    }
                    return .success(renderPreview(data: Data(result.stdout.utf8), maxBytes: maxBytes))
                }
            }

        case .sftp, .scp:
            let tempURL = temporaryFileURL(prefix: "preview-")
            defer { try? FileManager.default.removeItem(at: tempURL) }

            switch downloadFile(host: host, remotePath: remotePath, localPath: tempURL.path) {
            case .failure(let error):
                return .failure(error)
            case .success:
                guard let data = try? Data(contentsOf: tempURL) else {
                    return .failure("Failed to read downloaded preview file")
                }
                return .success(renderPreview(data: data, maxBytes: maxBytes))
            }
        }
    }

    static func uploadFile(host: HostEntry, localPath: String, remoteDirectory: String) -> TransferResult<Void> {
        var isDirectory = ObjCBool(false)
        let exists = FileManager.default.fileExists(atPath: localPath, isDirectory: &isDirectory)
        guard exists else {
            return .failure("Local path does not exist")
        }

        switch host.fileTransfer.protocolMode {
        case .sftp:
            return uploadWithSFTP(
                host: host,
                localPath: localPath,
                remoteDirectory: remoteDirectory,
                isDirectory: isDirectory.boolValue
            )
        case .scp:
            return uploadWithSCP(
                host: host,
                localPath: localPath,
                remoteDirectory: remoteDirectory,
                isDirectory: isDirectory.boolValue
            )
        case .ftp:
            return uploadWithFTP(
                host: host,
                localPath: localPath,
                remoteDirectory: remoteDirectory,
                isDirectory: isDirectory.boolValue
            )
        }
    }

    static func downloadFile(host: HostEntry, remotePath: String, localPath: String) -> TransferResult<Void> {
        switch host.fileTransfer.protocolMode {
        case .sftp:
            return downloadWithSFTP(host: host, remotePath: remotePath, localPath: localPath)
        case .scp:
            return downloadWithSCP(host: host, remotePath: remotePath, localPath: localPath)
        case .ftp:
            return downloadWithFTP(host: host, remotePath: remotePath, localPath: localPath)
        }
    }

    static func createDirectory(host: HostEntry, remotePath: String) -> TransferResult<Void> {
        switch host.fileTransfer.protocolMode {
        case .sftp, .scp:
            return runRemoteShell(host: host, command: "mkdir -p \(shellQuote(remotePath))", failureMessage: "Create folder failed")
        case .ftp:
            let credentials = ftpCredentials(for: host)
            switch credentials {
            case .failure(let error):
                return .failure(error)
            case .success(let creds):
                let path = ftpCommandPath(remotePath)
                let url = ftpURL(host: host, remotePath: "/")
                switch runFTPCurl(host: host, credentials: creds, extraArgs: ["-Q", "MKD \(path)", url]) {
                case .failure(let error):
                    return .failure(error)
                case .success(let result):
                    guard result.succeeded else {
                        return .failure(TransferError(result.combinedOutput.ifEmpty("Create folder failed")))
                    }
                    return .success(())
                }
            }
        }
    }

    static func renamePath(host: HostEntry, from oldPath: String, to newPath: String) -> TransferResult<Void> {
        switch host.fileTransfer.protocolMode {
        case .sftp, .scp:
            return runRemoteShell(
                host: host,
                command: "mv \(shellQuote(oldPath)) \(shellQuote(newPath))",
                failureMessage: "Rename failed"
            )
        case .ftp:
            let credentials = ftpCredentials(for: host)
            switch credentials {
            case .failure(let error):
                return .failure(error)
            case .success(let creds):
                let fromPath = ftpCommandPath(oldPath)
                let toPath = ftpCommandPath(newPath)
                let url = ftpURL(host: host, remotePath: "/")
                switch runFTPCurl(host: host, credentials: creds, extraArgs: ["-Q", "RNFR \(fromPath)", "-Q", "RNTO \(toPath)", url]) {
                case .failure(let error):
                    return .failure(error)
                case .success(let result):
                    guard result.succeeded else {
                        return .failure(TransferError(result.combinedOutput.ifEmpty("Rename failed")))
                    }
                    return .success(())
                }
            }
        }
    }

    static func deletePath(host: HostEntry, remotePath: String, isDirectory: Bool) -> TransferResult<Void> {
        switch host.fileTransfer.protocolMode {
        case .sftp, .scp:
            let command = isDirectory
                ? "rm -rf \(shellQuote(remotePath))"
                : "rm -f \(shellQuote(remotePath))"
            return runRemoteShell(host: host, command: command, failureMessage: "Delete failed")
        case .ftp:
            let credentials = ftpCredentials(for: host)
            switch credentials {
            case .failure(let error):
                return .failure(error)
            case .success(let creds):
                let path = ftpCommandPath(remotePath)
                let command = isDirectory ? "RMD \(path)" : "DELE \(path)"
                let url = ftpURL(host: host, remotePath: "/")
                switch runFTPCurl(host: host, credentials: creds, extraArgs: ["-Q", command, url]) {
                case .failure(let error):
                    return .failure(error)
                case .success(let result):
                    guard result.succeeded else {
                        return .failure(TransferError(result.combinedOutput.ifEmpty("Delete failed")))
                    }
                    return .success(())
                }
            }
        }
    }

    private static func listWithSFTP(host: HostEntry, path: String) -> TransferResult<[RemoteFileItem]> {
        let target = sshTarget(host)
        guard let target else { return .failure("Host or username is empty") }

        let commands = "cd \(sftpQuote(path))\nls -la\n"
        let batchURL = temporaryFileURL(prefix: "sftp-list-")
        do {
            try commands.write(to: batchURL, atomically: true, encoding: .utf8)
        } catch {
            return .failure("Failed to create temporary SFTP batch file")
        }
        defer { try? FileManager.default.removeItem(at: batchURL) }

        var args = ["-q", "-P", String(host.port)]
        args.append(contentsOf: sshOptionArgs(host: host))
        args.append(contentsOf: ["-b", batchURL.path, target])

        let result = runSSHProgram(host: host, executable: "/usr/bin/sftp", args: args)
        guard result.succeeded else {
            return .failure(TransferError(result.combinedOutput.ifEmpty("SFTP list failed")))
        }

        return .success(parseDirectoryListing(result.combinedOutput, currentPath: path))
    }

    private static func listWithSCP(host: HostEntry, path: String) -> TransferResult<[RemoteFileItem]> {
        let target = sshTarget(host)
        guard let target else { return .failure("Host or username is empty") }

        var args: [String] = []
        args.append(contentsOf: sshOptionArgs(host: host))
        args.append(contentsOf: ["-p", String(host.port), target, "LC_ALL=C ls -la \(shellQuote(path))"])

        let result = runSSHProgram(host: host, executable: "/usr/bin/ssh", args: args)
        guard result.succeeded else {
            return .failure(TransferError(result.combinedOutput.ifEmpty("SCP browse failed")))
        }

        return .success(parseDirectoryListing(result.combinedOutput, currentPath: path))
    }

    private static func listWithFTP(host: HostEntry, path: String) -> TransferResult<[RemoteFileItem]> {
        let credentials = ftpCredentials(for: host)
        switch credentials {
        case .failure(let error):
            return .failure(error)
        case .success(let creds):
            let url = ftpURL(host: host, remotePath: path)
            let firstListResult = runFTPCurl(host: host, credentials: creds, extraArgs: [url])
            switch firstListResult {
            case .failure(let error):
                return .failure(error)
            case .success(let result):
                guard result.succeeded else {
                    return .failure(TransferError(result.combinedOutput.ifEmpty("FTP list failed")))
                }

                let parsed = parseDirectoryListing(result.stdout, currentPath: path)
                if !parsed.isEmpty {
                    return .success(parsed)
                }

                let listOnlyResult = runFTPCurl(host: host, credentials: creds, extraArgs: ["--list-only", url])
                switch listOnlyResult {
                case .failure(let error):
                    return .failure(error)
                case .success(let fallback):
                    guard fallback.succeeded else {
                        return .failure(TransferError(fallback.combinedOutput.ifEmpty("FTP list failed")))
                    }
                    return .success(parseNameOnlyListing(fallback.stdout, currentPath: path))
                }
            }
        }
    }

    private static func uploadWithSFTP(
        host: HostEntry,
        localPath: String,
        remoteDirectory: String,
        isDirectory: Bool
    ) -> TransferResult<Void> {
        let target = sshTarget(host)
        guard let target else { return .failure("Host or username is empty") }

        let putCommand = isDirectory ? "put -r" : "put"
        let commands = "cd \(sftpQuote(remoteDirectory))\n\(putCommand) \(sftpQuote(localPath))\n"
        let batchURL = temporaryFileURL(prefix: "sftp-upload-")
        do {
            try commands.write(to: batchURL, atomically: true, encoding: .utf8)
        } catch {
            return .failure("Failed to create temporary SFTP upload batch file")
        }
        defer { try? FileManager.default.removeItem(at: batchURL) }

        var args = ["-q", "-P", String(host.port)]
        args.append(contentsOf: sshOptionArgs(host: host))
        args.append(contentsOf: ["-b", batchURL.path, target])

        let result = runSSHProgram(host: host, executable: "/usr/bin/sftp", args: args)
        guard result.succeeded else {
            return .failure(TransferError(result.combinedOutput.ifEmpty("SFTP upload failed")))
        }
        return .success(())
    }

    private static func uploadWithSCP(
        host: HostEntry,
        localPath: String,
        remoteDirectory: String,
        isDirectory: Bool
    ) -> TransferResult<Void> {
        guard let target = scpTarget(host, remotePath: joinRemotePath(remoteDirectory, (localPath as NSString).lastPathComponent)) else {
            return .failure("Host or username is empty")
        }

        var args = ["-P", String(host.port)]
        if isDirectory {
            args.append("-r")
        }
        args.append(contentsOf: sshOptionArgs(host: host))
        args.append(contentsOf: [localPath, target])

        let result = runSSHProgram(host: host, executable: "/usr/bin/scp", args: args)
        guard result.succeeded else {
            return .failure(TransferError(result.combinedOutput.ifEmpty("SCP upload failed")))
        }
        return .success(())
    }

    private static func uploadWithFTP(
        host: HostEntry,
        localPath: String,
        remoteDirectory: String,
        isDirectory: Bool
    ) -> TransferResult<Void> {
        if isDirectory {
            return .failure("FTP folder upload is not supported. Use SFTP/SCP or upload files.")
        }

        let credentials = ftpCredentials(for: host)
        switch credentials {
        case .failure(let error):
            return .failure(error)
        case .success(let creds):
            let filename = (localPath as NSString).lastPathComponent
            let destination = joinRemotePath(remoteDirectory, filename)
            let url = ftpURL(host: host, remotePath: destination)
            switch runFTPCurl(host: host, credentials: creds, extraArgs: ["-T", localPath, url]) {
            case .failure(let error):
                return .failure(error)
            case .success(let result):
                guard result.succeeded else {
                    return .failure(TransferError(result.combinedOutput.ifEmpty("FTP upload failed")))
                }
                return .success(())
            }
        }
    }

    private static func downloadWithSFTP(host: HostEntry, remotePath: String, localPath: String) -> TransferResult<Void> {
        let target = sshTarget(host)
        guard let target else { return .failure("Host or username is empty") }

        let commands = "get \(sftpQuote(remotePath)) \(sftpQuote(localPath))\n"
        let batchURL = temporaryFileURL(prefix: "sftp-download-")
        do {
            try commands.write(to: batchURL, atomically: true, encoding: .utf8)
        } catch {
            return .failure("Failed to create temporary SFTP download batch file")
        }
        defer { try? FileManager.default.removeItem(at: batchURL) }

        var args = ["-q", "-P", String(host.port)]
        args.append(contentsOf: sshOptionArgs(host: host))
        args.append(contentsOf: ["-b", batchURL.path, target])

        let result = runSSHProgram(host: host, executable: "/usr/bin/sftp", args: args)
        guard result.succeeded else {
            return .failure(TransferError(result.combinedOutput.ifEmpty("SFTP download failed")))
        }
        return .success(())
    }

    private static func downloadWithSCP(host: HostEntry, remotePath: String, localPath: String) -> TransferResult<Void> {
        guard let source = scpTarget(host, remotePath: remotePath) else {
            return .failure("Host or username is empty")
        }

        var args = ["-P", String(host.port)]
        args.append(contentsOf: sshOptionArgs(host: host))
        args.append(contentsOf: [source, localPath])

        let result = runSSHProgram(host: host, executable: "/usr/bin/scp", args: args)
        guard result.succeeded else {
            return .failure(TransferError(result.combinedOutput.ifEmpty("SCP download failed")))
        }
        return .success(())
    }

    private static func downloadWithFTP(host: HostEntry, remotePath: String, localPath: String) -> TransferResult<Void> {
        let credentials = ftpCredentials(for: host)
        switch credentials {
        case .failure(let error):
            return .failure(error)
        case .success(let creds):
            let url = ftpURL(host: host, remotePath: remotePath)
            switch runFTPCurl(host: host, credentials: creds, extraArgs: ["-o", localPath, url]) {
            case .failure(let error):
                return .failure(error)
            case .success(let result):
                guard result.succeeded else {
                    return .failure(TransferError(result.combinedOutput.ifEmpty("FTP download failed")))
                }
                return .success(())
            }
        }
    }

    private static func runSSHProgram(host: HostEntry, executable: String, args: [String]) -> RemoteCommandResult {
        if host.authMethod == .password {
            let password = KeychainHelper.loadPassword(for: host.id)
            if password.isEmpty {
                return RemoteCommandResult(exitCode: -1, stdout: "", stderr: "Password for this host is missing in Keychain")
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
            """

            var env = ProcessInfo.processInfo.environment
            env["SSH_PASSWORD"] = password
            return runProcess(
                executable: "/usr/bin/expect",
                args: ["-c", expectScript, executable] + args,
                environment: env
            )
        }

        return runProcess(executable: executable, args: args)
    }

    private static func runProcess(
        executable: String,
        args: [String],
        environment: [String: String]? = nil
    ) -> RemoteCommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args

        if let environment {
            process.environment = environment
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdoutReader = ProcessPipeReader(handle: stdoutPipe.fileHandleForReading)
        let stderrReader = ProcessPipeReader(handle: stderrPipe.fileHandleForReading)

        do {
            try process.run()
        } catch {
            return RemoteCommandResult(exitCode: -1, stdout: "", stderr: error.localizedDescription)
        }

        stdoutReader.begin()
        stderrReader.begin()
        process.waitUntilExit()
        let stdoutData = stdoutReader.finish()
        let stderrData = stderrReader.finish()

        return RemoteCommandResult(
            exitCode: process.terminationStatus,
            stdout: String(decoding: stdoutData, as: UTF8.self),
            stderr: String(decoding: stderrData, as: UTF8.self)
        )
    }

    private static func sshOptionArgs(host: HostEntry) -> [String] {
        var args: [String] = []

        args.append(contentsOf: ["-o", "StrictHostKeyChecking=\(host.sshSettings.strictHostKeyChecking.sshValue)"])

        let timeout = max(0, host.sshSettings.connectTimeoutSeconds)
        if timeout > 0 {
            args.append(contentsOf: ["-o", "ConnectTimeout=\(timeout)"])
        }

        let knownHosts = expandedLocalPath(host.sshSettings.userKnownHostsFile.trimmed)
        if !knownHosts.isEmpty {
            args.append(contentsOf: ["-o", "UserKnownHostsFile=\(knownHosts)"])
        }

        if let proxy = proxyCommand(from: host) {
            args.append(contentsOf: ["-o", "ProxyCommand=\(proxy)"])
        }

        if host.authMethod == .key {
            let keyPath = expandedLocalPath(host.keyPath.trimmed)
            if !keyPath.isEmpty {
                args.append(contentsOf: ["-o", "IdentitiesOnly=yes", "-i", keyPath])
            }
        }

        return args
    }

    private static func proxyCommand(from host: HostEntry) -> String? {
        let settings = host.sshSettings
        if settings.proxyType == .none {
            return nil
        }

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
        guard !proxyHost.isEmpty, proxyPort > 0 else { return nil }

        let endpoint = "\(proxyHost):\(proxyPort)"
        let proxyUser = settings.proxyUsername.trimmed
        let userArg = proxyUser.isEmpty ? "" : " -P \(proxyUser)"

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

    private static func sshTarget(_ host: HostEntry) -> String? {
        let username = host.username.trimmed
        let hostname = host.host.trimmed
        guard !username.isEmpty, !hostname.isEmpty else { return nil }
        return "\(username)@\(hostname)"
    }

    private static func scpTarget(_ host: HostEntry, remotePath: String) -> String? {
        guard let target = sshTarget(host) else { return nil }
        let escapedPath = remotePath.replacingOccurrences(of: "'", with: "'\\''")
        return "\(target):'\(escapedPath)'"
    }

    private static func ftpCredentials(for host: HostEntry) -> TransferResult<(username: String, password: String)> {
        let username = host.username.trimmed
        guard !username.isEmpty else {
            return .failure("FTP requires username")
        }

        let password = KeychainHelper.loadPassword(for: host.id)
        guard !password.isEmpty else {
            return .failure("FTP requires password in Keychain")
        }

        return .success((username, password))
    }

    private static func runFTPCurl(
        host: HostEntry,
        credentials: (username: String, password: String),
        extraArgs: [String]
    ) -> TransferResult<RemoteCommandResult> {
        let hostName = host.host.trimmed
        guard !hostName.isEmpty else {
            return .failure("FTP requires host")
        }
        guard !credentials.username.contains(where: \.isNewline),
              !credentials.password.contains(where: \.isNewline) else {
            return .failure("FTP credentials contain unsupported newline characters")
        }

        let netrcURL = temporaryFileURL(prefix: "ftp-netrc-")
        let netrcContent = """
        machine \(hostName)
        login \(netrcToken(credentials.username))
        password \(netrcToken(credentials.password))
        """

        do {
            try netrcContent.write(to: netrcURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: netrcURL.path)
        } catch {
            return .failure("Failed to prepare FTP credentials")
        }
        defer { try? FileManager.default.removeItem(at: netrcURL) }

        var args = ["-sS", "--netrc-file", netrcURL.path]
        if host.fileTransfer.ftpPassiveMode {
            args.append("--ftp-pasv")
        } else {
            args.append(contentsOf: ["--ftp-port", "-"])
        }
        args.append(contentsOf: extraArgs)

        return .success(runProcess(executable: "/usr/bin/curl", args: args))
    }

    private static func netrcToken(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static func runRemoteShell(host: HostEntry, command: String, failureMessage: String) -> TransferResult<Void> {
        guard let target = sshTarget(host) else { return .failure("Host or username is empty") }
        var args: [String] = []
        args.append(contentsOf: sshOptionArgs(host: host))
        args.append(contentsOf: ["-p", String(host.port), target, command])
        let result = runSSHProgram(host: host, executable: "/usr/bin/ssh", args: args)
        guard result.succeeded else {
            return .failure(TransferError(result.combinedOutput.ifEmpty(failureMessage)))
        }
        return .success(())
    }

    private static func ftpCommandPath(_ path: String) -> String {
        let value = path.trimmed
        if value.isEmpty { return "/" }
        return value.hasPrefix("/") ? value : "/" + value
    }

    private static func ftpURL(host: HostEntry, remotePath: String) -> String {
        let scheme = host.fileTransfer.ftpUseTLS ? "ftps" : "ftp"
        let hostName = host.host.trimmed
        let port = host.port > 0 ? ":\(host.port)" : ""

        let normalized = normalizeFTPPath(remotePath)
        return "\(scheme)://\(hostName)\(port)\(normalized)"
    }

    private static func normalizeFTPPath(_ path: String) -> String {
        var normalized = path.trimmed
        if normalized.isEmpty || normalized == "." {
            normalized = "/"
        }
        if !normalized.hasPrefix("/") {
            normalized = "/\(normalized)"
        }

        let trailingSlash = normalized.hasSuffix("/")
        var components = normalized.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        if components.isEmpty { components = [""] }

        let encoded = components.map { component -> String in
            guard !component.isEmpty else { return "" }
            return component.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? component
        }.joined(separator: "/")

        if trailingSlash && !encoded.hasSuffix("/") {
            return encoded + "/"
        }
        return encoded
    }

    private static func parseDirectoryListing(_ output: String, currentPath: String) -> [RemoteFileItem] {
        var items: [RemoteFileItem] = []

        for rawLine in output.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmed
            if line.isEmpty { continue }
            if line.hasPrefix("sftp>") || line.hasPrefix("Connected to") || line.hasPrefix("spawn ") || line.hasPrefix("total ") {
                continue
            }

            if let parsed = parseUnixStyleLine(line, currentPath: currentPath) {
                items.append(parsed)
                continue
            }

            if let parsed = parseWindowsFTPLine(line, currentPath: currentPath) {
                items.append(parsed)
                continue
            }

            if line.contains("No such file") || line.contains("not found") {
                continue
            }
        }

        return items.sorted(by: fileSort)
    }

    private static func parseNameOnlyListing(_ output: String, currentPath: String) -> [RemoteFileItem] {
        let items = output
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmed }
            .filter { !$0.isEmpty }
            .compactMap { name -> RemoteFileItem? in
                var normalized = name
                let isDirectory = normalized.hasSuffix("/")
                if isDirectory {
                    normalized.removeLast()
                }
                guard normalized != ".", normalized != "..", !normalized.isEmpty else { return nil }

                return RemoteFileItem(
                    name: normalized,
                    fullPath: joinRemotePath(currentPath, normalized),
                    isDirectory: isDirectory,
                    sizeText: "-",
                    modifiedText: ""
                )
            }

        return items.sorted(by: fileSort)
    }

    private static func parseUnixStyleLine(_ line: String, currentPath: String) -> RemoteFileItem? {
        let components = line.split(separator: " ", omittingEmptySubsequences: true)
        guard components.count >= 9 else { return nil }

        guard let type = components[0].first, type == "d" || type == "-" || type == "l" else {
            return nil
        }

        var name = components[8...].joined(separator: " ")
        if let arrowRange = name.range(of: " -> ") {
            name = String(name[..<arrowRange.lowerBound])
        }

        let trimmedName = name.trimmed
        guard !trimmedName.isEmpty, trimmedName != ".", trimmedName != ".." else { return nil }

        let sizeText = components.count > 4 ? String(components[4]) : "-"
        var modifiedText = ""
        if components.count > 7 {
            modifiedText = "\(components[5]) \(components[6]) \(components[7])"
        }

        return RemoteFileItem(
            name: trimmedName,
            fullPath: joinRemotePath(currentPath, trimmedName),
            isDirectory: type == "d",
            sizeText: sizeText,
            modifiedText: modifiedText
        )
    }

    private static func parseWindowsFTPLine(_ line: String, currentPath: String) -> RemoteFileItem? {
        let regex = try? NSRegularExpression(pattern: #"^\d{2}-\d{2}-\d{2}\s+\d{2}:\d{2}[AP]M\s+(<DIR>|\d+)\s+(.+)$"#)
        let range = NSRange(location: 0, length: line.utf16.count)

        guard let match = regex?.firstMatch(in: line, options: [], range: range), match.numberOfRanges == 3,
              let typeRange = Range(match.range(at: 1), in: line),
              let nameRange = Range(match.range(at: 2), in: line) else {
            return nil
        }

        let marker = String(line[typeRange])
        let name = String(line[nameRange]).trimmed
        guard !name.isEmpty, name != ".", name != ".." else { return nil }

        return RemoteFileItem(
            name: name,
            fullPath: joinRemotePath(currentPath, name),
            isDirectory: marker == "<DIR>",
            sizeText: marker == "<DIR>" ? "-" : marker,
            modifiedText: ""
        )
    }

    private static func fileSort(lhs: RemoteFileItem, rhs: RemoteFileItem) -> Bool {
        if lhs.isDirectory != rhs.isDirectory {
            return lhs.isDirectory
        }
        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    static func joinRemotePath(_ base: String, _ name: String) -> String {
        let cleanBase = base.trimmed.isEmpty ? "." : base.trimmed

        if cleanBase == "/" {
            return "/\(name)"
        }
        if cleanBase.hasSuffix("/") {
            return cleanBase + name
        }
        return cleanBase + "/" + name
    }

    static func parentPath(_ path: String) -> String {
        var value = path.trimmed
        if value.isEmpty || value == "." || value == "~" || value == "/" {
            return value.isEmpty ? "." : value
        }

        if value.hasSuffix("/") {
            value.removeLast()
        }

        if let slashIndex = value.lastIndex(of: "/") {
            let parent = String(value[..<slashIndex])
            if parent.isEmpty { return "/" }
            return parent
        }

        return "."
    }

    private static func shellQuote(_ value: String) -> String {
        if value.isEmpty {
            return "''"
        }
        let escaped = value.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }

    private static func sftpQuote(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static func expandedLocalPath(_ path: String) -> String {
        guard !path.isEmpty else { return "" }
        if path.hasPrefix("~/") {
            return NSHomeDirectory() + "/" + path.dropFirst(2)
        }
        return path
    }

    private static func temporaryFileURL(prefix: String) -> URL {
        let name = "\(prefix)\(UUID().uuidString)"
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
    }

    private static func renderPreview(data: Data, maxBytes: Int) -> String {
        let clipped = data.prefix(maxBytes)

        if clipped.contains(0) {
            let head = clipped.prefix(32).map { String(format: "%02X", $0) }.joined(separator: " ")
            return "Binary file\nSize: \(data.count) bytes\nHead: \(head)"
        }

        if let utf8 = String(data: clipped, encoding: .utf8) {
            return utf8
        }

        return String(decoding: clipped, as: UTF8.self)
    }
}

@MainActor
final class RemoteFileService: ObservableObject {
    @Published private(set) var activeHost: HostEntry?

    @Published var remotePath: String = "."
    @Published var entries: [RemoteFileItem] = []
    @Published var selectedEntryID: String?
    @Published var previewText: String = ""
    @Published var statusMessage: String = "Select a host"
    @Published var isBusy: Bool = false
    @Published var autoRefreshEnabled: Bool = true
    @Published var livePreviewEnabled: Bool = true
    @Published var logs: [String] = []

    private var timer: Timer?
    private let worker = DispatchQueue(label: "macssh.files.worker", qos: .userInitiated)
    private var listRequestID: UInt64 = 0
    private var previewRequestID: UInt64 = 0

    func activate(host: HostEntry?) {
        if activeHost == host {
            return
        }

        if let host,
           let previousHost = activeHost,
           previousHost.id == host.id {
            let previousRoot = normalizedRemoteRoot(for: previousHost)
            activeHost = host
            livePreviewEnabled = host.fileTransfer.livePreview

            if remotePath == previousRoot {
                remotePath = normalizedRemoteRoot(for: host)
            }

            addLog("Updated host settings for \(host.displayName)")
            restartTimer()
            refresh()
            return
        }

        activeHost = host
        entries = []
        selectedEntryID = nil
        previewText = ""
        cancelPendingRequests()

        guard let host else {
            statusMessage = "Select a host"
            timer?.invalidate()
            timer = nil
            return
        }

        remotePath = normalizedRemoteRoot(for: host)
        autoRefreshEnabled = true
        livePreviewEnabled = host.fileTransfer.livePreview
        addLog("Selected host \(host.displayName), protocol \(host.fileTransfer.protocolMode.title)")

        restartTimer()
        refresh()
    }

    private func normalizedRemoteRoot(for host: HostEntry) -> String {
        let root = host.fileTransfer.remoteRootPath.trimmed
        return root.isEmpty ? "." : root
    }

    func setAutoRefresh(_ enabled: Bool) {
        autoRefreshEnabled = enabled
        restartTimer()
        addLog(enabled ? "Auto refresh enabled" : "Auto refresh disabled")
    }

    func setLivePreview(_ enabled: Bool) {
        livePreviewEnabled = enabled
        addLog(enabled ? "Live preview enabled" : "Live preview disabled")
        if enabled {
            refreshPreview()
        }
    }

    func refresh() {
        guard let host = activeHost else {
            statusMessage = "Select a host"
            return
        }

        let path = remotePath.trimmed.isEmpty ? "." : remotePath.trimmed
        remotePath = path

        if !isBusy {
            isBusy = true
        }

        let selectedID = selectedEntryID
        let shouldRefreshPreview = livePreviewEnabled
        let requestID = nextListRequestID()

        worker.async { [host, path] in
            let result = RemoteTransferCommand.listDirectory(host: host, path: path)
            DispatchQueue.main.async {
                guard self.listRequestID == requestID,
                      self.activeHost?.id == host.id,
                      self.remotePath == path else {
                    return
                }
                self.isBusy = false
                switch result {
                case .failure(let error):
                    self.statusMessage = error.message
                    self.addLog("List failed: \(error.message)")
                case .success(let items):
                    self.entries = items
                    self.statusMessage = "\(items.count) item(s) in \(path)"
                    self.addLog("Listed \(items.count) item(s) in \(path)")

                    if let selectedID, items.contains(where: { $0.id == selectedID }) {
                        self.selectedEntryID = selectedID
                    } else {
                        self.selectedEntryID = nil
                        self.previewText = ""
                    }

                    if shouldRefreshPreview {
                        self.refreshPreview()
                    }
                }
            }
        }
    }

    func goUp() {
        remotePath = RemoteTransferCommand.parentPath(remotePath)
        refresh()
    }

    func openSelection() {
        guard let selected = selectedEntry else { return }
        open(item: selected)
    }

    func open(item: RemoteFileItem) {
        if item.isDirectory {
            remotePath = item.fullPath
            selectedEntryID = nil
            previewText = ""
            refresh()
        } else {
            selectedEntryID = item.id
            refreshPreview()
        }
    }

    func handleSelectionChange() {
        guard let selected = selectedEntry else {
            previewText = ""
            return
        }

        if selected.isDirectory {
            previewText = ""
            return
        }

        if livePreviewEnabled {
            refreshPreview()
        }
    }

    func refreshPreview() {
        guard let host = activeHost, let selected = selectedEntry, !selected.isDirectory else { return }

        let remotePath = selected.fullPath
        let requestID = nextPreviewRequestID()
        worker.async { [host, remotePath] in
            let result = RemoteTransferCommand.previewFile(host: host, remotePath: remotePath)
            DispatchQueue.main.async {
                guard self.previewRequestID == requestID,
                      self.activeHost?.id == host.id,
                      self.selectedEntryID == remotePath else {
                    return
                }
                switch result {
                case .failure(let error):
                    self.previewText = "Preview error: \(error.message)"
                case .success(let content):
                    self.previewText = content
                }
            }
        }
    }

    func uploadFromPicker() {
        guard activeHost != nil else {
            statusMessage = "Select a host"
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Upload"

        guard panel.runModal() == .OK, let localURL = panel.url else { return }
        upload(localURL: localURL)
    }

    func downloadSelectionToPicker() {
        guard let selected = selectedEntry, !selected.isDirectory else {
            statusMessage = "Select a file to download"
            return
        }

        let panel = NSSavePanel()
        panel.nameFieldStringValue = selected.name
        panel.prompt = "Download"

        guard panel.runModal() == .OK, let localURL = panel.url else { return }
        download(remoteFile: selected, localURL: localURL)
    }

    func upload(localURL: URL) {
        guard let host = activeHost else { return }

        statusMessage = "Uploading \(localURL.lastPathComponent)..."
        addLog("Upload started: \(localURL.lastPathComponent)")

        worker.async { [host, remotePath = self.remotePath, localPath = localURL.path] in
            let result = RemoteTransferCommand.uploadFile(host: host, localPath: localPath, remoteDirectory: remotePath)
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.statusMessage = error.message
                    self.addLog("Upload failed: \(error.message)")
                case .success:
                    self.statusMessage = "Upload completed"
                    self.addLog("Upload completed: \((localPath as NSString).lastPathComponent)")
                    self.refresh()
                }
            }
        }
    }

    func download(remoteFile: RemoteFileItem, localURL: URL) {
        guard let host = activeHost else { return }

        statusMessage = "Downloading \(remoteFile.name)..."
        addLog("Download started: \(remoteFile.name)")

        worker.async { [host, remotePath = remoteFile.fullPath, localPath = localURL.path] in
            let result = RemoteTransferCommand.downloadFile(host: host, remotePath: remotePath, localPath: localPath)
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.statusMessage = error.message
                    self.addLog("Download failed: \(error.message)")
                case .success:
                    self.statusMessage = "Download completed"
                    self.addLog("Download completed: \((localPath as NSString).lastPathComponent)")
                    self.refresh()
                }
            }
        }
    }

    func createRemoteDirectory(named name: String) {
        guard let host = activeHost else {
            statusMessage = "Select a host"
            return
        }

        let trimmed = name.trimmed
        guard !trimmed.isEmpty else {
            statusMessage = "Folder name is empty"
            return
        }

        let destination = RemoteTransferCommand.joinRemotePath(remotePath, trimmed)
        statusMessage = "Creating folder \(trimmed)..."
        addLog("Create remote folder: \(destination)")

        worker.async { [host, destination] in
            let result = RemoteTransferCommand.createDirectory(host: host, remotePath: destination)
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.statusMessage = error.message
                    self.addLog("Create folder failed: \(error.message)")
                case .success:
                    self.statusMessage = "Folder created"
                    self.addLog("Created remote folder: \(destination)")
                    self.refresh()
                }
            }
        }
    }

    func renameRemoteItem(_ item: RemoteFileItem, to newName: String) {
        guard let host = activeHost else {
            statusMessage = "Select a host"
            return
        }

        let trimmed = newName.trimmed
        guard !trimmed.isEmpty else {
            statusMessage = "New name is empty"
            return
        }

        let parent = RemoteTransferCommand.parentPath(item.fullPath)
        let destination = RemoteTransferCommand.joinRemotePath(parent, trimmed)
        statusMessage = "Renaming \(item.name)..."
        addLog("Rename remote: \(item.fullPath) -> \(destination)")

        worker.async { [host, source = item.fullPath, destination] in
            let result = RemoteTransferCommand.renamePath(host: host, from: source, to: destination)
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.statusMessage = error.message
                    self.addLog("Rename failed: \(error.message)")
                case .success:
                    self.statusMessage = "Rename completed"
                    self.addLog("Renamed remote: \(source) -> \(destination)")
                    self.refresh()
                }
            }
        }
    }

    func deleteRemoteItem(_ item: RemoteFileItem) {
        guard let host = activeHost else {
            statusMessage = "Select a host"
            return
        }

        statusMessage = "Deleting \(item.name)..."
        addLog("Delete remote: \(item.fullPath)")

        worker.async { [host, item] in
            let result = RemoteTransferCommand.deletePath(host: host, remotePath: item.fullPath, isDirectory: item.isDirectory)
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    self.statusMessage = error.message
                    self.addLog("Delete failed: \(error.message)")
                case .success:
                    self.statusMessage = "Delete completed"
                    self.addLog("Deleted remote: \(item.fullPath)")
                    self.refresh()
                }
            }
        }
    }

    private var selectedEntry: RemoteFileItem? {
        guard let selectedEntryID else { return nil }
        return entries.first(where: { $0.id == selectedEntryID })
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = nil

        guard autoRefreshEnabled, let host = activeHost else { return }

        let interval = TimeInterval(max(1, min(60, host.fileTransfer.autoRefreshSeconds)))
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.refresh()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func addLog(_ message: String) {
        let timestamp = Self.timeFormatter.string(from: Date())
        logs.append("[\(timestamp)] \(message)")
        if logs.count > 200 {
            logs.removeFirst(logs.count - 200)
        }
    }

    private func nextListRequestID() -> UInt64 {
        listRequestID &+= 1
        return listRequestID
    }

    private func nextPreviewRequestID() -> UInt64 {
        previewRequestID &+= 1
        return previewRequestID
    }

    private func cancelPendingRequests() {
        listRequestID &+= 1
        previewRequestID &+= 1
        isBusy = false
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

struct FileTransferPane: View {
    @ObservedObject var service: RemoteFileService
    let hosts: [HostEntry]
    @Binding var selectedHostID: UUID?
    @State private var localPath: String = NSHomeDirectory()
    @State private var localEntries: [LocalFileItem] = []
    @State private var selectedLocalEntryID: String?
    @State private var localStatusMessage: String = ""
    @State private var activePanel: CommanderPanel = .local
    @State private var previewTitle: String = ""
    @State private var previewText: String = ""
    @State private var isPreviewPresented: Bool = false
    @State private var isRenamePresented: Bool = false
    @State private var renameDraft: String = ""
    @State private var isNewFolderPresented: Bool = false
    @State private var newFolderDraft: String = ""
    @State private var deleteTarget: DeleteTarget?

    private enum CommanderPanel {
        case local
        case remote
    }

    private struct LocalFileItem: Identifiable, Hashable {
        var id: String { fullPath }
        let name: String
        let fullPath: String
        let isDirectory: Bool
        let sizeText: String
        let modifiedText: String
    }

    private struct DeleteTarget: Identifiable {
        let id = UUID()
        let panel: CommanderPanel
        let name: String
        let remoteItem: RemoteFileItem?
        let localPath: String?
        let isDirectory: Bool
    }

    private var selectedHost: HostEntry? {
        if let selectedHostID {
            return hosts.first(where: { $0.id == selectedHostID })
        }
        return hosts.first
    }

    private var selectedLocalEntry: LocalFileItem? {
        guard let selectedLocalEntryID else { return nil }
        return localEntries.first(where: { $0.id == selectedLocalEntryID })
    }

    private var selectedRemoteEntry: RemoteFileItem? {
        guard let selectedID = service.selectedEntryID else { return nil }
        return service.entries.first(where: { $0.id == selectedID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            commanderTopBar
            mainPanels
            commandBar
            transferLog
            statusBar
        }
        .controlSize(.small)
        .padding(8)
        .background(RadixTheme.surface)
        .onAppear {
            if selectedHostID == nil {
                selectedHostID = hosts.first?.id
            }
            service.activate(host: selectedHost)
            refreshLocal()
        }
        .onChange(of: selectedHostID) { _ in
            service.activate(host: selectedHost)
        }
        .onChange(of: service.selectedEntryID) { _ in
            service.handleSelectionChange()
            if service.selectedEntryID != nil {
                activePanel = .remote
            }
        }
        .onChange(of: selectedLocalEntryID) { _ in
            if selectedLocalEntryID != nil {
                activePanel = .local
            }
        }
        .sheet(isPresented: $isPreviewPresented) {
            previewSheet
        }
        .sheet(isPresented: $isRenamePresented) {
            renameSheet
        }
        .sheet(isPresented: $isNewFolderPresented) {
            newFolderSheet
        }
        .alert(item: $deleteTarget) { target in
            Alert(
                title: Text("Delete \(target.isDirectory ? "folder" : "file")?"),
                message: Text(target.name),
                primaryButton: .destructive(Text("Delete")) {
                    applyDelete(target)
                },
                secondaryButton: .cancel()
            )
        }
        .background(
            FunctionKeyCaptureView { key in
                handleFunctionKey(key)
            }
        )
    }

    private var commanderTopBar: some View {
        HStack(spacing: 8) {
            Text("Commander Transfer")
                .font(.system(size: 13, weight: .semibold))

            Divider().frame(height: 14)

            Picker("Host", selection: $selectedHostID) {
                ForEach(hosts) { host in
                    Text(host.displayName).tag(Optional(host.id))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 250)
            .disabled(hosts.isEmpty)

            if let selectedHost {
                Text(selectedHost.fileTransfer.protocolMode.title)
                    .font(.caption)
                    .foregroundStyle(RadixTheme.textMuted)
            }

            Spacer(minLength: 6)

            Toggle("Auto", isOn: Binding(
                get: { service.autoRefreshEnabled },
                set: { service.setAutoRefresh($0) }
            ))
            .toggleStyle(.switch)
            Toggle("Preview", isOn: Binding(
                get: { service.livePreviewEnabled },
                set: { service.setLivePreview($0) }
            ))
            .toggleStyle(.switch)
        }
    }

    private var mainPanels: some View {
        HSplitView {
            localPanel
            remotePanel
        }
        .frame(minHeight: 360)
    }

    private var localPanel: some View {
        VStack(spacing: 0) {
            panelHeader(title: "LOCAL", subtitle: localPath)
            panelPathBar(
                path: $localPath,
                onUp: goLocalUp,
                onOpen: refreshLocal
            )
            listHeader
            List(localEntries, selection: $selectedLocalEntryID) { item in
                fileRow(
                    icon: item.isDirectory ? "folder" : "doc",
                    name: item.name,
                    sizeText: item.sizeText,
                    modifiedText: item.modifiedText
                )
                .tag(item.id)
                .onTapGesture {
                    activePanel = .local
                }
                .onTapGesture(count: 2) {
                    openLocal(item)
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 18)
            panelFooter(text: "\(localEntries.count) items")
        }
        .overlay(Rectangle().stroke(activePanel == .local ? RadixTheme.accent : RadixTheme.border, lineWidth: 1))
    }

    private var remotePanel: some View {
        VStack(spacing: 0) {
            panelHeader(title: "REMOTE", subtitle: service.remotePath)
            panelPathBar(
                path: $service.remotePath,
                onUp: service.goUp,
                onOpen: service.refresh
            )
            listHeader
            List(service.entries, selection: $service.selectedEntryID) { item in
                fileRow(
                    icon: item.isDirectory ? "folder.fill" : "doc.text",
                    name: item.name,
                    sizeText: item.sizeText,
                    modifiedText: item.modifiedText
                )
                .tag(item.id)
                .onTapGesture {
                    activePanel = .remote
                }
                .onTapGesture(count: 2) {
                    service.open(item: item)
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 18)
            panelFooter(text: "\(service.entries.count) items")
        }
        .overlay(Rectangle().stroke(activePanel == .remote ? RadixTheme.accent : RadixTheme.border, lineWidth: 1))
    }

    private func panelHeader(title: String, subtitle: String) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(RadixTheme.textMuted)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.bar)
    }

    private func panelPathBar(path: Binding<String>, onUp: @escaping () -> Void, onOpen: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Button {
                onUp()
            } label: {
                Image(systemName: "arrow.up.to.line")
            }
            .buttonStyle(.borderless)

            TextField("", text: path)
                .textFieldStyle(.roundedBorder)
                .onSubmit(onOpen)

            Button("Open", action: onOpen)
                .buttonStyle(.bordered)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
    }

    private var listHeader: some View {
        HStack(spacing: 6) {
            Text("Name")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Size")
                .frame(width: 84, alignment: .trailing)
            Text("Modified")
                .frame(width: 132, alignment: .leading)
        }
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(RadixTheme.surfaceSubtle)
    }

    private func fileRow(icon: String, name: String, sizeText: String, modifiedText: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .frame(width: 14)
                .foregroundStyle(.secondary)
            Text(name)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(sizeText)
                .font(.caption2)
                .foregroundStyle(RadixTheme.textMuted)
                .frame(width: 84, alignment: .trailing)
            Text(modifiedText)
                .font(.caption2)
                .foregroundStyle(RadixTheme.textMuted)
                .frame(width: 132, alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    private func panelFooter(text: String) -> some View {
        HStack {
            Text(text)
                .font(.caption2)
                .foregroundStyle(RadixTheme.textMuted)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.bar)
    }

    private var commandBar: some View {
        HStack(spacing: 8) {
            Button("F3 View") {
                viewSelected()
            }
            .buttonStyle(.bordered)

            Button("F4 Edit") {
                editSelected()
            }
            .buttonStyle(.bordered)

            Button("F5 Copy") {
                copyBetweenPanels()
            }
            .buttonStyle(.borderedProminent)

            Button("F6 Rename") {
                presentRename()
            }
            .buttonStyle(.bordered)

            Button("F7 MkDir") {
                presentNewFolder()
            }
            .buttonStyle(.bordered)

            Button("F8 Delete") {
                presentDelete()
            }
            .buttonStyle(.bordered)

            Button("Refresh") {
                refreshLocal()
                service.refresh()
            }
            .keyboardShortcut("r", modifiers: [.command])
            .buttonStyle(.bordered)

            Spacer()

            if service.isBusy {
                ProgressView().scaleEffect(0.7)
            }
        }
    }

    private var previewSheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(previewTitle)
                .font(.headline)
            ScrollView {
                Text(previewText.ifEmpty("No preview"))
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            HStack {
                Spacer()
                Button("Close") {
                    isPreviewPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
        .frame(minWidth: 680, minHeight: 420)
    }

    private var renameSheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rename")
                .font(.headline)
            TextField("New name", text: $renameDraft)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") {
                    isRenamePresented = false
                }
                Button("Apply") {
                    applyRename()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
        .frame(width: 420)
    }

    private var newFolderSheet: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("New Folder")
                .font(.headline)
            TextField("Folder name", text: $newFolderDraft)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") {
                    isNewFolderPresented = false
                }
                Button("Create") {
                    applyNewFolder()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(12)
        .frame(width: 420)
    }

    private var transferLog: some View {
        let recentLogs = Array(service.logs.suffix(8))
        return ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(recentLogs.indices, id: \.self) { idx in
                    let log = recentLogs[idx]
                    Text(log)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .frame(minHeight: 60, maxHeight: 82)
        .overlay(Rectangle().stroke(RadixTheme.border, lineWidth: 1))
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Text(service.statusMessage)
                .font(.caption2)
                .foregroundStyle(RadixTheme.textMuted)
                .lineLimit(1)
            if !localStatusMessage.isEmpty {
                Text(localStatusMessage)
                    .font(.caption2)
                    .foregroundStyle(RadixTheme.textMuted)
                    .lineLimit(1)
            }
            Spacer()
        }
    }

    private func refreshLocal() {
        let normalized = normalizeLocalPath(localPath)
        localPath = normalized
        let url = URL(fileURLWithPath: normalized)

        do {
            let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
            let urls = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsHiddenFiles]
            )

            let mapped = urls.compactMap { itemURL -> LocalFileItem? in
                let values = try? itemURL.resourceValues(forKeys: Set(keys))
                let isDirectory = values?.isDirectory ?? false
                let size = values?.fileSize ?? 0
                let modified = values?.contentModificationDate
                return LocalFileItem(
                    name: itemURL.lastPathComponent,
                    fullPath: itemURL.path,
                    isDirectory: isDirectory,
                    sizeText: isDirectory ? "<DIR>" : ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file),
                    modifiedText: modified.map(Self.localDateFormatter.string(from:)) ?? "-"
                )
            }

            localEntries = mapped.sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory && !rhs.isDirectory
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            if let selected = selectedLocalEntryID, !localEntries.contains(where: { $0.id == selected }) {
                selectedLocalEntryID = nil
            }
            localStatusMessage = "\(localEntries.count) item(s) in \(normalized)"
        } catch {
            localEntries = []
            selectedLocalEntryID = nil
            localStatusMessage = "Local list error: \(error.localizedDescription)"
        }
    }

    private func normalizeLocalPath(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return NSHomeDirectory()
        }
        return NSString(string: trimmed).expandingTildeInPath
    }

    private func goLocalUp() {
        let current = URL(fileURLWithPath: normalizeLocalPath(localPath))
        let parent = current.deletingLastPathComponent()
        localPath = parent.path
        refreshLocal()
    }

    private func openLocal(_ item: LocalFileItem) {
        guard item.isDirectory else {
            selectedLocalEntryID = item.id
            return
        }
        localPath = item.fullPath
        selectedLocalEntryID = nil
        refreshLocal()
    }

    private func uploadSelectedLocal() {
        guard let selected = selectedLocalEntry, !selected.isDirectory else { return }
        service.upload(localURL: URL(fileURLWithPath: selected.fullPath))
    }

    private func downloadSelectedRemote() {
        guard let selected = selectedRemoteEntry, !selected.isDirectory else { return }
        let localDir = URL(fileURLWithPath: normalizeLocalPath(localPath))
        let destination = uniqueLocalDestination(in: localDir, preferredName: selected.name)
        service.download(remoteFile: selected, localURL: destination)
    }

    private func handleFunctionKey(_ key: FunctionKeyCaptureView.Key) -> Bool {
        switch key {
        case .f3:
            viewSelected()
        case .f4:
            editSelected()
        case .f5:
            copyBetweenPanels()
        case .f6:
            presentRename()
        case .f7:
            presentNewFolder()
        case .f8:
            presentDelete()
        }
        return true
    }

    private func viewSelected() {
        switch activePanel {
        case .local:
            guard let entry = selectedLocalEntry, !entry.isDirectory else { return }
            previewLocalFile(path: entry.fullPath, title: entry.name)
        case .remote:
            guard let entry = selectedRemoteEntry, let host = selectedHost else { return }
            if entry.isDirectory {
                service.open(item: entry)
                return
            }
            previewTitle = entry.name
            previewText = "Loading..."
            isPreviewPresented = true
            DispatchQueue.global(qos: .userInitiated).async {
                let result = RemoteTransferCommand.previewFile(host: host, remotePath: entry.fullPath)
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        previewText = "Preview error: \(error.message)"
                    case .success(let content):
                        previewText = content.ifEmpty("No preview")
                    }
                }
            }
        }
    }

    private func editSelected() {
        switch activePanel {
        case .local:
            guard let entry = selectedLocalEntry, !entry.isDirectory else { return }
            NSWorkspace.shared.open(URL(fileURLWithPath: entry.fullPath))
        case .remote:
            guard let entry = selectedRemoteEntry, !entry.isDirectory, let host = selectedHost else { return }
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension((entry.name as NSString).pathExtension)
            service.statusMessage = "Downloading \(entry.name) for edit..."
            DispatchQueue.global(qos: .userInitiated).async {
                let result = RemoteTransferCommand.downloadFile(host: host, remotePath: entry.fullPath, localPath: tempURL.path)
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        service.statusMessage = error.message
                    case .success:
                        NSWorkspace.shared.open(tempURL)
                        service.statusMessage = "Opened \(entry.name)"
                    }
                }
            }
        }
    }

    private func copyBetweenPanels() {
        switch activePanel {
        case .local:
            uploadSelectedLocal()
        case .remote:
            downloadSelectedRemote()
        }
    }

    private func presentRename() {
        switch activePanel {
        case .local:
            guard let entry = selectedLocalEntry else { return }
            renameDraft = entry.name
        case .remote:
            guard let entry = selectedRemoteEntry else { return }
            renameDraft = entry.name
        }
        isRenamePresented = true
    }

    private func applyRename() {
        let trimmed = renameDraft.trimmed
        guard !trimmed.isEmpty else { return }
        switch activePanel {
        case .local:
            guard let entry = selectedLocalEntry else { return }
            let source = URL(fileURLWithPath: entry.fullPath)
            let destination = source.deletingLastPathComponent().appendingPathComponent(trimmed)
            guard !FileManager.default.fileExists(atPath: destination.path) else {
                localStatusMessage = "Rename error: destination already exists"
                return
            }
            do {
                try FileManager.default.moveItem(at: source, to: destination)
                localStatusMessage = "Renamed \(entry.name) -> \(trimmed)"
                refreshLocal()
            } catch {
                localStatusMessage = "Rename error: \(error.localizedDescription)"
            }
        case .remote:
            guard let entry = selectedRemoteEntry else { return }
            service.renameRemoteItem(entry, to: trimmed)
        }
        isRenamePresented = false
    }

    private func presentNewFolder() {
        newFolderDraft = ""
        isNewFolderPresented = true
    }

    private func applyNewFolder() {
        let trimmed = newFolderDraft.trimmed
        guard !trimmed.isEmpty else { return }
        switch activePanel {
        case .local:
            let destination = URL(fileURLWithPath: normalizeLocalPath(localPath)).appendingPathComponent(trimmed)
            do {
                try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
                localStatusMessage = "Created folder \(trimmed)"
                refreshLocal()
            } catch {
                localStatusMessage = "Create folder error: \(error.localizedDescription)"
            }
        case .remote:
            service.createRemoteDirectory(named: trimmed)
        }
        isNewFolderPresented = false
    }

    private func presentDelete() {
        switch activePanel {
        case .local:
            guard let entry = selectedLocalEntry else { return }
            deleteTarget = DeleteTarget(
                panel: .local,
                name: entry.name,
                remoteItem: nil,
                localPath: entry.fullPath,
                isDirectory: entry.isDirectory
            )
        case .remote:
            guard let entry = selectedRemoteEntry else { return }
            deleteTarget = DeleteTarget(
                panel: .remote,
                name: entry.name,
                remoteItem: entry,
                localPath: nil,
                isDirectory: entry.isDirectory
            )
        }
    }

    private func applyDelete(_ target: DeleteTarget) {
        switch target.panel {
        case .local:
            guard let path = target.localPath else { return }
            do {
                var trashedURL: NSURL?
                try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: &trashedURL)
                localStatusMessage = "Deleted \(target.name)"
                refreshLocal()
            } catch {
                localStatusMessage = "Delete error: \(error.localizedDescription)"
            }
        case .remote:
            guard let item = target.remoteItem else { return }
            service.deleteRemoteItem(item)
        }
    }

    private func previewLocalFile(path: String, title: String) {
        let url = URL(fileURLWithPath: path)
        do {
            let data = try Data(contentsOf: url, options: [.mappedIfSafe])
            let clipped = data.prefix(65_536)
            if let text = String(data: clipped, encoding: .utf8) ?? String(data: clipped, encoding: .ascii) {
                previewTitle = title
                previewText = text
                isPreviewPresented = true
            } else {
                previewTitle = title
                previewText = "Binary file preview is not available."
                isPreviewPresented = true
            }
        } catch {
            localStatusMessage = "Preview error: \(error.localizedDescription)"
        }
    }

    private func uniqueLocalDestination(in directory: URL, preferredName: String) -> URL {
        let baseName = (preferredName as NSString).deletingPathExtension
        let ext = (preferredName as NSString).pathExtension
        var candidate = directory.appendingPathComponent(preferredName)
        guard FileManager.default.fileExists(atPath: candidate.path) else { return candidate }

        var index = 1
        while index < 10_000 {
            let suffix = " copy \(index)"
            let name = ext.isEmpty ? "\(baseName)\(suffix)" : "\(baseName)\(suffix).\(ext)"
            candidate = directory.appendingPathComponent(name)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }

        return directory.appendingPathComponent(UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)"))
    }

    private static let localDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}

struct FunctionKeyCaptureView: NSViewRepresentable {
    enum Key {
        case f3
        case f4
        case f5
        case f6
        case f7
        case f8
    }

    let onKey: (Key) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(onKey: onKey)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        context.coordinator.install()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onKey = onKey
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator {
        var onKey: (Key) -> Bool
        private var monitor: Any?

        init(onKey: @escaping (Key) -> Bool) {
            self.onKey = onKey
        }

        func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self else { return event }
                guard event.modifierFlags.intersection([.command, .option, .control]).isEmpty else {
                    return event
                }
                guard let key = Self.mapFunctionKey(event.keyCode) else { return event }
                let handled = self.onKey(key)
                return handled ? nil : event
            }
        }

        func uninstall() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        private static func mapFunctionKey(_ keyCode: UInt16) -> Key? {
            switch keyCode {
            case 99: return .f3
            case 118: return .f4
            case 96: return .f5
            case 97: return .f6
            case 98: return .f7
            case 100: return .f8
            default: return nil
            }
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmed.isEmpty ? fallback : self
    }
}
