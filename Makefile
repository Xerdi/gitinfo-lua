CONTRIBUTION = git-latex
INSTALL_PATH?=/usr/local/share/${CONTRIBUTION}
NAME = Erik Nijenhuis
EMAIL = erik@xerdi.com
DIRECTORY = /macros/latex/contrib/${CONTRIBUTION}
LICENSE = free
FREEVERSION = lppl
FILE = ${CONTRIBUTION}.tar.gz
export CONTRIBUTION VERSION NAME EMAIL SUMMARY DIRECTORY DONOTANNOUNCE \
	ANNOUNCE NOTES LICENSE FREEVERSION FILE

all: build clean

package: ${FILE}

prepare: ${CONTRIBUTION}.tds.zip

install: ${CONTRIBUTION}.tds.zip
	@echo "Installing in ${INSTALL_PATH}"
	unzip -d ${INSTALL_PATH} ${CONTRIBUTION}.tds.zip
	@echo "Note, the TDS tree has to be set as well and `update-texmf`\
	 has to be consulted afterward."

uninstall:
#	don't remove everything
	rm -rf ${INSTALL_PATH}

upload: ${FILE}
	@echo uploading (ctanupload -p)

build: ${CONTRIBUTION}.pdf

clean:
	latexmk -c 2> /dev/null
	rm -f lua.idx lua.ilg lua.ind

clean-all: clean
	rm -f ${FILE}
	rm -f ${CONTRIBUTION}.tds.zip

${CONTRIBUTION}.pdf: ${CONTRIBUTION}.tex
	@echo "Creating documentation PDF"
	lualatex -shell-escape ${CONTRIBUTION}.tex > /dev/null
	makeindex -s gind.ist ${CONTRIBUTION}.idx 2> /dev/null
#	makeindex -s gind.ist lua.idx 2> /dev/null
#	makeindex -s gglo.ist -o ${CONTRIBUTION}.gls ${CONTRIBUTION}.glo 2> /dev/null
	lualatex -shell-escape ${CONTRIBUTION}.tex > /dev/null

${FILE}: ${CONTRIBUTION}.pdf
	@echo "Creating package tarball"
	ctanify --pkgname=${CONTRIBUTION} git.sty git-latex.pdf git-cmd.lua git-latex.lua --tds "*.lua=scripts/git-latex/lua" > /dev/null

${CONTRIBUTION}.tds.zip: ${FILE}
	@echo "Extracting TDS zip file"
	tar --extract --file=$^ $@
