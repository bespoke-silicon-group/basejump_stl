
##########################################################
##########################################################
## Procs
##########################################################
##########################################################

# TODO: Make a little cleaner
proc bsg_backport_1r1w_disable { } {
    puts "Disabling 1r1w paths"
    set cells_to_disable [get_cells -quiet -hier "*macro.mem"]
    if { [sizeof ${cells_to_disable}] > 0 } {
      set libs_to_disable [get_db ${cells_to_disable} .lib_cell]
      foreach lib $libs_to_disable {
        if {[sizeof_collection [get_lib_pins -quiet -of_objects ${lib} -filter {name==CLKA}] > 0]} {
          puts "disabling CLKR<->CLKW for [get_db ${lib} .base_name]"
          set_disable_timing $lib -from CLKA -to CLKB
          set_disable_timing $lib -from CLKB -to CLKA
        }
        if {[sizeof_collection [get_lib_pins -quiet -of_objects ${lib} -filter {name==CLKR}] > 0]} {
          puts "disabling CLKR<->CLKW for [get_db ${lib} .base_name]"
          set_disable_timing $lib -from CLKR -to CLKW
          set_disable_timing $lib -from CLKW -to CLKR
        }
      }
    }
}

proc bsg_backport_clk_create { clk_name clk_period_ns clk_pin } {
    set clk_uncertainty_ns 0.020; # Fixed jitter

    create_clock -name ${clk_name} \
        -period ${clk_period_ns} \
        ${clk_pin}
    set clk_obj [get_clocks ${clk_name}]
    set_clock_uncertainty ${clk_uncertainty_ns} ${clk_obj}
    set_propagated_clock ${clk_obj}

    return ${clk_obj}
}

# Returns a dict with 
proc bsg_backport_unwrap_pinports { pins } {
    set ports {}
    foreach pin ${pins} {
        set pindir [get_db ${pin} .direction]

        if {${pindir}=="in"} {
            set fanx [all_fanin -to ${pin} -startpoints_only -trace_through all]
        } else {
            set fanx [all_fanout -from ${pin} -endpoints_only -trace_through all]
        }

        append_to_collection pins ${fanx}
        append_to_collection ports [filter_collection ${fanx} "is_port==true"]
    }

    set pinports [dict create]
    dict set pins ${pins}
    dict set ports ${ports}

    return ${pinports}
}

proc bsg_backport_tag_bus_create { tag_bus } {
    set base [dict get ${tag_bus} base]
    set clk_pins [dict get ${tag_bus} clk_pins]
    set input_pins [dict get ${tag_bus} input_pins]
    set output_pins [dict get ${tag_bus} output_pins]

    set clk_name ${base}clk
    set clk_period_ns 5.000; # 200 MHz
    dict set tag_bus clk [bsg_backport_clk_create ${clk_name} ${clk_period_ns} ${clk_pins}]

    set input_delay_ns [expr ${clk_period_ns} / 2.0]
    set output_delay_ns [expr ${clk_period_ns} / 4.0]
    set_input_delay ${input_delay_ns} ${input_pins} -clock ${clk_name} -source_latency_included -network_latency_included
    set_output_delay ${output_delay_ns} ${output_pins} -clock ${clk_name} -source_latency_included -network_latency_included

    set_multicycle_path 2 -setup -to ${output_pins} 
    set_multicycle_path 1 -hold  -to ${output_pins}

    return ${tag_bus}
}

proc bsg_backport_clk_gen_pearl_create { clk_gen_pearl } {
    set base [dict get ${clk_gen_pearl} base]
    set inst [dict get ${clk_gen_pearl} inst]
    set period_ns [dict get ${clk_gen_pearl} period_ns]

    set name [get_db ${inst} .name]
    set osc_pins [get_pins ${name}/clk_gen_inst/clk_gen_osc_inst/osc_BSG_DONT_TOUCH/B0/Z]
    set iclk_pins [all_fanin -to [get_pins -of_objects ${inst} -filter {name==ext_clk_i}] -startpoints]
    set oclk_pins [get_pins ${name}/clk_gen_inst/mux_inst/fi.rof[0].M0_BSG_RESIZE_OK/Z]
    set monitor_pins [all_fanin -startpoints_only -to [get_pins -of_objects ${inst} -filter {name==clk_monitor_o}]]
    set disable_pins [all_fanin -startpoints_only -to [get_pins -of_objects ${inst} -filter {name==async_output_disable_i}]]

    dict set clk_gen_pearl osc_pins ${osc_pins}
    dict set clk_gen_pearl iclk_pins ${iclk_pins}
    dict set clk_gen_pearl oclk_pins ${oclk_pins}
    dict set clk_gen_pearl monitor_pins ${monitor_pins}
    dict set clk_gen_pearl disable_pins ${disable_pins}

    set osc_name ${base}oclk
    set osc_period_ns [expr ${period_ns} / 2.0]
    set oclk_name ${base}clk
    set mclk_name ${base}mclk
    dict set clk_gen_pearl osc [bsg_backport_clk_create ${osc_name} ${osc_period_ns} ${osc_pins}]
    dict set clk_gen_pearl oclk [bsg_backport_clk_create ${oclk_name} ${period_ns} ${oclk_pins}]
    dict set clk_gen_pearl mclk [bsg_backport_clk_create ${mclk_name} ${period_ns} ${monitor_pins}]

    return ${clk_gen_pearl}
}

proc bsg_backport_sdr_link_pearl_create { sdr_link_pearl } {
    set base [dict get ${sdr_link_pearl} base]
    set inst [dict get ${sdr_link_pearl} inst]

    set master_clk_obj [dict get ${sdr_link_pearl} master_clk]
    set olink_clk_name "${base}olink_clk"
    set olink_clk_ratio 1
    set olink_clk_buf [get_db ${inst} .insts -regexp ".*BSG_OSDR_CKBUF_BSG_DONT_TOUCH"]
    set olink_clk_pin [get_pins -of_objects ${olink_clk_buf} -filter {name==Z}]
    create_generated_clock \
        -name ${olink_clk_name} \
        -master_clock ${master_clk_obj} \
        -source [get_db ${master_clk_obj} .sources] \
        -divide_by ${olink_clk_ratio} \
        -invert \
        -add ${olink_clk_pin}
    set olink_clk_obj [get_clocks ${olink_clk_name}]
    dict set sdr_link_pearl olink_clk ${olink_clk_obj}

    set ilink_token_name "${base}ilink_tkn"
    # DWP Workaround since manycore pod isn't using sdr_link_pearls
    if {[string first "manycore_pod" ${base}] == -1} {
        set ilink_token_reg [get_db ${inst} .insts -regexp ".*downstream_token_counter_count_o_reg.*"]
    } else {
        set ilink_token_reg [get_db ${inst} .insts -regexp ".*token_counter.*count_o_reg.*"]
    }
    set ilink_token_ratio 2
    set ilink_token_pin [get_pins -of_objects ${ilink_token_reg} -filter {name==Q}]
    create_generated_clock \
        -name ${ilink_token_name} \
        -master_clock ${master_clk_obj} \
        -source [get_db ${master_clk_obj} .sources] \
        -divide_by ${ilink_token_ratio} \
        -invert \
        -add ${ilink_token_pin}
    set ilink_token_obj [get_clocks ${ilink_token_name}]
    dict set sdr_link_pearl ilink_token ${ilink_token_obj}

    return ${sdr_link_pearl}
}

proc bsg_backport_subpod_link_create { subpod_link } {
    set subpod_link_base [dict get ${subpod_link} base]
    set subpod_link_inst [dict get ${subpod_link} inst]
    set subpod_link_period_ns [dict get ${subpod_link} period_ns]

    set clk_gen_pearl [dict create]
    set clk_gen_pearl_base "${subpod_link_base}clk_gen_pearl_"
    set clk_gen_pearl_inst [get_db ${subpod_link_inst} .hinsts -if {.ref_name=~bsg_clk_gen_pearl*}]
    set clk_gen_pearl_period_ns ${subpod_link_period_ns}

    dict set clk_gen_pearl base ${clk_gen_pearl_base}
    dict set clk_gen_pearl inst ${clk_gen_pearl_inst}
    dict set clk_gen_pearl period_ns ${clk_gen_pearl_period_ns}

    dict set subpod_link clk_gen_pearl [bsg_backport_clk_gen_pearl_create ${clk_gen_pearl}]

    set sdr_link_pearl_insts [get_db ${subpod_link_inst} .hinsts -if {.ref_name=~bsg_sdr_link_pearl*}]
    for { set i 0 } { $i < [llength ${sdr_link_pearl_insts}] } { incr i } {

        set sdr_link_pearl [dict create]
        set sdr_link_pearl_base "${subpod_link_base}sdr_link_pearl[$i]_"
        set sdr_link_pearl_inst [lindex ${sdr_link_pearl_insts} $i]

        dict set sdr_link_pearl base ${sdr_link_pearl_base}
        dict set sdr_link_pearl inst ${sdr_link_pearl_inst}
        dict set sdr_link_pearl master_clk [dict get ${subpod_link} clk_gen_pearl oclk]

        dict lappend subpod_link "sdr_link_pearls" [bsg_backport_sdr_link_pearl_create ${sdr_link_pearl}]
    }

    return ${subpod_link}
}

