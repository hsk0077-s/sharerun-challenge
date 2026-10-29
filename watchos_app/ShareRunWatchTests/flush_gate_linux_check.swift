// Linux check for the flush lock. Does not boot a watch.
// swiftc ShareRunWatch/WatchFlushGate.swift ShareRunWatchTests/flush_gate_linux_check.swift

var gate = WatchFlushGate()
precondition(gate.tryBegin(), "first flush takes the lock")
precondition(!gate.tryBegin(), "overlapping flush is refused")
gate.end()
precondition(gate.tryBegin(), "the lock opens after end")
gate.end()
precondition(gate.tryBegin(), "a later flush can start")
