import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var tunerVM = TunerViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            Color(white: 0.06).ignoresSafeArea()

            TabView(selection: $selectedTab) {
                TunerView(vm: tunerVM)
                    .tabItem {
                        Label("Tuner", systemImage: "waveform")
                    }
                    .tag(0)

                MetronomeView()
                    .tabItem {
                        Label("Metronome", systemImage: "metronome.fill")
                    }
                    .tag(1)
            }
            .tint(.green)
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

#Preview {
    ContentView()
}
