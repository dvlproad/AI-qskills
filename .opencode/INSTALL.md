# Installing AI-qskills for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add AI-qskills to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["ai-qskills@git+https://github.com/[你的github用户名]/AI-qskills.git"]
}
```

Restart OpenCode. That's it — the plugin auto-installs and registers all skills.

## Usage

AI-qskills skills will be automatically triggered based on their descriptions in SKILL.md files.

To manually use a skill:

```
use skill tool to load ai-qskills/crush-reply
```

## Available Skills

- **crush-reply**: Generate fun, flirty replies to crush messages

## Updating

AI-qskills updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
  "plugin": ["ai-qskills@git+https://github.com/[你的github用户名]/AI-qskills.git#v1.0.0"]
}
```