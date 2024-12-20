
source $::env(CHIP_TCL_DIR)/bsg_dmc.constraints.tcl
source $::env(CHIP_TCL_DIR)/bsg_link_sdr.constraints.tcl
source $::env(CHIP_TCL_DIR)/bsg_link_ddr.constraints.tcl

proc bsg_backport_clock_constrain { clk_name clk_period_ns clk_pins input_pins output_pins } {
     # Check for old clock
     set old_clk [get_db ${clk_pins} .clocks]
     set old_clk_name [get_db ${old_clk} .name]

     if {[sizeof_collection ${old_clk}] == 0} {
         puts "Creating new clock ${clk_name}"
         create_clock -period ${clk_period_ns} -name ${clk_name} ${clk_pins}
     } else {
         puts "Adding to old clock ${old_clk_name}"
         create_clock -period ${clk_period_ns} -name ${clk_name} -add ${clk_pins}
     }

    set_ideal_network -no_propagate [get_db ${clk_pins} .net]
    bsg_backport_io_constrain ${clk_name} ${input_pins} ${output_pins}
}

proc bsg_backport_tag_bus_constrain { tag_name_root tag_bus_root } {
    set tag_clk_name ${tag_name_root}clk
    set tag_clk_period_ns 5.000
    set tag_clk_pin [get_ports ${tag_bus_root}clk_i]
    set tag_data_pin [get_ports ${tag_bus_root}data_i]
    set tag_node_id_offset_pins [get_ports ${tag_bus_root}node_id_offset_i]

    set input_delay_min_per 20
    set input_delay_min_ns  [expr ${tag_clk_period_ns}*${input_delay_min_per}/100.0]
    set input_delay_max_per 80
    set input_delay_max_ns  [expr ${tag_clk_period_ns}*${input_delay_max_per}/100.0]
    
    set tag_input_pins {}
    append_to_collection tag_input_pins ${tag_data_pin}
    append_to_collection tag_input_pins ${tag_node_id_offset_pins}

    if {[sizeof_collection [get_db ${tag_clk_pin} .clocks]] > 0} {
        puts "Reusing tag bus at ${tag_bus_root}"
        return
    }

    puts "Creating tag bus at ${tag_bus_root}"
    create_clock -period ${tag_clk_period_ns} -name ${tag_clk_name} ${tag_clk_pin}
    set_input_delay -min ${input_delay_min_ns} -clock ${tag_clk_name} ${tag_input_pins}
    set_input_delay -max ${input_delay_max_ns} -clock ${tag_clk_name} ${tag_input_pins}
    set_false_path -from ${tag_node_id_offset_pins}
}

proc bsg_backport_io_constrain { clk input_pins output_pins } {
    set clk_obj [index_collection [get_clocks ${clk}] 0]
    set clk_name [get_db ${clk_obj} .name]
    set clk_period_ns [expr [get_db ${clk_obj} .period] / 1000]

    set input_delay_min_per 2
    set input_delay_min_ns  [expr ${clk_period_ns}*${input_delay_min_per}/100.0]
    set input_delay_max_per 20
    set input_delay_max_ns  [expr ${clk_period_ns}*${input_delay_max_per}/100.0]

    if {[sizeof_collection ${input_pins}] > 0} {
        set_input_delay -min ${input_delay_min_ns} -clock ${clk_name} ${input_pins}
        set_input_delay -max ${input_delay_max_ns} -clock ${clk_name} ${input_pins}
    }

    set output_delay_min_per 2
    set output_delay_min_ns  [expr ${clk_period_ns}*${output_delay_min_per}/100.0]
    set output_delay_max_per 20
    set output_delay_max_ns  [expr ${clk_period_ns}*${output_delay_max_per}/100.0]

    if {[sizeof_collection ${output_pins}] > 0} {
        set_output_delay -min ${output_delay_min_ns} -clock ${clk_name} ${output_pins}
        set_output_delay -max ${output_delay_max_ns} -clock ${clk_name} ${output_pins}
    }
}

proc bsg_backport_clk_gen_pearl_inst_constraints { clk_gen_pearl_inst name_root clk_period_ns input_pins output_pins } {
    set tag_name_root tag_
    set tag_bus_root tag_
    bsg_backport_tag_bus_constrain ${tag_name_root} ${tag_bus_root}

    set osc_clk_name ${name_root}osc_clk
    set osc_clk_period_ns [expr ${clk_period_ns} / 2.0]
    set osc_clk_pins [get_pins ${clk_gen_pearl_inst}/out_osc]
    create_clock -name ${osc_clk_name} -period ${osc_clk_period_ns} ${osc_clk_pins}

    set ext_clk_name ${name_root}ext_clk
    set ext_clk_period_ns [expr ${clk_period_ns} / 4.0]
    set ext_clk_pins {}
    append_to_collection ext_clk_pins [get_db [get_pins ${clk_gen_pearl_inst}/ext_clk_i] .net.drivers]
    append_to_collection ext_clk_pins [get_pins ${clk_gen_pearl_inst}/ext_clk_i]
    create_clock -name ${ext_clk_name} -period ${ext_clk_period_ns} ${ext_clk_pins}

    set mon_clk_name ${name_root}mon_clk
    set mon_clk_period_ns [expr ${clk_period_ns} / 4.0]
    set mon_clk_pins {}
    append_to_collection mon_clk_pins [get_db [get_pins ${clk_gen_pearl_inst}/clk_monitor_o] .net.loads]
    append_to_collection mon_clk_pins [get_pins ${clk_gen_pearl_inst}/clk_monitor_o]
    create_clock -name ${mon_clk_name} -period ${mon_clk_period_ns} ${mon_clk_pins}

    set output_disable_port [get_db [get_pins ${clk_gen_pearl_inst}/async_output_disable_i] .net.driver]

    set out_clk_name ${name_root}clk
    set out_clk_period_ns ${clk_period_ns}
    set out_clk_pins [get_pins ${clk_gen_pearl_inst}/clk_o]
    set out_input_pins ${input_pins}
    append_to_collection out_input_pins ${output_disable_port}
    set out_output_pins ${output_pins}
    bsg_backport_clock_constrain \
        ${out_clk_name} \
        ${out_clk_period_ns} \
        ${out_clk_pins} \
        ${out_input_pins} \
        ${out_output_pins}

    set_false_path -from ${output_disable_port}
}

