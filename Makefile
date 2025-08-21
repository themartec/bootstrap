.DEFAULT_GOAL := switch-to-mise

# terminal colours
RED     = \033[0;31m
GREEN   = \033[0;32m
YELLOW  = \033[0;33m
RESET   = \033[0m

define ANNOUNCE
echo "$(2)$(1)${NC}"
endef

.PHONY: switch-to-mise
switch-to-mise:
	@brew --version >> /dev/null || \
		{ echo "${RED}❌ Couldn't detect Homebrew${NC}"; exit 1; }
	@$(call ANNOUNCE,"✅ homebrew ready to brew bundle",${GREEN})
	@bash -c "command -v mise" >> /dev/null || \
		{ echo "let's install mise"; brew install mise; }
	@mise version >> /dev/null && \
		$(call ANNOUNCE,"✅ mise",${GREEN})
	@mise trust mise.toml
	@mise run
	@echo "\n\t${YELLOW}type ${GREEN}mise${YELLOW} to run commands\n"

.PHONY: build
build:
	@mise run build
