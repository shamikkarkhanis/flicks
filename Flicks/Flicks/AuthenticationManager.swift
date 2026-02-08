import Foundation
import AuthenticationServices
import Security
import UIKit

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private let tokenKey = "com.flicks.sessionToken"
    
    override init() {
        super.init()
        self.isAuthenticated = getToken() != nil
    }
    
    func handleSignInWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func handleAuthorization(_ authorization: ASAuthorization) {
        processAuthorization(authorization)
    }
    
    func loginAsDev() {
        guard Configuration.isDevelopmentMode else { return }
        saveToken("dev-session-token")
        isAuthenticated = true
    }
    
    func signOut() {
        deleteToken()
        isAuthenticated = false
    }
    
    private func processAuthorization(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let idTokenString = String(data: identityToken, encoding: .utf8),
              let authorizationCode = appleIDCredential.authorizationCode,
              let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
            return
        }
        
        Task {
            do {
                isLoading = true
                try await sendToBackend(idToken: idTokenString, authCode: authCodeString)
                isLoading = false
            } catch {
                self.error = error
                isLoading = false
            }
        }
    }
    
    // MARK: - Keychain Helpers
    
    private func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)
    }
}

extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        processAuthorization(authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = error
    }
    
    private func sendToBackend(idToken: String, authCode: String) async throws {
        guard let url = URL(string: "\(Configuration.backendURL)/auth/apple") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "id_token": idToken,
            "auth_code": authCode
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Backend authentication failed"])
        }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let sessionToken = json["session_token"] as? String {
            saveToken(sessionToken)
            isAuthenticated = true
        }
    }
}

extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first as? UIWindowScene
        return windowScene?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}
