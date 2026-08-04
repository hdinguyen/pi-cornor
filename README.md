# question

My own agent corner — quick terminal Q&A powered by [pi](https://pi.dev).

## Commands

| Command | What it does |
|---------|--------------|
| `q <question>` | Ask a new question (creates a new session, no memory involved) |
| `q -m <question>` | Same, but inject relevant sections of `~/.q/memory.md` into the prompt |
| `fq <question>` | Follow up on the latest `lq`-selected session; if none is selected, use the newest session |
| `fq <session-id> <question>` | Follow up on a specific session (partial id ok) |
| `lq` | List the 10 newest sessions and stay interactive: press `0`-`9` to select that session for future `fq` calls and copy its full id to the clipboard, `q` to quit |
| `lq --flush [days]` | Distill sessions older than N days (default 30) into `~/.q/memory.md`, then delete them |

`fq` and `lq` are symlinks to `q`; the script dispatches on its invoked name.

## How it works

- Questions run via `pi -p` with the system prompt in `SYSTEM-PROMPT.md`,
  always from `$HOME`, so behavior is identical regardless of cwd.
- Sessions are stored in an isolated directory (`~/.q/sessions`, override with
  `Q_HOME`), completely separate from pi's own `~/.pi/agent/sessions`.
- `lq` persists the selected session id in `~/.q/LATEST_Q_SESSION`. Future
  `fq <question>` calls use that selected session until another `lq` selection
  replaces it. If the selected session no longer exists, `fq` falls back to the
  newest session.
- Answers are rendered with `glow` when it is installed. Disable with `Q_GLOW=0`.
- Stdin is merged into the prompt, so piping works: `git diff | q "review this"`.
- `q -m` picks memory by keyword match: words of 4+ letters from your question
  are matched (case-insensitively) against the `##` sections of `memory.md`;
  only matching sections are injected. No match → the question is asked
  without memory, with a note on stderr.

## Installation

### Option 1: Run instantly on the same machine

Use this when you trust the local environment and want `q`, `fq`, and `lq` to run directly on your host machine.

Install `pi` first:

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

Add this repo to `PATH`, or symlink `q`, `fq`, and `lq` into a bin directory:

```bash
mkdir -p ~/.local/bin
ln -sf "$PWD/q" ~/.local/bin/q
ln -sf "$PWD/q" ~/.local/bin/fq
ln -sf "$PWD/q" ~/.local/bin/lq
```

Use it:

```bash
q "What is Docker?"
fq "follow up"
lq
```

If you use `zsh`, add a `noglob` alias so `?`, `*`, and `[...]` are passed to `q` literally instead of being expanded by the shell:

```bash
printf "\nalias q='noglob q'\n" >> ~/.zshrc
source ~/.zshrc
```

### Option 2: Dockerized isolated execution

Use this when you want `q` to run inside a container. This keeps execution isolated from the host, shares host pi skills, extensions, and installed pi packages as read-only mounts, and stores sessions on the host under `/Users/nguyenhuynh/.q/sessions`.

Build the image:

```bash
docker build -t question-q:latest .
```

Create `/usr/local/bin/q` wrapper on the host:

```bash
sudo tee /usr/local/bin/q >/dev/null <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cmd="$(basename "$0")"

mkdir -p "/Users/nguyenhuynh/.q/sessions"

exec docker run --rm -i \
  -e Q_HOME=/data/.q \
  -e PI_CODING_AGENT_DIR=/app/.pi/agent \
  -v ~/.q:/data/.q \
  -v ~/.pi/agent:/app/.pi/agent \
  -v "$HOME/.pi/agent/skills:/app/.pi/agent/skills:ro" \
  -v "$HOME/.pi/agent/extensions:/app/.pi/agent/extensions:ro" \
  -v "$HOME/.pi/agent/npm:/app/.pi/agent/npm:ro" \
  -v "$HOME/.pi/agent/git:/app/.pi/agent/git:ro" \
  -w /app \
  --entrypoint "$cmd" \
  question-q:latest \
  "$@"
EOF

sudo chmod +x /usr/local/bin/q
```

Create `fq` and `lq` symlinks:

```bash
sudo ln -sf /usr/local/bin/q /usr/local/bin/fq
sudo ln -sf /usr/local/bin/q /usr/local/bin/lq
```

Use it normally from the host:

```bash
q "What is Docker?"
fq "follow up"
lq
```

Rebuild after changing the `Dockerfile`, `q`, or `SYSTEM-PROMPT.md`:

```bash
docker build -t question-q:latest .
```
