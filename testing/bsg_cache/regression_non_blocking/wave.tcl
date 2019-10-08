# Begin_DVE_Session_Save_Info
# DVE view(Wave.1 ) session
# Saved on Mon Oct 7 13:16:09 2019
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Wave.1: 53 signals
# End_DVE_Session_Save_Info

# DVE version: L-2016.06-SP2-15_Full64
# DVE build date: Mar 11 2018 22:07:39


#<Session mode="View" path="/mnt/users/ssd1/homes/dcjung/bsg/basejump_stl/testing/bsg_cache/regression_non_blocking/wave.tcl" type="Debug">

#<Database>

gui_set_time_units 1ps
#</Database>

# DVE View/pane content session: 

# Begin_DVE_Session_Save_Info (Wave.1)
# DVE wave signals session
# Saved on Mon Oct 7 13:16:09 2019
# 53 signals
# End_DVE_Session_Save_Info

# DVE version: L-2016.06-SP2-15_Full64
# DVE build date: Mar 11 2018 22:07:39


#Add ncecessay scopes
gui_load_child_values {testbench.DUT}
gui_load_child_values {testbench.DUT.tl0}
gui_load_child_values {testbench.DUT.dma0}
gui_load_child_values {testbench.DUT.data_mem0}

gui_set_time_units 1ps

set _wave_session_group_19 input
if {[gui_sg_is_group -name "$_wave_session_group_19"]} {
    set _wave_session_group_19 [gui_sg_generate_new_name]
}
set Group1 "$_wave_session_group_19"

gui_sg_addsignal -group "$_wave_session_group_19" { {V1:testbench.DUT.clk_i} {V1:testbench.DUT.reset_i} {V1:testbench.DUT.v_i} {V1:testbench.DUT.cache_pkt} {V1:testbench.DUT.ready_o} }

set _wave_session_group_20 data_mem
if {[gui_sg_is_group -name "$_wave_session_group_20"]} {
    set _wave_session_group_20 [gui_sg_generate_new_name]
}
set Group2 "$_wave_session_group_20"

gui_sg_addsignal -group "$_wave_session_group_20" { {V1:testbench.DUT.data_mem0.v_i} {V1:testbench.DUT.data_mem0.data_o} {V1:testbench.DUT.data_mem0.data_mem_pkt.sigext_op} {V1:testbench.DUT.data_mem0.data_mem_pkt} }

set _wave_session_group_21 miss_FIFO
if {[gui_sg_is_group -name "$_wave_session_group_21"]} {
    set _wave_session_group_21 [gui_sg_generate_new_name]
}
set Group3 "$_wave_session_group_21"

gui_sg_addsignal -group "$_wave_session_group_21" { {V1:testbench.DUT.miss_fifo0.v_i} {V1:testbench.DUT.miss_fifo0.ready_o} {V1:testbench.DUT.miss_fifo0.read_inc} {V1:testbench.DUT.miss_fifo0.read_ptr} {V1:testbench.DUT.miss_fifo0.write_inc} {V1:testbench.DUT.miss_fifo0.write_ptr} {V1:testbench.DUT.miss_fifo0.cp_inc} {V1:testbench.DUT.miss_fifo0.cp_ptr} {V1:testbench.DUT.miss_fifo0.enque} {V1:testbench.DUT.miss_fifo0.inval} {V1:testbench.DUT.miss_fifo0.full} {V1:testbench.DUT.miss_fifo0.empty_o} {V1:testbench.DUT.miss_fifo0.v_o} {V1:testbench.DUT.miss_fifo0.valid_r} }
gui_set_radix -radix {decimal} -signals {V1:testbench.DUT.miss_fifo0.read_ptr}
gui_set_radix -radix {unsigned} -signals {V1:testbench.DUT.miss_fifo0.read_ptr}
gui_set_radix -radix {decimal} -signals {V1:testbench.DUT.miss_fifo0.write_ptr}
gui_set_radix -radix {unsigned} -signals {V1:testbench.DUT.miss_fifo0.write_ptr}
gui_set_radix -radix {decimal} -signals {V1:testbench.DUT.miss_fifo0.cp_ptr}
gui_set_radix -radix {unsigned} -signals {V1:testbench.DUT.miss_fifo0.cp_ptr}

set _wave_session_group_22 mhu
if {[gui_sg_is_group -name "$_wave_session_group_22"]} {
    set _wave_session_group_22 [gui_sg_generate_new_name]
}
set Group4 "$_wave_session_group_22"