proc bsg_backport_ddr_link_pearl_constrain { name_root core_clk_period_ns link_clk_period_ns } {
    set core_clk_name ${name_root}core_clk
    set core_clk_period_ns ${core_clk_period_ns}
    set core_clk_pin [get_ports "core_clk_i"]
    set core_input_pins [get_ports "core_v_i core_data_i core_yumi_i core_reset_i"]
    set core_output_pins [get_ports "core_v_o core_data_o core_ready_and_o"]
    bsg_backport_clock_constrain \
        ${core_clk_name} \
        ${core_clk_period_ns} \
        ${core_clk_pin} \
        ${core_input_pins} \
        ${core_output_pins}

    set clk_gen_pearl_inst io_clk_gen
    set clk_gen_pearl_root io_
    set clk_gen_pearl_clk_period_ns [expr ${link_clk_period_ns} / 2.0]
    set clk_gen_pearl_input_pins {}
    set clk_gen_pearl_output_pins {}
    bsg_backport_clk_gen_pearl_inst_constraints \
        ${clk_gen_pearl_inst} \
        ${clk_gen_pearl_root} \
        ${clk_gen_pearl_clk_period_ns} \
        ${clk_gen_pearl_input_pins} \
        ${clk_gen_pearl_output_pins}
    set io_clk_name ${clk_gen_pearl_root}clk

    set out_clk_name link_out_clk
    set out_clk_period_ns ${core_clk_period_ns}
    set out_clk_margin_ns 0.080; # Fixed
    set out_clk_pin [get_ports link_clk_o]
    set out_dv_pin [get_ports "link_data_o link_v_o"]
    set out_tkn_name link_out_tkn_clk
    set out_tkn_pin [get_ports link_token_o]

    set in_clk_name link_in_clk
    set in_clk_period_ns ${link_clk_period_ns}
    set in_clk_margin_ns 0.080; # Fixed
    set in_clk_pin [get_ports link_clk_i]
    set in_dv_pin [get_ports "link_data_i link_v_i"]
    set in_tkn_name link_in_tkn_clk
    set in_tkn_pin [get_ports link_token_i]

    bsg_link_ddr_constraints                       \
        ${io_clk_name}                             \
        ${out_clk_name}                            \
        ${out_clk_period_ns}                       \
        ${out_clk_margin_ns}                       \
        ${out_clk_pin}                             \
        ${out_dv_pin}                              \
        ${out_tkn_name}                            \
        ${out_tkn_pin}                             \
        ${in_clk_name}                             \
        ${in_clk_period_ns}                        \
        ${in_clk_margin_ns}                        \
        ${in_clk_pin}                              \
        ${in_dv_pin}                               \
        ${in_tkn_name}                             \
        ${in_tkn_pin}                              \
        0.0 ; # Uncertainty handled later in flow

    set_case_analysis 0 [get_pins -regexp {[i|o]delay/sig\[\d+].mux_BSG_DONT_TOUCH/S[0|1]}]
    set_dont_touch_network -no_propagate [get_ports "link_clk_i link_v_i link_data_i"]
    set_dont_touch_network -no_propagate [get_pins -hier "odelay/o[*]"]
}

proc bsg_backport_sdr_link_pearl_constraints { name_root core_clk_period_ns link_clk_period_ns } {
    # Tag bus
    set tag_name_root ${name_root}tag_
    set tag_bus_root tag_
    set tag_clk_name ${tag_name_root}clk
    bsg_backport_tag_bus_constrain ${tag_name_root} ${tag_bus_root}

    set core_clk_name ${name_root}core_clk
    set core_clk_period_ns ${core_clk_period_ns}
    set core_clk_pin [get_ports "core_clk_i"]
    set core_input_pins [get_ports "core_v_i core_data_i core_ready_and_i core_reset_i"]
    set core_output_pins [get_ports "core_v_o core_data_o core_ready_and_o"]
    append_to_collection core_output_pins [get_ports "async_link_i_disable_o async_link_o_disable_o"]
    bsg_backport_clock_constrain ${core_clk_name} ${core_clk_period_ns} ${core_clk_pin} ${core_input_pins} ${core_output_pins}

    set_false_path -to [get_ports async_link_i_disable_o]
    set_false_path -to [get_ports async_link_o_disable_o]

    set out_clk_name ${name_root}link_out_clk
    set out_clk_period_ns ${core_clk_period_ns}
    set out_clk_margin_ns 0.30; # Fixed
    set out_clk_pin [get_ports "link_clk_o"]
    set out_dv_pin [get_ports "link_data_o link_v_o"]
    set out_tkn_name link_out_tkn
    set out_tkn_pin [get_ports link_token_o]

    set in_clk_name ${name_root}link_in_clk
    set in_clk_period_ns ${link_clk_period_ns}
    set in_clk_margin_ns 0.30; # Fixed
    set in_clk_pin [get_ports link_clk_i]
    set in_dv_pin [get_ports "link_data_i link_v_i"]
    set in_tkn_name link_in_tkn
    set in_tkn_pin [get_ports link_token_i]

    bsg_link_sdr_constraints \
        ${core_clk_name} \
        ${core_clk_pin} \
        ${out_clk_name} \
        ${out_clk_period_ns} \
        ${out_clk_margin_ns} \
        ${out_clk_pin} \
        ${out_dv_pin} \
        ${out_tkn_name} \
        ${out_tkn_pin} \
        ${in_clk_name} \
        ${in_clk_period_ns} \
        ${in_clk_margin_ns} \
        ${in_clk_pin} \
        ${in_dv_pin} \
        ${in_tkn_name} \
        ${in_tkn_pin} \
        0.0 ; # Uncertainty handled later in flow

    set_clock_group \
        -asynchronous \
        -group ${tag_clk_name} \
        -group [list ${core_clk_name} ${out_clk_name} ${in_tkn_name}] \
        -group [list ${in_clk_name} ${out_tkn_name}]
}
   
