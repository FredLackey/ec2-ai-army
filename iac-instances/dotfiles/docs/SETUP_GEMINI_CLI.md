# Gemini CLI Setup Guide for Ubuntu 22/24

This guide provides step-by-step instructions for installing and configuring Google's Gemini CLI on a freshly installed Ubuntu 22 or Ubuntu 24 server.

## What is Gemini CLI?

Gemini CLI is Google's open-source AI agent that brings the power of Gemini directly into your terminal. It provides:

- **AI-powered coding assistance** with 1M+ token context window
- **Large codebase analysis** and editing capabilities
- **Built-in tools** for file operations, shell commands, and web search
- **MCP (Model Context Protocol) support** for extensibility
- **Free tier access** with personal Google account (60 requests/min, 1,000/day)

## Prerequisites

Before starting, ensure your Ubuntu server has:

- **Ubuntu 22.04 LTS or Ubuntu 24.04 LTS**
- **Sudo privileges** for software installation
- **Internet connection** for downloading packages
- **Google Account** for authentication

## Step 1: Update System Packages

First, update your system packages to ensure you have the latest versions:

```bash
sudo apt update
sudo apt upgrade -y
```

## Step 2: Install Node.js and npm

Gemini CLI requires **Node.js version 20 or higher**. Ubuntu's default repositories may have older versions, so we'll install from NodeSource.

### Check Current Node.js Version (if installed)

```bash
node -v
npm -v
```

### Install Latest Node.js (Recommended Method)

Install the latest Node.js from NodeSource repository:

```bash
# Download and run the NodeSource setup script
curl -fsSL https://deb.nodesource.com/setup_lts.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh

# Install Node.js and npm
sudo apt-get install -y nodejs
```

### Verify Installation

```bash
node -v    # Should show v20.x or higher
npm -v     # Should show npm version
```

## Step 3: Install Gemini CLI

There are several installation methods. Choose the one that best fits your needs:

### Method 1: Global Installation (Recommended)

Install Gemini CLI globally so it's available system-wide:

```bash
sudo npm install -g @google/gemini-cli
```

### Method 2: Run Without Installation

You can run Gemini CLI without installing it using npx:

```bash
npx @google/gemini-cli
```

### Method 3: Install Specific Version

To install a specific version (preview, stable, or nightly):

```bash
# Preview version (updated weekly)
sudo npm install -g @google/gemini-cli@preview

# Stable version (default)
sudo npm install -g @google/gemini-cli@latest

# Nightly version (daily updates)
sudo npm install -g @google/gemini-cli@nightly
```

## Step 4: Verify Installation

Test that Gemini CLI is properly installed:

```bash
gemini --version
```

You should see the version number displayed.

## Step 5: Initial Setup and Authentication

When you first run Gemini CLI, it will guide you through the setup process:

```bash
gemini
```

### Authentication Options

Choose one of the following authentication methods:

#### Option 1: Login with Google (Recommended for Individual Use)

- **Best for**: Individual developers and personal projects
- **Free tier**: 60 requests/min, 1,000 requests/day
- **Process**:
  1. Select "Login with Google" when prompted
  2. Follow the browser authentication flow
  3. Sign in with your Google account
  4. Return to terminal after successful authentication

**Note**: If you have a Google Workspace account or Gemini Code Assist license, you may need to set a Google Cloud Project:

```bash
export GOOGLE_CLOUD_PROJECT="your-project-id"
```

#### Option 2: Gemini API Key

- **Best for**: Developers who need specific model control
- **Setup**:
  1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
  2. Generate an API key
  3. Set environment variable:

```bash
export GEMINI_API_KEY="your-api-key-here"
```

#### Option 3: Vertex AI

- **Best for**: Enterprise users and production workloads
- **Setup**:
  1. Get API key from Google Cloud Console
  2. Set environment variables:

```bash
export GOOGLE_API_KEY="your-google-api-key"
export GOOGLE_GENAI_USE_VERTEXAI=true
```

## Step 6: Persistent Environment Variables

To make environment variables persistent across sessions, add them to your shell configuration file:

