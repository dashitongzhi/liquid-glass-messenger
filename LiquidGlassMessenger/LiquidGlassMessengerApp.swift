import SwiftUI

@main
struct LiquidGlassMessengerApp: App {
    @StateObject private var store = MessengerStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
