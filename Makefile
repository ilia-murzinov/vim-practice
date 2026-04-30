.PHONY: practice test clean

practice:
	vim -S "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))practice.vim"

test:
	vim --headless -u NONE -S "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))test.vim"

clean:
	rm -rf "$(dir $(abspath $(lastword $(MAKEFILE_LIST))))".tmp
