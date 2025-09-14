# Codex CLI Setup Guide for Ubuntu 22/24 Servers

This guide provides step-by-step instructions for installing OpenAI's Codex CLI on a fresh Ubuntu 22.04 or Ubuntu 24.04 server.

## What is Codex CLI?

Codex CLI is OpenAI's open-source command-line coding agent that runs locally on your machine. It can read, modify, and execute code directly in your terminal, helping you build features, fix bugs, and understand unfamiliar codebases.

## System Requirements

Before installing Codex CLI, ensure your Ubuntu server meets these requirements:

- **Operating System**: Ubuntu 20.04+ or Debian 10+ (Ubuntu 22/24 recommended)
- **Node.js**: Version 22 or newer (LTS recommended)
- **Git**: Version 2.23+ (optional but recommended for built-in PR helpers)
- **RAM**: Minimum 4 GB (8 GB recommended for better performance)
- **Architecture**: x86_64 or arm64

## Installation Methods

You can install Codex CLI using one of three methods:

### Method 1: NPM Installation (Recommended)

This is the easiest and most common installation method.

#### Step 1: Install Node.js

First, update your package list and install Node.js 22 LTS:

```bash
# Update package list
sudo apt update

# Install curl if not already installed
sudo apt install -y curl

# Install Node.js 22 LTS using NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

#### Step 2: Install Codex CLI globally

```bash
# Install Codex CLI globally
npm install -g @openai/codex

# Verify installation
codex --version
```

### Method 2: Binary Download

If you prefer not to use npm or don't want to install Node.js, you can download pre-built binaries.

#### Step 1: Download the appropriate binary

For **x86_64** systems:
```bash
# Create a directory for codex
sudo mkdir -p /usr/local/bin

# Download the binary
curl -L -o codex.tar.gz https://github.com/openai/codex/releases/latest/download/codex-x86_64-unknown-linux-musl.tar.gz

# Extract the binary
tar -xzf codex.tar.gz

# Move to system path and rename
sudo mv codex-x86_64-unknown-linux-musl /usr/local/bin/codex

# Make executable
sudo chmod +x /usr/local/bin/codex

# Clean up
rm codex.tar.gz
```

For **ARM64** systems:
```bash
# Create a directory for codex
sudo mkdir -p /usr/local/bin

# Download the binary
curl -L -o codex.tar.gz https://github.com/openai/codex/releases/latest/download/codex-aarch64-unknown-linux-musl.tar.gz

# Extract the binary
tar -xzf codex.tar.gz

# Move to system path and rename
sudo mv codex-aarch64-unknown-linux-musl /usr/local/bin/codex

# Make executable
sudo chmod +x /usr/local/bin/codex

# Clean up
rm codex.tar.gz
```

#### Step 2: Verify installation

```bash
# Check if codex is accessible
codex --version
```

### Method 3: Build from Source

For advanced users who want to build from source:

#### Step 1: Install Rust

```bash
# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source the cargo environment
source "$HOME/.cargo/env"

# Add required components
rustup component add rustfmt clippy
```

#### Step 2: Clone and build

```bash
# Clone the repository
git clone https://github.com/openai/codex.git
cd codex/codex-rs

# Build Codex
cargo build --release

# Move binary to system path
sudo cp target/release/codex /usr/local/bin/

# Verify installation
codex --version
```

## Optional: Install Git (Recommended)

Git is recommended for built-in PR helpers and version control integration:

```bash
# Install Git
sudo apt install -y git

# Configure Git (replace with your details)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify installation
git --version
```

## First Run and Authentication

### Step 1: Initial Setup

Run Codex CLI for the first time:

```bash
codex
```

On first run, you'll see an authentication prompt.

### Step 2: Authentication Options

You have two authentication options:

#### Option A: Sign in with ChatGPT Account (Recommended)

1. Select **"Sign in with ChatGPT"** when prompted
2. This allows you to use Codex with your ChatGPT Plus, Pro, Team, Edu, or Enterprise plan
3. Follow the authentication flow in your browser

#### Option B: Use OpenAI API Key

1. If you prefer to use an API key, you'll need to set up usage-based billing
2. Set your API key as an environment variable:

```bash
# Add to your shell profile (.bashrc, .zshrc, etc.)
echo 'export OPENAI_API_KEY="your-api-key-here"' >> ~/.bashrc
source ~/.bashrc
```

## Configuration

### Configuration File Location

Codex CLI stores its configuration in `~/.codex/config.toml`. This file is created automatically on first run.

### Basic Configuration

You can customize approval modes, models, and other settings:

```bash
# Open configuration file
nano ~/.codex/config.toml
```

### Approval Modes

Codex CLI has three approval modes:

- **Auto** (default): Codex can read files, make edits, and run commands in the working directory automatically, but needs approval for network access or working outside the directory
- **Read Only**: Codex can only read files and propose changes, requiring your approval for all modifications
- **Full Access**: Codex can read, write, and execute commands with network access without approval (use with caution)

Change approval mode during use with the `/approvals` command.

## Usage Examples

### Basic Usage

```bash
# Start interactive mode
codex

# Run with a specific prompt
codex "explain this codebase"

# Run with image input
codex -i screenshot.png "Explain this error"

# Non-interactive execution
codex exec "fix the CI failure"
```

### Working in a Project Directory

```bash
# Navigate to your project
cd /path/to/your/project

# Initialize git repository if not already done
git init

# Start codex in the project directory
codex
```

## Upgrading Codex CLI

### If installed via NPM:

```bash
npm install -g @openai/codex@latest
```

### If installed via binary:

Repeat the binary download steps with the latest release.

## Troubleshooting

### Common Issues

1. **Permission denied errors**: Ensure the binary has execute permissions with `chmod +x`

2. **Command not found**: Check that `/usr/local/bin` is in your PATH:
   ```bash
   echo $PATH
   # If not present, add to ~/.bashrc:
   echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

3. **Node.js version issues**: Ensure you have Node.js 22+ installed:
   ```bash
   node --version
   ```

4. **Authentication problems**: Check the [authentication documentation](https://github.com/openai/codex/blob/main/docs/authentication.md) for detailed troubleshooting.

### Getting Help

- Run `codex --help` for command-line options
- Visit the [official documentation](https://developers.openai.com/codex/cli/)
- Check the [GitHub repository](https://github.com/openai/codex) for issues and documentation
- Report issues at [github.com/openai/codex/issues](https://github.com/openai/codex/issues)

## Security Considerations

- Always review what Codex is doing, especially in "Full Access" mode
- Use Git to track changes and create backups before major modifications
- Be cautious when running Codex on sensitive codebases or production servers
- Consider using "Read Only" mode for initial exploration of unfamiliar codebases

## Next Steps

After installation:

1. Navigate to a project directory
2. Run `codex` to start the interactive terminal UI
3. Try basic prompts like "explain this codebase" or "help me fix this bug"
4. Explore the various approval modes and settings
5. Read the full documentation at [github.com/openai/codex](https://github.com/openai/codex)

---

*This guide covers Ubuntu 22.04 and Ubuntu 24.04 LTS server installations. For other operating systems or advanced configuration options, refer to the official Codex CLI documentation.*