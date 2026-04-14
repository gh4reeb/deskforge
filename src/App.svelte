<script lang="ts">
  import { invoke } from '@tauri-apps/api/core'
  let prompt = ''
  let messages: {task: string, result: string, screen: string}[] = []
  let persona = 'general'

  async function runAgent() {
    try {
      const result = await invoke('run_agent', { task: prompt, persona })
      const response = JSON.parse(result as string)
      messages = [...messages, {task: prompt, result: response.result, screen: response.screen}]
      prompt = ''
    } catch (e) {
      messages = [...messages, {task: prompt, result: `Error: ${e}`, screen: ''}]
    }
  }
</script>

<main>
  <h1>DeskForge AI Agent</h1>
  <select bind:value={persona}>
    <option value="general">General Assistant</option>
    <option value="developer">Senior Software Developer</option>
    <option value="network">Network Scanner</option>
  </select>
  <div class="chat">
    {#each messages as msg}
      <div class="message">
        <strong>Task:</strong> {msg.task}<br>
        <strong>Result:</strong> {msg.result}<br>
        {#if msg.screen}
          <img src="data:image/png;base64,{msg.screen}" alt="Screenshot" style="max-width: 100%;" />
        {/if}
      </div>
    {/each}
  </div>
  <input bind:value={prompt} placeholder="Enter your task" />
  <button on:click={runAgent}>Send Task</button>
</main>

<style>
  main {
    padding: 1rem;
  }
  .chat {
    max-height: 400px;
    overflow-y: auto;
    border: 1px solid #ccc;
    padding: 1rem;
    margin-bottom: 1rem;
  }
  .message {
    margin-bottom: 1rem;
  }
</style>