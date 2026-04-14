<script lang="ts">
  import { invoke } from '@tauri-apps/api/core'
  let prompt = ''
  let response: any = null
  let screenshot = ''

  async function runAgent() {
    try {
      const result = await invoke('run_agent', { task: prompt })
      response = JSON.parse(result as string)
      screenshot = response.screen || ''
    } catch (e) {
      response = { result: `Error: ${e}` }
    }
  }
</script>

<main>
  <h1>DeskForge AI Agent</h1>
  <input bind:value={prompt} placeholder="Enter your task" />
  <button on:click={runAgent}>Send Task</button>
  {#if response}
    <p>Result: {response.result}</p>
    {#if screenshot}
      <img src="data:image/png;base64,{screenshot}" alt="Screenshot" style="max-width: 100%;" />
    {/if}
  {/if}
</main>

<style>
  main {
    padding: 1rem;
  }
</style>