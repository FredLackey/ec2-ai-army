# Claude Code Installation Guide for Ubuntu 22/24

This guide provides step-by-step instructions for installing Claude Code on fresh Ubuntu 22 or Ubuntu 24 instances.

## System Requirements

- **Operating System**: Ubuntu 20.04+/Debian 10+ (includes Ubuntu 22 and 24)
- **Hardware**: 4GB+ RAM
- **Software**: Node.js 18+
- **Network**: Internet connection required for authentication and AI processing
- **Location**: Anthropic supported countries

## Prerequisites

Before installing Claude Code, ensure your system has the following:

### 1. Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Required Dependencies

```bash
# Install essential packages
sudo apt install -y curl git build-essential

# Install ripgrep (for search functionality)
sudo apt install -y ripgrep
```

### 3. Install Node.js 18+

```bash
# Remove any existing Node.js installation (optional)
sudo apt remove -y nodejs npm

# Install Node.js 20.x LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v20.x.x
npm --version   # Should show 10.x.x or higher
```

### 4. Configure npm for Global Packages (Recommended)

To avoid permission issues, configure npm to install global packages in your user directory:

```bash
# Create global npm directory
mkdir -p ~/.npm-global

# Configure npm to use the global directory
npm config set prefix ~/.npm-global

# Add to PATH
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

## Installation Methods

### Method 1: Standard npm Installation (Recommended)

```bash
npm install -g @anthropic-ai/claude-code
```

**Important:** Do NOT use `sudo npm install -g` as this can lead to permission issues and security risks.

### Method 2: Native Binary Installation (Beta)

For improved performance, you can use the native binary installer:

```bash
# Install stable version (default)
curl -fsSL https://claude.ai/install.sh | bash

# Install latest version
curl -fsSL https://claude.ai/install.sh | bash -s latest

# Install specific version
curl -fsSL https://claude.ai/install.sh | bash -s 1.0.58
```

**Note for Alpine Linux**: Native builds require additional packages:
```bash
apk add libgcc libstdc++ ripgrep
export USE_BUILTIN_RIPGREP=0
```

## Verification and Setup

### 1. Verify Installation

```bash
claude --version
```

You should see the current version of Claude Code.

### 2. Run Installation Doctor

```bash
claude doctor
```

This command checks your installation and identifies any issues.

### 3. First-Time Setup and Authentication

Navigate to your project directory and start Claude Code:

```bash
cd your-awesome-project
claude
```

On first launch, you'll be guided through a one-time OAuth process with the following authentication options:

1. **Anthropic Console** (Default): Connect through the Anthropic Console and complete OAuth. Requires active billing at [console.anthropic.com](https://console.anthropic.com/).

2. **Claude App (Pro or Max plan)**: Subscribe to Claude's Pro or Max plan for unified subscription. Log in with your Claude.ai account.

3. **Enterprise platforms**: Configure to use Amazon Bedrock or Google Vertex AI for enterprise deployments.

## Troubleshooting Common Issues

### "Command Not Found" Error

If you encounter a "command not found" error:

```bash
# Check your PATH configuration
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Node.js Version Issues

Ensure you have Node.js 18 or higher:

```bash
node --version  # Should be 18.x or higher
```

If you need to upgrade, repeat the Node.js installation steps.

### Authentication Failures

If authentication fails:

```bash
# Logout and login again
claude logout
claude login
```

Ensure your Anthropic account has active billing.

### Permission Issues

If you encounter permission errors during installation:

1. Never use `sudo` with npm global installs
2. Ensure you've configured the npm global directory correctly
3. Check that your user has write permissions to `~/.npm-global`

### Search Functionality Issues

If search functionality fails, ensure ripgrep is installed:

```bash
sudo apt install ripgrep
```

## Updates and Maintenance

### Auto-Updates

Claude Code automatically updates itself. To disable auto-updates:

```bash
export DISABLE_AUTOUPDATER=1
```

Add this to your `~/.bashrc` to make it permanent.

### Manual Updates

```bash
claude update
```

### Migration from npm to Native Binary

If you have an existing npm installation and want to migrate to the native binary:

```bash
claude install
```

## Security Best Practices

1. **Never use sudo** when installing or running Claude Code
2. **Review commands** before approving them in Claude Code
3. **Configure ignores** for sensitive directories
4. **Keep updated** with regular `claude update` commands
5. **Use environment variables** for API key management when applicable

## Enterprise Considerations

For enterprise deployments:

- Start with a pilot group to establish usage patterns
- Set up workspace spending limits in Anthropic Console
- Consider development container setups for consistent environments
- Implement network access controls for sensitive environments
- Review [third-party integrations](https://docs.anthropic.com/en/docs/claude-code/third-party-integrations) for AWS/GCP usage

## Additional Resources

- [Official Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Troubleshooting Guide](https://docs.anthropic.com/en/docs/claude-code/troubleshooting)
- [Third-Party Integrations](https://docs.anthropic.com/en/docs/claude-code/third-party-integrations)
- [Identity and Access Management](https://docs.anthropic.com/en/docs/claude-code/iam)

## Getting Started

Once installed, you can start using Claude Code by:

1. Navigating to your project directory
2. Running `claude` to start an interactive session
3. Asking Claude to help with your coding tasks

Example:
```bash
cd your-project
claude
> help me understand this codebase
```

Claude Code is now ready to assist with your development workflow!