proc bsg_backport_clk_gen_pearl_constraints { name_root clk_period_ns } {
     set clk_gen_inst clk_gen_inst
     set mux_inst ${clk_gen_inst}/mux_inst
     set osc_inst ${clk_gen_inst}/clk_gen_osc_inst
     set ds_inst ${clk_gen_inst}/clk_gen_ds_inst

     # TODO: Derive
     set tag_name_root ${name_root}tag_
     set tag_bus_root tag_
     bsg_backport_tag_bus_constrain ${tag_name_root} ${tag_bus_root}

     # Nonstandard SDC
     puts "Setting static DS selection for output clock"
     set_case_analysis 0 [get_pins ${mux_inst}/sel_i[1]]
     set_case_analysis 1 [get_pins ${mux_inst}/sel_i[0]]

     # Creating osc clock
     set osc_clk_name ${name_root}osc
     set osc_period_ns [expr ${clk_period_ns} / 2.0]
     set osc_pin_obj [get_pins ${clk_gen_inst}/clk_gen_osc_inst/osc_BSG_DONT_TOUCH/B0/Z]
     puts "Creating oscillator clock ${osc_clk_name} for instance clk_gen_inst"
     create_clock -name ${osc_clk_name} -period ${osc_period_ns} ${osc_pin_obj}
     set_sense -type clock -stop_propagation -clocks [get_clocks ${osc_clk_name}] [get_pins ${mux_inst}/data_i[0]]
     set_disable_timing [get_cells ${clk_gen_inst}/clk_gen_osc_inst/osc_BSG_DONT_TOUCH/B0]

     # Creating DS clock
     set ds_clk_name ${name_root}ds
     set ds_ratio 2
     set ds_pin_obj [get_pins ${clk_gen_inst}/clk_gen_ds_inst/d/macro.d[0].d_BSG_DONT_TOUCH/Q]
     puts "Creating ds clock ${ds_clk_name} for instance clk_gen_inst"
     create_generated_clock \
        -name ${ds_clk_name} \
        -divide_by ${ds_ratio} \
        -master_clock [get_clocks ${osc_clk_name}] \
        -source [get_db [get_clocks ${osc_clk_name}] .sources] \
        -add ${ds_pin_obj}
     set_sense -type clock -stop_propagation -clocks [get_clocks ${ds_clk_name}] [get_pins ${mux_inst}/data_i[1]]

     # Creating ext clock
     set ext_clk_name ${name_root}ext
     set ext_period_ns [expr ${clk_period_ns} / 2.0]
     set ext_pin_obj [get_ports ext_clk_i]
     puts "Creating external clock ${ext_clk_name} for instance clk_gen_inst"
     create_clock -name ${ext_clk_name} -period ${ext_period_ns} ${ext_pin_obj}
     set_sense -type clock -stop_propagation -clocks [get_clocks ${ext_clk_name}] [get_pins ${mux_inst}/data_i[2]]

     # Creating output clock
     set out_clk_name ${name_root}clk
     set out_clk_period_ns ${clk_period_ns}
     set out_clk_freq_mhz [expr 1000.0 / ${out_clk_period_ns}]
     set out_clk_pins {}
     append_to_collection out_clk_pins [get_ports clk_o]
     append_to_collection out_clk_pins [get_pins ${mux_inst}/data_o]
     set out_clk_input_pins [get_ports async_output_disable_i]
     set out_clk_output_pins {}
     puts "Creating ${out_clk_freq_mhz} MHz output clock ${out_clk_name}"
     create_clock -name ${out_clk_name} -period ${out_clk_period_ns} ${out_clk_pins}
     bsg_backport_io_constrain ${out_clk_name} ${out_clk_input_pins} ${out_clk_output_pins}

     set out_clk_mon_name ${out_clk_name}_mon
     set out_clk_mon_pin [get_ports clk_monitor_o]
     create_clock -name ${out_clk_mon_name} -period ${out_clk_period_ns} ${out_clk_mon_pin}

     set_clock_group \
        -name "${name_root}grp" \
        -asynchronous \
        -group [list ${out_clk_name} ${ds_clk_name}] \
        -group ${osc_clk_name} \
        -group ${ext_clk_name}

     set_false_path -from [get_ports async_output_disable_i]
 }

proc bsg_backport_default_drv_constrain { root } {
    set_max_fanout 30 [current_design]
    set_max_transition 0.200 [current_design]
    
    if {[sizeof_collection [all_clocks]] > 0} {
        # DRC
        set_max_transition 0.200 -data_path [all_clocks]
        set_max_transition 0.100 -clock_path [all_clocks]
    
        # Excessive uncertainty
        set_clock_uncertainty -setup 0.250 [all_clocks]
        set_clock_uncertainty -hold 0.100 [all_clocks]

        # Loosen uncertainty on SDR links
        if {[sizeof_collection [get_clocks -quiet *link*]] > 0} {
            set_clock_uncertainty -setup 0.125 [get_clocks *link*]
            set_clock_uncertainty -hold  0.50  [get_clocks *link*]
        }
    }

    set_load -max [load_of [index_collection [get_lib_pin INVD8BWP7T40P140/I] 0]] [all_outputs]
    set_load -min [load_of [index_collection [get_lib_pin INVD2BWP7T40P140/I] 0]] [all_outputs]

    set clk_outputs [get_ports -filter {direction==out&&clocks!=""}]
    set_load -max [load_of [index_collection [get_lib_pin CKBD4BWP7T40P140/I] 0]] ${clk_outputs}
    set_load -min [load_of [index_collection [get_lib_pin CKBD4BWP7T40P140/I] 0]] ${clk_outputs}

    set nc_inputs [get_ports -filter {direction==in&&clocks==""}]
    set_driving_cell -no_design_rule -min -lib_cell INVD8BWP7T40P140 ${nc_inputs}
    set_driving_cell -no_design_rule -max -lib_cell INVD2BWP7T40P140 ${nc_inputs}

    set clk_inputs [get_ports -filter {direction==in&&clocks!=""}]
    set_driving_cell -no_design_rule -min -lib_cell CKBD4BWP7T40P140 ${clk_inputs}
    set_driving_cell -no_design_rule -max -lib_cell CKBD4BWP7T40P140 ${clk_inputs}
}

