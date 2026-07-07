# vibe-env-init

Scaffold any project to run [opencode](https://opencode.ai) CLI inside a devcontainer, entirely from the terminal.

One command sets up `.devcontainer/`, `.opencode/`, and `mise.toml`.

![avif](assets/video.avif)

## Quick Start

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Miskamyasa/vibe-env-init/main/init.sh) my-project
```

The script will:
1. Create all configuration files with your project name
2. Skip any files that already exist (showing a diff so you can merge manually)

If no project name is given, the current directory name is used. The script normalizes it to a container-safe value (lowercase, `a-z0-9_.-`, separators collapsed to `-`).

If you need to test from a fork, override the template source:

```bash
VIBE_ENV_INIT_REPO="owner/repo" VIBE_ENV_INIT_BRANCH="branch" bash <(curl -fsSL https://raw.githubusercontent.com/Miskamyasa/vibe-env-init/main/init.sh) my-project
```

## Running opencode in a container

After scaffolding, use the [devcontainer CLI](https://github.com/devcontainers/cli) (installed via `mise`) to build and enter the container:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . opencode
```

### Wrapper script

To avoid typing the full commands every time, save this script as `~/.local/bin/oc` (or any name you prefer):

```bash
#!/usr/bin/env bash
set -e

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ensure container exists and is running
devcontainer up --workspace-folder "$ROOT" >/dev/null

exec devcontainer exec --workspace-folder "$ROOT" opencode
```

Then make it executable:

```bash
chmod +x ~/.local/bin/oc
```

Make sure `~/.local/bin` is in your `PATH` (add `export PATH="$HOME/.local/bin:$PATH"` to your shell profile if needed).

Now you can run `oc` from any scaffolded project directory to start opencode inside its container.

## Session Mode

The scaffolded environment uses the **latest** opencode with SQLite-based sessions.
Each project gets its own isolated opencode data directory at `~/.cache/containers/local-share-opencode/<project>`.
Auth credentials are mounted read-only from the host.

## What Gets Created

```
your-project/
  .devcontainer/
    devcontainer.json     # Container configuration
    Dockerfile            # Container image definition
  .opencode/
    opencode.json         # opencode CLI configuration
    tui.json              # Terminal UI theme and plugin configuration
    agents/
      build.html          # Direct-use implementation agent
      explore.html        # Fast codebase exploration sub-agent
      general.html        # Scoped implementation sub-agent
      investigate.html    # Read-only investigation agent (default)
      lead.html           # Orchestration agent for commands
      plan.html           # Planning agent
      review.html         # Code review sub-agent
    commands/
      execute.html        # Implementation execution command
      review.html         # Review orchestration command
  mise.toml               # Tool versions (node, npm, devcontainer CLI, opencode, gh)
```

## Usage Example: Plan, Execute, Review Workflow

The scaffolded `.opencode/` directory provides a three-phase workflow for implementing features. Each phase uses a dedicated slash command and specialized AI agents.

### Step 1: Initialize the devcontainer

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Miskamyasa/vibe-env-init/main/init.sh) my-project
```

Then start the container:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . opencode
```

Or use the `oc` wrapper if you set it up (see [Wrapper script](#wrapper-script)).

### Step 2: Plan (`/plan`)

Inside opencode, describe what you want to build:

```
/plan add a homepage benefits section
```

The `/plan` command triggers **Phase 1**. It uses the `plan` agent to:
- Read `AGENTS.md` and any referenced files for project conventions
- Investigate the codebase for existing patterns and architecture
- Produce a dependency-ordered list of implementation steps with acceptance criteria

Wait for the plan to complete. Review the output — it will contain numbered steps (S1, S2, ...) with scope, dependencies, and acceptance criteria for each.

### Step 3: Execute (`/execute`)

Once you are satisfied with the plan, run:

```
/execute
```

The `/execute` command triggers **Phase 2**. It uses the `lead` agent to:
- Walk through each planned step in dependency order
- Spawn `general` sub-agents for each step with implementation-only prompts
- Handle failures by inserting remediation steps and retrying
- Produce an execution summary with status per step and list of modified files

Wait for execution to finish. The agent will report which steps succeeded, failed, or were blocked.

### Step 4: Review (`/review`)

After execution completes, run:

```
/review
```

The `/review` command triggers **Phase 3**. It uses the `lead` agent to spawn read-only `review` sub-agents that:
- Verifies each planned step was implemented correctly (plan fidelity)
- Checks for regressions at API boundaries, state transitions, and error paths
- Validates acceptance criteria coverage
- Flags maintainability issues in touched areas

If the review finds critical issues, the agent will add fix steps and re-execute automatically. Once the review passes, you get:
- A structured review report with findings and verdict
- A **proposed commit message** (title + body with list of changes)

### Step 5: Commit

Copy the proposed commit message from the review output and commit the changes yourself:

```bash
git add -A
git commit -m "feat: add homepage benefits section

- Add BenefitsSection component with responsive grid layout
- Create benefits data module with icon mappings
- Integrate section into homepage below hero block
- Add unit tests for BenefitsSection rendering"
```

Review the diff before committing — the proposed message is a suggestion, not a guarantee.

### Agents Reference

| Agent | Model | Mode | Purpose |
|-------|-------|------|---------|
| `investigate` | default | primary (default) | Read-only codebase investigation, mapping structure, tracing dependencies |
| `plan` | default | primary | Produces execution-ready implementation plans |
| `lead` | default | primary | Orchestrates `/execute` and `/review` commands, delegates to sub-agents |
| `build` | default | primary | Direct-use agent for implementing changes end-to-end |
| `general` | `openai/gpt-5.4` | subagent | Scoped implementation tasks with minimal changes |
| `explore` | `opencode-go/deepseek-v4-flash` | subagent | Fast, broad codebase exploration for investigation |
| `review` | `openai/gpt-5.5` | subagent | Read-only code review with severity-rated findings |

### Commands Reference

| Command | Phase | Agent | Description |
|---------|-------|-------|-------------|
| `/plan <description>` | 1 | `plan` | Investigate codebase and produce an implementation plan |
| `/execute` | 2 | `lead` → `general` | Execute the plan step-by-step via implementation sub-agents |
| `/review` | 3 | `lead` → `review` | Run independent code review and produce commit message |

> **Tip:** The `investigate` agent is the default mode. When you open opencode, you can ask questions about the codebase and it will explore in read-only mode without making any changes. Switch to the workflow above when you are ready to implement.

## Conflict Handling

If a file already exists, the script will:
- Skip the file (never overwrites)
- Show a unified diff between your file and the template
- Print the template URL so you can review and merge changes manually

## Prerequisites

- macOS or Linux
- `curl` or `wget`
- Docker (or a compatible container runtime)
- [mise](https://mise.jdx.dev/) for tool management (installs `devcontainer` CLI, `opencode`, etc.)

## License

[MIT](LICENSE)
