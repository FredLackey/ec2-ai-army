# Using Gemini CLI - Complete Usage Guide

This guide covers the practical usage of Google's Gemini CLI after successful installation and setup. It assumes you've followed the installation instructions from `SETUP_GEMINI_CLI.md`.

## Authentication and API Keys

### Authentication Methods

Gemini CLI supports three primary authentication methods:

#### 1. Login with Google (Recommended for Individual Use)
**Best for:** Individual developers and personal projects
- **Free tier:** 60 requests/min, 1,000 requests/day
- **Access to:** Gemini 2.5 Pro with 1M token context window
- **Setup:** No API key management required

```bash
gemini
# Select "Login with Google" when prompted
# Follow browser authentication flow
```

For Google Workspace or Gemini Code Assist license users:
```bash
export GOOGLE_CLOUD_PROJECT="your-project-id"
gemini
```

#### 2. Gemini API Key
**Best for:** Developers needing specific model control or paid tier access
- **Free tier:** 100 requests/day with Gemini 2.5 Pro
- **Benefits:** Model selection, usage-based billing

**Get your API key:** Visit [Google AI Studio](https://aistudio.google.com/app/apikey)

**Set environment variable:**
```bash
export GEMINI_API_KEY="your-api-key-here"
gemini
```

#### 3. Vertex AI
**Best for:** Enterprise teams and production workloads
- **Benefits:** Enterprise features, higher rate limits, Google Cloud integration

```bash
export GOOGLE_API_KEY="your-api-key"
export GOOGLE_GENAI_USE_VERTEXAI=true
gemini
```

### Making Environment Variables Persistent

#### Using Shell Configuration Files

**For Bash users:**
```bash
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

**For Zsh users:**
```bash
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc
```

#### Using .env Files (Recommended)

**Global configuration:**
```bash
# Create .gemini directory
mkdir -p ~/.gemini

# Add environment variables
cat >> ~/.gemini/.env <<'EOF'
GEMINI_API_KEY="your-api-key-here"
GOOGLE_CLOUD_PROJECT="your-project-id"
EOF
```

**Project-specific configuration:**
```bash
mkdir -p .gemini
echo 'GOOGLE_CLOUD_PROJECT="project-specific-id"' >> .gemini/.env
```

## Basic Usage

### Starting Gemini CLI

**Interactive mode (default):**
```bash
gemini
```

**With specific model:**
```bash
gemini -m gemini-2.5-flash
```

**Include additional directories:**
```bash
gemini --include-directories ../lib,../docs
```

**Non-interactive mode:**
```bash
gemini -p "Explain how to optimize this code"
```

**JSON output for scripting:**
```bash
gemini -p "Analyze this codebase structure" --output-format json
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-m, --model <model>` | Use specific model (gemini-2.5-pro, gemini-2.5-flash) |
| `-p, --prompt <prompt>` | Non-interactive mode with single prompt |
| `-i, --prompt-interactive <prompt>` | Start interactive session with initial prompt |
| `--output-format json` | Output in JSON format for scripting |
| `--include-directories <dirs>` | Include additional directories (comma-separated) |
| `--sandbox` | Run tools in secure sandbox (requires Docker) |
| `--yolo` | Auto-approve all tool calls (use with caution) |
| `--checkpointing` | Save project snapshot before modifications |
| `-d, --debug` | Enable debug output |

## Configuration

### Settings File (settings.json)

Configuration files are loaded with this precedence:
1. **System:** `/etc/gemini-cli/settings.json` (highest precedence)
2. **Workspace:** `.gemini/settings.json` (overrides user settings)
3. **User:** `~/.gemini/settings.json`

**Example settings.json:**
```json
{
  "theme": "GitHub",
  "autoAccept": false,
  "sandbox": "docker",
  "vimMode": true,
  "checkpointing": { "enabled": true },
  "fileFiltering": { "respectGitIgnore": true },
  "usageStatisticsEnabled": true,
  "includeDirectories": ["../shared-library", "~/common-utils"],
  "chatCompression": { "contextPercentageThreshold": 0.6 },
  "mcpServers": {
    "github": {
      "httpUrl": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "YOUR_GITHUB_PAT"
      }
    }
  }
}
```

### Context Files (GEMINI.md)

Use `GEMINI.md` files to provide project-specific instructions and context to the model.

**Hierarchical loading order:**
1. Global: `~/.gemini/GEMINI.md`
2. Project/Ancestor: Search from current directory up to project root
3. Sub-directory: Component-specific instructions

**Example GEMINI.md:**
```markdown
# Project: My Awesome TypeScript Library

## General Instructions:
- When generating new TypeScript code, follow existing coding style
- Ensure all functions have JSDoc comments
- Prefer functional programming paradigms
- Compatible with TypeScript 5.0 and Node.js 20+

