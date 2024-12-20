#
# Paul Gao 03/2021
#
#

puts "Info: Start script [info script]\n"

proc bsg_link_ddr_in_constraints {clk_name ports max_delay_ns min_delay_ns} {
  set_input_delay -max $max_delay_ns -clock $clk_name -source_latency_included -network_latency_included $ports
  set_input_delay -max $max_delay_ns -clock $clk_name -source_latency_included -network_latency_included $ports -add_delay -clock_fall
  set_input_delay -min $min_delay_ns -clock $clk_name -source_latency_included -network_latency_included $ports
  set_input_delay -min $min_delay_ns -clock $clk_name -source_latency_included -network_latency_included $ports -add_delay -clock_fall
}

proc bsg_link_ddr_out_constraints {clk_port ports setup_time_ns hold_time_ns} {
  foreach_in_collection obj $ports {
    set_data_check -from $clk_port -to $obj -setup $setup_time_ns
    set_data_check -from $clk_port -to $obj -hold  $hold_time_ns
    set_multicycle_path -end   -setup 1 -to $obj
    set_multicycle_path -start -hold  0 -to $obj
  }
}

proc bsg_link_ddr_out_generated_clock_constraints {clk_name ports max_delay_ns min_delay_ns} {
  set_output_delay -max $max_delay_ns -clock $clk_name $ports
  set_output_delay -max $max_delay_ns -clock $clk_name $ports -add_delay -clock_fall
  set_output_delay -min $min_delay_ns -clock $clk_name $ports
  set_output_delay -min $min_delay_ns -clock $clk_name $ports -add_delay -clock_fall
}

proc bsg_link_ddr_constraints { \
  master_clk_name               \
  out_clk_name                  \
  out_clk_period_ns             \
  out_clk_margin_ns             \
  out_clk_port                  \
  out_dv_port                   \
  out_tkn_clk_name              \
  out_tkn_clk_port              \
  in_clk_name                   \
  in_clk_period_ns              \
  in_clk_margin_ns              \
  in_clk_port                   \
  in_dv_port                    \
  in_tkn_clk_name               \
  in_tkn_clk_port               \
  uncertainty_ns                \
  {BSG_LINK_DDR_USE_GENERATED_CLOCK 1} \
} {
  # token
  set in_tkn_clk_period_ns         [expr $in_clk_period_ns]
  create_clock -period $in_tkn_clk_period_ns -name $in_tkn_clk_name $in_tkn_clk_port
  set_clock_uncertainty $uncertainty_ns [get_clocks $in_tkn_clk_name]

  set out_tkn_clk_period_ns         [expr $out_clk_period_ns]
  create_clock -period $out_tkn_clk_period_ns -name $out_tkn_clk_name $out_tkn_clk_port
  set_clock_uncertainty $uncertainty_ns [get_clocks $out_tkn_clk_name]

  # input
  set max_input_delay_ns        [expr ($in_clk_period_ns/2.0)-$in_clk_margin_ns]
  set min_input_delay_ns        [expr $in_clk_margin_ns]
  create_clock -period $in_clk_period_ns -name $in_clk_name $in_clk_port
  set_clock_uncertainty $uncertainty_ns [get_clocks $in_clk_name]
  bsg_link_ddr_in_constraints $in_clk_name $in_dv_port $max_input_delay_ns $min_input_delay_ns
  #set_driving_cell -no_design_rule -lib_cell "CKBD4BWP7T40P140" -pin C $in_clk_port
  #set_driving_cell -no_design_rule -lib_cell "CKBD4BWP7T40P140" -pin Z $in_dv_port

  # output
  #puts "BSG_LINK_DDR_USE_GENERATED_CLOCK = $BSG_LINK_DDR_USE_GENERATED_CLOCK"
  if {$BSG_LINK_DDR_USE_GENERATED_CLOCK == 0} {
    set setup_time_output_ns      [expr ($out_clk_period_ns/4.0)-$out_clk_margin_ns]
    set hold_time_output_ns       [expr ($out_clk_period_ns/4.0)-$out_clk_margin_ns]
    bsg_link_ddr_out_constraints $out_clk_port $out_dv_port $setup_time_output_ns $hold_time_output_ns
  } else {
    set max_output_delay_ns       [expr ($out_clk_period_ns/4.0)-$out_clk_margin_ns]
    set min_output_delay_ns       [expr $out_clk_margin_ns-($out_clk_period_ns/4.0)]
    create_generated_clock -edges {2 4 6} -master_clock $master_clk_name -source [get_db [get_clocks $master_clk_name] .sources] -name $out_clk_name -add $out_clk_port
    bsg_link_ddr_out_generated_clock_constraints $out_clk_name $out_dv_port $max_output_delay_ns $min_output_delay_ns
  }
  #set_load [load_of [get_lib_pin "*/CKBD4BWP7T40P140/I"]] $out_clk_port
  #set_load [load_of [get_lib_pin "*/CKBD4BWP7T40P140/I"]] $out_dv_port
}

puts "Info: Completed script [info script]\n"
