use tauri::command;
use reqwest;
use serde_json::json;

#[command]
pub async fn run_agent(task: String) -> Result<String, String> {
    let client = reqwest::Client::new();
    let res = client.post("http://127.0.0.1:8001/run-agent")
        .json(&json!({"task": task}))
        .send()
        .await
        .map_err(|e| format!("Request failed: {}", e))?;

    if res.status().is_success() {
        let body: serde_json::Value = res.json().await.map_err(|e| format!("JSON parse failed: {}", e))?;
        Ok(serde_json::to_string(&body).unwrap())
    } else {
        Err(format!("HTTP error: {}", res.status()))
    }
}