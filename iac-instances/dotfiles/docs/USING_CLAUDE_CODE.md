# Using Claude Code: Complete Configuration and Usage Guide

This guide covers the essential steps needed to properly configure and use Claude Code after installation, focusing on authentication, environment setup, and key usage patterns.

## Authentication Setup

Claude Code requires authentication to access Anthropic's AI models. There are three main authentication options:

### Option 1: Anthropic Console (Recommended for API Users)

**For users with existing API keys:**

1. **Set Environment Variable:**
   ```bash
   export ANTHROPIC_API_KEY="your-api-key-here"

   # Make it persistent by adding to your shell profile
   echo 'export ANTHROPIC_API_KEY="your-api-key-here"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. **Verify Setup:**
   ```bash
   claude doctor
   ```

**For interactive OAuth setup:**

1. Navigate to your project directory:
   ```bash
   cd your-project
   claude
   ```

2. Follow the OAuth process to connect to [Anthropic Console](https://console.anthropic.com/)
3. Requires active billing at console.anthropic.com
4. A "Claude Code" workspace will be automatically created for usage tracking

### Option 2: Claude App Subscription

- Subscribe to Claude Pro or Max plan
- Log in with your Claude.ai account during setup
- Provides unified subscription for both Claude Code and web interface

### Option 3: Enterprise Platforms

- Configure for Amazon Bedrock or Google Vertex AI
- See [third-party integrations documentation](https://docs.anthropic.com/en/docs/claude-code/third-party-integrations)

## Essential Environment Variables

Claude Code supports several environment variables for configuration:

```bash
# Core Authentication
export ANTHROPIC_API_KEY="your-api-key-here"
export ANTHROPIC_AUTH_TOKEN="custom-bearer-token"  # Alternative to API key

# Model Configuration
export ANTHROPIC_MODEL="claude-sonnet-4-20250514"  # Specify default model

# Performance Settings
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="8192"  # Limit response length
export BASH_DEFAULT_TIMEOUT_MS="120000"      # Default timeout for commands

# Privacy & Telemetry
export DISABLE_TELEMETRY="1"                 # Opt out of usage telemetry
export DISABLE_AUTOUPDATER="1"              # Disable automatic updates
export DISABLE_ERROR_REPORTING="1"          # Opt out of error reporting

# Development Settings
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE="1"  # Disable terminal title updates
```

## Initial Setup and Verification

### 1. Doctor Command
Run the installation doctor to verify your setup:
```bash
claude doctor
```

This checks:
- Installation status and type
- Authentication configuration
- System dependencies
- Network connectivity

### 2. First Time Launch
Navigate to your project and start Claude Code:
```bash
cd your-awesome-project
claude
```

### 3. Version Check
Verify your installation:
```bash
claude --version
```

## Configuration Management

### Settings Files Hierarchy

Claude Code uses a hierarchical configuration system:

1. **Enterprise managed policies** (highest precedence)
   - macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
   - Linux: `/etc/claude-code/managed-settings.json`
   - Windows: `C:\ProgramData\ClaudeCode\managed-settings.json`

2. **Command line arguments**

3. **Local project settings**
   - `.claude/settings.local.json` (not checked into version control)

4. **Shared project settings**
   - `.claude/settings.json` (shared with team)

5. **User settings** (lowest precedence)
   - `~/.claude/settings.json`

### Example Settings Configuration

Create `.claude/settings.json` in your project:

```json
{
  "model": "claude-sonnet-4-20250514",
  "permissions": {
    "allow": [
      "Bash(git log:*)",
      "Bash(npm run test:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "WebFetch",
      "Bash(curl:*)"
    ],
    "defaultMode": "acceptEdits"
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "0"
  }
}
```

## Interactive Configuration

Use the `/config` command within Claude Code for interactive configuration:

```bash
# List all settings
claude config list

# Get specific setting
claude config get permissions

# Set a setting
claude config set model "claude-opus-4-1-20250805"

