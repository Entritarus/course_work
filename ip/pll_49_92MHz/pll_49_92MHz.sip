set_global_assignment -entity "pll_49_92MHz" -library "lib_pll_49_92MHz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_49_92MHz" -library "lib_pll_49_92MHz" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "pll_49_92MHz" -library "lib_pll_49_92MHz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_49_92MHz" -name SPD_FILE [file join $::quartus(sip_path) "pll_49_92MHz.spd"]

set_global_assignment -library "lib_pll_49_92MHz" -name MISC_FILE [file join $::quartus(sip_path) "pll_49_92MHz_sim/pll_49_92MHz.vho"]
