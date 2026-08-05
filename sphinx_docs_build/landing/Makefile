# Minimal makefile for the Sphinx landing page

SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = source
OUTPUTDIR     = ../../docs
DOCTREEDIR    = .doctrees

.PHONY: html clean help

help:
	@echo "Please use 'make <target>' where target is html or clean."

html:
	@$(SPHINXBUILD) -b html -d $(DOCTREEDIR) $(SPHINXOPTS) $(SOURCEDIR) $(OUTPUTDIR)
	@echo "Build finished. The HTML pages are in $(OUTPUTDIR)."

clean:
	rm -rf $(DOCTREEDIR)