proc bsg_backport_default_sync_constrain { root } {
  #foreach_in_collection s1 [get_pins -quiet -of_objects [get_cells -quiet -hier *hard_sync_int1_BSG_SYNC*] -filter "direction==in&&is_data==true"] {
  #  set_false_path -to $s1 -setup
  #  set_false_path -to $s1 -hold
  #}
}

proc bsg_backport_async_icl { clocks } {
  foreach_in_collection launch_clk ${clocks} {
    set launch_group {}
    if { [get_db ${launch_clk} .is_generated] } {
      set launch_master [get_db ${launch_clk} .master_clock]
      append_to_collection launch_group ${launch_master}
      append_to_collection launch_group [get_db ${launch_master} .generated_clocks]
    } else {
      append_to_collection launch_group ${launch_clk}
      append_to_collection launch_group [get_db ${launch_clk} .generated_clocks]
    }
  
    foreach_in_collection latch_clk [remove_from_collection ${clocks} ${launch_group}] {
      set launch_period_ps [get_db ${launch_clk} .period]
      set max_delay_ns [expr ${launch_period_ps} / 1000.0]
      set_max_delay ${max_delay_ns} -from ${launch_clk} -to ${latch_clk} -ignore_clock_latency
      set_min_delay 0               -from ${launch_clk} -to ${latch_clk} -ignore_clock_latency
    }
  }
}

proc bsg_backport_tag_loosen { root } {
    set tag_unsync_inst [get_cells -hier -filter "ref_name=~*bsg_tag_client_unsync*"]
    set tag_unsync_reg [get_db ${tag_unsync_inst} .insts -regexp ".*macro.*.d_BSG_DONT_TOUCH"]
    set tag_unsync_pins [get_pins -of_objects ${tag_unsync_reg} -filter "direction==out"]
    set_max_delay  10.0 -from ${tag_unsync_pins} -to [all_registers] -ignore_clock_latency
    set_min_delay  -1.0 -from ${tag_unsync_pins} -to [all_registers] -ignore_clock_latency
}

proc bsg_backport_default_cg_constrain { root } {
  foreach_in_collection clk [get_clocks -filter "!is_generated"] {
    set clk_name [get_db $clk .name]
    set clk_grp $clk
    append_to_collection clk_grp [get_db ${clk} .generated_clocks.name]
    puts "Creating clock group for ${clk_name}: ${clk_grp}"
    set_clock_groups -asynchronous -group $clk_grp

    set cdc_clk_name ${clk_name}_cdc
    set cdc_clk_period [expr [get_db $clk .period] / 1000]
    set cdc_clk_source [get_db $clk .sources]
    puts "Creating cdc clock $cdc_clk_name"
    create_clock -name $cdc_clk_name -period $cdc_clk_period -add $cdc_clk_source
  }

  puts "Making CDC clocks physically exclusive with regular clocks"
  set_clock_groups -physically_exclusive \
                   -group [remove_from_collection [get_clocks *] [get_clocks *_cdc]] \
                   -group [get_clocks *_cdc]

  puts "Setting max delays between cdc clocks"
  foreach_in_collection cdc_clk0 [get_clocks *_cdc] {
    foreach_in_collection cdc_clk1 [remove_from_collection [get_clocks *_cdc] $cdc_clk0] {
      set_false_path -from $cdc_clk0 -to $cdc_clk0
      set period0_ns [expr [get_db [get_clocks ${cdc_clk0}] .period] / 1000.0]
      set period1_ns [expr [get_db [get_clocks ${cdc_clk1}] .period] / 1000.0]
      set cdc_delay [expr min(${period0_ns}, ${period1_ns})]
      set_max_delay $cdc_delay -from $cdc_clk0 -to $cdc_clk1
      set_min_delay 0.0        -from $cdc_clk0 -to $cdc_clk1
    }
  }
}

proc bsg_backport_async_two_clocks { clk0 clk1 } {
    set period0_ns [expr [get_db [get_clocks ${clk0}] .period] / 1000.0]
    set period1_ns [expr [get_db [get_clocks ${clk1}] .period] / 1000.0]
    set min_period_ns [expr min(${period0_ns}, ${period1_ns})]

    set max_delay_ns [expr ${min_period_ns} / 2]
    set_max_delay ${max_delay_ns} -from ${clk0} -to ${clk1} -ignore_clock_latency
    set_min_delay 0               -from ${clk0} -to ${clk1} -ignore_clock_latency
    set_max_delay ${max_delay_ns} -from ${clk1} -to ${clk0} -ignore_clock_latency
    set_min_delay 0               -from ${clk1} -to ${clk0} -ignore_clock_latency

    set clk_grp0 {}
    set clk_name0 [get_db [get_clocks ${clk0}] .name]
    append_to_collection clk_grp0 ${clk0}
    append_to_collection clk_grp0 [get_generated_clocks -filter "master_clock==${clk_name0}"]

    set clk_grp1 {}
    set clk_name1 [get_db [get_clocks ${clk1}] .name]
    append_to_collection clk_grp1 ${clk1}
    append_to_collection clk_grp1 [get_generated_clocks -filter "master_clock==${clk_name1}"]

    set_clock_group -asynchronous -group ${clk_grp0} -group ${clk_grp1}
 }

