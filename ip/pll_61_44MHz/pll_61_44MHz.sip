set_global_assignment -entity "pll_61_44MHz" -library "lib_pll_61_44MHz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_61_44MHz" -library "lib_pll_61_44MHz" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "pll_61_44MHz" -library "lib_pll_61_44MHz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_61_44MHz" -name SPD_FILE [file join $::quartus(sip_path) "pll_61_44MHz.spd"]

set_global_assignment -library "lib_pll_61_44MHz" -name MISC_FILE [file join $::quartus(sip_path) "pll_61_44MHz_sim/pll_61_44MHz.vho"]
