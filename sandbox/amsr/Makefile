Styp=$(wildcard *.typ)
Otyp=$(Stype:.typ=.pdf)
Sjl=$(wildcard *.jl)
Ojl=$(Sjl:.jl=.out)
SR=$(wildcard *.R)
OR=$(SR:.R=.out)
all: $(Otyp) $(Ojl) $(OR)
%.pdf: %.typ
	typst compile $<
%.out: %.jl
	julia $< > $@
%.out: %.R
	Rscript $< > $@
clean: force
	-rm *.out *.pdf *png *~
force:
