TEX_PATH ?= /usr/bin

# OS-dependent defs
OS = $(shell uname)
ifneq (, $(findstring Darwin, $(OS)))
  PDFVIEWER ?= open -a Preview.app
else
  PDFVIEWER ?= evince
endif

# General tools
MAKE = make

# TexWorks: https://code.google.com/p/texworks
PDFLATEX = $(TEX_PATH)/pdflatex
#XELATEX = $(TEX_PATH)/xelatex
XELATEX = $(TEX_PATH)/latex
XDVIPDFMX = $(TEX_PATH)/xdvipdfmx
BIBER = $(TEX_PATH)/biber
BIBTEX = $(TEX_PATH)/bibtex

BASENAME=20130219

all: 
	convert figures/ucsd_ccores.png figures/ucsd_ccores.eps
	latex $(BASENAME)
	bibtex $(BASENAME).aux
	latex $(BASENAME)
	latex $(BASENAME)
	dvipdf $(BASENAME)


clean:
	rm -f *.dvi  *.toc *.blg *.bbl *.log *.aux $(BASENAME).pdf figures/*.aux figures/ucsd_ccores.eps

viewpdf:
	$(PDFVIEWER) $(BASENAME).pdf &
