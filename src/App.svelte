<script lang="ts">
  import { invoke } from '@tauri-apps/api/tauri'
  let prompt = ''
  let response = ''
  async function runAgent() {
    try {
      response = await invoke('run_agent', { prompt })
    } catch (e) {
      response = `Error: ${e}`
    }
  }
</script>

<main>
  <h1>DeskForge AI Agent</h1>
  <input bind:value={prompt} placeholder="Enter your prompt" />
  <button on:click={runAgent}>Run Agent</button>
  <p>{response}</p>
</main>

<style>
  main {
    padding: 1rem;
  }
</style>