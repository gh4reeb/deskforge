# Development Guide

## Setup

1. Run `./setup.sh` for automated setup
   - The installer will recommend a model based on available RAM
   - It saves the chosen Ollama model to `.env` as `DESKFORGE_MODEL`
2. Start services: `docker-compose up -d`
3. Run app: `npm run tauri dev`

### Change model later

Update `.env` or export `DESKFORGE_MODEL` with a valid Ollama model tag before starting the backend.

## Adding Tools

1. Define tool function in `main.py`
2. Add to ALLOWED_TOOLS
3. Implement security check
4. Update graph nodes if needed

## Testing

- Backend: `curl -X POST http://127.0.0.1:8001/run-agent -d '{"task":"test"}'`
- UI: Interact via Tauri app
- Security: Try forbidden paths, should be blocked

## Deployment

- Build: `npm run tauri build`
- Distribute: Generated binaries in `src-tauri/target/release/bundle/`

## Troubleshooting

- Backend not starting: Check Python dependencies
- Tools failing: Ensure PyAutoGUI works (DISPLAY set)
- Ollama errors: Verify models pulled and service running