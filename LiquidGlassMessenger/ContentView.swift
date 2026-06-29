import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: MessengerStore

    var body: some View {
        if ProcessInfo.processInfo.arguments.contains("--open-thread"),
           let first = store.conversations.first {
            NavigationStack {
                ChatThreadView(conversationID: first.id)
            }
            .tint(LGDesign.sentBlue)
        } else {
            TabView(selection: $store.tab) {
                ConversationListView()
                    .tabItem {
                        Label(AppTab.messages.title, systemImage: AppTab.messages.symbol)
                    }
                    .tag(AppTab.messages)

                ContactsView()
                    .tabItem {
                        Label(AppTab.contacts.title, systemImage: AppTab.contacts.symbol)
                    }
                    .tag(AppTab.contacts)

                DiscoverView()
                    .tabItem {
                        Label(AppTab.discover.title, systemImage: AppTab.discover.symbol)
                    }
                    .tag(AppTab.discover)

                ProfileView()
                    .tabItem {
                        Label(AppTab.profile.title, systemImage: AppTab.profile.symbol)
                    }
                    .tag(AppTab.profile)
            }
            .tint(LGDesign.sentBlue)
        }
    }
}

private struct ContactsView: View {
    @EnvironmentObject private var store: MessengerStore

    var contacts: [Participant] {
        Array(Set(store.conversations.flatMap(\.participants)))
            .sorted { $0.displayName < $1.displayName }
            .filter { $0.id != DemoData.currentUserID }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(contacts) { contact in
                        HStack(spacing: 12) {
                            AvatarView(participant: contact, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contact.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                Text(contact.handle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle("Contacts")
        }
    }
}

private struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Moments", systemImage: "sparkles")
                    Label("Scan", systemImage: "qrcode.viewfinder")
                    Label("Mini Programs", systemImage: "app.connected.to.app.below.fill")
                }

                Section {
                    Label("Stickers", systemImage: "face.smiling")
                    Label("Channels", systemImage: "play.rectangle.fill")
                }
            }
            .navigationTitle("Discover")
        }
    }
}

private struct ProfileView: View {
    @EnvironmentObject private var store: MessengerStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        AvatarView(participant: Participant(id: DemoData.currentUserID, displayName: "Kral", handle: "me", monogram: "K", tintHex: "007AFF", presence: .online), size: 58)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Kral")
                                .font(.system(size: 21, weight: .semibold))
                            Text("WeChat ID: official bridge demo")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Bridge") {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("WeChat Integration", systemImage: "link.circle.fill")
                    }

                    Button {
                        Task { await store.refreshFromWeChat() }
                    } label: {
                        Label("Refresh Capabilities", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationTitle("Me")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(MessengerStore())
}
