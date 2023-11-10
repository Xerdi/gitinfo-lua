CONTRIBUTION = gitinfo-lua
FILE = ${CONTRIBUTION}.tar.gz
INSTALL_PATH?=/usr/local/share/${CONTRIBUTION}

all: build clean

package: ${FILE}

build: doc/${CONTRIBUTION}.pdf

clean:
	cd doc && latexmk -c 2> /dev/null

clean-all:
	cd doc && latexmk -C 2> /dev/null && \
	rm -f ${FILE}

doc/${CONTRIBUTION}.pdf: doc/${CONTRIBUTION}.tex tex/$(wildcard *.sty) scripts/$(wildcard *.lua)
	@echo "Creating documentation PDF"
	cd doc && \
	lualatex -shell-escape ${CONTRIBUTION} > /dev/null && \
	makeindex -s gind.ist ${CONTRIBUTION}.idx 2> /dev/null && \
	lualatex -shell-escape ${CONTRIBUTION} > /dev/null

${FILE}: doc/${CONTRIBUTION}.pdf clean
	@echo "Creating package tarball"
	tar -czvf ${FILE} README.md doc scripts tex
