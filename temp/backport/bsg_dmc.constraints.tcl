
puts "Info: Start script [info script]\n"
set BSG_DMC_USE_GENERATED_CLOCK 1

############################################
#
# bsg_dmc datapath timing assertions
#
proc bsg_dmc_data_timing_constraints { ddr_intf_p id dfi_clk_1x_name dfi_clk_2x_name } {
  # Link to passed array parameter
  upvar 1 ${ddr_intf_p} ddr_intf

  set dfi_clk_1x_period_ns [expr [get_db [get_clocks $dfi_clk_1x_name] .period] / 1000.0 ] 

  # create input dqs clock
  set dqs_i_clk_name dqs_i[$id]
  # dfi_clk_1x and dfi_clk_2x are defined inside bsg_dram_clk_gen
  # we use their sources and cycle time to derive other dram-related clocks
  set dqs_i_clk_period_ns ${dfi_clk_1x_period_ns}
  create_clock \
    -name ${dqs_i_clk_name} \
    -period ${dqs_i_clk_period_ns} \
    [concat $ddr_intf($id,dqs_p_i) $ddr_intf($id,dqs_n_i)]

  set quarter_cycle [expr ${dqs_i_clk_period_ns} / 4.0]
  # create 90-degree shifted clock on the output of delay line

  #set dly_line_inst dmc/dmc_clk_rst_gen/dly_lines[$id].dly_line_inst
  #set dqs_i_dly_clk_name dqs_i_dly[$id]
  #set dqs_i_dly_clk_pins [get_pins ${dly_line_inst}/clk_o]
  #set dqs_i_dly_clk_edges {1 2 3}
  #set dqs_i_dly_clk_quarter [expr ${dqs_i_clk_period_ns} / 4]
  #set dqs_i_dly_clk_edge_shift [list ${dqs_i_dly_clk_quarter} ${dqs_i_dly_clk_quarter} ${dqs_i_dly_clk_quarter}]
  #create_generated_clock -name ${dqs_i_dly_clk_name} \
  #                       -edges ${dqs_i_dly_clk_edges} \
  #                       -edge_shift ${dqs_i_dly_clk_edge_shift} \
  #                       -master_clock [get_clocks ${dqs_i_clk_name}] \
  #                       -source [get_db [get_clocks ${dqs_i_clk_name}] .sources] \
  #                       -add ${dqs_i_dly_clk_pins}

  set max_io_skew_percent 5.0
  set max_io_skew_time [expr $max_io_skew_percent * $dfi_clk_1x_period_ns / 100.0]

  # determine the max and min input delay
  set max_input_delay [expr ($dfi_clk_1x_period_ns / 4.0) - $max_io_skew_time]
  set min_input_delay -$max_input_delay

  # input timing constraints
  # input data (dq) is edge aligned with input clock (dqs) after getting out of dram chips
  # we set 20% of the clock cycle time to account for the misalignment when the signals propagate through the pcb traces and bond wire
  set_input_delay  $max_input_delay $ddr_intf($id,dq_i) -clock [get_clocks dqs_i[$id]] -max
  set_input_delay -$max_input_delay $ddr_intf($id,dq_i) -clock [get_clocks dqs_i[$id]] -min

  # basically we have two approaches to constrain the output paths
  global BSG_DMC_USE_GENERATED_CLOCK
  puts "BSG_DMC_USE_GENERATED_CLOCK = $BSG_DMC_USE_GENERATED_CLOCK"
  if { ! ${BSG_DMC_USE_GENERATED_CLOCK} } {
  # output timing constraints
  # source synchronous output constraints, similar to comm_link output channels
    foreach_in_collection from_obj $ddr_intf($id,dqs_p_o) {
      foreach_in_collection to_obj [concat $ddr_intf($id,dq_o) $ddr_intf($id,dm_o)] {
        # ideally output clock is center aligned with output data, so the clock has (-25%, +25%) of clock cycle time as the sampling window
        # we deduct 20% from the margin and check if the clock is in the scope of (-5%, +5%) of the data center
        set_data_check -from $from_obj -to $to_obj [expr $dfi_clk_1x_period_ns * 0.2]
        # set_data_check has a default zero cycle checking behavior which need to overcome in this case
        # please take solvnet #024664 as a reference
        set_multicycle_path -end -setup 1 -to $to_obj
        set_multicycle_path -start -hold 0 -to $to_obj
      }
    }
  } else {
    # create generated output dqs clock based on 1x dfi clock
    set dqs_o_clk_name dqs_o[$id]
    create_generated_clock \
        -name ${dqs_o_clk_name} \
        -divide_by 2 \
        -master_clock $dfi_clk_2x_name \
        -source [get_db [get_clocks $dfi_clk_2x_name] .sources] \
        -add [concat $ddr_intf($id,dqs_p_o) $ddr_intf($id,dqs_n_o)]
  
    # determine max and min output delay
    set max_output_delay $max_input_delay
    set min_output_delay $min_input_delay
  
    # similarly we use the output delay values to determin the worst skew between clock and data
    # after they propagate through PCB traces and bond wires so that the data can be sampled
    # correctly at the virtual registers outside the chip
    # max_output_delay means data lags $max_output_delay behind clock
    # min_input_delay means clock lags |$min_input_delay| behind data
    set_output_delay -clock dqs_o[$id] -max $max_output_delay [concat $ddr_intf($id,dq_o) $ddr_intf($id,dqs_en_o) $ddr_intf($id,dm_o)]
    set_output_delay -clock dqs_o[$id] -max $max_output_delay [concat $ddr_intf($id,dq_o) $ddr_intf($id,dqs_en_o) $ddr_intf($id,dm_o)] -add_delay -clock_fall
    set_output_delay -clock dqs_o[$id] -min $min_output_delay [concat $ddr_intf($id,dq_o) $ddr_intf($id,dqs_en_o) $ddr_intf($id,dm_o)] 
    set_output_delay -clock dqs_o[$id] -min $min_output_delay [concat $ddr_intf($id,dq_o) $ddr_intf($id,dqs_en_o) $ddr_intf($id,dm_o)] -add_delay -clock_fall
  }
}

