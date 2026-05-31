import Foundation
import MagicOrbCore

@main
struct MagicOrb {
    static func main() async {
        let arguments = CommandLine.arguments.dropFirst()
        guard let targetFile = arguments.first, !targetFile.isEmpty else {
            print("No file provided.")
            printHelp()
            exit(0)
        }

        guard FileManager.default.fileExists(atPath: targetFile) else {
            print("File not found: \(targetFile).")
            printHelp()
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
            let response = try await orb.look(content: targetFileContent)
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
        Usage: magic-orb <file>
        """)
    }
}
