.PHONY: practice test clean

VIM := $(if $(shell command -v nvim 2>/dev/null),nvim,vim)

practice:
	$(VIM) -S "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))practice.vim"

test:
	nvim --headless -u NONE -S "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))test.vim"

clean:
	rm -rf "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))".tmp
