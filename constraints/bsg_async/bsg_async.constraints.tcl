puts "Info: Start script [info script]\n"

############################################
#
# cdc timing assertions
#
# this is a general procedure for constraining all the cdc paths in a design
# metastability issues should be fixed by synchronizers (two-stage dff) in the design
# a timing path between a clock and its generated clock is a synchronous path
# read http://www.zimmerdesignservices.com/mydownloads/no_mans_land_20130328.pdf for 
# motivation and more details
proc bsg_async {} {
  # find all clocks in the design
  set clocks [all_clocks]
  foreach_in_collection launch_clk $clocks {
    # the source clock and its generated clocks should be put into the same launch clock group
    if { [get_attribute $launch_clk is_generated] } {
      set launch_group [get_generated_clocks -filter "master_clock_name==[get_attribute $launch_clk master_clock_name]"]
      append_to_collection launch_group [get_attribute $launch_clk master_clock]
    } else {
      set launch_group [get_generated_clocks -filter "master_clock_name==[get_attribute $launch_clk name]"]
      append_to_collection launch_group $launch_clk
    }
    # the latch clock should be a clock which is not in the launch clock group
    foreach_in_collection latch_clk [remove_from_collection $clocks $launch_group] {
      set launch_period [get_attribute $launch_clk period]
      set latch_period [get_attribute $latch_clk period]
      set max_delay_ps [expr min($launch_period,$latch_period)/2]
      # we use -ignore_clock_latency to avoid taking clock network delay into account
      set_max_delay $max_delay_ps -from $launch_clk -to $latch_clk -ignore_clock_latency
      set_min_delay 0             -from $launch_clk -to $latch_clk -ignore_clock_latency
    }
  }
}

puts "Info: Completed script [info script]\n"