proc bsg_backport_dly_line_constrain { name_root clk_period_ns } {
    set in_clk_name ${name_root}in_clk
    set in_clk_period_ns ${clk_period_ns}
    set in_clk_pins [get_ports clk_i]
    set in_clk_input_pins [get_ports async_reset_i]
    set in_clk_output_pins {}
    bsg_backport_clock_constrain \
        ${in_clk_name} \
        ${in_clk_period_ns} \
        ${in_clk_pins} \
        ${in_clk_input_pins} \
        ${in_clk_output_pins}

    set out_clk_name ${name_root}out_clk
    set out_clk_pins [get_ports clk_o]
    set out_clk_edges {1 2 3}
    set out_clk_quarter [expr ${in_clk_period_ns} / 4]
    set out_clk_edge_shift [list ${out_clk_quarter} ${out_clk_quarter} ${out_clk_quarter}]
    create_generated_clock \
        -name ${out_clk_name} \
        -edges ${out_clk_edges} \
        -edge_shift ${out_clk_edge_shift} \
        -master_clock ${in_clk_name} \
        -source [get_db [get_clocks ${in_clk_name}] .sources] \
        -add ${out_clk_pins}

    set async_input_pins {}
    append_to_collection async_input_pins [get_ports async_reset_i]

    set_disable_timing [get_cells dly_BSG_DONT_TOUCH/meta_r]
    set_false_path -to [get_pins dly_BSG_DONT_TOUCH/meta_r/D]
    set_false_path -to [get_pins dly_BSG_DONT_TOUCH/d90_BSG_DONT_TOUCH/S1/D]
    set_false_path -to [get_pins dly_BSG_DONT_TOUCH/d180_BSG_DONT_TOUCH/S1/D]
}

proc bsg_backport_dly_line_inst_constraints { dly_line_inst dly_line_name_root } {
    set master_clk_pin [get_pins ${dly_line_inst}/clk_i]
    set master_clk_obj [get_db ${master_clk_pin} .clocks]
    set master_clk_name [get_db ${master_clk_obj} .name]
    set master_clk_period_ns [expr [get_db ${master_clk_obj} .period] / 1000.0]

    set dly_clk_name ${dly_line_name_root}dly_clk
    set dly_clk_pins [get_pins ${dly_line_inst}/dly_BSG_DONT_TOUCH/d90/BSG_DONT_TOUCH/B0/Z]
    #set dly_clk_edges {1 2 3}
    #set dly_clk_quarter [expr ${master_clk_period_ns} / 4]
    #set dly_clk_edge_shift [list ${dly_clk_quarter} ${dly_clk_quarter} ${dly_clk_quarter}]
    #puts ${master_clk_name}
    #create_generated_clock \
    #    -name ${dly_clk_name} \
    #    -edges ${dly_clk_edges} \
    #    -edge_shift ${dly_clk_edge_shift} \
    #    -master_clock ${master_clk_obj} \
    #    -source [get_db ${master_clk_obj} .sources *_p_*] \
    #    -add ${dly_clk_pins}
    create_clock -name ${dly_clk_name} -period ${master_clk_period_ns} ${dly_clk_pins}

    set meta_clk_name ${dly_line_name_root}meta_clk
    set meta_clk_pins [get_pins ${dly_line_inst}/dly_BSG_DONT_TOUCH/d180/BSG_DONT_TOUCH/B0/Z]
    create_clock -name ${meta_clk_name} -period ${master_clk_period_ns} ${meta_clk_pins}

    set_disable_timing [get_cells ${dly_line_inst}/dly_BSG_DONT_TOUCH/meta_r]
    set_false_path -to [get_pins ${dly_line_inst}/dly_BSG_DONT_TOUCH/meta_r/D]
    set_false_path -to [get_pins ${dly_line_inst}/dly_BSG_DONT_TOUCH/d90_BSG_DONT_TOUCH/S1/D]
    set_false_path -to [get_pins ${dly_line_inst}/dly_BSG_DONT_TOUCH/d180_BSG_DONT_TOUCH/S1/D] 
}

proc bsg_backport_subpod_link_inst_constraints { subpod_link_inst core_clk_period_ns num_links } {
    set clk_gen_pearl_inst ${subpod_link_inst}/clk_gen
    set clk_gen_pearl_root core_
    set subpod_input_pins {}
    set subpod_output_pins [get_ports async_*_link_*_disable_o[*]]
    bsg_backport_clk_gen_pearl_inst_constraints ${clk_gen_pearl_inst} ${clk_gen_pearl_root} ${core_clk_period_ns} ${subpod_input_pins} ${subpod_output_pins}

    set_false_path -to [get_ports async_*_link_*_disable_o[*]]

    for {set i 0} {$i < ${num_links}} {incr i} {
        set sdr_link_pearl_inst ${subpod_link_inst}/links[$i].fwd_sdr
        set sdr_link_pearl_root io_fwd[$i]_
        bsg_backport_sdr_link_pearl_inst_constraints ${sdr_link_pearl_inst} ${sdr_link_pearl_root}

        set sdr_link_pearl_inst ${subpod_link_inst}/links[$i].rev_sdr
        set sdr_link_pearl_root io_rev[$i]_
        bsg_backport_sdr_link_pearl_inst_constraints ${sdr_link_pearl_inst} ${sdr_link_pearl_root}
    }
}

