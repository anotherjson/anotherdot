# Global Conventions

## Shell & Tooling
- IMPORTANT: Use `eza -la` for directory listings, never bare `ls`
- IMPORTANT: Use `uv run` for all Python execution, never global python or pip
- Use `git switch -c <branch>` to create branches, `git switch <branch>` to change
- This is Arch Linux with zsh

## Code Style
- YOU MUST follow a functional programming paradigm: pure functions, immutable data, composition over inheritance, map/filter/reduce over loops
- Prefer type annotations in Python. Use `ruff` for linting when available.
- In Rust, prefer iterators and combinators over manual loops

## Workflow
- Run tests before committing. Verify changes compile/pass before marking done.
- Commit messages: imperative mood, concise first line (<72 chars)
- Never commit .env files, credentials, or API keys
