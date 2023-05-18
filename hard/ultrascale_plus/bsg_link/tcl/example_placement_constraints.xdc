
# This is an example for placing only one pin / one bank
# User should copy-n-paste these constraints for all pins / banks in the design

# Internal Vref for Conn
# User should modify bank numbers
set_property INTERNAL_VREF 0.900 [get_iobanks 64]

# DCI Cascade
# The 240 ohm resistor can be cascaded to other banks if needed
set_property DCI_CASCADE {64} [get_iobanks 65]

# Output Channel
# User should modify package_pins and port names
set_property PACKAGE_PIN B11      [get_ports { fmc_clk_o    }];
set_property PACKAGE_PIN A14      [get_ports {   fmc_v_o    }];
set_property PACKAGE_PIN F14      [get_ports { fmc_tkn_i    }]; # (GC)
set_property PACKAGE_PIN G13      [get_ports {fmc_data_o[0] }];

set_property IOSTANDARD  SSTL18_I  [get_ports {fmc_clk_o fmc_v_o fmc_data_o[*] fmc_tkn_i}];
# Alternaticely, replace SSTL18_I with SSTL18_I_DCI to enable DCI
set_property SLEW        FAST      [get_ports {fmc_clk_o fmc_v_o fmc_data_o[*]}];
set_property ODT         RTT_48    [get_ports {fmc_tkn_i}];
set_property OUTPUT_IMPEDANCE RDRV_48_48 [get_ports {fmc_clk_o fmc_v_o fmc_data_o[*]}];

# Input Channel
# User should modify package_pins and port names
set_property PACKAGE_PIN BJ4      [get_ports { fmc_clk_i    }]; # (GC)
set_property PACKAGE_PIN BN6      [get_ports {   fmc_v_i    }];
set_property PACKAGE_PIN BN5      [get_ports { fmc_tkn_o    }];
set_property PACKAGE_PIN BF7      [get_ports {fmc_data_i[0] }];

set_property IOSTANDARD  SSTL18_I  [get_ports {fmc_clk_i fmc_v_i fmc_data_i[*] fmc_tkn_o}];
# Alternaticely, replace SSTL18_I with SSTL18_I_DCI to enable DCI
set_property ODT         RTT_48    [get_ports {fmc_clk_i fmc_v_i fmc_data_i[*]}];
set_property SLEW        FAST      [get_ports {fmc_tkn_o}];
set_property OUTPUT_IMPEDANCE RDRV_48_48 [get_ports {fmc_tkn_o}];

# placement constraints
# User should modify the clockregions and get_cells list
create_pblock                    pblock_up01
add_cells_to_pblock [get_pblocks pblock_up01] [get_cells -quiet [list uplink upstream_node]]
resize_pblock       [get_pblocks pblock_up01] -add {CLOCKREGION_X4Y6:CLOCKREGION_X4Y6}

create_pblock                    pblock_down01
add_cells_to_pblock [get_pblocks pblock_down01] [get_cells -quiet [list downlink downstream_node]]
resize_pblock       [get_pblocks pblock_down01] -add {CLOCKREGION_X4Y5:CLOCKREGION_X4Y5}
