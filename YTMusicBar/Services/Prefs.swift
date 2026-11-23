import Foundation

/// Configurações simples (não é "Settings" para não colidir com a cena do SwiftUI) em UserDefaults, lidas fora das views (Player e menu do tray).
enum Prefs {
    private static let d = UserDefaults.standard

    /// Ao fim da fila, para em vez de deixar o YouTube seguir com a rádio automática.
    static var keepOrder: Bool {
        get { d.object(forKey: "keepOrder") as? Bool ?? true }
        set { d.set(newValue, forKey: "keepOrder") }
    }
}
