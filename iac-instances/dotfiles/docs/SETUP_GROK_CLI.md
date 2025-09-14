# Grok CLI Setup Instructions

## Overview

Grok CLI is a conversational AI command-line tool powered by Grok that brings AI assistance directly into your terminal with intelligent file operations, bash integration, and automatic tool selection.

## Prerequisites

### System Requirements
- Ubuntu 22.04 or Ubuntu 24.04 (freshly installed)
- Internet connection for package downloads

### Required Dependencies

#### Option 1: Bun (Recommended)
```bash
# Install Bun (recommended for better performance)
curl -fsSL https://bun.sh/install | bash
source ~/.bashrc
```

#### Option 2: Node.js (Fallback)
```bash
# If Bun is not available, install Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs npm
```

## Installation

### Global Installation (Recommended)

Using Bun:
```bash
bun add -g @vibe-kit/grok-cli
```

Using npm (fallback):
```bash
npm install -g @vibe-kit/grok-cli
```

### Verify Installation
```bash
grok --version
```

## API Key Setup

### Get Your Grok API Key
1. Visit [X.AI](https://x.ai/) to obtain your Grok API key
2. Sign up/login and navigate to API settings to generate your key

### Configure API Key (Choose One Method)

#### Method 1: Environment Variable (Recommended)
```bash
# Add to ~/.bashrc or ~/.profile
echo 'export GROK_API_KEY="your_api_key_here"' >> ~/.bashrc
source ~/.bashrc
```

#### Method 2: User Settings File
```bash
# Create grok directory
mkdir -p ~/.grok

# Create user settings file
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
# In your project directory
cp .env.example .env
# Edit .env and add: GROK_API_KEY=your_api_key_here
```

## Optional: Morph Fast Apply Setup

For high-speed code editing (4,500+ tokens/sec):

1. Get Morph API key from [Morph Dashboard](https://morphllm.com/dashboard/api-keys)
2. Configure the key:

```bash
# Add to ~/.bashrc
echo 'export MORPH_API_KEY="your_morph_api_key_here"' >> ~/.bashrc
source ~/.bashrc
```

## Basic Usage

### Interactive Mode
```bash
# Start conversational AI assistant
grok

# Specify working directory
grok -d /path/to/project
```

### Headless Mode (for scripts/automation)
```bash
# Single prompt execution
grok --prompt "show me the package.json file"
grok -p "create a new file called example.js with a hello world function"
grok --prompt "run tests and show results" --directory /path/to/project
```

### Example Conversations
Instead of typing commands, tell Grok what you want:

- "Show me the contents of package.json"
- "Create a new file called hello.js with a simple console.log"
- "Find all TypeScript files in the src directory"
- "Replace 'oldFunction' with 'newFunction' in all JS files"
- "Run the tests and show me the results"
- "What's the current directory structure?"

## Configuration Options

### Custom Instructions
Create project-specific behavior by adding `.grok/GROK.md`:

```bash
mkdir .grok
cat > .grok/GROK.md << 'EOF'
# Custom Instructions for Grok CLI

Always use TypeScript for any new code files.
When creating React components, use functional components with hooks.
Prefer const assertions and explicit typing over inference where it improves clarity.
Always add JSDoc comments for public functions and interfaces.
Follow the existing code style and patterns in this project.
EOF
```

### Model Selection
```bash
# Use specific model
grok --model grok-code-fast-1
grok --model grok-4-latest

# Set default model via environment
export GROK_MODEL=grok-code-fast-1
```

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure proper npm/bun global installation permissions
2. **API key not found**: Verify environment variable is set and sourced
3. **Network issues**: Check internet connectivity and firewall settings

### Verification Commands
```bash
# Check installation
which grok
grok --version

# Test API key
grok --prompt "hello world"

# Check environment variables
echo $GROK_API_KEY
echo $MORPH_API_KEY
```

## Features Overview

- **Conversational AI**: Natural language interface powered by Grok-3
- **Smart File Operations**: AI automatically uses tools to view, create, and edit files
- **Bash Integration**: Execute shell commands through natural conversation
- **Automatic Tool Selection**: AI intelligently chooses the right tools
- **Interactive UI**: Beautiful terminal interface built with Ink
- **MCP Tools**: Extend capabilities with Model Context Protocol servers
- **Global Installation**: Use anywhere after installation

## Security Notes

- Store API keys securely using environment variables or user settings files
- Never commit API keys to version control
- Use project-level .env files for team collaboration (add .env to .gitignore)

## Additional Resources

- [Official Website](https://grokcli.io/)
- [GitHub Repository](https://github.com/superagent-ai/grok-cli)
- [X.AI Platform](https://x.ai/)
- [Morph Dashboard](https://morphllm.com/dashboard/api-keys)