## Coding Style:
- Use 2 spaces for indentation
- Interface names prefixed with `I` (e.g., `IUserService`)
- Private members prefixed with underscore (`_`)
- Always use strict equality (`===` and `!==`)

## Dependencies:
- Avoid new external dependencies unless necessary
- State reason for any new dependency
```

**Generate initial GEMINI.md:**
```bash
/init
```

**View combined context:**
```bash
/memory show
```

### File Filtering (.geminiignore)

Create `.geminiignore` to exclude files and directories:
```
# Exclude directories
/backups/
/node_modules/
/.git/

# Exclude file types
*.log
*.tmp
secret-config.json

# Exclude patterns
**/temp/**
```

## Core Commands and Features

### Slash Commands (/)

| Command | Description |
|---------|-------------|
| `/help` | Display help and available commands |
| `/tools` | List available built-in and MCP tools |
| `/mcp` | List configured MCP servers |
| `/clear` | Clear terminal screen and context |
| `/compress` | Replace chat context with summary to save tokens |
| `/copy` | Copy last response to clipboard |
| `/stats` | Show session token usage and savings |
| `/memory show` | Show combined context from GEMINI.md files |
| `/memory refresh` | Reload all GEMINI.md files |
| `/chat save <tag>` | Save current conversation with tag |
| `/chat resume <tag>` | Resume saved conversation |
| `/chat list` | List saved conversation tags |
| `/restore` | List or restore project state checkpoint |
| `/auth` | Change authentication method |
| `/theme` | Change CLI visual theme |
| `/vim` | Toggle Vim mode for input editing |
| `/settings` | Open settings editor |
| `/directory add <path>` | Add directory to workspace |
| `/bug` | File issue or bug report |
| `/quit` | Exit Gemini CLI |

### Context Commands (@)

Reference files and directories in prompts:

**Include a file:**
```
> Explain this code. @./src/main.js
```

**Include an image:**
```
> Describe this screenshot. @./mockup.png
```

**Include entire directory:**
```
> Refactor this code to use async/await. @./src/
```

**Include multiple files:**
```
> Compare these implementations. @./old-version.js @./new-version.js
```

### Shell Commands (!)

**Single command:**
```
> !git status
```

**Toggle shell mode:**
```
> !
# Now in shell mode - type ! again to exit
```

### Keyboard Shortcuts

| Shortcut | Description |
|----------|-------------|
| `Ctrl+L` | Clear screen |
| `Ctrl+V` | Paste text or image from clipboard |
| `Ctrl+Y` | Toggle YOLO mode (auto-approve tools) |
| `Ctrl+X` | Open prompt in external editor |
| `Ctrl+C` | Interrupt current operation |

## Built-in Tools

Gemini CLI includes powerful built-in tools:

### File System Tools
- `list_directory(path)` - List directory contents
- `glob(pattern)` - Find files by pattern
- `read_file(path)` - Read file contents
- `write_file(file_path, content)` - Write to file
- `replace(file_path, old_string, new_string)` - Replace text in file
- `search_file_content(pattern, include)` - Search in files

### Web Tools
- `google_web_search(query)` - Search the web with grounding
- `web_fetch(url, prompt)` - Fetch and summarize web content

### Shell Tool
- `run_shell_command(command)` - Execute system commands

### Memory Tool
- `save_memory(fact)` - Save information across sessions

## MCP (Model Context Protocol) Servers

Extend Gemini CLI with custom tools using MCP servers.

### Configuration

Add MCP servers in `settings.json`:
```json
{
  "mcpServers": {
    "github": {
      "httpUrl": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "YOUR_GITHUB_PAT"
      }
    },
    "local-server": {
      "command": "python",
      "args": ["-m", "my_mcp_server"],
      "cwd": "./mcp_tools",
      "env": {
        "DATABASE_URL": "$DB_URL"
      }
    }
  }
}
```

### Popular MCP Servers

**GitHub MCP Server:**
- Tools for repository management, issues, PRs
- Remote server: `https://api.githubcopilot.com/mcp/`

**Context7 MCP Server:**
- Up-to-date documentation for frameworks
- Remote server: `https://mcp.context7.com/mcp`

**Firebase MCP Server:**
- Firebase project management tools

**Google Workspace MCP Server:**
- Integration with Docs, Sheets, Gmail, Calendar

### MCP Management Commands

```bash
/mcp                    # List configured servers
/mcp refresh            # Reload MCP servers
gemini mcp add <config> # Add MCP server via CLI
gemini mcp list         # List servers
gemini mcp remove <name> # Remove server
```

## Advanced Features

### Checkpointing and Restore

Save project state before modifications:

**Enable checkpointing:**
```bash
gemini --checkpointing
```

**Or in settings.json:**
```json
{
  "checkpointing": { "enabled": true }
}
```

**Restore commands:**
```bash
/restore              # List available checkpoints
/restore <checkpoint> # Restore specific checkpoint
```

### Custom Commands

Create reusable prompts as slash commands.

**Directory structure:**
- Global: `~/.gemini/commands/`
- Project: `<project>/.gemini/commands/`

**Example: `~/.gemini/commands/test.toml`**
```toml
description = "Generate unit tests for the given code"
prompt = """
You are an expert test engineer. Create comprehensive unit tests
for the following code using Jest framework:

{{args}}
"""
```

**Usage:**
```
/test "function addNumbers(a, b) { return a + b; }"
```

### IDE Integration (VS Code)

Connect Gemini CLI to VS Code:

```bash
/ide install    # Install VS Code extension
/ide enable     # Enable IDE integration
```

**Benefits:**
- Automatic workspace context
- Recent files and cursor position
- Native diff viewing
- Selected text awareness

### Extensions

Create extensions for custom functionality.

**Extension structure:**
```
.gemini/extensions/my-extension/
├── gemini-extension.json
└── GEMINI.md
```

**gemini-extension.json:**
```json
{
  "name": "my-extension",
  "version": "1.0.0",
  "mcpServers": {
    "my-server": {
      "command": "node my-server.js"
    }
  },
  "contextFileName": "GEMINI.md",
  "excludeTools": ["run_shell_command"]
}
```

## Security Considerations

### API Key Security

**Best practices:**
- Store keys in `.env` files, not shell profiles
- Use appropriate file permissions:
```bash
chmod 600 ~/.gemini/.env
```
- Never commit keys to version control
- Use different keys for different environments

### Tool Permissions

Gemini CLI requests permission for sensitive operations:
- **Allow once:** Single operation permission
- **Allow always:** Blanket permission for the session
- **Deny:** Refuse the operation

**Auto-approval settings:**
```json
{
  "autoAccept": true,  // Auto-approve read-only operations
  "trust": false       // Per-MCP server trust settings
}
```

### Sandbox Mode

Run tools in isolated environment:
```bash
gemini --sandbox
```

Requires Docker or Podman for secure execution.

## Common Usage Patterns

### Code Development Workflow

1. **Start with context:**
```bash
gemini --include-directories ../shared,../docs
```

2. **Understand codebase:**
```
> Analyze the architecture of @./src/
```

3. **Generate code:**
```
> Create a user authentication service following the patterns in @./src/auth/
```

4. **Review and test:**
```
> /plan Review the generated code and suggest improvements
```

### Project Documentation

```
> Generate a comprehensive README.md for this project @./
> Create API documentation from @./src/api/
> Write setup instructions for new developers
```

### Code Analysis and Debugging

```
> Find potential security issues in @./src/
> Explain why this test is failing @./tests/user.test.js
> Suggest performance optimizations for @./src/database/
```

### Automation and Scripting

```bash
# Daily standup preparation
gemini -p "Summarize commits from yesterday using git log"

# Code review assistance
gemini -p "Review this PR and suggest improvements @./changes.patch"

# Documentation updates
gemini -p "Update README based on recent changes @./CHANGELOG.md"
```

## Troubleshooting

### Common Issues

**Authentication failures:**
- Verify API key is correctly set
- Check environment variable names
- Ensure browser access for OAuth flow

**Tool permission errors:**
- Review tool permissions carefully
- Use sandbox mode for untrusted operations
- Check file system permissions

**MCP server connection issues:**
- Verify MCP server configuration
- Check network connectivity for remote servers
- Review server logs for local servers

**Performance issues:**
- Use `/compress` to reduce context size
- Enable `chatCompression` in settings
- Limit included directories

### Debug Mode

Enable detailed logging:
```bash
gemini --debug -p "your query"
```

### Getting Help

- Use `/help` for available commands
- Check `/tools` for available tools
- Use `/bug` to report issues
- Visit [GitHub Issues](https://github.com/google-gemini/gemini-cli/issues)

## Best Practices

1. **Set up proper authentication** before first use
2. **Create project-specific GEMINI.md** files for better context
3. **Use .geminiignore** to exclude unnecessary files
4. **Enable checkpointing** for important changes
5. **Configure relevant MCP servers** for your workflow
6. **Use non-interactive mode** for automation
7. **Regularly compress chat history** to manage token usage
8. **Review tool permissions** carefully before approving
9. **Keep API keys secure** and never commit them
10. **Use sandbox mode** for untrusted operations

---

This guide provides a comprehensive overview of using Gemini CLI effectively. For the latest features and updates, refer to the [official documentation](https://github.com/google-gemini/gemini-cli).