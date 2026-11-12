import SwiftUI
import Playgrounds

struct ContentView: View {
    @State private var enteredMain = false

    var body: some View {
        Group {
            if enteredMain {
                MainTabView()
            } else {
                EntryView(enteredMain: $enteredMain)
            }
        }
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
