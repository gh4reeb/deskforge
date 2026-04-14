use std::process::Command;
use tauri::command;

#[command]
pub fn run_agent(prompt: String) -> Result<String, String> {
    let output = Command::new("python3")
        .arg("../agent-backend/app/main.py")
        .arg(prompt)
        .output()
        .map_err(|e| format!("Failed to run python: {}", e))?;

    if output.status.success() {
        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    } else {
        Err(String::from_utf8_lossy(&output.stderr).to_string())
    }
}