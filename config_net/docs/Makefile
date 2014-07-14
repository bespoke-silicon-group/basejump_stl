include makefile/latex/tex.mk

BASENAME = 20130219

viewpdf: pdf
	$(PDFVIEWER) $(BASENAME).pdf

pdf:
	$(MAKE) $(BASENAME).aux
	$(MAKE) $(BASENAME).bbl
	$(MAKE) $(BASENAME).pdf
	$(MAKE) --always-make $(BASENAME).pdf

clean:
	make common-clean
	make -f ../Makefile -C figures common-clean
