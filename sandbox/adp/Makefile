SOURCES=$(wildcard *.jl)
OBJECTS=$(SOURCES:.jl=.out)
all: $(OBJECTS)
%.out: %.jl
	Julia $< > $@
clean: force
	-rm *.out *.pdf *~
force:
