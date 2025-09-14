# Using Codex CLI: Complete Usage Guide

This guide provides comprehensive instructions for using OpenAI's Codex CLI after installation, including authentication, API key setup, environment configuration, and practical usage examples.

## Prerequisites

Before using Codex CLI, ensure you have completed the installation process outlined in [SETUP_CODEX_CLI.md](./SETUP_CODEX_CLI.md).

## Authentication and API Keys

### Authentication Options

Codex CLI offers two primary authentication methods:

#### Option 1: Sign in with ChatGPT Account (Recommended)

This is the easiest method and allows you to use Codex with your existing ChatGPT subscription:

1. **Run Codex for the first time:**
   ```bash
   codex
   ```

2. **Select authentication method:**
   - Choose **"Sign in with ChatGPT"** when prompted
   - This works with ChatGPT Plus, Pro, Team, Edu, or Enterprise plans

3. **Complete authentication:**
   - Follow the browser authentication flow
   - Your credentials will be saved locally in `~/.codex/config.toml`

#### Option 2: OpenAI API Key (Alternative)

For users who prefer API key authentication or don't have a ChatGPT subscription:

1. **Obtain your API key:**
   - Visit [platform.openai.com](https://platform.openai.com/api-keys)
   - Create a new API key or use an existing one
   - Copy the key (starts with `sk-`)

2. **Set environment variable:**
   ```bash
   # Add to your shell profile (.bashrc, .zshrc, etc.)
   echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.bashrc
   source ~/.bashrc

   # Or set for current session only
   export OPENAI_API_KEY="your-api-key-here"
   ```

3. **Verify API key setup:**
   ```bash
   echo $OPENAI_API_KEY
   ```

### Important Authentication Notes

- **ChatGPT account method** includes usage as part of your subscription
- **API key method** requires usage-based billing setup
- Plus users can redeem $5 in free API credits
- Pro users can redeem $50 in free API credits
- Enterprise/Team accounts have centralized API key management

## Environment Setup

### Configuration File

Codex CLI stores configuration in `~/.codex/config.toml`. This file is automatically created on first run.

### Basic Configuration

Edit your configuration file:

```bash
nano ~/.codex/config.toml
```

Example configuration:
```toml
# Default model and reasoning level
model = "gpt-5"
reasoning = "medium"

# Approval mode (auto, read-only, full-access)
approval_mode = "auto"

# MCP servers (optional)
[mcp_servers]
# Add MCP server configurations here if needed
```

### Environment Variables

Key environment variables for Codex CLI:

```bash
# OpenAI API Key (if using API key authentication)
export OPENAI_API_KEY="your-api-key-here"

# Optional: Set custom config directory
export CODEX_CONFIG_DIR="$HOME/.codex"

# Optional: Enable debug logging
export CODEX_LOG_LEVEL="debug"
```

Add these to your shell profile for persistence:

```bash
# For bash users
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc

# For zsh users
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc
```

## Usage Modes and Approval Settings

### Approval Modes

Codex CLI has three approval modes that control how it interacts with your system:

#### 1. Auto Mode (Default)
- Codex can read files, make edits, and run commands in the working directory automatically
- Requires approval for network access or working outside the directory
- Balanced security and productivity

#### 2. Read Only Mode
- Codex can only read files and propose changes
- Requires approval for all modifications
- Safest mode for exploring unfamiliar codebases

#### 3. Full Access Mode
- Codex can read, write, and execute commands with network access without approval
- Use with extreme caution
- Best for trusted environments and experienced users

### Changing Approval Modes

During a Codex session, use the `/approvals` command to change modes:

```bash
# In Codex CLI
/approvals
```

## Basic Usage Examples

### Starting Codex CLI

#### Interactive Mode
```bash
# Start interactive session
codex

# Start in specific directory
cd /path/to/your/project
codex
```

#### Direct Prompt Execution
```bash
# Run with specific prompt
codex "explain this codebase"

# Non-interactive execution
codex exec "fix the CI failure"
```

### Common Use Cases

#### Code Analysis
```bash
# Analyze codebase
codex "explain what this application does"

# Review specific file
codex "review the security of auth.py"

# Understand complex function
codex "explain how the authentication middleware works"
```

#### Bug Fixing
```bash
# Fix specific issue
codex "fix the login bug in user authentication"

# Debug failing tests
codex "investigate why the unit tests are failing"
```

#### Feature Development
```bash
# Add new functionality
codex "add user profile editing feature"

# Implement specific requirement
codex "add email validation to the registration form"
```

#### Code Improvement
```bash
# Refactor code
codex "refactor the database connection code for better error handling"

# Optimize performance
codex "optimize the search query for better performance"
```

## Working with Images

Codex CLI supports image inputs for visual debugging and analysis:

### Attach Images via CLI
```bash
# Single image
codex -i screenshot.png "Explain this error message"

# Multiple images
codex --image img1.png,img2.jpg "Compare these diagrams"
```

### Paste Images in Interactive Mode
- Copy image to clipboard
- Paste directly into the Codex CLI composer
- Add descriptive prompt about the image

## Model Selection and Configuration

### Default Model Usage
Codex uses GPT-5 by default with medium reasoning level.

### Using Different Models
```bash
# Launch with specific model
codex --model o4-mini

# Change model during session
/model
```

### Reasoning Levels
- **Low**: Fast responses, basic reasoning
- **Medium**: Balanced performance and quality (default)
- **High**: Complex tasks, detailed analysis

## Working in Projects

### Best Practices

#### 1. Initialize Git Repository
```bash
cd /path/to/your/project
git init
git add .
git commit -m "Initial commit before using Codex"
```

#### 2. Start Codex in Project Root
```bash
cd /path/to/your/project
codex
```

#### 3. Use Descriptive Prompts
```bash
# Good prompts
codex "add user authentication using JWT tokens"
codex "fix the memory leak in the image processing module"

# Less effective prompts
codex "fix this"
codex "make it better"
```

## Scripting and Automation

### Non-Interactive Mode
```bash
# Execute specific task
codex exec "run tests and fix any failures"

# Process multiple files
codex exec "add type hints to all Python files in src/"
```

### Batch Operations
```bash
# Process multiple tasks
codex exec "
1. Update all dependencies
2. Fix any breaking changes
3. Run tests to ensure everything works
"
```

## Configuration Management

### Viewing Current Configuration
```bash
# Display config file location and contents
cat ~/.codex/config.toml
```

### Advanced Configuration Options

```toml
# ~/.codex/config.toml

# Model settings
model = "gpt-5"
reasoning = "medium"

# Approval mode
approval_mode = "auto"

# Custom prompts and behavior
max_tokens = 4000
temperature = 0.1

# MCP (Model Context Protocol) servers
[mcp_servers]
# Add custom MCP servers here

# Custom tools and integrations
[tools]
# Configure additional tools
```

## Troubleshooting

### Authentication Issues

#### Problem: "Authentication failed"
```bash
# Clear saved credentials
rm -rf ~/.codex/auth
codex  # Re-authenticate
```

#### Problem: API key not recognized
```bash
# Verify environment variable
echo $OPENAI_API_KEY

# Check if variable is set correctly
env | grep OPENAI_API_KEY
```

### Performance Issues

#### Problem: Slow responses
- Try lower reasoning level: `/model` → select "Low"
- Use more specific prompts
- Break complex tasks into smaller parts

#### Problem: Out of context
- Start new session for different projects
- Use more focused prompts
- Clear conversation history

### Common Error Solutions

#### "Permission denied" errors
```bash
# Ensure Codex has proper permissions
chmod +x /usr/local/bin/codex

# Check PATH includes Codex location
echo $PATH | grep /usr/local/bin
```

#### "Command not found" errors
```bash
# Add to PATH if missing
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## Security Best Practices

### Safe Usage Guidelines

1. **Always review changes** before accepting them
2. **Use Read Only mode** for unfamiliar codebases
3. **Backup your work** with Git before major changes
4. **Be cautious with Full Access mode** in production environments
5. **Don't share API keys** or store them in version control

### Environment Isolation

```bash
# Work in isolated directories
mkdir ~/codex-workspace
cd ~/codex-workspace
codex
```

### Sensitive Data Handling

- Never input passwords, API keys, or secrets into prompts
- Use environment variables for sensitive configuration
- Review all code changes before committing

## Advanced Usage

### Model Context Protocol (MCP)

Enable MCP servers in your configuration:

```toml
# ~/.codex/config.toml
[mcp_servers]
# Add MCP server configurations
```

### Custom Tools Integration

Codex can work with your existing development tools:

- **Git integration**: Automatic commit suggestions
- **Test frameworks**: Run and analyze test results
- **CI/CD**: Debug pipeline failures
- **Package managers**: Update and manage dependencies

## Getting Help and Support

### Built-in Help
```bash
# Show command line options
codex --help

# In-session help
/help
```

### Documentation Resources
- [Official Codex CLI Documentation](https://developers.openai.com/codex/cli/)
- [GitHub Repository](https://github.com/openai/codex)
- [Community Issues](https://github.com/openai/codex/issues)

### Reporting Issues
- Check existing issues on GitHub first
- Provide detailed reproduction steps
- Include configuration details (without sensitive data)
- Share relevant log files

---

## Quick Reference Commands

| Command | Description |
|---------|-------------|
| `codex` | Start interactive session |
| `codex "prompt"` | Run with specific prompt |
| `codex exec "task"` | Non-interactive execution |
| `codex -i image.png "prompt"` | Include image input |
| `codex --help` | Show help information |
| `/approvals` | Change approval mode |
| `/model` | Change model settings |
| `/help` | In-session help |

This completes the comprehensive usage guide for Codex CLI. Follow these instructions to effectively use Codex CLI in your development workflow while maintaining security and productivity.