proc bsg_backport_pod_link_create { pod_link } {
    set pod_link_base [dict get ${pod_link} base]
    set pod_link_inst [dict get ${pod_link} inst]
    set pod_link_period_ns [dict get ${pod_link} period_ns]

    set clk_gen_pearl [dict create]
    set clk_gen_pearl_base "${pod_link_base}clk_gen_pearl_"
    set clk_gen_pearl_inst [get_db ${pod_link_inst} .hinsts -if {.ref_name=~bsg_clk_gen_pearl*}]
    set clk_gen_pearl_period_ns ${pod_link_period_ns}

    dict set clk_gen_pearl base ${clk_gen_pearl_base}
    dict set clk_gen_pearl inst ${clk_gen_pearl_inst}
    dict set clk_gen_pearl period_ns ${clk_gen_pearl_period_ns}

    dict set pod_link clk_gen_pearl [bsg_backport_clk_gen_pearl_create ${clk_gen_pearl}]

    set sdr_link_pearl_insts [get_db ${pod_link_inst} .hinsts -if {.ref_name=~bsg_sdr_link_pearl*}]
    for { set i 0 } { $i < [llength ${sdr_link_pearl_insts}] } { incr i } {

        set sdr_link_pearl [dict create]
        set sdr_link_pearl_base "${pod_link_base}sdr_link_pearl[$i]_"
        set sdr_link_pearl_inst [lindex ${sdr_link_pearl_insts} $i]

        dict set sdr_link_pearl base ${sdr_link_pearl_base}
        dict set sdr_link_pearl inst ${sdr_link_pearl_inst}
        dict set sdr_link_pearl master_clk [dict get ${pod_link} clk_gen_pearl oclk]

        dict lappend pod_link "sdr_link_pearls" [bsg_backport_sdr_link_pearl_create ${sdr_link_pearl}]
    }

    return ${pod_link}
}

proc bsg_backport_manycore_pod_create { manycore_pod } {
    set manycore_pod_base [dict get ${manycore_pod} base]
    set manycore_pod_inst [dict get ${manycore_pod} inst]
    set manycore_pod_period_ns [dict get ${manycore_pod} period_ns]

    set clk_gen_pearl_base "${manycore_pod_base}clk_gen_pearl_"
    set clk_gen_pearl_inst [get_db ${manycore_pod_inst} .hinsts -if {.ref_name=~bsg_clk_gen_pearl*}]
    set clk_gen_pearl [dict create]
    dict set clk_gen_pearl base ${clk_gen_pearl_base}
    dict set clk_gen_pearl inst ${clk_gen_pearl_inst}
    dict set clk_gen_pearl period_ns ${manycore_pod_period_ns}

    dict set manycore_pod clk_gen_pearl [bsg_backport_clk_gen_pearl_create ${clk_gen_pearl}]

    foreach { dir } { "fwd" "rev" } {
        foreach { hside } { "e" "w" } {
            set sdr_link_pearl_insts [get_db ${manycore_pod_inst} .hinsts -regexp ".*sdr_${hside}_y.*.sdr_${hside}/${dir}_sdr"]
            for { set i 0 } { $i < [llength ${sdr_link_pearl_insts}] } { incr i } {
                puts "Creating manycore SDR link $i for dir=${dir} hside=${hside}"
                set sdr_link_pearl_base "${manycore_pod_base}${hside}_${dir}_sdr_link_pearl[$i]_"
                set sdr_link_pearl_inst [lindex ${sdr_link_pearl_insts} $i]
                set sdr_link_pearl [dict create]

                dict set sdr_link_pearl base ${sdr_link_pearl_base}
                dict set sdr_link_pearl inst ${sdr_link_pearl_inst}
                dict set sdr_link_pearl master_clk [dict get ${manycore_pod} clk_gen_pearl oclk]

                if {(${hside}=="w" && ($i==0 || $i==1 || $i==2 || $i==3 || $i==6 || $i==7))
                        || (${hside}=="e" && ($i == 0 || $i == 5 || $i == 6))} {
                    set stub_clki_pins {}
                    append_to_collection stub_clki_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_clk_i"]
                    append_to_collection stub_clki_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_token_i"]

                    # These nets are not preserved erroneously
                    set stub_clko_pins {}
                    #append_to_collection stub_clko_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_clk_o"]
                    #append_to_collection stub_clko_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_token_o"]

                    set stub_dvi_pins {}
                    append_to_collection stub_dvi_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_data_i[*]"]
                    append_to_collection stub_dvi_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_v_i"]

                    set stub_dvo_pins {}
                    append_to_collection stub_dvo_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_data_o[*]"]
                    append_to_collection stub_dvo_pins [get_pins -of_objects ${sdr_link_pearl_inst} -filter "name=~link_v_o"]

                    set stub_clk_srcs {}
                    append_to_collection stub_clk_srcs [all_fanout -from ${stub_clki_pins} -endpoints_only]
                    #append_to_collection stub_clk_srcs [all_fanin -to ${stub_clko_pins} -startpoints_only]
                    set stub_clk_name "${manycore_pod_base}_stub_sdr_${hside}_${dir}[$i]_olink_clk"
                    set stub_clk_period_ns 10000

                    set sdr_link_stub_clk [bsg_backport_clk_create ${stub_clk_name} ${stub_clk_period_ns} ${stub_clk_srcs}]
                    dict lappend manycore_pod "io_sdr_stubs" ${sdr_link_stub_clk}

                    # Set an arbitrary delay
                    set_input_delay 0.0 -clock ${sdr_link_stub_clk} ${stub_dvi_pins}
                    set_output_delay 0.0 -clock ${sdr_link_stub_clk} ${stub_dvo_pins}
                } else {
                    set sdr_link_pearl [bsg_backport_sdr_link_pearl_create ${sdr_link_pearl}]
                    dict lappend manycore_pod "io_sdr_link_pearls" ${sdr_link_pearl}
                }
            }
        }
    }

    foreach { vside } { "s" "n" } {
        foreach { hside } { "e" "w" } {
            set sdr_link_pearl_insts [get_db ${manycore_pod_inst} .hinsts -regexp ".*sdr_${vside}${hside}/wh_sdr.*.sdr"]
            for { set i 0 } { $i < [llength ${sdr_link_pearl_insts}] } { incr i } {
                set sdr_link_pearl_base "${manycore_pod_base}wh_${vside}${hside}_sdr_link_pearl[$i]_"
                set sdr_link_pearl_inst [lindex ${sdr_link_pearl_insts} $i]
                set sdr_link_pearl [dict create]

                dict set sdr_link_pearl base ${sdr_link_pearl_base}
                dict set sdr_link_pearl inst ${sdr_link_pearl_inst}
                dict set sdr_link_pearl master_clk [dict get ${manycore_pod} clk_gen_pearl oclk]
                set sdr_link_pearl [bsg_backport_sdr_link_pearl_create ${sdr_link_pearl}]
                dict lappend manycore_pod "wh_sdr_link_pearls" ${sdr_link_pearl}
            }
        }
    }

    return ${manycore_pod}
}

