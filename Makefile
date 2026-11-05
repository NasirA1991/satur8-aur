SHELL := /bin/bash

.PHONY: srcinfo check build clean

srcinfo:
	./scripts/gen-srcinfo.sh . > .SRCINFO
	./scripts/gen-srcinfo.sh satur8-bin > satur8-bin/.SRCINFO

check:
	@command -v makepkg >/dev/null || { echo "makepkg is required for make check" >&2; exit 1; }
	@tmp="$$(mktemp)"; trap 'rm -f "$$tmp"' EXIT; \
		makepkg --printsrcinfo > "$$tmp"; \
		./scripts/gen-srcinfo.sh . | diff -u "$$tmp" -; \
		echo "OK: satur8/.SRCINFO matches makepkg --printsrcinfo"
	@tmp="$$(mktemp)"; trap 'rm -f "$$tmp"' EXIT; \
		(cd satur8-bin && makepkg --printsrcinfo) > "$$tmp"; \
		./scripts/gen-srcinfo.sh satur8-bin | diff -u "$$tmp" -; \
		echo "OK: satur8-bin/.SRCINFO matches makepkg --printsrcinfo"
	@bash -n scripts/gen-srcinfo.sh

build:
	makepkg -si

clean:
	rm -rf src pkg satur8-bin/src satur8-bin/pkg
	rm -f ./*.pkg.tar.* satur8-bin/*.pkg.tar.* satur8-bin/*.tar.gz
