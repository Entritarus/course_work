set_global_assignment -entity "pll_12MHz" -library "lib_pll_12MHz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_12MHz" -library "lib_pll_12MHz" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "pll_12MHz" -library "lib_pll_12MHz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_12MHz" -name SPD_FILE [file join $::quartus(sip_path) "pll_12MHz.spd"]

set_global_assignment -library "lib_pll_12MHz" -name MISC_FILE [file join $::quartus(sip_path) "pll_12MHz_sim/pll_12MHz.vho"]
