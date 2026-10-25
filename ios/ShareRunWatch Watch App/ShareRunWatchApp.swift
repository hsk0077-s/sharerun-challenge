import SwiftUI

@main
struct ShareRunWatchApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    @StateObject private var accountManager = WatchAccountManager()
    @StateObject private var syncQueue = WatchSyncQueue()
    @StateObject private var connectivity = WatchConnectivityReceiver()

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(workoutManager)
                .environmentObject(accountManager)
                .environmentObject(syncQueue)
                .environmentObject(connectivity)
                .onAppear {
                    connectivity.bind(account: accountManager, queue: syncQueue)
                    Task {
                        await syncQueue.flush(using: accountManager)
                    }
                }
        }
    }
}
