puts "Info: Start script [info script]\n"

############################################
#
# bsg_comm_link timing assertions
#
proc bsg_comm_link_timing_constraints { \
  iom_clk_name                          \
  ch_idx                                \
  ch_in_clk_port                        \
  ch_in_dv_port                         \
  ch_in_tkn_port                        \
  ch_out_clk_port                       \
  ch_out_dv_port                        \
  ch_out_tkn_port                       \
  input_cell_rise_fall_difference       \
  output_cell_rise_fall_difference      \
  uncertainty                           \
} {
  # determin the clock period of io master clock, io clock and token clock
  set iom_clk_period [get_attribute [get_clocks $iom_clk_name] period]
  set io_clk_period  [expr $iom_clk_period * 2.0]
  set tkn_clk_period $io_clk_period

  set max_io_skew_percent 2.5
  set max_io_skew_time [expr $max_io_skew_percent * $io_clk_period / 100.0]

  # create input io clock
  set sdi_clk sdi_${ch_idx}_clk
  create_clock -period $io_clk_period -name $sdi_clk $ch_in_clk_port
  set_clock_uncertainty $uncertainty [get_clocks $sdi_clk]

  # create input token clock
  set sdo_tkn_clk sdo_${ch_idx}_tkn_clk
  create_clock -period $tkn_clk_period -name $sdo_tkn_clk $ch_out_tkn_port
  set_clock_uncertainty $uncertainty [get_clocks $sdo_tkn_clk]

  # determin the max and min input delay
  set max_input_delay [expr ($io_clk_period / 2.0) - $max_io_skew_time]
  set min_input_delay $max_io_skew_time

  # "set_input_delay -clock" will assume data is edge aligned with clock by default
  # but in our case, the input clock is actually center aligned with data
  # we use the input delay values to determin the worst skew between clock and data
  # after they propagate through PCB traces and bond wires so that the data can be 
  # sampled correctly at the input registers (first level)
  # max_input_delay means data lags $max_input_delay-quarter($io_clk_period) behind clock
  # min_input_delay means clock lags quarter($io_clk_period)-$min_input_delay behind data
  set_input_delay -clock $sdi_clk -max $max_input_delay $ch_in_dv_port 
  set_input_delay -clock $sdi_clk -max $max_input_delay $ch_in_dv_port -add_delay -clock_fall
  set_input_delay -clock $sdi_clk -min $min_input_delay $ch_in_dv_port
  set_input_delay -clock $sdi_clk -min $min_input_delay $ch_in_dv_port -add_delay -clock_fall

  # basically we have two approaches to constrain the output paths
  # the approach of set_data_check is silicon proven while the other of
  # set_output_delay is not
  set USE_GENERATED_CLOCK 0
  if { $USE_GENERATED_CLOCK } {
    # create generated output io clock based on the edges of io master clock
    set sdo_clk sdo_${ch_idx}_clk
    create_generated_clock -edges {2 4 6} -master_clock $iom_clk_name -source [get_attribute [get_clocks $iom_clk_name] sources] -name $sdo_clk $ch_out_clk_port
  
    # determine max and min output delay
    set max_output_delay [expr ($io_clk_period / 4.0) - $max_io_skew_time]
    set min_output_delay [expr $max_io_skew_time - ($io_clk_period / 4.0)]
  
    # similarly we use the output delay values to determin the worst skew between clock and data
    # after they propagate through PCB traces and bond wires so that the data can be sampled
    # correctly at the virtual registers outside the chip
    # max_output_delay means data lags $max_output_delay behind clock
    # min_input_delay means clock lags |$min_input_delay| behind data
    set_output_delay -clock $sdo_clk -max $max_output_delay $ch_out_dv_port 
    set_output_delay -clock $sdo_clk -max $max_output_delay $ch_out_dv_port -add_delay -clock_fall
    set_output_delay -clock $sdo_clk -min $min_output_delay $ch_out_dv_port 
    set_output_delay -clock $sdo_clk -min $min_output_delay $ch_out_dv_port -add_delay -clock_fall
  } else {
    # output timing constraints
    # source synchronous output constraints
    foreach_in_collection obj $ch_out_dv_port {
      # ideally output clock is center aligned with output data, so the clock has (-25%, +25%) of clock cycle time as the sampling window
      # we check if the clock if the clock edge is in the center +/- $max_io_skew_time of the data
      set_data_check -from $ch_out_clk_port -to $obj -setup [expr $io_clk_period / 4.0 - $max_io_skew_time]
      set_data_check -from $ch_out_clk_port -to $obj -hold  [expr $io_clk_period / 4.0 - $max_io_skew_time]
      # set_data_check has a default zero cycle checking behavior which need to overcome in this case
      # please take solvnet #024664 as a reference
      set_multicycle_path -end   -setup 1 -to $obj
      set_multicycle_path -start -hold  0 -to $obj
    }
  }
}

puts "Info: Completed script [info script]\n"
