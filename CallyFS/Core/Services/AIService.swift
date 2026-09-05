//
//  AIService.swift
//  CallyFS
//
//  Option B: the app never holds the AI provider key. Every AI feature calls the
//  CallyFS backend, which makes the provider call server-side and returns only
//  the result. See BACKEND_BLUEPRINT.md (§5 API spec, §11 iOS integration).
//

import Foundation

// MARK: - Backend configuration

enum APIConfig {
    /// Base URL of the CallyFS backend (deployed on Vercel; deploys on push to
    /// main). For local testing, point this at your machine's LAN IP
    /// (e.g. http://192.168.1.x:8080/v1) and add an App Transport Security
    /// exception for that host.
    static let baseURL = URL(string: "https://cally-fs-backend.vercel.app/v1")!

    /// Sign in with Apple needs a paid Apple Developer account (app entitlement
    /// + backend APPLE_* env). Until both exist the backend answers 503 for it,
    /// so the UI hides the Apple button and email/password is the auth method.
    static let appleSignInEnabled = false
}

// MARK: - Auth token store

/// Holds the user's auth tokens. The access token lives in memory; the refresh
/// token is persisted in the Keychain. Populated by Sign in with Apple (auth
/// phase, blueprint §5.1). Until then both are nil and requests go out
/// unauthenticated — useful while the backend runs auth in a permissive dev mode.
final class AuthTokenStore {
    static let shared = AuthTokenStore()
    private init() {}

    /// Short-lived bearer token attached to every request when present.
    var accessToken: String?

    private let refreshKey = "callyfs_refresh_token"

    /// Long-lived refresh token, stored securely in the Keychain.
    var refreshToken: String? {
        get { KeychainManager.shared.readString(key: refreshKey) }
        set {
            if let value = newValue {
                _ = KeychainManager.shared.saveString(key: refreshKey, string: value)
            } else {
                _ = KeychainManager.shared.delete(key: refreshKey)
            }
        }
    }
}

// MARK: - API client

/// Minimal JSON client for the backend. Wraps the `{ "data": … }` /
/// `{ "error": … }` envelope used by every endpoint.
struct APIClient {
    static let shared = APIClient()
    private init() {}

    private struct DataEnvelope<T: Decodable>: Decodable { let data: T }
    private struct ErrorEnvelope: Decodable {
        struct Payload: Decodable { let code: String; let message: String }
        let error: Payload
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        try await post(path, body: body, allowAuthRetry: true)
    }

    /// `allowAuthRetry`: on a 401, refresh the session once and retry the request.
    /// Disabled for the refresh call itself (and its retry) to avoid recursion.
    func post<Body: Encodable, Response: Decodable>(
        _ path: String,
        body: Body,
        allowAuthRetry: Bool
    ) async throws -> Response {
        let url = APIConfig.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = AuthTokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        // Expired/missing access token: refresh once (single-flight) and retry.
        if http.statusCode == 401, allowAuthRetry, AuthTokenStore.shared.refreshToken != nil {
            try await TokenRefresher.shared.refreshSession()
            return try await post(path, body: body, allowAuthRetry: false)
        }

        guard (200..<300).contains(http.statusCode) else {
            if let env = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
                throw APIError.server(code: env.error.code, message: env.error.message)
            }
            throw APIError.http(status: http.statusCode)
        }

        do {
            return try JSONDecoder().decode(DataEnvelope<Response>.self, from: data).data
        } catch {
            throw APIError.decoding
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case http(status: Int)
    case server(code: String, message: String)
    case decoding
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Couldn't reach the server. Check your connection and try again."
        case .http(let status): return "Server error (\(status)). Please try again."
        case .server(_, let message): return message
        case .decoding: return "Unexpected response from the server."
        case .notSignedIn: return "Please sign in to use AI features (Settings → Account)."
        }
    }

    /// The backend's error envelope code, when this is a server error.
    var serverCode: String? {
        if case .server(let code, _) = self { return code }
        return nil
    }

    /// True when the backend rejected the call because it needs a Pro subscription (402).
    var isEntitlementRequired: Bool { serverCode == "ENTITLEMENT_REQUIRED" }

    /// True when the session itself is invalid (as opposed to a transient failure).
    var isAuthFailure: Bool {
        if case .notSignedIn = self { return true }
        if case .http(401) = self { return true }
        return serverCode == "UNAUTHENTICATED"
    }
}

// MARK: - Auth (Sign in with Apple → backend session)

