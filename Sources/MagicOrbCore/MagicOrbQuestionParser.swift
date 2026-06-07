import Foundation

enum QuestionType: String, CaseIterable {
    case ask
    case search
    case peek
}

typealias Questions = [QuestionType: [String]]

struct MagicOrbQuestionParser {
    private struct BlockStart {
        let questionType: QuestionType
        let inlineQuestion: String?
        let isComplete: Bool
    }

    static func replaceQuestionBlocks(in content: String, for questionType: QuestionType, with answers: [String]) -> String {
        var answerIndex = 0
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var replacedLines = [String]()
        var lineIndex = 0

        while lineIndex < lines.count {
            let line = lines[lineIndex]
            guard let blockStart = blockStart(for: line), blockStart.questionType == questionType, answerIndex < answers.count else {
                replacedLines.append(line)
                lineIndex += 1
                continue
            }

            var questionLines = [String]()
            if let inlineQuestion = blockStart.inlineQuestion {
                questionLines.append(inlineQuestion)
            }
            lineIndex += 1

            while blockStart.isComplete == false, lineIndex < lines.count, isEndMarker(lines[lineIndex], for: questionType) == false {
                questionLines.append(lines[lineIndex])
                lineIndex += 1
            }
            if blockStart.isComplete == false, lineIndex < lines.count, isEndMarker(lines[lineIndex], for: questionType) {
                lineIndex += 1
            }

            let question = questionLines.joined(separator: "\n")
            replacedLines.append(question + "\n" + answers[answerIndex])
            answerIndex += 1
        }

        return replacedLines.joined(separator: "\n")
    }

    static func extractQuestions(from content: String) -> Questions {
        var questions = Dictionary(uniqueKeysWithValues: QuestionType.allCases.map { ($0, [String]()) })
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var lineIndex = 0

        while lineIndex < lines.count {
            guard let blockStart = blockStart(for: lines[lineIndex]) else {
                lineIndex += 1
                continue
            }

            var questionLines = [String]()
            if let inlineQuestion = blockStart.inlineQuestion {
                questionLines.append(inlineQuestion)
            }
            lineIndex += 1

            while blockStart.isComplete == false, lineIndex < lines.count, isEndMarker(lines[lineIndex], for: blockStart.questionType) == false {
                questionLines.append(lines[lineIndex])
                lineIndex += 1
            }
            if blockStart.isComplete == false, lineIndex < lines.count, isEndMarker(lines[lineIndex], for: blockStart.questionType) {
                lineIndex += 1
            }

            questions[blockStart.questionType, default: []].append(questionLines.joined(separator: "\n"))
        }

        return questions
    }

    static func questionBlocks(for questionType: QuestionType, questions: Questions) -> String {
        questions[questionType, default: []].map {
            "<<<\(questionType.rawValue)\n\($0)\n\(questionType.rawValue)>>>"
        }.joined(separator: "\n")
    }

    private static func blockStart(for line: String) -> BlockStart? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        return QuestionType.allCases.compactMap { questionType in
            let marker = "<<<\(questionType.rawValue)"
            let endMarker = "\(questionType.rawValue)>>>"
            guard trimmedLine == marker || trimmedLine.hasPrefix(marker + " ") else {
                return nil
            }

            if trimmedLine.hasSuffix(endMarker) {
                let inlineQuestion = trimmedLine
                    .dropFirst(marker.count)
                    .dropLast(endMarker.count)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return BlockStart(questionType: questionType, inlineQuestion: inlineQuestion.isEmpty ? nil : inlineQuestion, isComplete: true)
            }

            let inlineQuestion = trimmedLine == marker ? nil : String(trimmedLine.dropFirst(marker.count + 1))
            return BlockStart(questionType: questionType, inlineQuestion: inlineQuestion, isComplete: false)
        }.first
    }

    private static func isEndMarker(_ line: String, for questionType: QuestionType) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines) == "\(questionType.rawValue)>>>"
    }
}
