# Gitinfo Lua
![CTAN Version](https://img.shields.io/ctan/v/gitinfo-lua)
[![build](https://github.com/Xerdi/gitinfo-lua/actions/workflows/build.yml/badge.svg?branch=master)](https://github.com/Xerdi/gitinfo-lua/actions/workflows/build.yml)

A LaTeX package which provides macros integrated with LuaTeX and the commandline tool `git`.

## Installation
The recommended way of installing is using `tlmgr install gitinfo-lua`.
If you can't update/install packages with `tlmgr`, you can download the latest `gitinfo-lua-<version>.tds.tar.gz` from the [releases page](https://github.com/Xerdi/gitinfo-lua/releases) and then unpack it in your `TEXMFHOME`.
To find out where your `TEXMFHOME` is, you can consult `kpsewhich --var-value TEXMFHOME` on the commandline.

## Documentation
A prerequisite is that you have the [texmf-packaging](https://github.com/Xerdi/texmf-packaging) available in your `TEXMFHOME`.
The documentation can be built using `make build clean` or manually using `lualatex`:
```bash
# Using the original TEXMFHOME and the project directory
CNF_LINE="TEXMFHOME={$(pwd),$(kpsewhich --var-value TEXMFHOME)}"
cd doc
lualatex --lua=gitinfo-lua-init.lua --cnf-line $CNF_LINE gitinfo-lua
makeindex -s gind.ist gitinfo-lua.idx
lualatex --lua=gitinfo-lua-init.lua --cnf-line $CNF_LINE gitinfo-lua
```
To do the same as the Lua initialization script, commandline option `--shell-restricted` should be passed and `git` should be added to `shell_escape_commands` in your `texmf.cnf`.
The `texmf.cnf` file to edit can be found with `kpsewhich texmf.cnf`.

See the [releases section](https://github.com/Xerdi/gitinfo-lua/releases) for getting the latest manual.

## License
This project is licensed under the LPPL version 1.3c and maintained by Erik Nijenhuis.
See [LICENSE.txt](LICENSE.txt) for more information.
