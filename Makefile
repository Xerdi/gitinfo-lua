CONTRIBUTION = gitinfo-lua
FILE = ${CONTRIBUTION}.tar.gz
MANUAL = doc/${CONTRIBUTION}
COMPILER = lualatex --shell-escape

TEST_PROJECT ?= ../git-test-project

all: build clean

package: ${FILE}

build: ${MANUAL}.pdf

scenario: ${TEST_PROJECT}

clean:
	cd doc && latexmk -c 2> /dev/null

clean-all:
	cd doc && latexmk -C 2> /dev/null && \
	rm -f ${FILE}

${TEST_PROJECT}:
	mkdir -p ${TEST_PROJECT}
	cp -f doc/git-scenario.sh ${TEST_PROJECT}
	cd ${TEST_PROJECT} && git init
	cd ${TEST_PROJECT} && ./git-scenario.sh

${MANUAL}.aux: ${MANUAL}.tex
	cd doc && $(COMPILER) ${CONTRIBUTION}

${MANUAL}.idx: ${MANUAL}.aux
	cd doc && makeindex -s gind.ist ${CONTRIBUTION}.idx

${MANUAL}.pdf: scenario ${MANUAL}.idx ${MANUAL}.tex tex/$(wildcard *.sty) scripts/$(wildcard *.lua)
	@echo "Creating documentation PDF"
	cd doc && $(COMPILER) ${CONTRIBUTION}
	while grep 'Rerun to get ' doc/${CONTRIBUTION}.log ; do cd doc && $(COMPILER) ${CONTRIBUTION} ; done

${FILE}: ${MANUAL}.pdf clean
	@echo "Creating package tarball"
	tar --transform 's,^\.,gitinfo-lua,' -czvf ${FILE} ./README.md ./doc ./scripts ./tex
