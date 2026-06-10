import Foundation

protocol PersistenceStore: AnyObject {
    var completedLevels: Set<Int> { get set }
    var isUnlocked: Bool { get set }
}

final class UserDefaultsStore: PersistenceStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var completedLevels: Set<Int> {
        get {
            let ids = defaults.array(forKey: "completedLevels") as? [Int] ?? []
            return Set(ids)
        }
        set {
            defaults.set(Array(newValue), forKey: "completedLevels")
        }
    }

    var isUnlocked: Bool {
        get { defaults.bool(forKey: "isUnlocked") }
        set { defaults.set(newValue, forKey: "isUnlocked") }
    }
}