/// Refreshes the backend session at most once at a time. Concurrent 401s from
/// parallel requests all await the same refresh instead of racing, which would
/// burn the rotated refresh token (the backend revokes it on first use).
actor TokenRefresher {
    static let shared = TokenRefresher()
    private var inFlight: Task<Void, Error>?

    private struct RefreshRequest: Encodable { let refreshToken: String }
    private struct RefreshResponse: Decodable { let accessToken: String; let refreshToken: String }

    func refreshSession() async throws {
        if let inFlight { return try await inFlight.value }
        guard let refreshToken = AuthTokenStore.shared.refreshToken else {
            throw APIError.notSignedIn
        }

        let task = Task<Void, Error> {
            do {
                let tokens: RefreshResponse = try await APIClient.shared.post(
                    "auth/refresh",
                    body: RefreshRequest(refreshToken: refreshToken),
                    allowAuthRetry: false
                )
                AuthTokenStore.shared.accessToken = tokens.accessToken
                AuthTokenStore.shared.refreshToken = tokens.refreshToken
            } catch {
                if let apiError = error as? APIError, apiError.isAuthFailure {
                    // The stored session is dead — clear it so the UI can offer sign-in.
                    AuthTokenStore.shared.accessToken = nil
                    AuthTokenStore.shared.refreshToken = nil
                    throw APIError.notSignedIn
                }
                throw error
            }
        }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }
}

/// App-facing account state + the /v1/auth endpoints. UI observes `isSignedIn`
/// and `displayName`; tokens live in AuthTokenStore (Keychain-backed refresh).
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var isSignedIn: Bool
    @Published private(set) var displayName: String?

    private static let displayNameKey = "account.displayName"

    private init() {
        isSignedIn = AuthTokenStore.shared.refreshToken != nil
        displayName = UserDefaults.standard.string(forKey: Self.displayNameKey)
    }

    /// Re-derive published state from the token store (e.g. after a dead session
    /// was cleared by TokenRefresher). Call from `onAppear` of account UI.
    func refreshLocalState() {
        isSignedIn = AuthTokenStore.shared.refreshToken != nil
    }

    private struct NamePayload: Encodable { let givenName: String?; let familyName: String? }
    private struct SignInRequest: Encodable {
        let identityToken: String
        let authorizationCode: String
        let fullName: NamePayload?
    }
    private struct UserPayload: Decodable { let id: String; let displayName: String?; let email: String? }
    private struct SessionResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let user: UserPayload
    }

    /// Exchange Apple's identity token for a backend session (POST /v1/auth/apple).
    func signIn(
        identityToken: String,
        authorizationCode: String,
        fullName: PersonNameComponents?
    ) async throws {
        let name = fullName.map { NamePayload(givenName: $0.givenName, familyName: $0.familyName) }
        let session: SessionResponse = try await APIClient.shared.post(
            "auth/apple",
            body: SignInRequest(identityToken: identityToken, authorizationCode: authorizationCode, fullName: name)
        )

        // Apple only provides the name on the *first* authorization, so prefer
        // the backend's stored copy and fall back to what we were just handed.
        let fallbackName = [fullName?.givenName, fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        applySession(session, fallbackName: fallbackName.isEmpty ? nil : fallbackName)
    }

    private struct RegisterRequest: Encodable {
        let email: String
        let password: String
        var displayName: String?
    }
    private struct LoginRequest: Encodable { let email: String; let password: String }

    /// Create an email/password account (POST /v1/auth/register, 201).
    func register(email: String, password: String, displayName: String?) async throws {
        let trimmedName = displayName?.trimmingCharacters(in: .whitespaces)
        let session: SessionResponse = try await APIClient.shared.post(
            "auth/register",
            body: RegisterRequest(
                email: email,
                password: password,
                displayName: (trimmedName?.isEmpty ?? true) ? nil : trimmedName
            )
        )
        applySession(session, fallbackName: trimmedName)
    }

    /// Log in with email/password (POST /v1/auth/login).
    func login(email: String, password: String) async throws {
        let session: SessionResponse = try await APIClient.shared.post(
            "auth/login",
            body: LoginRequest(email: email, password: password)
        )
        applySession(session, fallbackName: nil)
    }

    /// Store tokens + resolve display name, then flip the published state.
    private func applySession(_ session: SessionResponse, fallbackName: String?) {
        AuthTokenStore.shared.accessToken = session.accessToken
        AuthTokenStore.shared.refreshToken = session.refreshToken

        let resolved = session.user.displayName ?? fallbackName ?? session.user.email
        if let resolved {
            UserDefaults.standard.set(resolved, forKey: Self.displayNameKey)
        }

        isSignedIn = true
        displayName = resolved
    }

    /// Revoke the session server-side (best effort) and clear local credentials.
    func signOut() async {
        if let refreshToken = AuthTokenStore.shared.refreshToken {
            struct LogoutRequest: Encodable { let refreshToken: String }
            struct EmptyResponse: Decodable {}
            // 204 has no body, so decoding fails by design — the revoke still lands.
            _ = try? await APIClient.shared.post(
                "auth/logout",
                body: LogoutRequest(refreshToken: refreshToken),
                allowAuthRetry: false
            ) as EmptyResponse
        }
        AuthTokenStore.shared.accessToken = nil
        AuthTokenStore.shared.refreshToken = nil
        UserDefaults.standard.removeObject(forKey: Self.displayNameKey)
        isSignedIn = false
        displayName = nil
    }
}

