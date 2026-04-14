# API Documentation

## Endpoints

### GET /
Returns server status.

**Response:**
```json
{
  "status": "DeskForge backend running",
  "version": "0.1.0"
}
```

### POST /run-agent
Runs the AI agent on a task.

**Request:**
```json
{
  "task": "string"
}
```

**Response:**
```json
{
  "result": "string",
  "screen": "base64"
}
```

## Tools

- `take_screenshot()`: Captures screen as base64
- `mouse_click(x, y)`: Clicks at coordinates
- `type_text(text)`: Types text
- `read_file(path)`: Reads file content
- `write_file(path, content)`: Writes to file

All tools require security approval.

## Security

- Tools checked against ALLOWED_TOOLS
- Paths validated against FORBIDDEN_PATHS
- User prompted for permission before execution