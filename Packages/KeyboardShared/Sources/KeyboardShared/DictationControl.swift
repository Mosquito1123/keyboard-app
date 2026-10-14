import Foundation

/// Coordinates one dictation attempt between the keyboard (or the app) and the recognizer.
/// A second tap calls `requestFinish()` so the best transcript is kept.
/// Leaving the keyboard calls `cancel()` so nothing is inserted.
public final class DictationControl: @unchecked Sendable {
    private let lock = NSLock()
    private var finishHandler: (@Sendable () -> Void)?
    private var cancelHandler: (@Sendable () -> Void)?
    private var partialHandler: (@Sendable (String) -> Void)?
    private var finishRequested = false
    private var cancelRequested = false

    public init() {}

    public var isFinishRequested: Bool {
        lock.lock()
        defer { lock.unlock() }
        return finishRequested
    }

    public var isCancelRequested: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelRequested
    }

    /// Sticky. If finish was already requested, the handler runs immediately.
    public func onFinish(_ handler: @escaping @Sendable () -> Void) {
        let already: Bool
        lock.lock()
        finishHandler = handler
        already = finishRequested
        lock.unlock()
        if already {
            handler()
        }
    }

    /// Sticky. If cancel was already requested, the handler runs immediately.
    public func onCancel(_ handler: @escaping @Sendable () -> Void) {
        let already: Bool
        lock.lock()
        cancelHandler = handler
        already = cancelRequested
        lock.unlock()
        if already {
            handler()
        }
    }

    public func onPartial(_ handler: @escaping @Sendable (String) -> Void) {
        lock.lock()
        partialHandler = handler
        lock.unlock()
    }

    public func requestFinish() {
        let handler: (@Sendable () -> Void)?
        lock.lock()
        finishRequested = true
        handler = finishHandler
        lock.unlock()
        handler?()
    }

    public func cancel() {
        let handler: (@Sendable () -> Void)?
        lock.lock()
        cancelRequested = true
        handler = cancelHandler
        lock.unlock()
        handler?()
    }

    func publishPartial(_ text: String) {
        let handler: (@Sendable (String) -> Void)?
        lock.lock()
        handler = partialHandler
        lock.unlock()
        handler?(text)
    }
}
