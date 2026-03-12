# 🍱 Bento Releases

> **⚠️ Beta** — Bento is under active development. APIs and config format may change.

Public release binaries for **Bento** — a terminal UI for managing multi-service projects.

Define your tasks in a single `bento.yaml`, then launch an interactive dashboard to start, stop, restart, and monitor everything at once. Built with [Bubble Tea](https://github.com/charmbracelet/bubbletea) and [Lip Gloss](https://github.com/charmbracelet/lipgloss).

## Features

- **Multi-module support** — organize tasks by module (e.g. `web`, `api`) or use flat mode for simpler projects
- **List and pane views** — toggle between a task list and a split-pane output grid
- **Tabs** — filter tasks by type (dev, build, test, etc.) with optional hotkeys
- **Auto-start and auto-restart** — configure tasks to start on launch and restart on crash
- **Task dependencies** — `depends_on` ensures prerequisite tasks run first
- **Environment variables** — layered env resolution (project → module → task)
- **Themes** — 8 built-in color presets (default, catppuccin, dracula, nord, gruvbox, solarized, tokyo-night, rose-pine) with full override support
- **Persistent state** — view mode, pane layout, and theme selection are saved across sessions
- **Log export** — dump task output to timestamped log files
- **Scaffold** — `bento init` auto-detects your project type and generates a starter config, with optional interactive mode
- **Custom config** — load a specific config file with `--config` instead of the default `bento.yaml`

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/appology/bento-releases/main/install.sh | bash
```

Set `BENTO_INSTALL_DIR` to customize the install location (default: `/usr/local/bin`).

## Downloads

Pre-built binaries for each release are available on the [Releases](https://github.com/appology/bento-releases/releases) page.

Platforms:
- macOS (Apple Silicon / Intel)
- Linux (x86_64 / arm64)

## Quick Start

```sh
# Generate a bento.yaml for your project
bento init

# Launch the dashboard
bento
```

To run against a specific directory:

```sh
bento ./path/to/project
```

To load a specific config file:

```sh
bento --config=my-config.yaml
bento -c ./configs/staging.yaml
```

## Configuration

Bento is configured with a `bento.yaml` file in your project root.

### Minimal example (flat mode)

```yaml
name: my-app

tasks:
  dev:
    command: npm run dev
  build:
    command: npm run build
  test:
    command: npm test
```

### Multi-module example

```yaml
name: my-monorepo
icon: "🍱"

defaults:
  view: list
  panes: 4

env:
  NODE_ENV: development

modules:
  web:
    path: ./packages/web
    env:
      PORT: "3000"
    tasks:
      dev:
        command: npm run dev
        autostart: true
        restart: true
      build:
        command: npm run build

  api:
    path: ./packages/api
    env:
      PORT: "8080"
    tasks:
      dev:
        command: npm run dev
        restart:
          max: 3
          delay: 2s
      test:
        command: npm test

tabs:
  dev-servers:
    label: "dev servers"
    key: d
    filter:
      task: dev
  builds:
    label: "builds"
    key: b
    filter:
      task: build
```

### Task options

| Option | Description |
|---|---|
| `command` | Shell command to run |
| `mode` | `watch` (long-running) or `run` (one-shot). Auto-inferred from task name (`dev`, `serve`, `watch`, `start` → watch). |
| `autostart` | Start automatically when bento launches |
| `restart` | `true` for unlimited restarts, or `{ max: N, delay: Ns }` |
| `depends_on` | List of task IDs (`module/task`) that must start first |
| `env` | Task-specific environment variables |

### Global config

Place a global config at `~/.config/bento/config.yaml` to set defaults and theme overrides across all projects:

```yaml
defaults:
  view: panes
  panes: 4
  dim_panes: true
  max_lines: 10000

theme:
  primary: "#BB9AF7"
  success: "#9ECE6A"
```

## Keyboard Shortcuts

### Global

| Key | Action |
|---|---|
| `q` | Quit (double-press if tasks are running) |
| `Ctrl+C` | Force quit |
| `t` | Cycle theme |
| `?` | Toggle help screen |

### Home

| Key | Action |
|---|---|
| `←` `→` | Switch tabs |
| `↓` / `Enter` | Enter tab |
| `v` | View all processes in panes |

### List View

| Key | Action |
|---|---|
| `↑` `↓` | Navigate |
| `Enter` | View output in pane |
| `s` | Start |
| `k` | Kill (press twice to force) |
| `r` | Restart |
| `v` | Switch to panes |
| `Space` | Toggle select |
| `a` | Select all |

### Panes View

| Key | Action |
|---|---|
| `↑` `↓` `←` `→` | Move between panes |
| `Enter` | Focus pane (scroll mode) |
| `s` / `k` / `r` | Start / kill / restart |
| `l` | Export log |
| `-` / `+` | Change grid size |
| `v` | Switch to list |
| `n` / `p` | Next / previous page |

### Focused Pane

| Key | Action |
|---|---|
| `↑` `↓` | Scroll output |
| `PgUp` / `PgDn` | Scroll fast |
| `Home` / `End` | Jump to top / bottom |
| `Esc` | Exit focus mode |

## Scaffold

`bento init` scans your project for known markers and generates a starter `bento.yaml`:

| Marker | Detected as | Tasks |
|---|---|---|
| `package.json` | npm | dev, build, test, lint |
| `Cargo.toml` | Cargo | build, test, lint (clippy) |
| `go.mod` | Go | build, test |
| `Package.swift` | Swift | build, test |
| `Makefile` | Make | build |
| `pyproject.toml` | Python | test |
| `Gemfile` | Ruby | test |

### Init flags

| Flag | Description |
|---|---|
| `--force` | Overwrite an existing config file |
| `--depth=N` | Scan N levels deep for sub-projects (default: 1). Useful for monorepos with nested packages. |
| `-i`, `--interactive` | Run the interactive setup wizard: choose a project name, icon, filename, select which modules/tasks/tabs to include. |

## License

MIT
