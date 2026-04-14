# Contributing to DeskForge

## Development Setup

1. Fork and clone the repo

2. Follow the Quick Start in README.md

3. For backend development:
   - Add LangGraph agents in `agent-backend/app/`
   - Test with `python main.py "test prompt"`

4. For frontend:
   - Modify `src/App.svelte`
   - Run `npm run dev`

5. For Rust bridge:
   - Edit `src-tauri/src/commands.rs`
   - Run `cargo build`

## Code Style

- Python: Black, isort
- Rust: rustfmt, clippy
- JS/TS: Prettier

## Testing

- Add tests for new agents
- Run `npm run check` for linting

## Pull Requests

- Describe the feature/bug fix
- Include screenshots for UI changes
- Ensure CI passes