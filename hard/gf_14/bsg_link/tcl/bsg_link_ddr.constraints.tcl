#
# Paul Gao 03/2021
#
#

puts "Info: Start script [info script]\n"
set BSG_LINK_DDR_USE_GENERATED_CLOCK 0

proc bsg_link_ddr_in_constraints {clk_name ports max_delay min_delay} {
  set_input_delay -max $max_delay -clock $clk_name -source_latency_included -network_latency_included $ports
  set_input_delay -max $max_delay -clock $clk_name -source_latency_included -network_latency_included $ports -add_delay -clock_fall
  set_input_delay -min $min_delay -clock $clk_name -source_latency_included -network_latency_included $ports
  set_input_delay -min $min_delay -clock $clk_name -source_latency_included -network_latency_included $ports -add_delay -clock_fall
}

proc bsg_link_ddr_out_constraints {clk_port ports setup_time hold_time} {
  foreach_in_collection obj $ports {
    set_data_check -from $clk_port -to $obj -setup $setup_time
    set_data_check -from $clk_port -to $obj -hold  $hold_time
    set_multicycle_path -end   -setup 1 -to $obj
    set_multicycle_path -start -hold  0 -to $obj
  }
}

proc bsg_link_ddr_out_generated_clock_constraints {clk_name ports max_delay min_delay} {
  set_output_delay -max $max_delay -clock $clk_name $ports
  set_output_delay -max $max_delay -clock $clk_name $ports -add_delay -clock_fall
  set_output_delay -min $min_delay -clock $clk_name $ports
  set_output_delay -min $min_delay -clock $clk_name $ports -add_delay -clock_fall
}

proc bsg_link_ddr_constraints { \
  master_clk_name               \
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
  set tkn_clk_period         [expr $in_clk_period]
  create_clock -period $tkn_clk_period -name $tkn_clk_name $tkn_clk_port
  set_clock_uncertainty $uncertainty [get_clocks $tkn_clk_name]
  set_driving_cell -no_design_rule -lib_cell "IN12LP_GPIO18_13M9S30P_IO_H" -pin Y $tkn_clk_port

  # input
  set max_input_delay        [expr ($in_clk_period/2.0)-$in_clk_margin]
  set min_input_delay        [expr $in_clk_margin]
  create_clock -period $in_clk_period -name $in_clk_name $in_clk_port
  set_clock_uncertainty $uncertainty [get_clocks $in_clk_name]
  bsg_link_ddr_in_constraints $in_clk_name $in_dv_port $max_input_delay $min_input_delay
  set_driving_cell -no_design_rule -lib_cell "IN12LP_GPIO18_13M9S30P_IO_H" -pin Y $in_clk_port
  set_driving_cell -no_design_rule -lib_cell "IN12LP_GPIO18_13M9S30P_IO_H" -pin Y $in_dv_port

  # output
  global BSG_LINK_DDR_USE_GENERATED_CLOCK
  puts "BSG_LINK_DDR_USE_GENERATED_CLOCK = $BSG_LINK_DDR_USE_GENERATED_CLOCK"
  if {$BSG_LINK_DDR_USE_GENERATED_CLOCK == 0} {
    set setup_time_output      [expr ($out_clk_period/4.0)-$out_clk_margin]
    set hold_time_output       [expr ($out_clk_period/4.0)-$out_clk_margin]
    bsg_link_ddr_out_constraints $out_clk_port $out_dv_port $setup_time_output $hold_time_output
  } else {
    set max_output_delay       [expr ($out_clk_period/4.0)-$out_clk_margin]
    set min_output_delay       [expr $out_clk_margin-($out_clk_period/4.0)]
    create_generated_clock -edges {2 4 6} -master_clock $master_clk_name -source [get_attribute [get_clocks $master_clk_name] sources] -name $out_clk_name $out_clk_port
    bsg_link_ddr_out_generated_clock_constraints $out_clk_name $out_dv_port $max_output_delay $min_output_delay
  }
  set_load [load_of [get_lib_pin "*/IN12LP_GPIO18_13M9S30P_IO_H/DATA"]] $out_clk_port
  set_load [load_of [get_lib_pin "*/IN12LP_GPIO18_13M9S30P_IO_H/DATA"]] $out_dv_port
}

puts "Info: Completed script [info script]\n"