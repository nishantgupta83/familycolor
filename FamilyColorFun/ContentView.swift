import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    enum Tab {
        case home, gallery
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "paintpalette.fill")
                }
                .tag(Tab.home)

            GalleryView()
                .tabItem {
                    Image(systemName: "photo.stack.fill")
                }
                .tag(Tab.gallery)
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
}
