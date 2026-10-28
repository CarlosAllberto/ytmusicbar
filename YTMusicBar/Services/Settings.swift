import Foundation

/// Configurações simples em UserDefaults. @AppStorage só funciona dentro de views SwiftUI,
/// e este app é AppKit puro, então usamos UserDefaults direto.
enum Settings {
    private static let d = UserDefaults.standard

    static var keepOrder: Bool {
        get { d.object(forKey: "keepOrder") as? Bool ?? true }
        set { d.set(newValue, forKey: "keepOrder") }
    }
    static var globalShortcut: Bool {
        get { d.object(forKey: "globalShortcut") as? Bool ?? true }
        set { d.set(newValue, forKey: "globalShortcut") }
    }
}
