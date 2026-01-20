jlSOURCES=$(wildcard *.jl)
jlOBJECTS=$(jlSOURCES:.jl=.out)
RSOURCES=$(wildcard *.R)
ROBJECTS=$(RSOURCES:.R=.out)
all: $(jlOBJECTS) $(ROBJECTS)
%.out: %.jl
	Julia $< > $@
%.out: %.R
	Rscript $< > $@
clean: force
	-rm *.out *.pdf *~
force:
