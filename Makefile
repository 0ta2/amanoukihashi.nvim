.PHONY: test

test:
	nvim --headless -u spec/minimal_init.lua -c "PlenaryBustedDirectory spec/ {}" -c "qa"
