# Fission Drive

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/fission-suite/drive/blob/master/LICENSE)
[![Built by FISSION](https://img.shields.io/badge/⌘-Built_by_FISSION-purple.svg)](https://fission.codes)
[![Discord](https://img.shields.io/discord/478735028319158273.svg)](https://discord.gg/zAQBDEq)
[![Discourse](https://img.shields.io/discourse/https/talk.fission.codes/topics)](https://talk.fission.codes)

The Drive application that lives on your `fission.name` domain.

# Quickstart

```shell
# 🍱
# 1. Install programming languages
#    (or install manually, see .tool-versions)
#    (https://asdf-vm.com)
#    `brew install asdf`
#    `brew install gpg2`
asdf plugin-add elm
asdf plugin-add nodejs && bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
asdf install

# 2. Install https://github.com/casey/just
#    `brew install just`
# 3. Install https://github.com/watchexec/watchexec
#    `brew install watchexec`
# 4. Install https://pnpm.js.org/
#    `brew install pnpm`
# 5. (optional) Install https://github.com/avh4/elm-format
#    `brew install elm-format`

# 5. Install dependencies
just install-deps

# 🛠
# Build, watch & start server
just
```
