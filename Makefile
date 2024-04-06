CONTRIBUTION = gitinfo-lua
VERSION = $(shell git describe --tags --always)
FILE = ${CONTRIBUTION}-${VERSION}.tar.gz
MANUAL = doc/${CONTRIBUTION}
CNF_LINE = -cnf-line TEXMFHOME={${CURDIR},$(shell kpsewhich --var-value TEXMFHOME)} -cnf-line shell_escape_commands=git
COMPILER = lualatex --shell-restricted --interaction=nonstopmode $(CNF_LINE)
RM = rm
ifeq ($(OS),Windows_NT)
RM = del
endif

TEST_PROJECT ?= ../git-test-project

all: build clean

package: ${FILE}

build: ${MANUAL}.pdf

scenario: ${TEST_PROJECT}

clean:
	cd doc && latexmk -c

clean-all:
	cd doc && latexmk -C && \
	$(RM) -f ${FILE}

${TEST_PROJECT}:
	mkdir -p ${TEST_PROJECT}
	cp -f doc/git-scenario.sh ${TEST_PROJECT}
	cd ${TEST_PROJECT} && git init
	cd ${TEST_PROJECT} && ./git-scenario.sh

${MANUAL}.aux: ${MANUAL}.tex
	cd doc && $(COMPILER) ${CONTRIBUTION}

${MANUAL}.idx: ${MANUAL}.aux
	cd doc && makeindex -s gind.ist ${CONTRIBUTION}.idx

${MANUAL}.pdf: scenario ${MANUAL}.idx ${MANUAL}.tex $(wildcard tex/*.sty) $(wildcard scripts/*.lua)
	@echo "Creating documentation PDF"
	cd doc && $(COMPILER) ${CONTRIBUTION}

${FILE}: ${MANUAL}.pdf clean
	@echo "Creating package tarball"
	tar --transform 's,^\.,gitinfo-lua,' \
		--exclude=doc/.latexmkrc \
		-czvf ${FILE} ./README.md ./doc ./scripts ./tex
