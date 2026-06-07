import Darwin
import Foundation

private enum MagicOrbError: LocalizedError {
    case invalidHTTPResponse
    case apiRequestFailed(statusCode: Int, body: String)
    case missingOutputText

    var errorDescription: String? {
        switch self {
        case .invalidHTTPResponse:
            return "OpenAI API response was not an HTTP response."
        case let .apiRequestFailed(statusCode, body):
            return "OpenAI API request failed with status \(statusCode): \(body)"
        case .missingOutputText:
            return "OpenAI API response missing output_text."
        }
    }
}

public struct MagicOrbCLI {  
    private let apiKey: String

    public init() {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            fputs("OPENAI_API_KEY environment variable is required\n", stderr)
            exit(1)
        }
        self.apiKey = apiKey
    }

    public func look(content: String) async throws -> String {
        let questions = MagicOrbQuestionParser.extractQuestions(from: content)
        var updatedContent = content

        for questionType in QuestionType.allCases where questions[questionType]?.isEmpty == false {
            let request: URLRequest
            switch questionType {
            case .peek:
                request = try makePeekRequest(content: MagicOrbQuestionParser.questionBlocks(for: .peek, questions: questions))
            case .search:
                request = try makeSearchRequest(content: MagicOrbQuestionParser.questionBlocks(for: .search, questions: questions))
            case .ask:
                request = try makeAskRequest(content: updatedContent)
            }

            let (data, response) = try await URLSession.shared.data(for: request)
            saveResponseLog(data)
            try validate(response: response, data: data)

            let answers = try extractAnswers(from: data, for: questionType)
            updatedContent = MagicOrbQuestionParser.replaceQuestionBlocks(in: updatedContent, for: questionType, with: answers)
        }

        return updatedContent
    }

    private func makeAskRequest(content: String) throws -> URLRequest {
        let modelName = "gpt-5.5"
        let systemInstructions = """
            Look for each <<<ask ... ask>>> block in the user's input.
            Return one answer per <<<ask ... ask>>> block in the response_format.ask array, in the same order.
            Each answer must contain only replacement text for that <<<ask ... ask>>> block.
        """

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": modelName,
            "instructions": systemInstructions,
            "input": content,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "response_format",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "ask": [
                                "type": "array",
                                "items": [
                                    "type": "string"
                                ]
                            ],
                        ],
                        "required": ["ask"],
                        "additionalProperties": false
                    ],
                    "strict": true
                ]
            ]
        ])

        return request
    }

    private func makePeekRequest(content: String) throws -> URLRequest {
        let modelName = "gpt-5.4-mini"
        let systemInstructions = """
            Look for each <<<peek ... peek>>> block in the user's input.
            Return one answer per <<<peek ... peek>>> block in the response_format.peek array, in the same order.
            Each answer must contain only replacement text for that <<<peek ... peek>>> block.
        """

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": modelName,
            "instructions": systemInstructions,
            "input": content,
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "response_format",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "peek": [
                                "type": "array",
                                "items": [
                                    "type": "string"
                                ]
                            ],
                        ],
                        "required": ["peek"],
                        "additionalProperties": false
                    ],
                    "strict": true
                ]
            ]
        ])

        return request
    }
    
    private func makeSearchRequest(content: String) throws -> URLRequest {
        let modelName = "gpt-5.5"
        let systemInstructions = """
            Look for each <<<search ... search>>> block in the user's input.
            Return one answer per <<<search ... search>>> block in the response_format.search array, in the same order.
            Each answer must contain only replacement text for that <<<search ... search>>> block.
        """

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": modelName,
            "instructions": systemInstructions,
            "input": content,
            "tools": [
                [
                    "type": "web_search"
                ]
            ],
            "text": [
                "format": [
                    "type": "json_schema",
                    "name": "response_format",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "search": [
                                "type": "array",
                                "items": [
                                    "type": "string"
                                ]
                            ]
                        ],
                        "required": ["search"],
                        "additionalProperties": false
                    ],
                    "strict": true
                ]
            ]
        ])

        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MagicOrbError.invalidHTTPResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "Bad response"
            fputs("OpenAI API request failed with status \(httpResponse.statusCode): \(responseBody)\n", stderr)
            throw MagicOrbError.apiRequestFailed(statusCode: httpResponse.statusCode, body: responseBody)
        }
    }

    private func extractAnswers(from data: Data, for questionType: QuestionType) throws -> [String] {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let output = json["output"] as? [[String: Any]]
        else {
            throw MagicOrbError.missingOutputText
        }

        for item in output {
            guard let responseContent = item["content"] as? [[String: Any]] else {
                continue
            }

            for contentItem in responseContent where contentItem["type"] as? String == "output_text" {
                if let outputText = contentItem["text"] as? String {
                    guard
                        let outputData = outputText.data(using: .utf8),
                        let responseJSON = try JSONSerialization.jsonObject(with: outputData) as? [String: Any],
                        let answers = responseJSON[questionType.rawValue] as? [String]
                    else {
                        throw MagicOrbError.missingOutputText
                    }

                    return answers
                }
            }
        }

        throw MagicOrbError.missingOutputText
    }

    private func saveResponseLog(_ response: Data) {
        guard let logsDirPath = ProcessInfo.processInfo.environment["LOGS_DIR_PATH"] else {
            fputs("LOGS_DIR_PATH environment variable is not defined, logs will not be saved.\n", stderr)
            return
        }
        let logsDir = URL(fileURLWithPath: logsDirPath, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

            let logName = "magic-orb_\(Self.utcTimestamp()).log.json"
            try response.write(to: logsDir.appendingPathComponent(logName), options: .atomic)
        } catch {
            fputs("Could not save response log: \(error.localizedDescription)\n", stderr)
        }
    }

    private static func utcTimestamp() -> String {
        var now = timeval()
        gettimeofday(&now, nil)

        var seconds = now.tv_sec
        var utc = tm()
        gmtime_r(&seconds, &utc)

        return String(
            format: "%04d%02d%02dT%02d%02d%02d%06dZ",
            utc.tm_year + 1900,
            utc.tm_mon + 1,
            utc.tm_mday,
            utc.tm_hour,
            utc.tm_min,
            utc.tm_sec,
            now.tv_usec
        )
    }
}
