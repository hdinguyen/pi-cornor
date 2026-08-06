# LiteLLM Proxy setup for q/pi

Use LiteLLM Proxy as one gateway for cloud and local models:

```text
q CLI -> pi -> LiteLLM Proxy -> OpenAI / ChatGPT subscription / Ollama / OpenRouter
```

## 1. Install LiteLLM

```bash
uv tool install 'litellm[proxy]'
```

Alternative:

```bash
pip install 'litellm[proxy]'
```

LiteLLM requires Python 3.10+.

## 2. Prepare Ollama

```bash
brew install ollama
ollama serve
```

In another shell:

```bash
ollama pull qwen2.5-coder:7b
ollama pull llama3.1:8b
```

Test:

```bash
ollama run qwen2.5-coder:7b "write hello world in python"
```

## 3. Create LiteLLM config

Create the config directory:

```bash
mkdir -p ~/.q/litellm
```

Create `~/.q/litellm/config.yaml`:

```yaml
model_list:
  # OpenAI API models. Requires OPENAI_API_KEY.
  - model_name: q-openai-fast
    litellm_params:
      model: openai/gpt-4o-mini
      api_key: os.environ/OPENAI_API_KEY

  - model_name: q-openai-strong
    litellm_params:
      model: openai/gpt-4o
      api_key: os.environ/OPENAI_API_KEY

  # ChatGPT subscription models. Uses LiteLLM chatgpt/ OAuth device flow.
  # Use this only if you mean ChatGPT Pro/Max subscription, not OpenAI API credits.
  - model_name: q-chatgpt
    model_info:
      mode: responses
    litellm_params:
      model: chatgpt/gpt-5.4

  - model_name: q-codex
    model_info:
      mode: responses
    litellm_params:
      model: chatgpt/gpt-5.3-codex

  # Ollama local models. Requires Ollama on localhost:11434.
  # LiteLLM recommends ollama_chat/ for chat responses.
  - model_name: q-local-code
    litellm_params:
      model: ollama_chat/qwen2.5-coder:7b
      api_base: http://localhost:11434
      input_cost_per_token: 0
      output_cost_per_token: 0

  - model_name: q-local-general
    litellm_params:
      model: ollama_chat/llama3.1:8b
      api_base: http://localhost:11434
      input_cost_per_token: 0
      output_cost_per_token: 0

  # OpenRouter models. Requires OPENROUTER_API_KEY.
  - model_name: q-openrouter-auto
    litellm_params:
      model: openrouter/openrouter/auto-beta
      api_key: os.environ/OPENROUTER_API_KEY

  - model_name: q-openrouter-sonnet
    litellm_params:
      model: openrouter/anthropic/claude-sonnet-4.5
      api_key: os.environ/OPENROUTER_API_KEY

  - model_name: q-openrouter-cheap
    litellm_params:
      model: openrouter/google/gemini-2.5-flash
      api_key: os.environ/OPENROUTER_API_KEY

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
```

## 4. Export keys

OpenAI API:

```bash
export OPENAI_API_KEY="sk-..."
```

OpenRouter:

```bash
export OPENROUTER_API_KEY="sk-or-..."
```

LiteLLM proxy key:

```bash
export LITELLM_MASTER_KEY="sk-q-local"
```

For ChatGPT subscription models, LiteLLM uses OAuth device login. The first request prints a device code and verification URL. Sign in there. LiteLLM stores tokens locally for reuse.

## 5. Start LiteLLM Proxy

```bash
litellm --config ~/.q/litellm/config.yaml --port 4000
```

Proxy URL:

```text
http://localhost:4000
```

OpenAI-compatible base URL:

```text
http://localhost:4000/v1
```

## 6. Test LiteLLM directly

Test local Ollama:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-q-local" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "q-local-code",
    "messages": [
      {"role": "user", "content": "write a python hello world"}
    ]
  }'
```

Test OpenAI API:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-q-local" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "q-openai-fast",
    "messages": [
      {"role": "user", "content": "explain docker in 3 bullets"}
    ]
  }'
```

Test OpenRouter:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-q-local" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "q-openrouter-auto",
    "messages": [
      {"role": "user", "content": "which model are you?"}
    ]
  }'
```

## 7. Connect pi to LiteLLM

Create `~/.pi/agent/extensions/litellm-provider.ts`:

```ts
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerProvider("litellm", {
    name: "LiteLLM Proxy",
    baseUrl: "http://localhost:4000/v1",
    apiKey: "$LITELLM_MASTER_KEY",
    api: "openai-completions",
    models: [
      {
        id: "q-local-code",
        name: "q-local-code",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 8192
      },
      {
        id: "q-local-general",
        name: "q-local-general",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 8192
      },
      {
        id: "q-openai-fast",
        name: "q-openai-fast",
        reasoning: false,
        input: ["text"],
        cost: { input: 0.15, output: 0.6, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384
      },
      {
        id: "q-openai-strong",
        name: "q-openai-strong",
        reasoning: false,
        input: ["text"],
        cost: { input: 2.5, output: 10, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384
      },
      {
        id: "q-openrouter-auto",
        name: "q-openrouter-auto",
        reasoning: false,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384
      },
      {
        id: "q-openrouter-sonnet",
        name: "q-openrouter-sonnet",
        reasoning: true,
        input: ["text"],
        cost: { input: 3, output: 15, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 200000,
        maxTokens: 16384
      },
      {
        id: "q-chatgpt",
        name: "q-chatgpt",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384
      },
      {
        id: "q-codex",
        name: "q-codex",
        reasoning: true,
        input: ["text"],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 128000,
        maxTokens: 16384
      }
    ]
  });
}
```

Test pi model discovery:

```bash
pi --list-models litellm
```

Run through pi:

```bash
pi -p --provider litellm --model q-local-code "write a shell script"
pi -p --provider litellm --model q-openrouter-auto "analyze this architecture"
pi -p --provider litellm --model q-openai-fast "summarize this"
```

## 8. Recommended q model aliases

Use these logical names in the `q` wrapper:

```text
q-local-code        private/local coding
q-local-general     private/local simple Q&A
q-openai-fast       cheap cloud general
q-openai-strong     stronger OpenAI task
q-openrouter-auto   automatic cloud routing
q-openrouter-sonnet hard coding/reasoning
q-chatgpt           ChatGPT subscription general
q-codex             ChatGPT subscription coding
```

Suggested routing:

```text
private/offline/local keywords -> q-local-code
simple question                -> q-local-general or q-openai-fast
coding/debug/refactor          -> q-openrouter-sonnet or q-codex
unknown complex task           -> q-openrouter-auto
```

LiteLLM should be the gateway. The `q` script should choose the logical model alias and pass it to pi.
