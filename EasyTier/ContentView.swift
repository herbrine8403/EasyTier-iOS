import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            TabView {
                DashboardView()
                    .tabItem {
                        Image(systemName: "list.bullet.below.rectangle")
                        Text("Dashboard")
                    }
                Text("Not Implemented")
                    .tabItem {
                        Image(systemName: "rectangle.and.text.magnifyingglass")
                        Text("Logs")
                    }
                Text("Not Implemented")
                    .tabItem {
                        Image(systemName: "gearshape")
                            .environment(\.symbolVariants, .none)
                        Text("Settings")
                    }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
