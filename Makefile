SHELL := /bin/bash

.PHONY: srcinfo check build clean

srcinfo:
	./scripts/gen-srcinfo.sh > .SRCINFO

check:
	@command -v makepkg >/dev/null || { echo "makepkg is required for make check" >&2; exit 1; }
	@tmp="$$(mktemp)"; trap 'rm -f "$$tmp"' EXIT; \
		makepkg --printsrcinfo > "$$tmp"; \
		./scripts/gen-srcinfo.sh | diff -u "$$tmp" -; \
		echo "OK: .SRCINFO matches makepkg --printsrcinfo"
	@bash -n scripts/gen-srcinfo.sh

build:
	makepkg -si

clean:
	rm -rf src pkg
	rm -f ./*.pkg.tar.*