// MARK: - DTOs

struct NutritionResponse: Codable {
    let calories: Int
    let protein: Double
    let carbs: Double
    let fat: Double
    // Optional metadata the backend may include (source/confidence/cache hit).
    var source: String? = nil
    var confidence: Double? = nil
    var cached: Bool? = nil
}

// MARK: - AIService (backend-backed)

final class AIService {
    static let shared = AIService()
    private init() {}

    // MARK: Nutrition  →  POST /v1/nutrition/analyze

    private struct NutritionRequest: Encodable {
        let name: String
        var quantity: Double?
        var unit: String?
    }

    func getNutritionInfo(for mealName: String) async throws -> NutritionResponse {
        try await APIClient.shared.post(
            "nutrition/analyze",
            body: NutritionRequest(name: mealName, quantity: nil, unit: nil)
        )
    }

    // MARK: Meal plans  →  POST /v1/mealplans/generate

    private struct MealPlanRequest: Encodable {
        struct Targets: Encodable {
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
        }
        let name: String
        let durationDays: Int
        let targets: Targets
        let goal: String
        let dietaryRestrictions: [String]
    }
    private struct MealPlanResult: Decodable { let planMarkdown: String }

    func generateMealPlan(
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        goal: FitnessGoal,
        dietaryRestrictions: [String],
        duration: Int = 7
    ) async throws -> String {
        // The backend validates goal against its four real values — "Not Set"
        // (the pre-onboarding default) would be rejected with a 400.
        let effectiveGoal = goal == .notSet ? FitnessGoal.maintain : goal
        let body = MealPlanRequest(
            name: name,
            durationDays: duration,
            targets: .init(calories: calories, protein: protein, carbs: carbs, fat: fat),
            goal: effectiveGoal.rawValue,
            dietaryRestrictions: dietaryRestrictions
        )
        let result: MealPlanResult = try await APIClient.shared.post("mealplans/generate", body: body)
        return result.planMarkdown
    }

    // MARK: Insights  →  POST /v1/insights/weekly

    private struct InsightsRequest: Encodable {
        struct Weekly: Encodable {
            let calories: Double
            let protein: Double
            let carbs: Double
            let fat: Double
        }
        let weekly: Weekly
        let targetCalories: Double
        let goal: String
    }
    private struct InsightsResult: Decodable {
        let assessment: String
        let recommendations: [String]
        let motivation: String
    }

    func generateInsights(
        weeklyCalories: Double,
        weeklyProtein: Double,
        weeklyCarbs: Double,
        weeklyFat: Double,
        goal: FitnessGoal,
        targetCalories: Double
    ) async throws -> String {
        let body = InsightsRequest(
            weekly: .init(calories: weeklyCalories, protein: weeklyProtein, carbs: weeklyCarbs, fat: weeklyFat),
            targetCalories: targetCalories,
            goal: goal.rawValue
        )
        let result: InsightsResult = try await APIClient.shared.post("insights/weekly", body: body)

        var parts = [result.assessment]
        if !result.recommendations.isEmpty {
            parts.append(result.recommendations.map { "•  \($0)" }.joined(separator: "\n"))
        }
        parts.append(result.motivation)
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Legacy error type
//
// Retained so existing call sites that still reference it (e.g. MealDetailView)
// continue to compile. New failures surface via `APIError` (a LocalizedError),
// so prefer `error.localizedDescription` at call sites.
enum AIServiceError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case noContent
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from the server."
        case .serverError(let code): return "Server error (code: \(code)). Please try again."
        case .noContent: return "No content received from the server."
        case .parsingFailed: return "Failed to parse the server response."
        }
    }
}
