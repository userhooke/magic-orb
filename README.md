# Magic Orb

AI chat apps keep research conversations linear. That works for a single thread,
but research often branches: one answer suggests several directions, one phrase
needs a deeper follow-up, and later another part of the same answer becomes the
next topic.

Magic Orb is a tiny Swift CLI experiment in making that workflow more
document-shaped. You can quote or keep a specific answer, add a question beside
it, and expand that part without losing the surrounding context. The goal is a
tree-like research flow: topics can branch into details while the source notes
stay in one editable file.

## Example

Create a file:

```txt
Project note

<<<peek
Summarize why SQLite is a good default for small local apps.
peek>>>

<<<search
What is the latest stable Swift release?
search>>>

<<<ask
Give me three title options for this note.
ask>>>
```

Run Magic Orb:

```sh
magic-orb notes.txt
```

Magic Orb sends matching blocks to OpenAI, gets one answer per question, and
rewrites the file in place. It removes the `<<<ask`, `<<<search`, or `<<<peek`
wrapper, keeps the original question text, and writes the answer below it.

After running, the file looks like:

```txt
Project note

Summarize why SQLite is a good default for small local apps.
SQLite is a good default for small local apps because...

What is the latest stable Swift release?
The latest stable Swift release is...

Give me three title options for this note.
1. ...
```

### Question blocks

```txt
<<<ask Answer using the full current file context. ask>>>

<<<ask
Answer using the full current file context.
ask>>>

<<<search
Research online before answering.
search>>>

<<<peek
Answer only the block content, without full file context.
peek>>>
```

### Rules

- The target file must exist.
- The file is read as UTF-8 text.
- Matching blocks start with `<<<ask`, `<<<search`, or `<<<peek`.
- Matching blocks may put question text on the opening line after the marker.
- Matching blocks end with a typed marker: `ask>>>`, `search>>>`, or `peek>>>`.
- Single-line blocks may use `<<<ask question ask>>>`.
- Answers replace the matching question wrapper and are written below the
  original question text.
- Files are rewritten in place.

## Install

Clone and build:

```sh
git clone <repo-url>
cd magic-orb
swift build -c release
```

Run the built binary:

```sh
.build/release/magic-orb notes.txt
```

Or run through SwiftPM during development:

```sh
swift run magic-orb notes.txt
```

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

## Status

Early open source project.
