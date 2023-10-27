CONTRIBUTION = git-latex
NAME = Erik Nijenhuis
EMAIL = erik@xerdi.com
DIRECTORY = /macros/latex/contrib/${CONTRIBUTION}
LICENSE = free
FREEVERSION = lppl
FILE = ${CONTRIBUTION}.tar.gz
export CONTRIBUTION VERSION NAME EMAIL SUMMARY DIRECTORY DONOTANNOUNCE \
	ANNOUNCE NOTES LICENSE FREEVERSION FILE

all: build clean

upload: package
	echo uploading (ctanupload -p)

package: ${FILE}

build: pre-build indices
	lualatex -shell-escape ${CONTRIBUTION}.tex > /dev/null

clean:
	latexmk -c > /dev/null
	rm -f lua.idx lua.ilg lua.ind
	rm -f pkgopts.idx pkgopts.ilg pkgopts.ind
	rm -f ${FILE}

pre-build:
	lualatex -shell-escape ${CONTRIBUTION}.tex > /dev/null

indices:
	makeindex -s gind.ist ${CONTRIBUTION}.idx
	makeindex -s gind.ist lua.idx
	makeindex -s gind.ist pkgopts.idx
	makeindex -s gglo.ist -o ${CONTRIBUTION}.gls ${CONTRIBUTION}.glo

${FILE}: build
	ctanify --pkgname=${CONTRIBUTION} git.sty git-latex.pdf git-cmd.lua git-latex.lua --tds "*.lua=scripts/git-latex/lua" > /dev/null
