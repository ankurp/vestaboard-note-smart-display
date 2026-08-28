# Contributing

Thanks for your interest in improving this project!

## Development setup

```sh
npm install
npm run build:native   # macOS only — compiles the Swift helpers
```

`npm install` also sets up a [Husky](https://typicode.github.io/husky/) pre-commit
hook. On every commit, [lint-staged](https://github.com/lint-staged/lint-staged)
runs ESLint (`--fix`) and Prettier on your staged files, so formatting is applied
automatically before the commit is created.

## Before opening a pull request

Please make sure the following pass locally:

```sh
npm run lint          # ESLint
npm run format:check  # Prettier formatting
npm test              # Node test runner
```

You can auto-fix most issues with:

```sh
npm run lint:fix
npm run format
```

## Guidelines

- Keep changes focused and small; open an issue first for larger changes.
- Add or update tests for any behavior change. New logic should include unit tests.
- Keep the platform-independent logic (`src/`) free of macOS-specific calls so it
  stays testable in CI.
- Follow the existing code style; formatting is enforced by Prettier.

## Project layout

See the [README](README.md#project-structure) for an overview of the folder
structure.