proc bsg_backport_ddr_link_pearl_create { ddr_link_pearl } {
    set link_clk_period_ns 2.500; # 400 MHz link, 800 MHz io
    set max_io_output_margin_ns 0.300; # Fixed
    set max_io_input_margin_ns  0.300; # Fixed

    set base [dict get ${ddr_link_pearl} base]
    set inst [dict get ${ddr_link_pearl} inst]
    set master_clk_obj [dict get ${ddr_link_pearl} master_clk]
    set master_clk_period_ns [expr [get_db ${master_clk_obj} .period]]

    set io_clk_gen_pearl_inst [get_db ${inst} .hinsts -if {.ref_name=~bsg_clk_gen_pearl*}]
    set io_clk_gen_pearl_base "${base}io_clk_gen_pearl_"

    set io_clk_gen_pearl [dict create]
    dict set io_clk_gen_pearl base ${io_clk_gen_pearl_base}
    dict set io_clk_gen_pearl inst ${io_clk_gen_pearl_inst}
    dict set io_clk_gen_pearl period_ns ${link_clk_period_ns}
    dict set ddr_link_pearl io_clk_gen_pearl [bsg_backport_clk_gen_pearl_create ${io_clk_gen_pearl}]
    set io_clk_obj [dict get ${ddr_link_pearl} io_clk_gen_pearl oclk]

    set out_clk_name ${base}olink_clk
    set out_clk_period_ns ${master_clk_period_ns}
    set out_clk_margin_ns ${max_io_output_margin_ns}
    set out_clk_edges {2 4 6}
    set out_clk_pins [get_pins -of_objects ${inst} -filter "name==link_clk_o"]
    #set out_clk_ports [all_fanout -endpoints_only -from ${out_clk_pins} -trace_through all]
    # DWP tempus has a hard time tracing this clock otherwise
    #set out_clk_obj [get_db ${inst} .insts -regexp ".*oddr_phy_clk_r_o_reg.*"]
    #set out_clk_ports [get_pins -of_objects ${out_clk_obj} -filter "name==Q"]
    set out_clk_ports [all_fanout -endpoints_only -from ${out_clk_pins}]
    set out_dv_pins [get_pins -of_objects ${inst} -filter "name=~link_data_o*||name==link_v_o"]
    set out_dv_ports [all_fanout -endpoints_only -from ${out_dv_pins} -trace_through all]
    set out_tkn_name ${base}olink_tkn
    set out_tkn_pins [get_pins -of_objects ${inst} -filter "name==link_token_i"]
    set out_tkn_ports [all_fanin -startpoints_only -to ${out_tkn_pins} -trace_through all]
    create_clock -name ${out_tkn_name} -period ${out_clk_period_ns} ${out_tkn_ports}

    set setup_time_output_ns      [expr (${out_clk_period_ns}/4.0)-${out_clk_margin_ns}]
    set hold_time_output_ns       [expr (${out_clk_period_ns}/4.0)-${out_clk_margin_ns}]
    foreach_in_collection port ${out_dv_ports} {
        set_data_check -from ${out_clk_ports} -to ${port} -setup ${setup_time_output_ns}
        set_data_check -from ${out_clk_ports} -to ${port} -hold ${setup_time_output_ns}
        set_multicycle_path -end   -setup 1 -to ${port}
        set_multicycle_path -start -hold  0 -to ${port}
    }
    create_clock -name ${out_clk_name} -period ${out_clk_period_ns} ${out_clk_ports}
    set_clock_groups -async -group [get_clocks ${out_clk_name}]

    # DWP We're doing data check instead of generated clock style
    #create_generated_clock \
    #    -name ${out_clk_name} \
    #    -edges ${out_clk_edges} \
    #    -master_clock ${io_clk_obj} \
    #    -source [get_db ${io_clk_obj} .sources] \
    #    -add ${out_clk_ports}

    #set max_output_delay_ns [expr (${out_clk_period_ns}/4.0)-${out_clk_margin_ns}]
    #set min_output_delay_ns [expr ${out_clk_margin_ns}-(${out_clk_period_ns}/4.0)]
    #set_output_delay -max ${max_output_delay_ns} -clock ${out_clk_name} ${out_dv_ports}
    #set_output_delay -max ${max_output_delay_ns} -clock ${out_clk_name} ${out_dv_ports} -add_delay -clock_fall
    #set_output_delay -min ${min_output_delay_ns} -clock ${out_clk_name} ${out_dv_ports}
    #set_output_delay -min ${min_output_delay_ns} -clock ${out_clk_name} ${out_dv_ports} -add_delay -clock_fall

    set in_clk_name ${base}ilink_clk
    set in_clk_period_ns ${link_clk_period_ns}
    set in_clk_margin_ns ${max_io_input_margin_ns}
    set in_clk_pins [get_pins -of_objects ${inst} -filter "name==link_clk_i"]
    set in_clk_ports [all_fanin -startpoints_only -to ${in_clk_pins} -trace_through all]
    set in_dv_pins [get_pins -of_objects ${inst} -filter "name=~link_data_i*||name==link_v_i"]
    set in_dv_ports [all_fanin -startpoints_only -to ${in_dv_pins} -trace_through all]
    set in_tkn_name ${base}ilink_tkn
    #set in_tkn_pins [get_pins -of_objects ${inst} -filter "name==link_token_o"]
    #set in_tkn_ports [all_fanin -startpoints_only -to ${in_tkn_pins} -trace_through all]
    # TODO: harden
    set in_token_reg [get_db ${inst} .insts *downstream_token_counter_count_o_reg[4]]
    set in_token_pins [get_pins -of_objects ${in_token_reg} -filter "name==Q"]
    create_clock -name ${in_clk_name} -period ${in_clk_period_ns} ${in_clk_ports}

    set max_input_delay_ns [expr (${in_clk_period_ns}/2.0)-${in_clk_margin_ns}]
    set min_input_delay_ns [expr ${in_clk_margin_ns}]
    set_input_delay -max ${max_input_delay_ns} -clock ${in_clk_name} -source_latency_included -network_latency_included ${in_dv_ports}
    set_input_delay -max ${max_input_delay_ns} -clock ${in_clk_name} -source_latency_included -network_latency_included ${in_dv_ports} -add_delay -clock_fall
    set_input_delay -min ${min_input_delay_ns} -clock ${in_clk_name} -source_latency_included -network_latency_included ${in_dv_ports}
    set_input_delay -min ${min_input_delay_ns} -clock ${in_clk_name} -source_latency_included -network_latency_included ${in_dv_ports} -add_delay -clock_fall

    set in_tkn_ratio 2
    create_generated_clock \
        -name ${in_tkn_name} \
        -divide_by ${in_tkn_ratio} \
        -invert \
        -master_clock ${master_clk_obj} \
        -source [get_db ${master_clk_obj} .sources] \
        -add ${in_token_pins}

    set delay_mux [get_db ${inst} .insts -regexp {.*sig.*mux.*BSG_DONT_TOUCH.*}]
    set delay_sel [get_pins -of_objects ${delay_mux} -filter "name==S0||name==S1"]
    set_case_analysis 0 ${delay_sel}

    return ${ddr_link_pearl}
}

#############################
## Misc constraints
#############################

proc bsg_backport_ddr_intf_create { ddr_intf_p pre } {
    # Link to passed array parameter
    upvar 1 ${ddr_intf_p} ddr_intf

    set ddr_intf(ck_p)                [get_ports -regexp "${pre}ck_p_o"]
    set ddr_intf(ck_n)                [get_ports -regexp "${pre}ck_n_o"]
    set ddr_intf(ca)                  [get_ports -regexp "${pre}cke_o"]
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}cs_n_o"]
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}ras_n_o"]
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}cas_n_o"]
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}we_n_o"]
    # Slow, but we put on this bus
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}init_o"]
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}trans_o"]
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}stall_o"]
    append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}refresh_o"]
    for {set j 0} {$j < 3} {incr j} {
        append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}ba_${j}_o"]
    }
    for {set j 0} {$j < 16} {incr j} {
        append_to_collection ddr_intf(ca) [get_ports -regexp "${pre}addr_${j}_o"]
    }
    for {set gid 0} {${gid} < 4} {inc gid} {
        set ddr_intf(${gid},dqs_p_i)    [get_ports -regexp "${pre}dqs_p_${gid}_io"]
        set ddr_intf(${gid},dqs_p_o)    [get_ports -regexp "${pre}dqs_p_${gid}_io"]
        set ddr_intf(${gid},dqs_n_i)    [get_ports -regexp "${pre}dqs_n_${gid}_io"]
        set ddr_intf(${gid},dqs_n_o)    [get_ports -regexp "${pre}dqs_n_${gid}_io"]
        set ddr_intf(${gid},dm_i)       [get_ports -regexp "${pre}dm_${gid}_io"]
        set ddr_intf(${gid},dm_o)       [get_ports -regexp "${pre}dm_${gid}_io"]
        for {set j [expr (${gid}+0)*8]} {$j < [expr (${gid}+1)*8]} {incr j} {
            append_to_collection ddr_intf(${gid},dq_i) [get_ports -regexp "${pre}dq_${j}_io"]
            append_to_collection ddr_intf(${gid},dq_o) [get_ports -regexp "${pre}dq_${j}_io"]
        }
    }
}

