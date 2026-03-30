import SwiftUI

struct FartButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(role: nil) {
            SoundPlayer.shared.playFart()
            configuration.trigger()
        } label: {
            configuration.label
        }
        .buttonStyle(.bordered)
    }
}
