# Using Grok CLI - Complete Guide

## Overview

Grok CLI is a conversational AI command-line tool that brings the power of Grok directly into your terminal. This guide covers all the key requirements and setup needed before using Grok CLI effectively.

## Required API Keys

### 1. Grok API Key (Required)

**Where to get it:**
- Visit [X.AI](https://x.ai/) or [Grok PromptIDE](https://ide.x.ai/)
- Login with your X (Twitter) account
- Navigate to API Keys section from your username dropdown
- Click "Create API Key"
- Select appropriate permissions:
  - `chat:write` - For full Grok access (recommended)
  - `sampler:write` - For raw Grok-1 model sampling

**Setup methods (choose one):**

#### Method 1: Environment Variable (Recommended)
```bash
# Add to ~/.bashrc or ~/.profile
export GROK_API_KEY="your_api_key_here"
source ~/.bashrc
```

#### Method 2: User Settings File
```bash
mkdir -p ~/.grok
cat > ~/.grok/user-settings.json << 'EOF'
{
  "apiKey": "your_api_key_here",
  "baseURL": "https://api.x.ai/v1",
  "defaultModel": "grok-code-fast-1"
}
EOF
```

#### Method 3: Project-level .env File
```bash
cp .env.example .env
# Edit .env and add: GROK_API_KEY=your_api_key_here
```

#### Method 4: Command Line Flag
```bash
grok --api-key your_api_key_here
```

### 2. Morph API Key (Optional but Recommended)

**Purpose:** Enables Fast Apply editing at 4,500-10,500+ tokens/second with 98% accuracy for high-speed code transformations.

**Where to get it:**
- Visit [Morph Dashboard](https://morphllm.com/dashboard/api-keys)
- Sign up and generate API key

**Setup:**
```bash
# Add to ~/.bashrc
export MORPH_API_KEY="your_morph_api_key_here"
source ~/.bashrc

# Or add to .env file
MORPH_API_KEY=your_morph_api_key_here
```

**Benefits of Morph Fast Apply:**
- Ultra-fast: 10,500+ tokens/second
- High accuracy: 98% success rate
- Intelligent editing with abbreviated format
- Automatic tool selection for complex vs simple edits

## Required Dependencies

### Option 1: Bun (Recommended)
```bash
# Install Bun for better performance
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc

# Install Grok CLI globally
bun add -g @vibe-kit/grok-cli
```

### Option 2: Node.js (Fallback)
```bash
# Install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs npm

# Install Grok CLI globally
npm install -g @vibe-kit/grok-cli
```

## Configuration Files

### User-Level Settings (~/.grok/user-settings.json)
Global settings that apply across all projects:

```json
{
  "apiKey": "your_api_key_here",
  "baseURL": "https://api.x.ai/v1",
  "defaultModel": "grok-code-fast-1",
  "models": [
    "grok-code-fast-1",
    "grok-4-latest",
    "grok-3-latest",
    "grok-3-fast",
    "grok-3-mini-fast"
  ]
}
```

### Project-Level Settings (.grok/settings.json)
Project-specific settings in your current directory:

```json
{
  "model": "grok-3-fast",
  "mcpServers": {
    "linear": {
      "name": "linear",
      "transport": "stdio",
      "command": "npx",
      "args": ["@linear/mcp-server"]
    }
  }
}
```

## Usage Modes

### Interactive Mode
```bash
# Start conversational assistant
grok

# Specify working directory
grok -d /path/to/project

# Use specific model
grok --model grok-code-fast-1
```

### Headless Mode (Automation/Scripting)
```bash
# Single prompt execution
grok --prompt "show me the package.json file"
grok -p "create a new file called example.js with a hello world function"
grok --prompt "run tests and show results" --directory /path/to/project

# Control tool execution rounds
grok --max-tool-rounds 10 --prompt "show current directory"
grok --max-tool-rounds 50 --prompt "complex refactoring task"
```

## Custom Instructions

Create project-specific behavior:

```bash
mkdir .grok
cat > .grok/GROK.md << 'EOF'
# Custom Instructions for Grok CLI

Always use TypeScript for any new code files.
When creating React components, use functional components with hooks.
Prefer const assertions and explicit typing over inference.
Always add JSDoc comments for public functions and interfaces.
Follow the existing code style and patterns in this project.
EOF
```

## Model Selection Priority

1. `--model` command line flag
2. `GROK_MODEL` environment variable
3. User default model in settings
4. System default (`grok-code-fast-1`)

## Alternative API Providers

Grok CLI supports OpenAI-compatible APIs:

```json
{
  "apiKey": "your_provider_key",
  "baseURL": "https://openrouter.ai/api/v1",
  "defaultModel": "anthropic/claude-3.5-sonnet",
  "models": [
    "anthropic/claude-3.5-sonnet",
    "openai/gpt-4o",
    "meta-llama/llama-3.1-70b-instruct"
  ]
}
```

**Popular providers:**
- X.AI (Grok): `https://api.x.ai/v1` (default)
- OpenAI: `https://api.openai.com/v1`
- OpenRouter: `https://openrouter.ai/api/v1`
- Groq: `https://api.groq.com/openai/v1`

## MCP Tools (Optional)

Extend capabilities with Model Context Protocol servers:

```bash
# Add MCP server
grok mcp add linear --transport sse --url "https://mcp.linear.app/sse"

# List servers
grok mcp list

# Test connection
grok mcp test server-name

# Remove server
grok mcp remove server-name
```

## Verification Commands

```bash
# Check installation
which grok
grok --version

# Test API key
grok --prompt "hello world"

# Check environment variables
echo $GROK_API_KEY
echo $MORPH_API_KEY
echo $GROK_MODEL
```

## Common Usage Examples

Instead of traditional CLI commands, use natural language:

- "Show me the contents of package.json"
- "Create a new file called hello.js with a simple console.log"
- "Find all TypeScript files in the src directory"
- "Replace 'oldFunction' with 'newFunction' in all JS files"
- "Run the tests and show me the results"
- "What's the current directory structure?"
- "Refactor this function to use async/await"

## Rate Limits and Costs

### Grok API
- Tied to your X subscription plan
- Basic: $3/month or $32/year
- Premium: $8/month or $84/year
- Premium+: $16/month or $168/year
- Higher plans = higher rate limits

### Rate Limit Headers
```
x-ratelimit-limit-requests: 14400 (RPD)
x-ratelimit-limit-tokens: 18000 (TPM)
x-ratelimit-remaining-requests: 14370
x-ratelimit-remaining-tokens: 17997
```

## Common Errors and Fixes

### 1. Missing API Key
**Error:** `ValueError: Trying to read the xAI API key from the XAI_API_KEY environment variable but it doesn't exist.`

**Fix:** Verify environment variable is set correctly:
```bash
export GROK_API_KEY="your_key_here"
source ~/.bashrc
```

### 2. Missing Permissions
**Error:** `API key is missing ACLs required to perform this request.`

**Fix:** Go to [ide.x.ai](https://ide.x.ai/) and edit your API key to grant required permissions (`chat:write` or `sampler:write`).

### 3. Rate Limit Exceeded
**Error:** `429 Too Many Requests`

**Fix:** Wait for the time specified in `retry-after` header, or upgrade your X subscription for higher limits.

## Security Best Practices

- Store API keys in environment variables, not in code
- Use project-level .env files for team collaboration
- Add .env to .gitignore
- Never commit API keys to version control
- Use user settings files for personal configurations

## Next Steps

Once properly configured, Grok CLI becomes a powerful conversational interface for:
- File operations and code editing
- Running shell commands through natural language
- Automated code refactoring and generation
- Integration with development workflows
- MCP tool extensions for specialized tasks

The key to success is having both the Grok API key and optionally the Morph API key properly configured in your environment before starting to use the tool.