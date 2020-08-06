# Fission Drive

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/fission-suite/drive/blob/master/LICENSE)
[![Built by FISSION](https://img.shields.io/badge/⌘-Built_by_FISSION-purple.svg)](https://fission.codes)
[![Discord](https://img.shields.io/discord/478735028319158273.svg)](https://discord.gg/zAQBDEq)
[![Discourse](https://img.shields.io/discourse/https/talk.fission.codes/topics)](https://talk.fission.codes)

First-party application for your Fission filesystem.


## Development

This project uses Nix to manage the project's environment. If you'd like to build this project without Nix, check out the dependencies in the `shell.nix` file (most are available through Homebrew as well).

```shell
# Install javascript dependencies
just install-deps

# Build, watch & serve
just

# Production build
just production-build

# Use a different config
just config=local-lobby dev-build
```
