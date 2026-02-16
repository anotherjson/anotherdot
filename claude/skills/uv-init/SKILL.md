---
name: uv-init
description: Bootstrap a new Python project with uv, ruff, pytest
allowed-tools: ["Bash", "Write", "Read"]
user-invocable: true
disable-model-invocation: true
model: haiku
---

Bootstrap a new Python project with modern tooling.

Steps:
1. Run `uv init $ARGUMENTS` (project name from arguments, or ask)
2. Add dev dependencies: `uv add --dev ruff pytest mypy`
3. Configure pyproject.toml with ruff rules and pytest config
4. Create src layout with __init__.py
5. Create tests/ directory with conftest.py
6. Create .gitignore if not present
7. Initialize git repo if not already one
8. Print summary of created structure

Follow functional programming conventions: pure functions, type hints, no classes unless necessary.