# Global settings (use -g flag)
claude config set -g theme "dark"
```

## Permission Management

### Interactive Permissions
Use the `/permissions` command for a user-friendly interface:
```bash
/permissions
```

This allows you to:
- View current tool permissions
- Allow/deny specific tools
- Configure tool-specific rules
- Manage file access patterns

### Permission Modes
Set different permission behaviors:

- **default**: Standard behavior, prompts for new tools
- **acceptEdits**: Auto-accepts file editing permissions
- **plan**: Analysis only, no file modifications or command execution
- **bypassPermissions**: Skip all prompts (use with caution)

## Model Selection

### Available Models

**Claude 4.1 Opus** (Latest, maximum capability):
```bash
export ANTHROPIC_MODEL="claude-opus-4-1-20250805"
```

**Claude 4 Sonnet** (Balanced performance):
```bash
export ANTHROPIC_MODEL="claude-sonnet-4-20250514"
```

**Claude 3.5 Haiku** (Fastest, most economical):
```bash
export ANTHROPIC_MODEL="claude-3-5-haiku-20241022"
```

### Runtime Model Switching
Change models during a session:
```bash
/model
```

This provides an interactive menu for model selection.

## Working Directory Management

### Single Directory
By default, Claude Code works in the directory where it's launched:
```bash
cd your-project
claude
```

### Multiple Directories
Add additional working directories:

**At startup:**
```bash
claude --add-dir /path/to/other/project
claude --add-dir ~/shared/libraries
```

**During session:**
```bash
/add-dir /path/to/other/project
/add-dir ~/shared/libraries
```

## Essential Slash Commands

Key commands to know:

```bash
/help                    # Show available commands
/permissions            # Manage tool permissions
/config                 # Interactive configuration
/model                  # Switch AI models
/add-dir               # Add working directories
/login                  # Re-authenticate
/logout                 # Sign out
```

## Security Best Practices

### File Access Control
Protect sensitive files by denying read access:

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)",
      "Read(./config/credentials.json)",
      "Read(**/*private*)",
      "Read(**/*secret*)"
    ]
  }
}
```

### Command Restrictions
Limit dangerous command execution:

```json
{
  "permissions": {
    "ask": [
      "Bash(git push:*)",
      "Bash(rm:*)",
      "Bash(sudo:*)"
    ],
    "deny": [
      "Bash(curl:*)",
      "WebFetch"
    ]
  }
}
```

### Network Controls
For security-conscious environments:
```bash
# Disable web access entirely
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
```

## Common Workflow Patterns

### Development Workflow
1. Navigate to project: `cd your-project`
2. Start Claude Code: `claude`
3. Set permissions as needed: `/permissions`
4. Begin development conversation

### Multi-Project Workflow
1. Start in main project: `cd main-project && claude`
2. Add related projects: `/add-dir ../backend-api`
3. Work across multiple codebases simultaneously

### Team Configuration
1. Create shared `.claude/settings.json` in project root
2. Configure team-wide permissions and models
3. Commit to version control for consistency
4. Use `.claude/settings.local.json` for personal overrides

## Troubleshooting

### Authentication Issues
```bash
# Clear and re-authenticate
claude logout
claude login

# Check credentials
claude doctor
```

### Permission Issues
```bash
# Reset permissions
/permissions
# Or manually edit .claude/settings.json
```

### Model Access Issues
```bash
# Verify API key has model access
claude doctor

# Try different model
export ANTHROPIC_MODEL="claude-3-5-haiku-20241022"
```

### Environment Issues
```bash
# Check environment variables
env | grep ANTHROPIC
env | grep CLAUDE

# Reset configuration
rm -rf ~/.claude/settings.json
claude
```

## Updates and Maintenance

### Auto-Updates (Default)
Claude Code automatically updates itself. To disable:
```bash
export DISABLE_AUTOUPDATER="1"
```

### Manual Updates
```bash
claude update
```

### Migration
If migrating from npm to native binary:
```bash
claude install
```

## Advanced Features

### Custom API Key Helper
For dynamic API key generation:
```json
{
  "apiKeyHelper": "/path/to/your/key-generation-script.sh"
}
```

### Hooks
Run custom commands before/after tool execution:
```json
{
  "hooks": {
    "PreToolUse": {
      "Bash": "echo 'About to run command...'"
    }
  }
}
```

### Status Line
Custom status line configuration:
```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

## Getting Help

- **Interactive help**: `/help` within Claude Code
- **Official documentation**: [https://docs.anthropic.com/en/docs/claude-code](https://docs.anthropic.com/en/docs/claude-code)
- **Installation issues**: Run `claude doctor`
- **Troubleshooting guide**: [https://docs.anthropic.com/en/docs/claude-code/troubleshooting](https://docs.anthropic.com/en/docs/claude-code/troubleshooting)

## Next Steps

1. **Configure authentication** using your preferred method
2. **Set up project settings** with appropriate permissions
3. **Try basic interactions** to familiarize yourself with the interface
4. **Explore advanced features** like multi-directory workflows and model switching
5. **Customize configuration** to match your development workflow

Claude Code is now ready for productive development work!