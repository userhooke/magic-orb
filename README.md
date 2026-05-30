# Magic Orb

Magic Orb is a tiny Swift CLI that edits a text file in place by replacing
`/ask` lines with answers from OpenAI.

It is built for lightweight "ask inside the document" workflows: write notes,
drop in one or more `/ask ...` prompts, run the CLI, and keep the generated
answers in the file.

## Example

Create a file:

```txt
Project note

/ask Summarize why SQLite is a good default for small local apps.

/ask Give me three test cases for a CLI that rewrites files in place.
```

Run Magic Orb:

```sh
magic-orb look notes.txt
```

Magic Orb sends the file content to OpenAI, gets one answer per `/ask` line, and
rewrites the file with each `/ask` line replaced by its answer.

## Install

Clone and build:

```sh
git clone <repo-url>
cd magic-orb
swift build -c release
```

Run the built binary:

```sh
.build/release/magic-orb look notes.txt
```

Or run through SwiftPM during development:

```sh
swift run magic-orb look notes.txt
```

## Usage

```sh
magic-orb <command> <file>
```

Commands:

```txt
look    Open a text file, answer /ask lines with an LLM, and update the file
```

Rules:

- The target file must exist.
- The file is read as UTF-8 text.
- Matching lines are either `/ask` or `/ask ...`.
- Answers replace the full `/ask` line.
- Files are rewritten in place.

## Environment

Required:

```sh
export OPENAI_API_KEY="sk-..."
```

Optional:

```sh
export LOGS_DIR_PATH="./logs"
```

`LOGS_DIR_PATH` stores raw OpenAI response JSON files named like:

```txt
magic-orb_20260530T121314123456Z.log.json
```

If `LOGS_DIR_PATH` is unset, Magic Orb still runs and prints:

```txt
LOGS_DIR_PATH environment variable is not defined, logs will not be saved.
```

## Build

Requirements:

- macOS 13 or newer
- Swift 5.10 or newer

Debug build:

```sh
swift build
```

Release build:

```sh
swift build -c release
```

Run tests:

```sh
swift test
```

## Development

Main entry point:

```txt
Sources/MagicOrb/main.swift
```

Core OpenAI request and file rewrite logic:

```txt
Sources/MagicOrbCore/MagicOrbCLI.swift
```

## Status

Early open source project. The current CLI surface is intentionally small:
`look` is the only command.
