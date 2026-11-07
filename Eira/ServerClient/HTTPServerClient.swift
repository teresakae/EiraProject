import Foundation

enum ServerClientError: Error { case notConfigured, insecureAddress, invalidResponse, http(Int) }

struct HTTPServerClient: ServerClient {
    private let baseURL: URL?
    private let token: String
    private let session: URLSession

    init(baseURL: URL?, token: String, session: URLSession? = nil) {
        self.baseURL = baseURL
        self.token = token
        if let session { self.session = session }
        else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.urlCache = nil
            configuration.httpCookieStorage = nil
            configuration.httpShouldSetCookies = false
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
            configuration.timeoutIntervalForRequest = 90
            configuration.timeoutIntervalForResource = 120
            self.session = URLSession(configuration: configuration, delegate: NoRedirects(), delegateQueue: nil)
        }
    }

    static func configured() -> HTTPServerClient {
        let address = Bundle.main.object(forInfoDictionaryKey: "EiraServerURL") as? String ?? ""
        let token = Bundle.main.object(forInfoDictionaryKey: "EiraAppToken") as? String ?? ""
        return HTTPServerClient(baseURL: URL(string: address), token: token)
    }

    func cancelPendingRequests() {
        session.getAllTasks { tasks in tasks.forEach { $0.cancel() } }
    }

    private func request(_ endpoint: String, body: Data, contentType: String) async throws -> Data {
        guard let baseURL, !token.isEmpty, !token.contains("$("), baseURL.host != nil,
              baseURL.user == nil, baseURL.password == nil else { throw ServerClientError.notConfigured }
        if baseURL.scheme != "https" {
            #if DEBUG && targetEnvironment(simulator)
            guard baseURL.scheme == "http", baseURL.host == "127.0.0.1" else { throw ServerClientError.insecureAddress }
            #else
            throw ServerClientError.insecureAddress
            #endif
        }
        try Task.checkCancellation()
        var request = URLRequest(url: baseURL.appendingPathComponent("api/\(endpoint)"))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = body
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else { throw ServerClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw ServerClientError.http(http.statusCode) }
        guard data.count <= 1_000_000 else { throw ServerClientError.invalidResponse }
        return data
    }

    private func json<Input: Encodable, Output: Decodable>(_ endpoint: String, _ input: Input) async throws -> Output {
        let body = try JSONEncoder().encode(input)
        guard body.count <= 1_000_000 else { throw ServerClientError.invalidResponse }
        return try JSONDecoder().decode(Output.self,
            from: await request(endpoint, body: body, contentType: "application/json"))
    }

    func extract(_ request: ExtractRequest) async throws -> ExtractResponse { try await json("extract", request) }
    func ask(_ request: AskRequest) async throws -> AskResponse { try await json("ask", request) }
    func draft(_ request: DraftRequest) async throws -> DraftResponse { try await json("draft", request) }

    func transcribe(_ request: TranscribeRequest) async throws -> String {
        guard !request.audio.isEmpty, request.audio.count <= 4_000_000 else { throw ServerClientError.invalidResponse }
        let boundary = "Eira-\(UUID().uuidString)"
        var body = Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"language\"\r\n\r\nid\r\n".utf8)
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\nContent-Type: audio/mp4\r\n\r\n".utf8))
        body.append(request.audio)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        struct Transcript: Decodable { let text: String }
        let data = try await self.request("transcribe", body: body, contentType: "multipart/form-data; boundary=\(boundary)")
        return try JSONDecoder().decode(Transcript.self, from: data).text
    }
}

private final class NoRedirects: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}
