jSOURCES=$(wildcard *.jl)
jOBJECTS=$(jSOURCES:.jl=.out)
rSOURCES=$(wildcard *.R)
rOBJECTS=$(rSOURCES:.R=.out)
all: $(jOBJECTS) $(rOBJECTS)
%.out: %.jl
	julia $< &> $@
%.out: %.R
	Rscript $< &> $@
clean: force
	-rm *.out *.png *~
force:
