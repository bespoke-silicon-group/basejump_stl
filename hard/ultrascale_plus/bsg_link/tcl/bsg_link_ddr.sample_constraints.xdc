# User should re-define periods / names / ports / pins / margins
# Then add the following lines into the .xdc constraint file

# create input clock
set fmc_input_clk_period         2.000
set fmc_input_clk_name           fmc_clk_in
set fmc_input_clk_port           [get_ports fmc_clk_i]
create_clock -name $fmc_input_clk_name -period $fmc_input_clk_period $fmc_input_clk_port

# create output clock
set fmc_output_clk_name          fmc_clk_out
set fmc_output_clk_pin           [get_pins uplink/ch[0].oddr_phy/ODDRE1_clk/C]
set fmc_output_clk_port          [get_ports fmc_clk_o]
create_generated_clock -name $fmc_output_clk_name -source $fmc_output_clk_pin -edges {1 2 3} -edge_shift {0 0 0} $fmc_output_clk_port

# input delay margins
set dv_bre                 1.0
set dv_are                 1.0
set dv_bfe                 1.0
set dv_afe                 1.0

# input delay constraints
set fmc_input_data_port          [get_ports {fmc_data_i[*] fmc_v_i}]
set_input_delay -clock $fmc_input_clk_name -max [expr $fmc_input_clk_period/2 - $dv_bre] $fmc_input_data_port
set_input_delay -clock $fmc_input_clk_name -min $dv_are                                  $fmc_input_data_port
set_input_delay -clock $fmc_input_clk_name -max [expr $fmc_input_clk_period/2 - $dv_bfe] $fmc_input_data_port -clock_fall -add_delay
set_input_delay -clock $fmc_input_clk_name -min $dv_afe                                  $fmc_input_data_port -clock_fall -add_delay

# output delay margins
set tsu_r                  0.8
set thd_r                  0.8
set tsu_f                  0.8
set thd_f                  0.8

# output delay constraints
set fmc_output_data_port         [get_ports {fmc_data_o[*] fmc_v_o}]
set_output_delay -clock $fmc_output_clk_name -max [expr $fmc_input_clk_period/4 + $fmc_input_clk_period/2 - $tsu_r] $fmc_output_data_port
set_output_delay -clock $fmc_output_clk_name -min [expr $fmc_input_clk_period/4 + $thd_r]                           $fmc_output_data_port
set_output_delay -clock $fmc_output_clk_name -max [expr $fmc_input_clk_period/4 + $fmc_input_clk_period/2 - $tsu_f] $fmc_output_data_port -clock_fall -add_delay
set_output_delay -clock $fmc_output_clk_name -min [expr $fmc_input_clk_period/4 + $thd_f]                           $fmc_output_data_port -clock_fall -add_delay
