.PHONY: install uninstall check help

help:
	@echo "make install    - Script und Menüeintrag installieren"
	@echo "make uninstall  - beides wieder entfernen"
	@echo "make check      - shellcheck über alle Scripts laufen lassen"

install:
	@./install.sh

uninstall:
	@./uninstall.sh

check:
	@shellcheck bin/fedora-update install.sh uninstall.sh
	@desktop-file-validate share/applications/fedora-update.desktop 2>/dev/null || true
	@echo "Prüfung abgeschlossen."
