# config-sync

Personal configuration files synced across macOS, Ubuntu, Kali, RedHat, and WSL.

## Quick Install

```bash
git clone git@github.com:USERNAME/config-sync.git ~/.config-sync && ~/.config-sync/setup.sh
```

Replace `USERNAME` with your GitHub username.

## What's Included

| Tool | Description | Config Files |
|------|-------------|--------------|
| [yazi](https://github.com/sxyazi/yazi) | Terminal file manager | `yazi.toml`, `keymap.toml`, flavors |
| [btop](https://github.com/aristocratos/btop) | Resource monitor | `btop.conf` |
| [powerline](https://github.com/powerline/powerline) | Statusline plugin | themes, colorschemes |
| [git](https://git-scm.com/) | Global gitignore | `ignore` |
| [glow](https://github.com/charmbracelet/glow) | Terminal markdown renderer | `glow.yml` |
| [devcontainer](https://containers.dev/) | VS Code devcontainer overrides | `docker-compose.override.yml` |

## Supported Platforms

- macOS (Intel/Apple Silicon)
- Ubuntu Linux
- Kali Linux
- RedHat / Fedora
- Windows WSL

## How It Works

The setup script:

1. Detects your platform and distribution
2. Checks which tools are installed
3. Backs up any existing configs to `~/.config/config-sync-backup-<timestamp>/`
4. Creates symlinks from `~/.config/<tool>` to `~/.config-sync/<tool>`
5. Configures git `core.excludesfile` to use the synced gitignore

## Manual Setup

If you prefer to run steps manually:

```bash
# Clone the repo
git clone git@github.com:USERNAME/config-sync.git ~/.config-sync

# Run setup
~/.config-sync/setup.sh
```

Or create symlinks yourself:

```bash
ln -sf ~/.config-sync/btop ~/.config/btop
ln -sf ~/.config-sync/yazi ~/.config/yazi
ln -sf ~/.config-sync/powerline ~/.config/powerline
ln -sf ~/.config-sync/git ~/.config/git
ln -sf ~/.config-sync/glow ~/Library/Preferences/glow  # macOS; use ~/.config/glow on Linux
ln -sf ~/.config-sync/devcontainer ~/.config/devcontainer

# Configure git to use the global ignore file
git config --global core.excludesfile ~/.config/git/ignore
```

## Adding New Configs

1. Copy the config folder to `~/.config-sync/`
2. Add the tool to `TOOLS` in `setup.sh`
3. Add a case in `get_config_path()` if it has a non-standard location
4. Commit and push

## Notes

### macOS

XDG_CONFIG_HOME is not set by default. Most tools still use `~/.config/` but you can add this to `~/.zshrc` for full XDG compliance:

```bash
export XDG_CONFIG_HOME="$HOME/.config"
```

### WSL

Git configuration in WSL is separate from Windows Git. These configs won't affect Git Bash or other Windows Git installations.

### btop on macOS

btop can use either `~/.config/btop/` or `~/Library/Application Support/btop/`. The setup script prefers the XDG location for consistency across platforms.