proc bsg_backport_pod_link_inst_constraints { pod_link_inst core_clk_period_ns num_links } {
    set clk_gen_pearl_inst ${pod_link_inst}/clk_gen
    set clk_gen_pearl_root noc_
    set pod_input_pins {}
    set pod_output_pins {}
    bsg_backport_clk_gen_pearl_inst_constraints ${clk_gen_pearl_inst} ${clk_gen_pearl_root} ${core_clk_period_ns} ${pod_input_pins} ${pod_output_pins}

    for {set i 0} {$i < ${num_links}} {incr i} {
        set sdr_link_pearl_inst ${pod_link_inst}/links[$i].sdr
        set sdr_link_pearl_root noc[$i]_
        bsg_backport_sdr_link_pearl_inst_constraints ${sdr_link_pearl_inst} ${sdr_link_pearl_root}
    }
}


proc bsg_backport_sdr_link_pearl_inst_constraints { sdr_link_pearl_inst sdr_name_root } {
    set link_clk_period_ns     0.800; # Fixed 1.25 GHz
    set max_io_output_margin_ns 0.30; # Fixed
    set max_io_input_margin_ns  0.30; # Fixed

    set master_clk_pin [get_pins ${sdr_link_pearl_inst}/core_clk_i]
    set master_clk_obj [get_db ${master_clk_pin} .clocks]
    set master_clk_port [get_db ${master_clk_obj} .sources]
    set master_clk_name [get_db ${master_clk_obj} .name]
    set master_clk_period_ns [expr [get_db ${master_clk_obj} .period] / 1000.0]

    set out_clk_name ${sdr_name_root}out_clk
    set out_clk_period_ns ${master_clk_period_ns}
    set out_clk_margin_ns ${max_io_output_margin_ns}
    set out_clk_pins [get_pins ${sdr_link_pearl_inst}/link_clk_o]
    set out_clk_ports [get_db ${out_clk_pins} .net.loads]
    set out_dv_pins [get_pins "${sdr_link_pearl_inst}/link_data_o ${sdr_link_pearl_inst}/link_v_o"]
    set out_dv_ports [get_db ${out_dv_pins} .net.loads]
    set out_tkn_name ${sdr_name_root}out_tkn
    set out_tkn_pins [get_pins ${sdr_link_pearl_inst}/link_token_o]
    set out_tkn_ports [get_db ${out_tkn_pins} .net.loads]

    set in_clk_name ${sdr_name_root}in_clk
    set in_clk_period_ns ${link_clk_period_ns}
    set in_clk_margin_ns ${max_io_input_margin_ns}
    set in_clk_pins [get_pins ${sdr_link_pearl_inst}/link_clk_i]
    set in_clk_ports [get_db ${in_clk_pins} .net.driver]
    set in_dv_pins [get_pins "${sdr_link_pearl_inst}/link_data_i ${sdr_link_pearl_inst}/link_v_i"]
    set in_dv_ports [get_db ${in_dv_pins} .net.driver]
    set in_tkn_name ${sdr_name_root}in_tkn
    set in_tkn_pins [get_pins ${sdr_link_pearl_inst}/link_token_i]
    set in_tkn_ports [get_db ${in_tkn_pins} .net.driver]
    bsg_link_sdr_constraints \
        ${master_clk_name} \
        ${master_clk_port} \
        ${out_clk_name} \
        ${out_clk_period_ns} \
        ${out_clk_margin_ns} \
        ${out_clk_ports} \
        ${out_dv_ports} \
        ${out_tkn_name} \
        ${out_tkn_ports} \
        ${in_clk_name} \
        ${in_clk_period_ns} \
        ${in_clk_margin_ns} \
        ${in_clk_ports} \
        ${in_dv_ports} \
        ${in_tkn_name} \
        ${in_tkn_ports} \
        0.0; # Taken care of later in flow
}

proc bsg_backport_dmc_pearl_constrain { name_root ui_clk_period_ns dfi_clk_2x_period_ns } {
    # Tag bus
    set tag_name_root tag_
    set tag_bus_root tag_
    bsg_backport_tag_bus_constrain ${tag_name_root} ${tag_bus_root}

    set ui_clk_name ${name_root}ui_clk
    set ui_clk_period_ns ${ui_clk_period_ns}
    set ui_clk_pin [get_ports ui_clk_i]
    set ui_input_pins {}
    append_to_collection ui_input_pins [get_ports app_*_i]
    append_to_collection ui_input_pins [get_ports trace_*_i]
    #append_to_collection ui_input_pins [get_ports ui_*_i]

    set ui_output_pins {}
    append_to_collection ui_output_pins [get_ports app_*_o]
    append_to_collection ui_output_pins [get_ports trace_*_o]
    append_to_collection ui_output_pins [get_ports ui_*_o]

    bsg_backport_clock_constrain ${ui_clk_name} ${ui_clk_period_ns} ${ui_clk_pin} ${ui_input_pins} ${ui_output_pins}

    set_false_path -to [get_ports ui_transaction_in_progress_o]

    set dfi_clk_2x_name ${name_root}dfi_clk_2x
    set dfi_clk_2x_period_ns ${dfi_clk_2x_period_ns}
    set dfi_clk_2x_pin [get_ports ext_dfi_clk_2x_i]
    set dfi_clk_2x_input_pins {}
    set dfi_clk_2x_output_pins [get_ports dfi_*_o -filter "name!~*clk*"]
    bsg_backport_clock_constrain ${dfi_clk_2x_name} ${dfi_clk_2x_period_ns} ${dfi_clk_2x_pin} ${dfi_clk_2x_input_pins} ${dfi_clk_2x_output_pins}

    set_false_path -to [get_ports dfi_init_calib_complete_o]
    set_false_path -to [get_ports dfi_stall_transactions_o]
    set_false_path -to [get_ports dfi_refresh_in_progress_o]
    set_false_path -to [get_ports dfi_test_mode_o]

    set dfi_clk_1x_name ${name_root}dfi_clk_1x
    set dfi_clk_1x_ratio 2
    set dfi_clk_1x_pin [get_pins dmc/dmc_clk_rst_gen/clk_gen_ds_inst/d/macro.d[0].d_BSG_DONT_TOUCH/Q]
    create_generated_clock \
        -name ${dfi_clk_1x_name} \
        -divide_by ${dfi_clk_1x_ratio} \
        -master_clock [get_clocks ${dfi_clk_2x_name}] \
        -source [get_db [get_clocks ${dfi_clk_2x_name}] .sources] \
        -add ${dfi_clk_1x_pin}

    set clk_mon_name ${name_root}mon_clk
    set clk_mon_period_ns ${ui_clk_period_ns}
    set clk_mon_pins {}
    append_to_collection clk_mon_pins [get_ports dfi_clk_1x_o] 
    append_to_collection clk_mon_pins [get_ports dfi_clk_2x_monitor_o] 
    append_to_collection clk_mon_pins [get_ports dfi_clk_1x_monitor_o] 
    append_to_collection clk_mon_pins [get_ports calib_clk_monitor_o]
    append_to_collection clk_mon_pins [get_ports calib_dqs_monitor_o]
    append_to_collection clk_mon_pins [get_ports calib_dqs_dly_monitor_o]
    create_clock -name ${clk_mon_name} -period ${clk_mon_period_ns} ${clk_mon_pins}

    array set ddr_intf {}
    bsg_backport_ddr_intf_create ddr_intf

    bsg_dmc_ctrl_timing_constraints ddr_intf ${dfi_clk_1x_name} ${dfi_clk_2x_name}
    foreach id [list 0 1 2 3] {
        bsg_dmc_data_timing_constraints ddr_intf $id ${dfi_clk_1x_name} ${dfi_clk_2x_name}
    }

    set_case_analysis 0 [get_pins dqs_mux/sel_i[0]]
    set_case_analysis 0 [get_pins dqs_mux/sel_i[1]]
    set_case_analysis 0 [get_pins dqs_dly_mux/sel_i[0]]
    set_case_analysis 0 [get_pins dqs_dly_mux/sel_i[1]]
}

