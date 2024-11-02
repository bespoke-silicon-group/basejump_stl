##############################
# Constraints file for design
##############################

reset_design

# 500 MHz Clock
create_clock -name clk -period 4.5 [get_ports clk]

# create_clock -period 4.5 -name vclk

set_clock_uncertainty -setup 0.1 [get_clocks clk]

set_clock_transition 0.05 [get_clocks clk]

# Using default "Operating Conditions" 

# set_input_delay -clock clk -max 0.2 [get_ports "a2 b* c* d*"]
# remove_input_delay [get_ports clk]
# 
# set_input_delay -clock clk -max 1.9 [get_ports a1]
# 
# set_input_delay -clock clk -max 0.05 [get_ports M]
# set_input_delay -clock clk -max 0.2 [get_ports X]
# set_input_delay -clock clk -max 0.3 [get_ports N]
# 
# set_input_delay -clock clk -max 0.1 [get_ports sel1]
# set_input_delay -clock clk -max 1.0 [get_ports sel2]
# 
# set_input_delay -clock vclk -max 0.1 [all_inputs]

set_max_area 200000.0

set_input_delay -clock clk -max 0.0 [all_inputs]

# set_driving_cell -lib_cell inv0d1 [all_inputs]
# remove_driving_cell [get_ports clk]

# set_output_delay -clock vclk -max 0.2 [all_outputs]

set_output_delay -clock clk -max 0.0 [all_outputs]

set_load 0.5 [all_outputs]
