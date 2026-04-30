.PHONY: practice random generate test clean

VIM := $(if $(shell command -v nvim 2>/dev/null),nvim,vim)
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

practice:
	$(VIM) -u NONE -S "$(ROOT)plugin/vim-practice.vim" -c "VimList"

random:
	python3 "$(ROOT)generate.py" "$(ROOT).tmp/random"
	$(VIM) -u NONE -S "$(ROOT)plugin/vim-practice.vim" -c "VimLoadDir $(ROOT).tmp/random"

generate:
	python3 "$(ROOT)generate.py" --batch 20 "$(ROOT)challenges"

test:
	nvim --headless -u NONE -S "$(ROOT)test.vim"

clean:
	rm -rf "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))".tmp