############################################
#
# bsg_dmc address and command path timing assertions
#
proc bsg_dmc_ctrl_timing_constraints { ddr_intf_p dfi_clk_1x_name dfi_clk_2x_name } {
  # Link to passed array parameter
  upvar 1 ${ddr_intf_p} ddr_intf
  # dfi_clk_1x and dfi_clk_2x are defined inside bsg_dram_clk_gen
  # we use their sources and cycle time to derive other dram-related clocks
  set dfi_clk_1x_period_ns [expr [get_db [get_clocks $dfi_clk_1x_name] .period] / 1000.0]
  set dfi_clk_1x_source [get_db [get_clocks $dfi_clk_1x_name] .sources]
  # create generated clocks to drive dram device, all the address and command signals are synchronous to these clocks
  create_generated_clock -name ddr_ck_p -divide_by 1         -source $dfi_clk_1x_source -master_clock [get_clocks $dfi_clk_1x_name] -add $ddr_intf(ck_p)
  create_generated_clock -name ddr_ck_n -divide_by 1 -invert -source $dfi_clk_1x_source -master_clock [get_clocks $dfi_clk_1x_name] -add $ddr_intf(ck_n)
  # all the address and command signals are registered outputs which are aligned well with clock edges
  # we give it a 10% margin to account for the misalignment caused by PCB traces and bond wires
  set_output_delay [expr  $dfi_clk_1x_period_ns * 0.1] $ddr_intf(ca) -clock [get_clocks ddr_ck_p] -max
  set_output_delay [expr -$dfi_clk_1x_period_ns * 0.1] $ddr_intf(ca) -clock [get_clocks ddr_ck_p] -min
}

puts "Info: Completed script [info script]\n"