proc bsg_backport_ddr_intf_create { ddr_intf_p } {
    # Link to passed array parameter
    upvar 1 ${ddr_intf_p} ddr_intf

    set ddr_intf(ck_p)            [get_ports ddr_ck_p_o]
    set ddr_intf(ck_n)            [get_ports ddr_ck_n_o]
    set ddr_intf(ca)              [get_ports -filter "name=~ddr_*_o*&&name!~ddr_ck_*&&name!~ddr_dm_*&&name!~ddr_dq*"]
    set gid 0
    set ddr_intf($gid,dqs_p_i)    [get_ports -regexp {ddr_dqs_p_i\[0\]}]
    set ddr_intf($gid,dqs_p_o)    [get_ports -regexp {ddr_dqs_p_o\[0\]}]
    set ddr_intf($gid,dqs_en_o)   [get_ports -regexp {ddr_dqs_[p|n][_ien|_oen]+_o\[0\]}]
    set ddr_intf($gid,dqs_n_i)    [get_ports -regexp {ddr_dqs_n_i\[0\]}]
    set ddr_intf($gid,dqs_n_o)    [get_ports -regexp {ddr_dqs_n_o\[0\]}]
    set ddr_intf($gid,dm_o)       [get_ports -regexp {ddr_dm[_oen]*_o\[0\]}]
    set ddr_intf($gid,dq_i)       [get_ports -regexp {ddr_dq_i\[([0-7])\]}]
    set ddr_intf($gid,dq_o)       [get_ports -regexp {ddr_dq[_oen]*_o\[([0-7])\]}]
    incr gid
    set ddr_intf($gid,dqs_p_i)    [get_ports -regexp {ddr_dqs_p_i\[1\]}]
    set ddr_intf($gid,dqs_p_o)    [get_ports -regexp {ddr_dqs_p_o\[1\]}]
    set ddr_intf($gid,dqs_en_o)   [get_ports -regexp {ddr_dqs_[p|n][_ien|_oen]+_o\[1\]}]
    set ddr_intf($gid,dqs_n_i)    [get_ports -regexp {ddr_dqs_n_i\[1\]}]
    set ddr_intf($gid,dqs_n_o)    [get_ports -regexp {ddr_dqs_n_o\[1\]}]
    set ddr_intf($gid,dm_o)       [get_ports -regexp {ddr_dm[_oen]*_o\[1\]}]
    set ddr_intf($gid,dq_i)       [get_ports -regexp {ddr_dq_i\[([8-9]|1[0-5])\]}]
    set ddr_intf($gid,dq_o)       [get_ports -regexp {ddr_dq[_oen]*_o\[([8-9]|1[0-5])\]}]
    incr gid
    set ddr_intf($gid,dqs_p_i)    [get_ports -regexp {ddr_dqs_p_i\[2\]}]
    set ddr_intf($gid,dqs_p_o)    [get_ports -regexp {ddr_dqs_p_o\[2\]}]
    set ddr_intf($gid,dqs_en_o)   [get_ports -regexp {ddr_dqs_[p|n][_ien|_oen]+_o\[2\]}]
    set ddr_intf($gid,dqs_n_i)    [get_ports -regexp {ddr_dqs_n_i\[2\]}]
    set ddr_intf($gid,dqs_n_o)    [get_ports -regexp {ddr_dqs_n_o\[2\]}]
    set ddr_intf($gid,dm_o)       [get_ports -regexp {ddr_dm[_oen]*_o\[2\]}]
    set ddr_intf($gid,dq_i)       [get_ports -regexp {ddr_dq_i\[(1[6-9]|2[0-3])\]}]
    set ddr_intf($gid,dq_o)       [get_ports -regexp {ddr_dq[_oen]*_o\[(1[6-9]|2[0-3])\]}]
    incr gid
    set ddr_intf($gid,dqs_p_i)    [get_ports -regexp {ddr_dqs_p_i\[3\]}]
    set ddr_intf($gid,dqs_p_o)    [get_ports -regexp {ddr_dqs_p_o\[3\]}]
    set ddr_intf($gid,dqs_en_o)   [get_ports -regexp {ddr_dqs_[p|n][_ien|_oen]+_o\[3\]}]
    set ddr_intf($gid,dqs_n_i)    [get_ports -regexp {ddr_dqs_n_i\[3\]}]
    set ddr_intf($gid,dqs_n_o)    [get_ports -regexp {ddr_dqs_n_o\[3\]}]
    set ddr_intf($gid,dm_o)       [get_ports -regexp {ddr_dm[_oen]*_o\[3\]}]
    set ddr_intf($gid,dq_i)       [get_ports -regexp {ddr_dq_i\[(2[4-9]|3[0-1])\]}]
    set ddr_intf($gid,dq_o)       [get_ports -regexp {ddr_dq[_oen]*_o\[(2[4-9]|3[0-1])\]}]
}

