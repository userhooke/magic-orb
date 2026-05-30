# Conventional Swift CLI layout

```text
my-tool/
  Package.swift
  README.md
  .gitignore
  Sources/
    MyTool/
      main.swift
      Commands/
      Services/
      Models/
      Utilities/
  Tests/
    MyToolTests/
      MyToolTests.swift
```

For Swift Package Manager, `Package.swift` is the root. CLI entry point lives in:

```text
Sources/<ExecutableTargetName>/main.swift
```

Common conventions:

- `Sources/` holds app code.
- One folder per target under `Sources/`.
- `Tests/` mirrors source targets.
- `main.swift` stays thin: parse args, call command/app logic.
- Put reusable logic outside `main.swift`, usually in `Services/`, `Models/`, `Core/`, or `Utilities/`.
- Use `ArgumentParser` for CLI structure if the tool has commands/options.

Example with `swift-argument-parser`:

```text
Sources/
  MagicOrb/
    MagicOrb.swift        # @main command
    Commands/
      AskCommand.swift
      ConfigCommand.swift
    Core/
      OrbClient.swift
      PromptBuilder.swift
    Models/
      Message.swift
      Config.swift
```

If the CLI grows, split into library + executable:

```text
Sources/
  MagicOrbCLI/
    main.swift
  MagicOrbCore/
    Client.swift
    Models/
Tests/
  MagicOrbCoreTests/
```

That keeps core logic testable without invoking the CLI.
