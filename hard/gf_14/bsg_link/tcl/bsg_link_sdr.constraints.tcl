#
# Paul Gao 03/2021
#
# Link to BSG Link SDR Constraints User Guide:
# https://docs.google.com/document/d/1YEUgOdaGesm_mv495k7OwfxzDKGrBoQ-DphwivE91DE
#

puts "Info: Start script [info script]\n"
set BSG_LINK_SDR_USE_GENERATED_CLOCK 0

proc bsg_link_sdr_dont_touch_constraints {in_dv_port} {
  # inputs
  set_dont_touch_network -no_propagate $in_dv_port
  # outputs
  set_dont_touch_network -no_propagate [get_flat_pins -filter "full_name=~*BSG_OSDR_BUF_BSG_DONT_TOUCH/Z"]
  global BSG_LINK_SDR_USE_GENERATED_CLOCK
  puts "BSG_LINK_SDR_USE_GENERATED_CLOCK = $BSG_LINK_SDR_USE_GENERATED_CLOCK"
  if {$BSG_LINK_SDR_USE_GENERATED_CLOCK == 0} {
    set_dont_touch_network -no_propagate [get_flat_pins -filter "full_name=~*BSG_OSDR_CKBUF_BSG_DONT_TOUCH/Z"]
  }
}

proc bsg_link_sdr_disable_timing_constraints {} {
  global BSG_LINK_SDR_USE_GENERATED_CLOCK
  puts "BSG_LINK_SDR_USE_GENERATED_CLOCK = $BSG_LINK_SDR_USE_GENERATED_CLOCK"
  if {$BSG_LINK_SDR_USE_GENERATED_CLOCK == 0} {
    set_disable_timing [get_flat_pins -filter "full_name=~*BSG_OSDR_DFFPOS_BSG_DONT_TOUCH/Q"]
  }
}

proc bsg_link_sdr_in_constraints {clk_name ports max_delay min_delay} {
  set_input_delay -max $max_delay -clock $clk_name -source_latency_included -network_latency_included $ports
  set_input_delay -min $min_delay -clock $clk_name -source_latency_included -network_latency_included -add_delay $ports
}

proc bsg_link_sdr_out_constraints {clk_port ports setup_time hold_time} {
  foreach_in_collection obj $ports {
    set_data_check -rise_from $clk_port -to $obj -setup $setup_time
    set_data_check -rise_from $clk_port -to $obj -hold  $hold_time
    set_multicycle_path -end   -setup 1 -to $obj
    set_multicycle_path -start -hold  0 -to $obj
  }
}

proc bsg_link_sdr_out_generated_clock_constraints {clk_name ports max_delay min_delay} {
  set_output_delay -max $max_delay -clock $clk_name $ports
  set_output_delay -min $min_delay -clock $clk_name -add_delay $ports
}

proc bsg_link_sdr_constraints { \
  master_clk_name               \
  master_clk_port               \
  out_clk_name                  \
  out_clk_period                \
  out_clk_margin                \
  out_clk_port                  \
  out_dv_port                   \
  in_clk_name                   \
  in_clk_period                 \
  in_clk_margin                 \
  in_clk_port                   \
  in_dv_port                    \
  tkn_clk_name                  \
  tkn_clk_port                  \
  uncertainty                   \
} {
  # token
  set tkn_clk_period         [expr 2*$in_clk_period]
  create_clock -period $tkn_clk_period -name $tkn_clk_name $tkn_clk_port
  set_clock_uncertainty $uncertainty [get_clocks $tkn_clk_name]
  set_driving_cell -no_design_rule -lib_cell "SC7P5T_CKBUFX4_SSC14R" $tkn_clk_port

  # input
  set max_input_delay        [expr ($in_clk_period)-$in_clk_margin]
  set min_input_delay        [expr $in_clk_margin]
  create_clock -period $in_clk_period -name $in_clk_name $in_clk_port
  set_clock_uncertainty $uncertainty [get_clocks $in_clk_name]
  bsg_link_sdr_in_constraints $in_clk_name $in_dv_port $max_input_delay $min_input_delay
  set_driving_cell -no_design_rule -lib_cell "SC7P5T_CKBUFX4_SSC14R" $in_clk_port
  set_driving_cell -no_design_rule -lib_cell "SC7P5T_CKBUFX4_SSC14R" $in_dv_port

  # output
  global BSG_LINK_SDR_USE_GENERATED_CLOCK
  puts "BSG_LINK_SDR_USE_GENERATED_CLOCK = $BSG_LINK_SDR_USE_GENERATED_CLOCK"
  if {$BSG_LINK_SDR_USE_GENERATED_CLOCK == 0} {
    set setup_time_output      [expr ($out_clk_period/2)-$out_clk_margin]
    set hold_time_output       [expr ($out_clk_period/2)-$out_clk_margin]
    bsg_link_sdr_out_constraints $out_clk_port $out_dv_port $setup_time_output $hold_time_output
  } else {
    set max_output_delay       [expr ($out_clk_period/2)-$out_clk_margin]
    set min_output_delay       [expr $out_clk_margin-($out_clk_period/2)]
    create_generated_clock -divide_by 1 -invert -master_clock $master_clk_name -source $master_clk_port -name $out_clk_name $out_clk_port
    bsg_link_sdr_out_generated_clock_constraints $out_clk_name $out_dv_port $max_output_delay $min_output_delay
  }
  set_load [load_of [get_lib_pin "*/SC7P5T_CKBUFX4_SSC14R/CLK"]] $out_clk_port
  set_load [load_of [get_lib_pin "*/SC7P5T_CKBUFX4_SSC14R/CLK"]] $out_dv_port
}

puts "Info: Completed script [info script]\n"