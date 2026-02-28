import Foundation

final class ProcessPipeReader: @unchecked Sendable {
    private let handle: FileHandle
    private let group = DispatchGroup()
    private var data = Data()
    private let lock = NSLock()

    init(handle: FileHandle) {
        self.handle = handle
    }

    func begin() {
        group.enter()
        handle.readabilityHandler = { [weak self] handle in
            guard let self else { return }
            let chunk = handle.availableData
            if chunk.isEmpty {
                handle.readabilityHandler = nil
                self.group.leave()
                return
            }

            self.lock.lock()
            self.data.append(chunk)
            self.lock.unlock()
        }
    }

    func finish() -> Data {
        group.wait()
        lock.lock()
        let result = data
        lock.unlock()
        return result
    }
}
