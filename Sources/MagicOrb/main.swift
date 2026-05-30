import Foundation
import MagicOrbCore

@main
struct MagicOrb {
    static func main() async {
        let arguments = CommandLine.arguments.dropFirst()
        guard let command = arguments.first, !command.isEmpty else {
            print("No command provided.")
            exit(0)
        }

        guard let targetFile = arguments.dropFirst().first, !targetFile.isEmpty else {
            print("No file provided.")
            exit(0)
        }

        guard FileManager.default.fileExists(atPath: targetFile) else {
            print("File not found: \(targetFile).")
            exit(0)
        }

        let targetFileContent: String
        do {
            targetFileContent = try String(contentsOfFile: targetFile, encoding: .utf8)
        } catch {
            fputs("Could not read file: \(targetFile). \(error.localizedDescription)\n", stderr)
            exit(1)
        }

        let orb = MagicOrbCLI()

        do {
            let response: String
            switch command {
            case "look":
                response = try await orb.look(content: targetFileContent)
            default:
                print("Unknown command: \(command).")
                printHelp()
                exit(0)
            }

            if !response.isEmpty {
                try response.write(toFile: targetFile, atomically: true, encoding: .utf8)
            }
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func printHelp() {
        print("""
        Usage: magic-orb <command> <file>

        Commands:
          look    Open a text file, answer /ask lines with a fast, cheap LLM, and update the file
        """)
    }
}