proc bsg_backport_manycore_tile_constraints { core_clk_period_ns } {
    set core_clk_name core_clk
    set core_clk_period_ns 1.250
    set core_clk_pin [get_ports "clk_i"]
    set core_input_pins {}
    append_to_collection core_input_pins [get_ports reset_i]
    append_to_collection core_input_pins [get_ports global_x_i[*]]
    append_to_collection core_input_pins [get_ports global_y_i[*]]
    append_to_collection core_input_pins [get_ports link_sif_i[*]]
    set core_output_pins [get_ports link_sif_o[*]]
    bsg_backport_clock_constrain ${core_clk_name} ${core_clk_period_ns} ${core_clk_pin} ${core_input_pins} ${core_output_pins}

    set_false_path -from [get_ports global_x_i[*]]
    set_false_path -from [get_ports global_y_i[*]]
}

proc bsg_backport_ddr_link_pearl_inst_constraints { ddr_link_pearl_inst name_root } {
    set core_clk_period_ns 1.000
    set link_clk_period_ns 2.500; # 400 MHz link, 800 MHz io
    set max_io_output_margin_ns 0.80; # Fixed
    set max_io_input_margin_ns  0.80; # Fixed

    set master_clk_pin [get_pins ${ddr_link_pearl_inst}/core_clk_i]
    set master_clk_obj [get_db ${master_clk_pin} .clocks]
    set master_clk_name [get_db ${master_clk_obj} .name]
    set master_clk_period_ns [expr [get_db ${master_clk_obj} .period] / 1000.0]

    # Tag bus
    set tag_name_root ${name_root}tag_
    set tag_bus_root tag_
    set tag_clk_name ${tag_name_root}clk
    bsg_backport_tag_bus_constrain ${tag_name_root} ${tag_bus_root}

    set clk_gen_pearl_inst ${ddr_link_pearl_inst}/io_clk_gen
    set clk_gen_pearl_root ${name_root}io_
    set clk_gen_pearl_clk_period_ns [expr ${link_clk_period_ns} / 2.0]
    set clk_gen_pearl_input_pins {}
    set clk_gen_pearl_output_pins {}
    bsg_backport_clk_gen_pearl_inst_constraints \
        ${clk_gen_pearl_inst} \
        ${clk_gen_pearl_root} \
        ${clk_gen_pearl_clk_period_ns} \
        ${clk_gen_pearl_input_pins} \
        ${clk_gen_pearl_output_pins}
    set io_clk_name ${clk_gen_pearl_root}clk

    set out_clk_name ${name_root}out_clk
    set out_clk_period_ns ${master_clk_period_ns}
    set out_clk_margin_ns ${max_io_output_margin_ns}
    set out_clk_pins [get_pins ${ddr_link_pearl_inst}/link_clk_o]
    set out_clk_ports [get_db ${out_clk_pins} .net.loads]
    set out_dv_pins [get_pins "${ddr_link_pearl_inst}/link_data_o ${ddr_link_pearl_inst}/link_v_o"]
    set out_dv_ports [get_db ${out_dv_pins} .net.loads]
    set out_tkn_name ${name_root}out_tkn
    set out_tkn_pins [get_pins ${ddr_link_pearl_inst}/link_token_o]
    set out_tkn_ports [get_db ${out_tkn_pins} .net.loads]

    set in_clk_name ${name_root}in_clk
    set in_clk_period_ns ${link_clk_period_ns}
    set in_clk_margin_ns ${max_io_input_margin_ns}
    set in_clk_pins [get_pins ${ddr_link_pearl_inst}/link_clk_i]
    set in_clk_ports [get_db ${in_clk_pins} .net.driver]
    set in_dv_pins [get_pins "${ddr_link_pearl_inst}/link_data_i ${ddr_link_pearl_inst}/link_v_i"]
    set in_dv_ports [get_db ${in_dv_pins} .net.driver]
    set in_tkn_name ${name_root}in_tkn
    set in_tkn_pins [get_pins ${ddr_link_pearl_inst}/link_token_i]
    set in_tkn_ports [get_db ${in_tkn_pins} .net.driver]
    bsg_link_ddr_constraints                       \
        ${io_clk_name}                             \
        ${out_clk_name}                            \
        ${out_clk_period_ns}                       \
        ${out_clk_margin_ns}                       \
        ${out_clk_ports}                             \
        ${out_dv_ports}                              \
        ${out_tkn_name}                            \
        ${out_tkn_ports}                             \
        ${in_clk_name}                             \
        ${in_clk_period_ns}                        \
        ${in_clk_margin_ns}                        \
        ${in_clk_ports}                              \
        ${in_dv_ports}                               \
        ${in_tkn_name}                             \
        ${in_tkn_ports}                              \
        0.0 ; # Uncertainty handled later in flow
}

