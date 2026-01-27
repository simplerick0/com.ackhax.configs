# com.ackhax.configs

Configuration files and Claude Code skills for development environments.

## Structure

```
.
├── vscode/           # VSCode/Cursor configuration
├── skills/           # Claude Code skill templates
├── rules/            # Cursor rules (symlink to activate)
├── agents/           # Cursor agent configs (symlink to activate)
└── vendor/           # Git submodules (anthropic-skills)
```

## VSCode/Cursor Configuration

Targeted for **VIM users** of the Cursor IDE.

- **Leader key**: `,` (comma)
- **Ctrl+K**: Disabled in Cursor so VIM can use it
- **Escape alternatives**: `jk` or `jj` in insert mode

### Configuration Layers

| Layer | Location | Sync Method |
|-------|----------|-------------|
| Machine | `vscode/machines/<hostname>/` | `setup.sh` symlink (server-side) |
| User | `vscode/user/` | Settings Sync (client-side) |
| Profile | `vscode/profiles/<name>/` | Settings Sync (client-side) |

### Server Setup

```bash
cd vscode && ./setup.sh
# Uses hostname by default, or specify: ./setup.sh --machine ops
```

## Skills

Claude Code skills stored in `skills/`, symlinked to `.claude/skills/` to activate.

| Skill | Purpose |
|-------|---------|
| `skill-creator` | Guide for creating effective skills (from anthropics/skills) |
| `vscode-config` | Manage VSCode configs in this repo |
| `cursor-rules` | Create and manage Cursor IDE rules |
| `cursor-agents` | Configure Cursor agents |
| `fix-issue` | Fix GitHub issues with PR workflow |
| `research` | Deep codebase research (forked context) |
| `deploy` | Deployment workflow template |

## Cursor Rules & Agents

Store configs in `rules/` and `agents/` directories. Symlink to target project's `.cursor/rules/` or `.cursor/agents/` to activate.

```bash
# Example: activate a rule in another project
ln -s /path/to/rules/python.mdc /project/.cursor/rules/python.mdc
```
