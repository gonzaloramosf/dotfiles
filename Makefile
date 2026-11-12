.DEFAULT_GOAL := install

COMPONENTS := homebrew jetbrains-font zed zsh ghostty skhd yabai no-sleep-speaker macos-settings firefox-settings
SELECTED_COMPONENTS := $(filter $(COMPONENTS),$(MAKECMDGOALS))
MODES := $(filter install update,$(MAKECMDGOALS))
UNKNOWN_GOALS := $(filter-out install update help $(COMPONENTS),$(MAKECMDGOALS))

ifneq ($(strip $(UNKNOWN_GOALS)),)
$(error Unknown target(s): $(UNKNOWN_GOALS))
endif
ifeq ($(words $(MODES)),2)
$(error Choose either install or update, not both)
endif

.PHONY: install update help $(COMPONENTS)
.NOTPARALLEL:

install update:
	bash ./install.sh $(SELECTED_COMPONENTS)

$(COMPONENTS):
ifeq ($(strip $(MODES)),)
	bash ./install.sh $@
else
	@:
endif

help:
	@printf '%s\n' \
	  'Usage examples:' \
	  '  make install                 Run the full setup' \
	  '  make update                  Reapply the full setup' \
	  '  make install zed             Install and configure Zed only' \
	  '  make update zsh ghostty      Reapply selected components' \
	  '  make zed                     Shorthand for make install zed' \
	  '  make help                    Show this help' \
	  '' \
	  'Available components:'
	@printf '%s\n' '$(COMPONENTS)' | sed 's/ /, /g; s/^/  /'