proc bsg_backport_dmc_pearl_create { dmc_pearl } {
    set base [dict get ${dmc_pearl} base]
    set inst [dict get ${dmc_pearl} inst]
    set dfi_clk_2x [dict get ${dmc_pearl} dfi_clk_2x]
    array set ddr_intf [dict get ${dmc_pearl} ddr_intf]

    set dfi_clk_2x_name [get_db ${dfi_clk_2x} .base_name]
    set dfi_clk_2x_period_ns [get_db ${dfi_clk_2x} .period]
    set dfi_clk_1x_name ${base}dfi_clk_1x
    set dfi_clk_1x_ratio 2
    set dfi_clk_1x_period_ns [expr ${dfi_clk_2x_period_ns} * ${dfi_clk_1x_ratio}]
    set dfi_clk_1x_ds [get_db ${inst} .insts -regexp ".*clk_gen_ds_inst/d_macro.*d_BSG_DONT_TOUCH"]
    set dfi_clk_1x_pin [get_pins -of_objects ${dfi_clk_1x_ds} -filter "name==Q"]
    create_generated_clock \
        -name ${dfi_clk_1x_name} \
        -divide_by ${dfi_clk_1x_ratio} \
        -master_clock ${dfi_clk_2x} \
        -source [get_db ${dfi_clk_2x} .sources] \
        -add ${dfi_clk_1x_pin}
    dict set dmc_pearl dfi_clk_1x [get_clocks ${dfi_clk_1x_name}]

    set ck_p_name ${base}ck_p
    set ck_p_ratio 2
    set ck_p_pin [all_fanin -startpoints_only -to $ddr_intf(ck_p)]
    create_generated_clock \
        -name ${ck_p_name} \
        \
        -divide_by ${ck_p_ratio} \
        -master_clock [get_clocks ${dfi_clk_2x_name}] \
        -source [get_db [get_clocks ${dfi_clk_2x_name}] .sources] \
        -add ${ck_p_pin}

    #set ck_n_name ${base}ck_n
    #set ck_n_ratio 1
    #set ck_n_pin [all_fanin -startpoints_only -to $ddr_intf(ck_n)]
    #create_generated_clock \
    #    -name ${ck_n_name} \
    #    -invert \
    #    -divide_by ${ck_n_ratio} \
    #    -master_clock [get_clocks ${dfi_clk_1x_name}] \
    #    -source [get_db [get_clocks ${dfi_clk_1x_name}] .sources] \
    #    -add ${ck_n_pin}

    set ca_max_skew_ns [expr  ${dfi_clk_1x_period_ns} * 0.1]
    set ca_min_skew_ns [expr -${dfi_clk_1x_period_ns} * 0.1]
    set ca_pins $ddr_intf(ca)
    set_output_delay -max ${ca_max_skew_ns} ${ca_pins} -clock [get_clocks ${ck_p_name}]
    set_output_delay -min ${ca_min_skew_ns} ${ca_pins} -clock [get_clocks ${ck_p_name}]

    set max_io_skew_ns [expr ${dfi_clk_1x_period_ns} * 0.05]
    set dqs_max_delay_ns [expr (${dfi_clk_1x_period_ns} / 4.0) - ${max_io_skew_ns}]
    set dqs_min_delay_ns 0; #[expr -${dqs_max_delay_ns}]
    for {set gid 0} {${gid} < 4} {incr gid} {
        set dqs_i_clk_name ${base}dqs_i[${gid}]
        set dqs_i_clk_period_ns ${dfi_clk_1x_period_ns}
        create_clock \
            -name ${dqs_i_clk_name} \
            -period ${dqs_i_clk_period_ns} \
            [concat $ddr_intf(${gid},dqs_p_i) $ddr_intf(${gid},dqs_n_i)]

        set dly_line [get_db ${inst} .hinsts *dly_lines[${gid}].dly_line_inst]

        #set dqs_i_dly_name ${base}dqs_i_dly[${gid}]
        #set dqs_i_dly_buf [get_db ${dly_line} .insts -regexp ".*d(90|180)_BSG_DONT_TOUCH/B0"]
        #set dqs_i_dly_pins [get_pins -of_objects ${dqs_i_dly_buf} -filter "pin_direction==out"]
        #create_clock \
        #    -name ${dqs_i_dly_name} \
        #    -period ${dqs_i_clk_period_ns} \
        #    ${dqs_i_dly_pins}

        set dqs_input_pins [concat $ddr_intf(${gid},dq_i) $ddr_intf(${gid},dm_i)]
        set_input_delay -max ${dqs_max_delay_ns} -clock ${dqs_i_clk_name} ${dqs_input_pins}
        set_input_delay -min ${dqs_min_delay_ns} -clock ${dqs_i_clk_name} ${dqs_input_pins} -add_delay

        set dqs_o_clk_name ${base}dqs_o[${gid}]
        set dqs_o_period_ns ${dfi_clk_1x_period_ns}
        set dqs_o_pins [concat $ddr_intf(${gid},dqs_p_o) $ddr_intf(${gid},dqs_n_o)]
        #set dqs_o_ratio 2
        #create_generated_clock \
        #    -name ${dqs_o_clk_name} \
        #    -divide_by ${dqs_o_ratio} \
        #    -master_clock [get_clocks ${dfi_clk_2x_name}] \
        #    -source [get_db [get_clocks ${dfi_clk_2x_name}] .sources] \
        #    -add ${dqs_o_pins}
        ## DWP: Disable these paths
        # This is better than false path, because at least the tool tracks the paths
        #set_max_delay 10.0 -to [get_clocks ${dqs_o_clk_name}]

        #set dqs_output_pins [concat $ddr_intf(${gid},dq_o) $ddr_intf(${gid},dm_o)]
        #set_output_delay -max ${dqs_max_delay_ns} -clock ${dqs_o_clk_name} ${dqs_output_pins}
        #set_output_delay -min ${dqs_min_delay_ns} -clock ${dqs_o_clk_name} ${dqs_output_pins}

        # Create the data check
        #set output_setup_margin_ns [expr ${dqs_o_period_ns} * 0.2]
        #set output_hold_margin_ns [expr ${dqs_o_period_ns} * 0.2]
        set output_setup_margin_ns [expr ${dqs_o_period_ns} * 0.05]
        set output_hold_margin_ns [expr ${dqs_o_period_ns} * 0.05]
        foreach_in_collection dqs_pin [concat $ddr_intf(${gid},dqs_p_o) $ddr_intf(${gid},dqs_n_o)] {
          foreach_in_collection dq_pin [concat $ddr_intf(${gid},dq_o) $ddr_intf(${gid},dm_o)] {
            set_data_check -from ${dqs_pin} -to ${dq_pin} -setup ${output_setup_margin_ns}
            set_data_check -from ${dqs_pin} -to ${dq_pin} -hold ${output_hold_margin_ns}
            set_multicycle_path -end -setup 1 -to ${dq_pin}
            set_multicycle_path -start -hold 0 -to ${dq_pin}
          }
        }
    }

    set test_mode_reg [get_db ${inst} .insts -regexp .*dfi_test_mode.*recv_macro.*]
    set test_mode_pin [get_pins -of_objects ${test_mode_reg} -filter "name==Q"]
    set_case_analysis 0 ${test_mode_pin}
}

#############################
## Misc constraints
#############################

proc bsg_backport_clock_discount { clks } {
    foreach_in_collection clk ${clks} {
        set_max_delay  100.0 -from [get_clock ${clk}]
        set_min_delay -100.0 -from [get_clock ${clk}]

        set_max_delay  100.0 -to   [get_clock ${clk}]
        set_min_delay -100.0 -to   [get_clock ${clk}]
    }
}