gui_sg_addsignal -group "$_wave_session_group_22" { {V1:testbench.DUT.mhu0.data_mem_pkt_v_o} {V1:testbench.DUT.mhu0.data_mem_pkt} {V1:testbench.DUT.mhu0.miss_fifo_entry} {V1:testbench.DUT.mhu0.miss_fifo_empty_i} {V1:testbench.DUT.mhu0.is_secondary} {V1:testbench.DUT.mhu0.miss_fifo_yumi_o} {V1:testbench.DUT.mhu0.miss_fifo_yumi_op_o} {V1:testbench.DUT.mhu0.miss_fifo_scan_not_dq_o} {V1:testbench.DUT.mhu0.miss_fifo_rollback_o} {V1:testbench.DUT.mhu0.mhu_state_r} {V1:testbench.DUT.mhu0.dma_pending_i} {V1:testbench.DUT.mhu0.dma_done_i} {V1:testbench.DUT.mhu0.curr_dma_cmd_r} }

set _wave_session_group_23 TL
if {[gui_sg_is_group -name "$_wave_session_group_23"]} {
    set _wave_session_group_23 [gui_sg_generate_new_name]
}
set Group5 "$_wave_session_group_23"

gui_sg_addsignal -group "$_wave_session_group_23" { {V1:testbench.DUT.tl0.v_tl_r} {V1:testbench.DUT.tl0.id_tl_r} {V1:testbench.DUT.tl0.addr_tl_r} {V1:testbench.DUT.tl0.data_tl_r} {V1:testbench.DUT.tl0.tag_hit_way} {V1:testbench.DUT.tl0.tag_hit_found} {V1:testbench.DUT.tl0.miss_fifo_v_o} {V1:testbench.DUT.tl0.miss_fifo_entry} {V1:testbench.DUT.tl0.miss_fifo_ready_i} }

set _wave_session_group_24 DMA
if {[gui_sg_is_group -name "$_wave_session_group_24"]} {
    set _wave_session_group_24 [gui_sg_generate_new_name]
}
set Group6 "$_wave_session_group_24"

gui_sg_addsignal -group "$_wave_session_group_24" { {V1:testbench.DUT.dma0.dma_cmd_v_i} {V1:testbench.DUT.dma0.dma_cmd_r} {V1:testbench.DUT.dma0.dma_state_r} {V1:testbench.DUT.dma0.data_mem_pkt_v_o} {V1:testbench.DUT.dma0.data_mem_pkt} }

set _wave_session_group_25 output
if {[gui_sg_is_group -name "$_wave_session_group_25"]} {
    set _wave_session_group_25 [gui_sg_generate_new_name]
}
set Group7 "$_wave_session_group_25"

gui_sg_addsignal -group "$_wave_session_group_25" { {V1:testbench.DUT.v_o} {V1:testbench.DUT.id_o} {V1:testbench.DUT.data_o} }
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
gui_wv_zoom_timerange -id ${Wave.1} 109660 112277
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group1}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group2}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group3}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group4}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group5}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group6}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group7}]
gui_list_collapse -id ${Wave.1} ${Group2}
gui_list_collapse -id ${Wave.1} ${Group5}
gui_list_collapse -id ${Wave.1} ${Group6}
gui_list_collapse -id ${Wave.1} ${Group7}
gui_list_expand -id ${Wave.1} testbench.DUT.cache_pkt
gui_list_select -id ${Wave.1} {testbench.DUT.clk_i testbench.DUT.reset_i testbench.DUT.v_i testbench.DUT.cache_pkt testbench.DUT.ready_o testbench.DUT.miss_fifo0.v_i testbench.DUT.miss_fifo0.ready_o testbench.DUT.miss_fifo0.read_inc testbench.DUT.miss_fifo0.read_ptr testbench.DUT.miss_fifo0.write_inc testbench.DUT.miss_fifo0.write_ptr testbench.DUT.miss_fifo0.cp_inc testbench.DUT.miss_fifo0.cp_ptr testbench.DUT.miss_fifo0.enque testbench.DUT.miss_fifo0.inval testbench.DUT.miss_fifo0.full testbench.DUT.miss_fifo0.empty_o testbench.DUT.miss_fifo0.v_o testbench.DUT.miss_fifo0.valid_r testbench.DUT.mhu0.data_mem_pkt_v_o testbench.DUT.mhu0.data_mem_pkt testbench.DUT.mhu0.miss_fifo_entry testbench.DUT.mhu0.miss_fifo_empty_i testbench.DUT.mhu0.is_secondary testbench.DUT.mhu0.miss_fifo_yumi_o testbench.DUT.mhu0.miss_fifo_yumi_op_o testbench.DUT.mhu0.miss_fifo_scan_not_dq_o testbench.DUT.mhu0.miss_fifo_rollback_o testbench.DUT.mhu0.mhu_state_r testbench.DUT.mhu0.dma_pending_i testbench.DUT.mhu0.dma_done_i testbench.DUT.mhu0.curr_dma_cmd_r }
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
gui_list_set_insertion_bar  -id ${Wave.1} -group ${Group4}  -item testbench.DUT.mhu0.curr_dma_cmd_r -position below

gui_marker_move -id ${Wave.1} {C1} 110492
gui_view_scroll -id ${Wave.1} -vertical -set 0
gui_show_grid -id ${Wave.1} -enable false
#</Session>

