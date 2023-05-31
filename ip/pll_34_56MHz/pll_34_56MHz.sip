set_global_assignment -entity "pll_34_56MHz" -library "lib_pll_34_56MHz" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_34_56MHz" -library "lib_pll_34_56MHz" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "pll_34_56MHz" -library "lib_pll_34_56MHz" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_34_56MHz" -name SPD_FILE [file join $::quartus(sip_path) "pll_34_56MHz.spd"]

set_global_assignment -library "lib_pll_34_56MHz" -name MISC_FILE [file join $::quartus(sip_path) "pll_34_56MHz_sim/pll_34_56MHz.vho"]
