import Foundation

enum Configuration {
    static var isDevelopmentMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static var backendURL: String {
        #if DEBUG
        return "http://192.168.1.18:8000"
        #else
        return "https://api.flicks.app"
        #endif
    }
}
