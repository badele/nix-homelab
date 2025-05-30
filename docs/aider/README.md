# Aider Configuration

This document describes the setup of [Aider](https://aider.chat/), an AI pair
programming tool. The configuration integrates Aider with various AI models,
providing a powerful and flexible AI-assisted development environment.

## Overview

Aider's configuration is primarily managed through the file
`nix/home-manager/apps/development/aider.nix`, which handles the following:

- Installs `aider-chat-full`
- Creates the configuration files `.aider.conf.yml` and
  `.aider.model.settings.yml`

Additionally, custom scripts (`my-aider` and `my-aider-models`) are used to
manage API key retrieval and model listing, particularly for GitHub Copilot.

## API Key Management

The `my-aider` script integrates API keys from various providers.

### GitHub Copilot

For GitHub Copilot, the API key is automatically retrieved by the `my-aider`
script from the file: `~/.config/github-copilot/apps.json`.

### Google Gemini Integration

The `my-aider` script also supports integration with Google Gemini:

- **API Key Retrieval**: The `GEMINI_API_KEY` is fetched from your password
  store (`pass`) at `home/bruno/gemini/aider/API-KEY`.
- The key is then exported as an environment variable before launching Aider.

## Usage

To run Aider with this configuration, use the `my-aider` script. It sets up the
required environment variables for both Copilot and Gemini, then launches Aider.

```bash
my-aider
```

To list the available models from the Copilot API, use:

```bash
my-aider-models
```

![aider](/docs/aider/aider.png)
