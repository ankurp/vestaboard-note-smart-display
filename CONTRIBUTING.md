# Contributing

Thanks for your interest in improving this project!

## Development setup

```sh
swift build
./Scripts/build.sh   # macOS only — builds and code-signs the release binary
```

The package uses the Swift Package Manager. Building the signed binary is only
needed when you want Calendar (EventKit) access to work; unit tests and the core
logic build and run without it.

## Before opening a pull request

Please make sure the following pass locally:

```sh
swift build           # compiles the package
swift test            # runs the test suite
```

## Guidelines

- Keep changes focused and small; open an issue first for larger changes.
- Add or update tests for any behavior change. New logic should include unit tests.
- Keep the platform-independent logic (`Sources/VestaboardCore/`) free of
  macOS-specific calls so it stays testable in CI.
- Follow the existing code style.

## Project layout

See the [README](README.md#project-structure) for an overview of the folder
structure.
