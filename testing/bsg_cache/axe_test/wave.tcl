
gui_set_time_units 1ps

gui_load_child_values {testbench.cache.miss}
gui_load_child_values {testbench.cache.data_mem}

gui_set_time_units 1ps

set _wave_session_group_9 input
if {[gui_sg_is_group -name "$_wave_session_group_9"]} {
    set _wave_session_group_9 [gui_sg_generate_new_name]
}
set Group1 "$_wave_session_group_9"

gui_sg_addsignal -group "$_wave_session_group_9" { {V1:testbench.cache.clk_i} {V1:testbench.cache.reset_i} {V1:testbench.cache.v_i} {V1:testbench.cache.ready_o} {V1:testbench.cache.cache_pkt.opcode} {V1:testbench.cache.cache_pkt.addr} {V1:testbench.cache.cache_pkt.data} }

set _wave_session_group_10 {tl stage}
if {[gui_sg_is_group -name "$_wave_session_group_10"]} {
    set _wave_session_group_10 [gui_sg_generate_new_name]
}
set Group2 "$_wave_session_group_10"

gui_sg_addsignal -group "$_wave_session_group_10" { {V1:testbench.cache.v_tl_r} {V1:testbench.cache.addr_tl_r} }

set _wave_session_group_11 v_stage
if {[gui_sg_is_group -name "$_wave_session_group_11"]} {
    set _wave_session_group_11 [gui_sg_generate_new_name]
}
set Group3 "$_wave_session_group_11"

gui_sg_addsignal -group "$_wave_session_group_11" { {V1:testbench.cache.v_v_r} {V1:testbench.cache.miss_v} {V1:testbench.cache.addr_v_r} {V1:testbench.cache.ld_data_v_r} {V1:testbench.cache.ld_op_v_r} {V1:testbench.cache.st_op_v_r} {V1:testbench.cache.tag_hit_v} }

set _wave_session_group_12 output
if {[gui_sg_is_group -name "$_wave_session_group_12"]} {
    set _wave_session_group_12 [gui_sg_generate_new_name]
}
set Group4 "$_wave_session_group_12"

gui_sg_addsignal -group "$_wave_session_group_12" { {V1:testbench.cache.data_o} {V1:testbench.cache.v_o} {V1:testbench.cache.yumi_i} }

set _wave_session_group_13 miss
if {[gui_sg_is_group -name "$_wave_session_group_13"]} {
    set _wave_session_group_13 [gui_sg_generate_new_name]
}
set Group5 "$_wave_session_group_13"

gui_sg_addsignal -group "$_wave_session_group_13" { {V1:testbench.cache.recover_lo} {V1:testbench.cache.miss.miss_state_r} {V1:testbench.cache.miss_tag_mem_v_lo} {V1:testbench.cache.miss_tag_mem_w_lo} }

set _wave_session_group_14 data_mem
if {[gui_sg_is_group -name "$_wave_session_group_14"]} {
    set _wave_session_group_14 [gui_sg_generate_new_name]
}
set Group6 "$_wave_session_group_14"

gui_sg_addsignal -group "$_wave_session_group_14" { {V1:testbench.cache.data_mem.v_i} {V1:testbench.cache.data_mem.w_i} {V1:testbench.cache.data_mem.addr_i} {V1:testbench.cache.data_mem.data_i} {V1:testbench.cache.data_mem.write_mask_i} {V1:testbench.cache.data_mem.data_o} }

set _wave_session_group_15 tag_mem
if {[gui_sg_is_group -name "$_wave_session_group_15"]} {
    set _wave_session_group_15 [gui_sg_generate_new_name]
}
set Group7 "$_wave_session_group_15"

gui_sg_addsignal -group "$_wave_session_group_15" { {V1:testbench.cache.tag_mem_addr_li} {V1:testbench.cache.tag_mem_data_li} {V1:testbench.cache.tag_mem_data_lo} {V1:testbench.cache.tag_mem_v_li} {V1:testbench.cache.tag_mem_w_li} }

set _wave_session_group_16 sbuf
if {[gui_sg_is_group -name "$_wave_session_group_16"]} {
    set _wave_session_group_16 [gui_sg_generate_new_name]
}
set Group8 "$_wave_session_group_16"

gui_sg_addsignal -group "$_wave_session_group_16" { {V1:testbench.cache.sbuf_v_lo} {V1:testbench.cache.sbuf_yumi_li} {V1:testbench.cache.sbuf_data_lo} {V1:testbench.cache.sbuf_addr_lo} {V1:testbench.cache.sbuf_set_lo} }

set _wave_session_group_17 Group2
if {[gui_sg_is_group -name "$_wave_session_group_17"]} {
    set _wave_session_group_17 [gui_sg_generate_new_name]
}
set Group9 "$_wave_session_group_17"

gui_sg_addsignal -group "$_wave_session_group_17" { } 
if {![info exists useOldWindow]} { 
	set useOldWindow true
}
if {$useOldWindow && [string first "Wave" [gui_get_current_window -view]]==0} { 
	set Wave.1 [gui_get_current_window -view] 
} else {
	set Wave.1 [lindex [gui_get_window_ids -type Wave] 0]
if {[string first "Wave" ${Wave.1}]!=0} {
gui_open_window Wave
set Wave.1 [ gui_get_current_window -view ]
}
}

set groupExD [gui_get_pref_value -category Wave -key exclusiveSG]
gui_set_pref_value -category Wave -key exclusiveSG -value {false}
set origWaveHeight [gui_get_pref_value -category Wave -key waveRowHeight]
gui_list_set_height -id Wave -height 25
set origGroupCreationState [gui_list_create_group_when_add -wave]
gui_list_create_group_when_add -wave -disable
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 84667 84713
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group1}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group2}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group3}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group4}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group5}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group6}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group7}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group8}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group9}]
gui_list_select -id ${Wave.1} {testbench.cache.addr_v_r }
gui_seek_criteria -id ${Wave.1} {Any Edge}


gui_set_pref_value -category Wave -key exclusiveSG -value $groupExD
gui_list_set_height -id Wave -height $origWaveHeight
if {$origGroupCreationState} {
	gui_list_create_group_when_add -wave -enable
}
if { $groupExD } {
 gui_msg_report -code DVWW028
}
gui_list_set_filter -id ${Wave.1} -list { {Buffer 1} {Input 1} {Others 1} {Linkage 1} {Output 1} {Parameter 1} {All 1} {Aggregate 1} {LibBaseMember 1} {Event 1} {Assertion 1} {Constant 1} {Interface 1} {BaseMembers 1} {Signal 1} {$unit 1} {Inout 1} {Variable 1} }
gui_list_set_filter -id ${Wave.1} -text {*}
gui_list_set_insertion_bar  -id ${Wave.1} -group ${Group8}  -item testbench.cache.sbuf_set_lo -position below

gui_marker_move -id ${Wave.1} {C1} 84695
gui_view_scroll -id ${Wave.1} -vertical -set 0
gui_show_grid -id ${Wave.1} -enable false
#</Session>

