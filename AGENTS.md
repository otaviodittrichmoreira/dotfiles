# Repository Guide

This is a personal Linux dotfiles repository, not a buildable application. Top-level directories hold files at their target home-relative paths: for example, `nvim/.config/nvim`, `i3/.config/i3`, `zsh/.zshrc`, and `tmux/.tmux.conf`. Preserve that layout when adding configuration.

## Validation

- There is no tracked CI, task runner, formatter, linter, or unified test suite. Validate only the configuration touched.
- Check the i3 configuration with `i3 -C -c i3/.config/i3/config`.
- Check edited shell scripts with `bash -n path/to/script.sh` before relying on a live reload.
- Reload i3 with `Mod1+Shift+c`; it starts Polybar through `polybar/.config/polybar/launch_polybar.sh`, which launches one `toph` bar per connected monitor.
- Reload tmux configuration with its configured prefix shortcut: `C-a r`.

## Neovim

- Neovim starts at `nvim/.config/nvim/init.vim`, which sets the Python host to `~/.venvs/nvim/bin/python`, loads `lua/init.lua`, then sources `color.vim`.
- `lua/init.lua` loads the shared configuration modules. Plugin specs are explicitly required in `lua/kickstart.lua`; `lua/pluggins/` is not auto-discovered despite its name.
- `kickstart.lua` bootstraps `lazy.nvim` under Neovim's data directory if absent. Keep `nvim/.config/nvim/lazy-lock.json` unchanged unless intentionally changing plugin resolution.
- Custom UltiSnips snippets live in `nvim/.config/nvim/UltiSnips/`; use the configured `<Leader>ur` mapping to refresh them in a running Neovim session.

## Coupled Desktop Config

- The i3 config calls scripts from `~/.config/i3/scripts` and starts Polybar from `~/.config/polybar/launch_polybar.sh`; changes across these paths are often coupled.
- The tab/workspace bindings in i3 depend on `go_workspace.sh`, `switch_tab.sh`, `move_to_tab.sh`, and `move_to_workspace.sh`. Keep their argument conventions aligned with the bindings.
- `tmux/.tmux.conf` has bindings that assume this checkout is at `~/dotfiles`; update those paths if the repository location changes.

## Managed Dependencies

- Yazi plugin and flavor revisions are pinned in `yazi/.config/yazi/package.toml`; update its revision and hash together when updating a managed dependency.
- `miscellaneos/package_list.txt`, `cargo_packages.txt`, and `pip_freeze_*.txt` are environment inventories, not install manifests or lockfiles.
