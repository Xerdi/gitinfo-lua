# Gitinfo Lua
![CTAN Version](https://img.shields.io/ctan/v/gitinfo-lua)

A LaTeX package which provides macros integrated with LuaTeX and the commandline tool `git`.

## Installation
In order to install this package the right way, one should create the release tarball first with `make package`.
Afterward be sure to unpack the contents of the release tarball anywhere where TeX will find it, i.e. `~/texmf`.

## Documentation
The documentation can be built using `make` or manually using `lualatex`:
```bash
make build clean
# Or manually
cd doc
lualatex -shell-escape gitinfo-lua.tex
makeindex -s gind.ist gitinfo-lua.idx
lualatex -shell-escape gitinfo-lua.tex
```

See the [releases section](https://github.com/Xerdi/gitinfo-lua/releases) for getting the latest manual.

## License
This project is licensed under the LPPL version 1.3c and maintained by Erik Nijenhuis.
See [LICENSE.txt](LICENSE.txt) for more information.
