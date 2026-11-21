puts "Info: Start script [info script]\n"

############################################
#
# bsg_dmc datapath timing assertions
#
proc bsg_dmc_data_timing_constraints { \
  grp_idx                              \
  dfi_clk_1x_name                      \
  dfi_clk_2x_name                      \
  dqs_i                                \
  dqs_o                                \
  dm_o                                 \
  dq_i                                 \
  dq_o                                 \
} {
  # dfi_clk_1x and dfi_clk_2x are defined inside bsg_dram_clk_gen
  # we use their sources and cycle time to derive other dram-related clocks
  set dfi_clk_1x_period [expr [get_attribute [get_clocks $dfi_clk_2x_name] period] * 2.0]
  set dfi_clk_1x_source [get_attribute [get_clocks $dfi_clk_1x_name] sources]
  # create input dqs clock
  create_clock -period $dfi_clk_1x_period \
               -name dqs_${grp_idx}    \
               $dqs_i

  set quarter_cycle [expr [get_attribute [get_clocks dqs_${grp_idx}] period] / 4.0]
  # create 90-degree shifted clock on the output of delay line
  create_generated_clock -name dqs_${grp_idx}_dly \
                         -edges {1 2 3} \
                         -edge_shift [list $quarter_cycle $quarter_cycle $quarter_cycle] \
                         -source [get_pins -of_objects [get_cells -of_objects [get_nets -of_objects [get_attribute [get_clocks dqs_${grp_idx}] sources]]] -filter "direction==out"]  \
                         [get_pins -leaf -of_objects [get_nets -hierarchical dly_clk_o[${grp_idx}]] -filter "direction==out"]

  # input timing constraints
  # input data (dq) is edge aligned with input clock (dqs) after getting out of dram chips
  # we set 5% of the clock cycle time to account for the misalignment when the signals propagate through the pcb traces and bond wires
  set_input_delay  [expr  [get_attribute [get_clocks dqs_${grp_idx}] period] * 0.05] $dq_i -clock [get_clocks dqs_${grp_idx}] -max
  set_input_delay  [expr -[get_attribute [get_clocks dqs_${grp_idx}] period] * 0.05] $dq_i -clock [get_clocks dqs_${grp_idx}] -min

  # output timing constraints
  # source synchronous output constraints, similar to comm_link output channels
  foreach_in_collection from_obj $dqs_o {
    foreach_in_collection to_obj [concat $dq_o $dm_o] {
      # ideally output clock is center aligned with output data, so the clock has (-25%, +25%) of clock cycle time as the sampling window
      # we deduct 20% from the margin and check if the clock is in the scope of (-5%, +5%) of the data center
      set_data_check -from $from_obj -to $to_obj [expr $dfi_clk_1x_period * 0.2]
      # set_data_check has a default zero cycle checking behavior which need to overcome in this case
      # please take solvnet #024664 as a reference
      set_multicycle_path -end -setup 1 -to $to_obj
      set_multicycle_path -start -hold 0 -to $to_obj
    }
  }
}

############################################
#
# bsg_dmc address and command path timing assertions
#
proc bsg_dmc_ctrl_timing_constraints { \
  dfi_clk_1x_name                      \
  dfi_clk_2x_name                      \
  ck_p                                 \
  ck_n                                 \
  ctrl_signals                         \
} {
  # dfi_clk_1x and dfi_clk_2x are defined inside bsg_dram_clk_gen
  # we use their sources and cycle time to derive other dram-related clocks
  set dfi_clk_1x_period [expr [get_attribute [get_clocks $dfi_clk_2x_name] period] * 2.0]
  set dfi_clk_1x_source [get_attribute [get_clocks $dfi_clk_1x_name] sources]
  # create generated clocks to drive dram device, all the address and command signals are synchronous to these clocks
  create_generated_clock -name ddr_ck_p -divide_by 1         -source $dfi_clk_1x_source -master_clock [get_clocks $dfi_clk_1x_name] $ck_p
  create_generated_clock -name ddr_ck_n -divide_by 1 -invert -source $dfi_clk_1x_source -master_clock [get_clocks $dfi_clk_1x_name] $ck_n
  # all the address and command signals are registered outputs which are aligned well with clock edges
  # we give it a 10% margin to account for the misalignment caused by PCB traces and bond wires
  set_output_delay [expr  $dfi_clk_1x_period * 0.1] $ctrl_signals -clock [get_clocks ddr_ck_p] -max
  set_output_delay [expr -$dfi_clk_1x_period * 0.1] $ctrl_signals -clock [get_clocks ddr_ck_p] -min
}

puts "Info: Completed script [info script]\n"
