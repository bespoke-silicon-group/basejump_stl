# Begin_DVE_Session_Save_Info
# DVE view(Wave.1 ) session
# Saved on Tue Oct 8 13:11:23 2019
# Toplevel windows open: 1
# 	TopLevel.2
#   Wave.1: 38 signals
# End_DVE_Session_Save_Info

# DVE version: L-2016.06-SP2-15_Full64
# DVE build date: Mar 11 2018 22:07:39


#<Session mode="View" path="/mnt/users/ssd1/homes/dcjung/bsg/basejump_stl/testing/bsg_cache/regression_non_blocking/replacement_bug.tcl" type="Debug">

#<Database>

gui_set_time_units 1ps
#</Database>

# DVE View/pane content session: 

# Begin_DVE_Session_Save_Info (Wave.1)
# DVE wave signals session
# Saved on Tue Oct 8 13:11:23 2019
# 38 signals
# End_DVE_Session_Save_Info

# DVE version: L-2016.06-SP2-15_Full64
# DVE build date: Mar 11 2018 22:07:39


#Add ncecessay scopes

gui_set_time_units 1ps

set _wave_session_group_1 input
if {[gui_sg_is_group -name "$_wave_session_group_1"]} {
    set _wave_session_group_1 [gui_sg_generate_new_name]
}
set Group1 "$_wave_session_group_1"

gui_sg_addsignal -group "$_wave_session_group_1" { {V1:testbench.DUT.clk_i} {V1:testbench.DUT.reset_i} {V1:testbench.DUT.v_i} {V1:testbench.DUT.cache_pkt} {V1:testbench.DUT.ready_o} }

set _wave_session_group_2 output
if {[gui_sg_is_group -name "$_wave_session_group_2"]} {
    set _wave_session_group_2 [gui_sg_generate_new_name]
}
set Group2 "$_wave_session_group_2"

gui_sg_addsignal -group "$_wave_session_group_2" { {V1:testbench.DUT.v_o} {V1:testbench.DUT.id_o} {V1:testbench.DUT.data_o} }

set _wave_session_group_3 tl_stage
if {[gui_sg_is_group -name "$_wave_session_group_3"]} {
    set _wave_session_group_3 [gui_sg_generate_new_name]
}
set Group3 "$_wave_session_group_3"

gui_sg_addsignal -group "$_wave_session_group_3" { {V1:testbench.DUT.tl0.id_tl_r} {V1:testbench.DUT.tl0.addr_tl_r} {V1:testbench.DUT.tl0.data_tl_r} {V1:testbench.DUT.tl0.miss_tl} {V1:testbench.DUT.tl0.tag_hit_found} {V1:testbench.DUT.tl0.recover_i} {V1:testbench.DUT.tl0.mhu_evict_match} {V1:testbench.DUT.tl0.dma_evict_match} {V1:testbench.DUT.tl0.mhu_tag_mem_pkt_v_i} {V1:testbench.DUT.tl0.tag_mem_pkt} {V1:testbench.DUT.tl0.miss_fifo_v_o} {V1:testbench.DUT.tl0.miss_fifo_ready_i} }

set _wave_session_group_4 MHU
if {[gui_sg_is_group -name "$_wave_session_group_4"]} {
    set _wave_session_group_4 [gui_sg_generate_new_name]
}
set Group4 "$_wave_session_group_4"

gui_sg_addsignal -group "$_wave_session_group_4" { {V1:testbench.DUT.mhu0.mhu_state_r} {V1:testbench.DUT.mhu0.miss_fifo_v_i} {V1:testbench.DUT.mhu0.miss_fifo_entry} {V1:testbench.DUT.mhu0.miss_fifo_yumi_o} {V1:testbench.DUT.mhu0.miss_fifo_yumi_op_o} {V1:testbench.DUT.mhu0.miss_fifo_scan_not_dq_o} {V1:testbench.DUT.mhu0.data_mem_pkt_v_o} {V1:testbench.DUT.mhu0.data_mem_pkt_id_o} {V1:testbench.DUT.mhu0.data_mem_pkt} {V1:testbench.DUT.mhu0.set_dirty_r} }

set _wave_session_group_5 dma_data_out
if {[gui_sg_is_group -name "$_wave_session_group_5"]} {
    set _wave_session_group_5 [gui_sg_generate_new_name]
}
set Group5 "$_wave_session_group_5"

gui_sg_addsignal -group "$_wave_session_group_5" { {V1:testbench.DUT.dma0.dma_data_o} {V1:testbench.DUT.dma0.dma_data_v_o} {V1:testbench.DUT.dma0.dma_data_yumi_i} }

set _wave_session_group_6 dma_data_in
if {[gui_sg_is_group -name "$_wave_session_group_6"]} {
    set _wave_session_group_6 [gui_sg_generate_new_name]
}
set Group6 "$_wave_session_group_6"

gui_sg_addsignal -group "$_wave_session_group_6" { {V1:testbench.DUT.dma0.dma_data_i} {V1:testbench.DUT.dma0.dma_data_v_i} {V1:testbench.DUT.dma0.dma_data_ready_o} }

set _wave_session_group_7 Group8
if {[gui_sg_is_group -name "$_wave_session_group_7"]} {
    set _wave_session_group_7 [gui_sg_generate_new_name]
}
set Group7 "$_wave_session_group_7"

gui_sg_addsignal -group "$_wave_session_group_7" { {V1:testbench.DUT.dma0.dma_cmd_v_i} {V1:testbench.DUT.dma0.dma_cmd_in} }
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
gui_marker_create -id ${Wave.1} M1 1898826100
gui_marker_create -id ${Wave.1} M2 1898310500
gui_marker_create -id ${Wave.1} M3 1898398600
gui_marker_select -id ${Wave.1} {  M2 }
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 1898398271 1898399304
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group1}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group2}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group3}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group4}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group5}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group6}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group7}]
gui_list_collapse -id ${Wave.1} ${Group2}
gui_list_collapse -id ${Wave.1} ${Group3}
gui_list_expand -id ${Wave.1} testbench.DUT.cache_pkt
gui_list_expand -id ${Wave.1} testbench.DUT.mhu0.miss_fifo_entry
gui_list_expand -id ${Wave.1} testbench.DUT.mhu0.data_mem_pkt
gui_list_expand -id ${Wave.1} testbench.DUT.dma0.dma_cmd_in
gui_list_select -id ${Wave.1} {testbench.DUT.dma0.dma_data_o }
gui_seek_criteria -id ${Wave.1} {Value...}


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
gui_list_set_insertion_bar  -id ${Wave.1} -group ${Group4}  -item testbench.DUT.mhu0.set_dirty_r -position below

gui_marker_move -id ${Wave.1} {C1} 1898398795
gui_view_scroll -id ${Wave.1} -vertical -set 72
gui_show_grid -id ${Wave.1} -enable false
#</Session>

