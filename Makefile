.PHONY: practice test clean

VIM := $(if $(shell command -v nvim 2>/dev/null),nvim,vim)
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

practice:
	$(VIM) -c "source $(ROOT)plugin/vim-practice.vim" -c "VimList"

test:
	nvim --headless -u NONE -S "$(ROOT)test.vim"

clean:
	rm -rf "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))".tmp
