CONTRIBUTION = gitinfo-lua
VERSION = $(shell git describe --tags --always)
CTAN_UPLOAD = ${CONTRIBUTION}-${VERSION}.tar.gz
TDS_ARCHIVE = ${CONTRIBUTION}-${VERSION}.tds.tar.gz
MANUAL = doc/${CONTRIBUTION}
CNF_LINE = -cnf-line TEXMFHOME={${CURDIR},$(shell kpsewhich --var-value TEXMFHOME)}
COMPILER = lualatex --lua=gitinfo-lua-init.lua --interaction=nonstopmode $(CNF_LINE)
RM = rm
ifeq ($(OS),Windows_NT)
RM = del
endif

TEST_PROJECT ?= ../git-test-project

all: package tds

package: ctan_upload

build: ${MANUAL}.pdf clean

tds: ${TDS_ARCHIVE}

ctan_upload: ${CTAN_UPLOAD}

scenario: ${TEST_PROJECT}

clean:
	cd doc && latexmk -c

clean-all:
	cd doc && latexmk -C
	$(RM) -f ${CTAN_UPLOAD} ${TDS_ARCHIVE}

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

${CTAN_UPLOAD}: ${MANUAL}.pdf clean
	@echo "Creating CTAN Upload"
	tar --transform 's,^\.,gitinfo-lua,' \
		--exclude=doc/.latexmkrc \
		-czvf ${CTAN_UPLOAD} ./README.md ./doc ./scripts ./tex

${TDS_ARCHIVE}: ${MANUAL}.pdf clean
	@echo "Creating TDS Archive"
	tar --transform 's,^doc,doc/lualatex/gitinfo-lua,' \
	    --transform 's,^README,doc/lualatex/gitinfo-lua/README,' \
		--transform 's,^scripts,scripts/gitinfo-lua,' \
		--transform 's,^tex,tex/lualatex/gitinfo-lua,' \
		-czvf ${TDS_ARCHIVE} README.md doc scripts tex
