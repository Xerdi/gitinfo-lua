# Git LaTeX

A LaTeX package which provides macros integrated with LuaTeX and the commandline tool `git`.

## Installation
In order to install this package the 'TDS' tree has to be copied to a directory LaTeX will search in.
Consult `tlmgr conf texmf TEXMFHOME` to get any ideas of where that should be.

In order to get the TDS tree of `git-latex`'s source run `make prepare`.
This target uses package `ctanify`, which is a perl module.
Make sure to have the Perl module `libfile-copy-recursive-perl`.
Afterward it can be installed with:
```bash
# Default installing in /usr/local/share
sudo make install
# Installing in a user directory
export INSTALL_PATH=~/.local/share
make install
# Or install in an already known TDS structure
export INSTALL_PATH=~/texmf
make install
```

Note that when using the existing `~/texmf` directory, one should **NOT** use `make uninstall`, for that also erases your existing files in `~/texmf`.

For adding a TDS directory manually consult the documentation of TDS.
For Debian systems it's pretty straightforward.
One can easily add a configuration file which sets the `TEXMFAUXTREES` in `/etc/texmf/texmf.d`.
```bash
TEXMFAUXTREES=/usr/local/share/git-latex,
```
*/etc/texmf/texmf.d/01xerdi.cnf*

Afterward execute `update-texmf` with root permissions.
It can be validated by the output of: `kpsewhich -var-value TEXMFAUXTREES`.

## Documentation
The documentation can be built using `make` or manually using `lualatex`:
```bash
lualatex -shell-escape git-latex.tex
makeindex -s gind.ist git-latex.idx
lualatex -shell-escape git-latex.tex
```

Read [git-latex.pdf](git-latex.pdf) for more information about this package.

## License
This project is licensed under the LPPL version 1.3c and maintained by Erik Nijenhuis.
See [LICENSE.pdf](LICENSE.pdf) for more information.