proc bsg_backport_async_icl { clocks } {
  foreach_in_collection launch_clk ${clocks} {
    if { [get_db ${launch_clk} .is_generated] } {
      set launch_master [get_db ${launch_clk} .master_clock]
    } else {
      set launch_master ${launch_clk}
    }

    set launch_group {}
    append_to_collection launch_group [get_clocks ${launch_master}]
    append_to_collection launch_group [get_clocks -quiet [get_db ${launch_master} .generated_clocks]]

    puts "Launch Clock [get_db ${launch_clk} .base_name] Launch Group [get_db ${launch_group} .base_name]"
    set cdc_delay_ns [get_db ${launch_master} .period]

    set latch_group [remove_from_collection ${clocks} ${launch_group}]
    foreach_in_collection latch_clk ${latch_group} {
      set_max_delay ${cdc_delay_ns} -from ${launch_clk} -to ${latch_clk} -ignore_clock_latency
      set_min_delay -0.1            -from ${launch_clk} -to ${latch_clk} -ignore_clock_latency
    }
  }
}


##########################################################
##########################################################
## Actual constraints
##########################################################
##########################################################

proc bsg_backport_constraints_execute { } {

    #############################
    ## Set static pad constraints
    #############################
    set vclk_name vclk
    set vclk_period_ns 10.000; # 100 MHz
    create_clock -name ${vclk_name} -period ${vclk_period_ns}
    set vclk [get_clocks ${vclk_name}]

    # Default drive and load
    set_driving_cell -no_design_rule -lib_cell PDDW12DGZ_H_G -pin C -from_pin PAD [all_inputs]
    set_load [lindex [get_db [get_lib_pin "*/PDDW12DGZ_H_G/I"] .fanout_load] 0] [all_outputs]

    # Enable output on output pads
    set_case_analysis 0 [get_pins *_o_pad_inst_BSG_DONT_TOUCH/OEN]
    # Enable input on input pads
    set_case_analysis 1 [get_pins *_i_pad_inst_BSG_DONT_TOUCH/OEN]

    # Set fake input delay on output pads
    set_input_delay 0.0 -clock ${vclk} [get_ports -regexp "pad_(b|r)_.*_o"] -source_latency_included -network_latency_included

    # Set fake output delay on input pads
    set_output_delay 0.0 -clock ${vclk} [get_ports -regexp "pad_(b|r)_.*_i"]

    # Setting test signals
    set_case_analysis 1 [all_fanin -startpoints_only -to [get_ports pad_r_testp_o]]
    set_case_analysis 1 [all_fanin -startpoints_only -to [get_ports pad_b_testp_o]]
    set_case_analysis 0 [all_fanin -startpoints_only -to [get_ports pad_r_testn_o]]
    set_case_analysis 0 [all_fanin -startpoints_only -to [get_ports pad_b_testn_o]]

    # These are analog pads, get any constraints from them
    set b_analog_refclk_name "b_analog_refclk"
    set b_analog_refclk_period_ns 10.0
    set b_analog_refclk_pins [get_ports REFCLK]
    create_clock -name ${b_analog_refclk_name} -period ${b_analog_refclk_period_ns} ${b_analog_refclk_pins}

    set analog_input_pads [get_ports "SCLK MOSI SSN CHIPEN SPIMUX VSS VDDH VDD RF_RXHB RF_RXLB"]
    set analog_output_pads [get_ports "MISO RF_TXHB RF_TXLB TESTP TESTM MISO_VALID"]
    set_input_delay 0.0 -clock ${b_analog_refclk_name} ${analog_input_pads} -source_latency_included -network_latency_included
    set_output_delay 0.0 -clock ${b_analog_refclk_name} ${analog_output_pads}

    set analog_obj [get_cells black/analog]
    set analog_input_pins [get_pins -of_objects ${analog_obj} -filter "pin_direction==in"]
    set analog_output_pins [get_pins -of_objects ${analog_obj} -filter "pin_direction==out"]
    set_input_delay 0.0 -clock ${b_analog_refclk_name} ${analog_input_pins} -source_latency_included -network_latency_included
    set_output_delay 0.0 -clock ${b_analog_refclk_name} ${analog_output_pins}

    #############################
    ## Clock Pads
    #############################

    set r_clk_output_disable_pin [get_ports "pad_r_clk_output_disable_i"]
    set_case_analysis 0 ${r_clk_output_disable_pin}

    set b_clk_output_disable_pin [get_ports "pad_b_clk_output_disable_i"]
    set_case_analysis 0 ${b_clk_output_disable_pin}

    set r_clk_mon_sel_pins [get_ports "pad_r_clk_mon_sel_*_i"]
    set_case_analysis 0 ${r_clk_mon_sel_pins}

    set b_clk_mon_sel_pins [get_ports "pad_b_clk_mon_sel_*_i"]
    set_case_analysis 0 ${b_clk_mon_sel_pins}

    set r_A_clk_name "r_A_clk"
    set r_A_clk_period_ns 2.0; # 500 MHz
    set r_A_clk_pins [get_ports "pad_r_clk_A_i"]
    set r_A_clk_obj [bsg_backport_clk_create ${r_A_clk_name} ${r_A_clk_period_ns} ${r_A_clk_pins}]

    set r_B_clk_name "r_B_clk"
    set r_B_clk_period_ns 2.0; # 500 MHz
    set r_B_clk_pins [get_ports "pad_r_clk_B_i"]
    set r_B_clk_obj [bsg_backport_clk_create ${r_B_clk_name} ${r_B_clk_period_ns} ${r_B_clk_pins}]

    set r_C_clk_name "r_C_clk"
    set r_C_clk_period_ns 2.0; # 500 MHz 
    set r_C_clk_pins [get_ports "pad_r_clk_C_i"]
    set r_C_clk_obj [bsg_backport_clk_create ${r_C_clk_name} ${r_C_clk_period_ns} ${r_C_clk_pins}]

    #set r_D_clk_name "r_D_clk"
    set r_D_clk_name "r_dmc_pearl_dfi_clk_2x"
    set r_D_clk_period_ns 2.5; # 400 MHz
    set r_D_clk_pins [get_ports "pad_r_clk_D_i"]
    set r_D_clk_obj [bsg_backport_clk_create ${r_D_clk_name} ${r_D_clk_period_ns} ${r_D_clk_pins}]
    # Mirror D clk as dfi_2x_clk
    #set r_dfi_clk_2x_name "r_dmc_pearl_dfi_clk_2x"
    #set r_dfi_clk_2x_ratio 1
    #create_generated_clock \
    #    -name ${r_dfi_clk_2x_name} \
    #    -divide_by ${r_dfi_clk_2x_ratio} \
    #    -master_clock [get_clocks ${r_D_clk_name}] \
    #    -source [get_db [get_clocks ${r_D_clk_name}] .sources] \
    #    -add ${r_D_clk_pins}

    set r_rt_clk_name "r_rt_clk"
    set r_rt_clk_period_ns 10.0; # 100 MHz
    set r_rt_clk_pins [get_ports "pad_r_rt_clk_i"]
    set r_rt_clk_obj [bsg_backport_clk_create ${r_rt_clk_name} ${r_rt_clk_period_ns} ${r_rt_clk_pins}]

    set b_A_clk_name "b_A_clk"
    set b_A_clk_period_ns 2.0; # 500 MHz
    set b_A_clk_pins [get_ports "pad_b_clk_A_i"]
    set b_A_clk_obj [bsg_backport_clk_create ${b_A_clk_name} ${b_A_clk_period_ns} ${b_A_clk_pins}]

    set b_B_clk_name "b_B_clk"
    set b_B_clk_period_ns 2.0; # 500 MHz
    set b_B_clk_pins [get_ports "pad_b_clk_B_i"]
    set b_B_clk_obj [bsg_backport_clk_create ${b_B_clk_name} ${b_B_clk_period_ns} ${b_B_clk_pins}]

    set b_C_clk_name "b_C_clk"
    set b_C_clk_period_ns 2.0; # 500 MHz
    set b_C_clk_pins [get_ports "pad_b_clk_C_i"]
    set b_C_clk_obj [bsg_backport_clk_create ${b_C_clk_name} ${b_C_clk_period_ns} ${b_C_clk_pins}]

    #set b_D_clk_name "b_D_clk"
    set b_D_clk_name "b_dmc_pearl_dfi_clk_2x"
    set b_D_clk_period_ns 2.5; # 400 MHz
    set b_D_clk_pins [get_ports "pad_b_clk_D_i"]
    set b_D_clk_obj [bsg_backport_clk_create ${b_D_clk_name} ${b_D_clk_period_ns} ${b_D_clk_pins}]
    # Mirror D clk as dfi_2x_clk
    #set b_dfi_clk_2x_name "b_dmc_pearl_dfi_clk_2x"
    #set b_dfi_clk_2x_ratio 1
    #create_generated_clock \
    #    -name ${b_dfi_clk_2x_name} \
    #    -divide_by ${b_dfi_clk_2x_ratio} \
    #    -master_clock [get_clocks ${b_D_clk_name}] \
    #    -source [get_db [get_clocks ${b_D_clk_name}] .sources] \
    #    -add ${b_D_clk_pins}

    set b_rt_clk_name "b_rt_clk"
    set b_rt_clk_period_ns 10.0; # 100 MHz
    set b_rt_clk_pins [get_ports "pad_b_rt_clk_i"]
    set b_rt_clk_obj [bsg_backport_clk_create ${b_rt_clk_name} ${b_rt_clk_period_ns} ${b_rt_clk_pins}]

    set b_adc_clk_name "b_adc_clk"
    set b_adc_clk_period_ns 0.8
    set b_adc_clk_pins [get_pins black/analog/d_adc_clk]
    set b_adc_clk_obj [bsg_backport_clk_create ${b_adc_clk_name} ${b_adc_clk_period_ns} ${b_adc_clk_pins}]

    # Analog constraints
    # TODO: Check with backend team, should come from .lib
    set b_adc_input_delay_min_ns [expr 0.02 * ${b_adc_clk_period_ns}]
    set b_adc_input_delay_max_ns [expr 0.2 * ${b_adc_clk_period_ns}]
    set b_adc_input_pins [get_pins "black/analog/d_adc_idata black/analog/d_adc_qdata"]
    set_input_delay -min ${b_adc_input_delay_min_ns} -clock ${b_adc_clk_name} ${b_adc_input_pins} -source_latency_included -network_latency_included
    set_input_delay -max ${b_adc_input_delay_max_ns} -clock ${b_adc_clk_name} ${b_adc_input_pins} -source_latency_included -network_latency_included -add_delay
    set b_dac_clk_name "b_dac_clk"
    set b_dac_clk_period_ns [expr 2*${b_adc_clk_period_ns}]
    set b_dac_clk_pins [get_pins black/analog/d_dac_clk]
    set b_dac_clk_obj [bsg_backport_clk_create ${b_dac_clk_name} ${b_dac_clk_period_ns} ${b_dac_clk_pins}]
    #set b_dac_clk_out_pins [get_pins black/analog_subpod/resampler_tile/osdr/s4.BSG_OSDR_CKBUF_BSG_DONT_TOUCH/Z]
    #set b_dac_output_pins [get_pins "black/analog/d_dac_idata* black/analog/d_dac_qdata* black/analog/d_dac_data_valid"]
    #set b_dac_output_delay_min_ns [expr 0.02 * ${b_dac_clk_period_ns}]
    #set b_dac_output_delay_max_ns [expr 0.2 * ${b_dac_clk_period_ns}]
    #set dac_out_clk_name "dac_out_clk"
    #create_generated_clock \
    #    -name ${dac_out_clk_name} \
    #    -divide_by 1 \
    #    -invert \
    #    -master_clock [get_clocks ${b_dac_clk_name}] \
    #    -source [get_db [get_clocks ${b_dac_clk_name}] .sources] \
    #    -add ${b_dac_clk_out_pins}

    # TODO: Don't hardcode
    set b_dac_osdr_clk_reg [get_cells black/analog_subpod/resampler_tile/osdr/BSG_OSDR_DFFPOS_BSG_DONT_TOUCH]
    set b_dac_osdr_clk_pin [get_pins -of_objects ${b_dac_osdr_clk_reg} -filter "direction==out"]
    set b_dac_clk_ports [get_pins "black/analog/d_clk_in_soc"]
    set b_dac_dv_ports [get_pins "black/analog/d_dac_*data*"]
    set b_dac_setup_margin_ns 0.100
    set b_dac_hold_margin_ns 0.100
    foreach_in_collection port ${b_dac_dv_ports} {
        set_data_check -rise_from ${b_dac_clk_ports} -to ${port} -setup ${b_dac_setup_margin_ns}
        set_data_check -rise_from ${b_dac_clk_ports} -to ${port} -hold  ${b_dac_hold_margin_ns}
        
        set_multicycle_path -end   -setup 1 -to ${port}
        set_multicycle_path -start -hold  0 -to ${port}
    }
    set_disable_timing ${b_dac_osdr_clk_pin}

    #set_output_delay -min ${b_dac_output_delay_min_ns} -clock ${b_dac_clk_name} ${b_dac_output_pins} 
    #set_output_delay -max ${b_dac_output_delay_min_ns} -clock ${b_dac_clk_name} ${b_dac_output_pins} -add_delay

    set b_spi_clk_name "b_spi_clk"
    set b_spi_clk_period_ns 10.000
    set b_spi_xcvr_base black/analog_subpod/spi_tile/xcvr_spi_inst_spi_master_inst
    set b_spi_clk_pins [get_pins -of_objects [get_cells ${b_spi_xcvr_base}/sck_l_reg] -filter "pin_direction==out"]
    set b_spi_clk_obj [bsg_backport_clk_create ${b_spi_clk_name} ${b_spi_clk_period_ns} ${b_spi_clk_pins}]
    set b_spi_output_pins [get_pins "black/analog/d_mosi black/analog/d_ssn black/analog/d_chipen"]
    set b_spi_input_pins [get_pins "black/analog/d_miso"]
    set b_spi_input_delay_min_ns [expr 0.02 * ${b_spi_clk_period_ns}]
    set b_spi_input_delay_max_ns [expr 0.2 * ${b_spi_clk_period_ns}]
    set b_spi_output_delay_min_ns [expr 0.02 * ${b_spi_clk_period_ns}]
    set b_spi_output_delay_max_ns [expr 0.2 * ${b_spi_clk_period_ns}]
    set_output_delay -min ${b_spi_output_delay_min_ns} -clock ${b_spi_clk_name} ${b_spi_output_pins} 
    set_output_delay -max ${b_spi_output_delay_min_ns} -clock ${b_spi_clk_name} ${b_spi_output_pins} -add_delay
    set_input_delay -min ${b_spi_input_delay_min_ns} -clock ${b_spi_clk_name} ${b_spi_input_pins} -source_latency_included -network_latency_included
    set_input_delay -max ${b_spi_input_delay_max_ns} -clock ${b_spi_clk_name} ${b_spi_input_pins} -source_latency_included -network_latency_included -add_delay
    # TODO: generated SPI clock?

    set b_rx_resampler_base black/analog_subpod/resampler_tile/resampler_inst
    set b_rx_downsampler_base ${b_rx_resampler_base}/rx_clk_downsample_192m_inst_g_bsg_balanced.clk_downsample_inst
    set b_rx_downsampler_reg ${b_rx_downsampler_base}/d/macro.d[0].d_BSG_DONT_TOUCH
    set b_rx_sample_clk_name "b_rx_sample_clk"
    set b_rx_sample_ratio 6
    set b_rx_sample_pins [get_pins -of_objects [get_cells ${b_rx_downsampler_reg}] -filter "pin_direction==out"]
    create_generated_clock \
        -name ${b_rx_sample_clk_name} \
        -divide_by ${b_rx_sample_ratio} \
        -master_clock ${b_adc_clk_obj} \
        -source [get_db ${b_adc_clk_obj} .sources] \
        -add ${b_rx_sample_pins}

    set b_tx_resampler_base black/analog_subpod/resampler_tile/resampler_inst
    set b_tx_downsampler_reg ${b_tx_resampler_base}/tx_clk_downsample_192m_inst_g_rtl.clk_downsample_inst_clk_internal_reg
    set b_tx_sample_clk_name "b_tx_sample_clk"
    set b_tx_sample_edges {1 5 7}
    # TODO: Should harden
    set b_tx_sample_pins [get_pins -of_objects [get_cells ${b_tx_downsampler_reg}] -filter "pin_direction==out"]
    create_generated_clock \
        -name ${b_tx_sample_clk_name} \
        -edges ${b_tx_sample_edges} \
        -master_clock ${b_dac_clk_obj} \
        -source [get_db ${b_dac_clk_obj} .sources] \
        -add ${b_tx_sample_pins}

    #############################
    ## Tag
    #############################

    set b_tag_bus [dict create]
    dict set b_tag_bus base "b_tag_"
    dict set b_tag_bus clk_pins [get_ports "pad_b_tag_clk_i"]
    dict set b_tag_bus input_pins [get_ports "pad_b_tag_en_i pad_b_tag_data_i"]
    dict set b_tag_bus output_pins [get_ports "pad_b_tag_data_o"]
    bsg_backport_tag_bus_create ${b_tag_bus}

    set r_tag_bus [dict create]
    dict set r_tag_bus base "r_tag_"
    dict set r_tag_bus clk_pins [get_ports "pad_r_tag_clk_i"]
    dict set r_tag_bus input_pins [get_ports "pad_r_tag_en_i pad_r_tag_data_i"]
    dict set r_tag_bus output_pins [get_ports "pad_r_tag_data_o"]
    bsg_backport_tag_bus_create ${r_tag_bus}

    #############################
    ## Subpod links
    #############################

    set inst [get_cells black/analog_subpod/subpod_link]
    set analog_subpod_link [dict create]
    dict set analog_subpod_link base "analog_subpod_"
    dict set analog_subpod_link inst ${inst}
    dict set analog_subpod_link period_ns 1.6
    set analog_subpod_link [bsg_backport_subpod_link_create ${analog_subpod_link}]

    # These are totally asynchronous in reality
    set b_gpio_pins [get_ports "pad_b_gpio_*_io"]
    set master_clk [dict get ${analog_subpod_link} clk_gen_pearl oclk]
    set_max_delay  10.0 -from ${master_clk} -to ${b_gpio_pins}
    set_min_delay -10.0 -from ${master_clk} -to ${b_gpio_pins}
    set_max_delay  10.0 -to ${master_clk} -from ${b_gpio_pins}
    set_min_delay -10.0 -to ${master_clk} -from ${b_gpio_pins}

    set inst [get_cells black/bp[0].blackparrot_subpod/subpod_link]
    set bp0_subpod_link [dict create]
    dict set bp0_subpod_link base "bp0_subpod_"
    dict set bp0_subpod_link inst ${inst}
    dict set bp0_subpod_link period_ns 1.6
    set bp0_subpod_link [bsg_backport_subpod_link_create ${bp0_subpod_link}]

    set inst [get_cells black/bp[1].blackparrot_subpod/subpod_link]
    set bp1_subpod_link [dict create]
    dict set bp1_subpod_link base "bp1_subpod_"
    dict set bp1_subpod_link inst ${inst}
    dict set bp1_subpod_link period_ns 1.6
    set bp1_subpod_link [bsg_backport_subpod_link_create ${bp1_subpod_link}]

    set inst [get_cells black/host_subpod/subpod_link]
    set host_subpod_link [dict create]
    dict set host_subpod_link base "host_subpod_"
    dict set host_subpod_link inst ${inst}
    dict set host_subpod_link period_ns 1.25
    set host_subpod_link [bsg_backport_subpod_link_create ${host_subpod_link}]

    set inst [get_cells black/ldpc_subpod/subpod_link]
    set ldpc_subpod_link [dict create]
    dict set ldpc_subpod_link base "ldpc_subpod_"
    dict set ldpc_subpod_link inst ${inst}
    dict set ldpc_subpod_link period_ns 1.6
    set ldpc_subpod_link [bsg_backport_subpod_link_create ${ldpc_subpod_link}]

    #############################
    ## Pod links
    #############################

    set inst [get_cells black/host_subpod/pod_link]
    set host_pod_link [dict create]
    dict set host_pod_link base "host_pod_"
    dict set host_pod_link inst ${inst}
    dict set host_pod_link period_ns 1.25
    set host_pod_link [bsg_backport_pod_link_create ${host_pod_link}]

    set inst [get_cells black/chip_guts/pod_link]
    set b_guts_pod_link [dict create]
    dict set b_guts_pod_link base "b_guts_pod_"
    dict set b_guts_pod_link inst ${inst}
    dict set b_guts_pod_link period_ns 1.25
    set b_guts_pod_link [bsg_backport_pod_link_create ${b_guts_pod_link}]

    set inst [get_cells red/chip_guts/pod_link]
    set r_guts_pod_link [dict create]
    dict set r_guts_pod_link base "r_guts_pod_"
    dict set r_guts_pod_link inst ${inst}
    dict set r_guts_pod_link period_ns 1.25
    set r_guts_pod_link [bsg_backport_pod_link_create ${r_guts_pod_link}]

    set inst [get_cells red/redparrot/pod_link]
    set redparrot_pod_link [dict create]
    dict set redparrot_pod_link base "redparrot_pod_"
    dict set redparrot_pod_link inst ${inst}
    dict set redparrot_pod_link period_ns 1.6
    set redparrot_pod_link [bsg_backport_pod_link_create ${redparrot_pod_link}]

    set inst [get_cells black/manycore_pod]
    set manycore_pod_link [dict create]
    dict set manycore_pod_link base "manycore_pod_"
    dict set manycore_pod_link inst ${inst}
    dict set manycore_pod_link period_ns 1.15; # 1.25 - 0.100
    set manycore_pod_link [bsg_backport_manycore_pod_create ${manycore_pod_link}]

    #############################
    ## DDR Links
    #############################
    # TODO: encompass in chip_guts constraint
    set b_ddr_link_pearl [dict create]
    set b_ddr_link_pearl_base "b_ddr_link_pearl_"
    set b_ddr_link_pearl_inst [get_cells black/chip_guts/ddr_link]

    dict set b_ddr_link_pearl base ${b_ddr_link_pearl_base}
    dict set b_ddr_link_pearl inst ${b_ddr_link_pearl_inst}
    dict set b_ddr_link_pearl master_clk [dict get ${b_guts_pod_link} clk_gen_pearl oclk]
    set b_ddr_link_pearl [bsg_backport_ddr_link_pearl_create ${b_ddr_link_pearl}]

    set r_ddr_link_pearl [dict create]
    set r_ddr_link_pearl_base "r_ddr_link_pearl_"
    set r_ddr_link_pearl_inst [get_cells red/chip_guts/ddr_link]

    dict set r_ddr_link_pearl base ${r_ddr_link_pearl_base}
    dict set r_ddr_link_pearl inst ${r_ddr_link_pearl_inst}
    dict set r_ddr_link_pearl master_clk [dict get ${r_guts_pod_link} clk_gen_pearl oclk]
    set r_ddr_link_pearl [bsg_backport_ddr_link_pearl_create ${r_ddr_link_pearl}]

    #############################
    ## DMC Links
    #############################

    # Black DMC interface
    array set b_ddr_intf {}
    bsg_backport_ddr_intf_create b_ddr_intf pad_b_ddr_

    set b_dmc_pearl [dict create]
    set b_dmc_pearl_base "b_dmc_pearl_"
    set b_dmc_pearl_inst [get_cells black/chip_guts/io_complex/dmc_pearl]
    dict set b_dmc_pearl ui_clk [dict get ${b_guts_pod_link} clk_gen_pearl oclk]
    dict set b_dmc_pearl dfi_clk_2x ${b_D_clk_obj}
    dict set b_dmc_pearl ddr_intf [array get b_ddr_intf]

    dict set b_dmc_pearl base ${b_dmc_pearl_base}
    dict set b_dmc_pearl inst ${b_dmc_pearl_inst}
    set b_dmc_pearl [bsg_backport_dmc_pearl_create ${b_dmc_pearl}]
    
    # Red DMC interface
    array set r_ddr_intf {}
    bsg_backport_ddr_intf_create r_ddr_intf pad_r_ddr_

    set r_dmc_pearl [dict create]
    set r_dmc_pearl_base "r_dmc_pearl_"
    set r_dmc_pearl_inst [get_cells red/chip_guts/io_complex/dmc_pearl]
    dict set r_dmc_pearl ui_clk [dict get ${r_guts_pod_link} clk_gen_pearl oclk]
    dict set r_dmc_pearl dfi_clk_2x ${r_D_clk_obj}
    dict set r_dmc_pearl ddr_intf [array get r_ddr_intf]

    dict set r_dmc_pearl base ${r_dmc_pearl_base}
    dict set r_dmc_pearl inst ${r_dmc_pearl_inst}
    set r_dmc_pearl [bsg_backport_dmc_pearl_create ${r_dmc_pearl}]

    # Multicycle constraints
    set ruche_tiles [get_cells -hier -filter {ref_name=~bsg_manycore_tile_compute_ruche_*}]
    set ruche_cord_reg [get_db ${ruche_tiles} .hinsts -regexp ".*dff_(x|y)"]
    set ruche_cord_inst [get_db ${ruche_cord_reg} .insts]

    set vcache_tiles [get_cells -hier -filter {ref_name=~bsg_manycore_tile_vcache_*}]
    set vcache_cord_reg [get_db ${vcache_tiles} .hinsts -regexp ".*(x|y)_dff"]
    set vcache_cord_inst [get_db ${vcache_cord_reg} .insts]

    set podrow [get_cells -hier -filter {ref_name=~bsg_manycore_pod_row_sdr_*}]
    set podrow_cord_reg [get_db ${podrow} .hinsts -regexp ".*dff_global_(x|y)"]
    set podrow_cord_inst [get_db ${podrow_cord_reg} .insts]

    set multicycle_cells {}
    append_to_collection multicycle_cells [get_cells ${ruche_cord_inst}]
    append_to_collection multicycle_cells [get_cells ${vcache_cord_inst}]
    append_to_collection multicycle_cells [get_cells ${podrow_cord_inst}]

    set_multicycle_path 2 -setup -to   ${multicycle_cells}
    set_multicycle_path 1 -hold  -to   ${multicycle_cells}
    set_multicycle_path 2 -setup -from ${multicycle_cells}
    set_multicycle_path 1 -hold  -from ${multicycle_cells}

    # False path
    set dly_lines [get_cells -hier -filter {ref_name==bsg_dmc_dly_line_v3_p64}]
    set meta_inst [get_db ${dly_lines} .insts -regexp ".*meta_r"]
    set_false_path -to ${meta_inst}
    set cg_inst [get_db ${dly_lines} .insts -regexp ".*CG0"]
    set cg_en_pins [get_pins -of_objects ${cg_inst} -filter "name==E"]
    set_case_analysis 1 ${cg_en_pins}

    # Relax timing on async tag clients
    set tag_unsync_inst [get_cells -hier -filter "ref_name=~*bsg_tag_client_unsync*"]
    set tag_unsync_reg [get_db ${tag_unsync_inst} .insts -regexp ".*macro.*.d_BSG_DONT_TOUCH"]
    set tag_unsync_pins [get_pins -of_objects ${tag_unsync_reg} -filter "direction==out"]
    set_max_delay  10.0 -from ${tag_unsync_pins}
    set_min_delay -10.0 -from ${tag_unsync_pins}

    set vclk [get_clocks -nocase -regexp {(vclk|b_analog_refclk)}]
    set pad_clks [get_clocks -nocase -regexp {.*([ABCD]|rt)_clk}]
    set tag_clks [get_clocks -nocase -regexp {.*tag_clk}]
    set core_clks [get_clocks -nocase -regexp {.*clk_gen_pearl_clk}]
    set osc_clks [get_clocks -nocase -regexp {.*clk_gen_pearl_oclk}]
    set mon_clks [get_clocks -nocase -regexp {.*clk_gen_pearl_mclk}]
    set sdr_link_clks [get_clocks -nocase -regexp {.*sdr.*_[io]link_clk}]
    set sdr_link_tkns [get_clocks -nocase -regexp {.*sdr.*_[io]link_tkn}]
    set ddr_link_clks [get_clocks -nocase -regexp {.*ddr.*_[io]link_clk}]
    set ddr_link_tkns [get_clocks -nocase -regexp {.*ddr.*_[io]link_tkn}]
    set dmc_phy_clks [get_clocks -nocase -regexp {.*dmc_pearl_(dqs|dfi|ck).*}]
    set xcvr_clks [get_clocks -nocase -regexp {(.*sample_clk.*|.*spi_clk.*|.*adc_clk.*|.*dac_clk.*)}]

    set clks [all_clocks]
    set clks [remove_from_collection ${clks} ${vclk}]
    set clks [remove_from_collection ${clks} ${pad_clks}]
    set clks [remove_from_collection ${clks} ${tag_clks}]
    set clks [remove_from_collection ${clks} ${core_clks}]
    set clks [remove_from_collection ${clks} ${osc_clks}]
    set clks [remove_from_collection ${clks} ${mon_clks}]
    set clks [remove_from_collection ${clks} ${sdr_link_clks}]
    set clks [remove_from_collection ${clks} ${sdr_link_tkns}]
    set clks [remove_from_collection ${clks} ${ddr_link_clks}]
    set clks [remove_from_collection ${clks} ${ddr_link_tkns}]
    set clks [remove_from_collection ${clks} ${dmc_phy_clks}]
    set clks [remove_from_collection ${clks} ${xcvr_clks}]

    set all_misc_clks {}
    append_to_collection all_misc_clks ${tag_clks}
    append_to_collection all_misc_clks ${pad_clks}
    append_to_collection all_misc_clks ${core_clks}
    append_to_collection all_misc_clks ${osc_clks}
    append_to_collection all_misc_clks ${mon_clks}
    bsg_backport_async_icl ${all_misc_clks}

    set all_sdr_clks {}
    append_to_collection all_sdr_clks ${tag_clks}
    append_to_collection all_sdr_clks ${core_clks}
    append_to_collection all_sdr_clks ${sdr_link_clks}
    append_to_collection all_sdr_clks ${sdr_link_tkns}
    bsg_backport_async_icl ${all_sdr_clks}

    set all_ddr_clks {}
    append_to_collection all_ddr_clks ${tag_clks}
    append_to_collection all_ddr_clks ${core_clks}
    append_to_collection all_ddr_clks ${ddr_link_clks}
    append_to_collection all_ddr_clks ${ddr_link_tkns}
    bsg_backport_async_icl ${all_ddr_clks}

    set all_analog_clks {}
    append_to_collection all_analog_clks ${tag_clks}
    append_to_collection all_analog_clks ${core_clks}
    append_to_collection all_analog_clks ${xcvr_clks}
    bsg_backport_async_icl ${all_analog_clks}

    set all_dmc_clks {}
    append_to_collection all_dmc_clks ${tag_clks}
    append_to_collection all_dmc_clks ${core_clks}
    append_to_collection all_dmc_clks ${dmc_phy_clks}
    bsg_backport_async_icl ${all_dmc_clks}

    puts "Relaxing timing on dmc clocks"
    bsg_backport_clock_discount ${dmc_phy_clks}

    set master_clk [get_clocks r_*dmc_pearl*dfi_clk_1x]
    set_max_delay  10.0 -from ${master_clk} -to [get_ports pad_r_ddr_*_io] -ignore_clock_latency
    set_min_delay -10.0 -from ${master_clk} -to [get_ports pad_r_ddr_*_io] -ignore_clock_latency
    set_max_delay  10.0 -to ${master_clk} -from [get_ports pad_r_ddr_*_io] -ignore_clock_latency
    set_min_delay -10.0 -to ${master_clk} -from [get_ports pad_r_ddr_*_io] -ignore_clock_latency

    set master_clk [get_clocks b_*dmc_pearl*dfi_clk_1x]
    set_max_delay  10.0 -from ${master_clk} -to [get_ports pad_b_ddr_*_io] -ignore_clock_latency
    set_min_delay -10.0 -from ${master_clk} -to [get_ports pad_b_ddr_*_io] -ignore_clock_latency
    set_max_delay  10.0 -to ${master_clk} -from [get_ports pad_b_ddr_*_io] -ignore_clock_latency
    set_min_delay -10.0 -to ${master_clk} -from [get_ports pad_b_ddr_*_io] -ignore_clock_latency

    set_false_path -to [get_ports pad_*_ddr_init_o]
    set_false_path -to [get_ports pad_*_ddr_trans_o]
    set_false_path -to [get_ports pad_*_ddr_stall_o]
    set_false_path -to [get_ports pad_*_ddr_test_o]
    set_false_path -to [get_ports pad_*_ddr_refresh_o]

    set_false_path -hold -to [get_ports pad_*_ddr_dqs_io]

    # Set clock attributes
    set uncertainty_ns 0.020
    set_clock_uncertainty ${uncertainty_ns} [all_clocks]
    set_propagated_clock [all_clocks]
}