### For Bash users:

```bash
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

### For Zsh users:

```bash
echo 'export GEMINI_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc
```

### Using .env Files (Recommended)

Create a Gemini-specific environment file:

```bash
# Create .gemini directory in your home folder
mkdir -p ~/.gemini

# Add your API key to the .env file
cat >> ~/.gemini/.env <<'EOF'
GEMINI_API_KEY="your-api-key-here"
GOOGLE_CLOUD_PROJECT="your-project-id"
EOF
```

## Step 7: Basic Usage Examples

### Start Gemini CLI

```bash
# Start in current directory
gemini

# Include multiple directories
gemini --include-directories ../lib,../docs

# Use specific model
gemini -m gemini-2.5-flash
```

### Non-Interactive Mode

For scripting and automation:

```bash
# Simple text response
gemini -p "Explain how to optimize this code"

# JSON output for scripting
gemini -p "Analyze this codebase structure" --output-format json
```

## Step 8: Configuration and Customization

### Theme Selection

On first run, you can choose from different visual themes to customize the CLI appearance.

### Project-Specific Settings

Create a `.gemini/.env` file in your project directory for project-specific configurations:

```bash
mkdir -p .gemini
echo 'GOOGLE_CLOUD_PROJECT="project-specific-id"' >> .gemini/.env
```

## Troubleshooting

### Common Issues and Solutions

#### Node.js Version Error
```bash
# Check version
node -v
# If less than v20, reinstall Node.js using the NodeSource method above
```

#### Permission Errors
```bash
# Use sudo for global installations
sudo npm install -g @google/gemini-cli
```

#### Authentication Failures
- Ensure your browser can access localhost during OAuth flow
- Check that you're using the correct Google account
- Verify environment variables are set correctly

#### Network or Model Issues
- Gemini CLI automatically switches between models if connection issues occur
- Check your internet connection
- Verify API quotas haven't been exceeded

### Getting Help

- Use `/help` command within Gemini CLI for available commands
- Check the [official documentation](https://github.com/google-gemini/gemini-cli)
- Report bugs using `/bug` command or on [GitHub Issues](https://github.com/google-gemini/gemini-cli/issues)

## Advanced Features

### MCP Server Integration

Extend Gemini CLI with custom tools by configuring MCP servers in `~/.gemini/settings.json`.

### Non-Interactive/Headless Mode

For server environments without browser access, use API key authentication:

```bash
export GEMINI_API_KEY="your-api-key"
export GOOGLE_GENAI_USE_VERTEXAI=true  # Optional for Vertex AI
gemini -p "Your prompt here"
```

## Security Considerations

- **API Key Storage**: Store API keys securely and never commit them to version control
- **Environment Variables**: Be cautious when exporting keys in shell configuration files
- **Permissions**: Use appropriate file permissions for `.env` files:

```bash
chmod 600 ~/.gemini/.env
```

## Next Steps

After successful installation:

1. **Explore Commands**: Run `gemini` and type `/help` to see available commands
2. **Try Examples**: Test basic code analysis and generation tasks
3. **Configure MCP**: Set up additional tools and integrations as needed
4. **Read Documentation**: Visit the [official docs](https://github.com/google-gemini/gemini-cli) for advanced usage

## Uninstallation

If you need to remove Gemini CLI:

```bash
# Remove global installation
sudo npm uninstall -g @google/gemini-cli

# Clean up configuration (optional)
rm -rf ~/.gemini
```

## Additional Resources

- **Official Repository**: [https://github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)
- **NPM Package**: [https://www.npmjs.com/package/@google/gemini-cli](https://www.npmjs.com/package/@google/gemini-cli)
- **Google AI Studio**: [https://aistudio.google.com/](https://aistudio.google.com/)
- **Documentation**: [https://google-gemini.github.io/gemini-cli/](https://google-gemini.github.io/gemini-cli/)

---

This guide provides a comprehensive setup process for Gemini CLI on Ubuntu servers. The CLI offers powerful AI assistance directly in your terminal and can significantly enhance your development workflow.