import Foundation

/// Same idea as Wear OS `SyncQueue.tryBeginFlush`.
/// Two flushes can overlap on an actor because `await` gives the actor back.
/// The second one must send nothing.
struct WatchFlushGate {
    private var flushing = false

    mutating func tryBegin() -> Bool {
        if flushing { return false }
        flushing = true
        return true
    }

    mutating func end() {
        flushing = false
    }
}
