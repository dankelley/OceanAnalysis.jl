SOURCES=$(wildcard *.jl)
OBJECTS=$(SOURCES:.jl=.out)
all: $(OBJECTS)
%.out: %.jl
	julia $< &> $@
install: force
	cp amsr.jl argo_map.jl argo_profile.jl ctd_diagram.jl maps.jl ../docs/src/

clean: force
	-rm *.out *.png *~
force:
