SOURCES=$(wildcard *.jl)
OBJECTS=$(SOURCES:.jl=.out)
all: $(OBJECTS)
%.out: %.jl
	julia $< > $@
clean: force
	-rm *.out *.png *~
force:
