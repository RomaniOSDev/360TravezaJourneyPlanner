import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DataStore
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Settings")
                    .font(.system(.title, design: .serif).weight(.bold))
                    .foregroundColor(.white)
                Text("Housekeeping for saved trips, kits, and notes.")
                    .foregroundColor(.white.opacity(0.75))

                RaisedButton(title: "Rate Us", systemImage: "star.fill") {
                    viewModel.rateApp()
                }
                RaisedButton(title: "Privacy", systemImage: "hand.raised.fill") {
                    viewModel.openPrivacy()
                }
                RaisedButton(title: "Terms", systemImage: "doc.text.fill") {
                    viewModel.openTerms()
                }

                Button {
                    viewModel.confirmReset = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset All Data")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color("AppPrimary"), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(18)
        }
        .canvasBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset all destinations, contacts, kits, and notes?", isPresented: $viewModel.confirmReset, titleVisibility: .visible) {
            Button("Reset All Data", role: .destructive) { store.resetAllData() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
