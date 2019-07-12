# Begin_DVE_Session_Save_Info
# DVE view(Wave.1 ) session
# Saved on Fri May 10 12:31:18 2019
# Toplevel windows open: 2
# 	TopLevel.1
# 	TopLevel.2
#   Wave.1: 96 signals
# End_DVE_Session_Save_Info

# DVE version: L-2016.06-SP2-15_Full64
# DVE build date: Mar 11 2018 22:07:39


#<Session mode="View" path="/mnt/bsg/diskbits/dcjung/bsg/basejump_stl/testing/bsg_cache/dmc/wave.tcl" type="Debug">

#<Database>

gui_set_time_units 1ps
#</Database>

# DVE View/pane content session: 

# Begin_DVE_Session_Save_Info (Wave.1)
# DVE wave signals session
# Saved on Fri May 10 12:31:18 2019
# 96 signals
# End_DVE_Session_Save_Info

# DVE version: L-2016.06-SP2-15_Full64
# DVE build date: Mar 11 2018 22:07:39


#Add ncecessay scopes
gui_load_child_values {testbench.test_master.genblk2[3].cache}
gui_load_child_values {testbench.test_master}
gui_load_child_values {testbench.test_master.genblk2[0].cache}
gui_load_child_values {testbench.DUT.rx}
gui_load_child_values {testbench.DUT.tx}
gui_load_child_values {testbench.test_master.genblk2[1].cache}

gui_set_time_units 1ps

set _wave_session_group_1 cache0
if {[gui_sg_is_group -name "$_wave_session_group_1"]} {
    set _wave_session_group_1 [gui_sg_generate_new_name]
}
set Group1 "$_wave_session_group_1"

gui_sg_addsignal -group "$_wave_session_group_1" { {V1:testbench.test_master.genblk2[0].cache.clk_i} {V1:testbench.test_master.genblk2[0].cache.reset_i} {V1:testbench.test_master.genblk2[0].cache.v_i} {V1:testbench.test_master.genblk2[0].cache.cache_pkt} {V1:testbench.test_master.genblk2[0].cache.ready_o} {V1:testbench.test_master.genblk2[0].cache.data_o} {V1:testbench.test_master.genblk2[0].cache.v_o} {V1:testbench.test_master.genblk2[0].cache.addr_v_r} {V1:testbench.test_master.genblk2[0].cache.yumi_i} }

set _wave_session_group_2 cache1
if {[gui_sg_is_group -name "$_wave_session_group_2"]} {
    set _wave_session_group_2 [gui_sg_generate_new_name]
}
set Group2 "$_wave_session_group_2"

gui_sg_addsignal -group "$_wave_session_group_2" { {V1:testbench.test_master.genblk2[1].cache.clk_i} {V1:testbench.test_master.genblk2[1].cache.reset_i} {V1:testbench.test_master.genblk2[1].cache.v_i} {V1:testbench.test_master.genblk2[1].cache.cache_pkt.opcode} {V1:testbench.test_master.genblk2[1].cache.cache_pkt.addr} {V1:testbench.test_master.genblk2[1].cache.cache_pkt.data} {V1:testbench.test_master.genblk2[1].cache.ready_o} {V1:testbench.test_master.genblk2[1].cache.data_o} {V1:testbench.test_master.genblk2[1].cache.v_o} {V1:testbench.test_master.genblk2[1].cache.data_v_r} {V1:testbench.test_master.genblk2[1].cache.addr_v_r} {V1:testbench.test_master.genblk2[1].cache.ld_op_v_r} {V1:testbench.test_master.genblk2[1].cache.st_op_v_r} {V1:testbench.test_master.genblk2[1].cache.miss_v} {V1:testbench.test_master.genblk2[1].cache.yumi_i} }

set _wave_session_group_3 cache2
if {[gui_sg_is_group -name "$_wave_session_group_3"]} {
    set _wave_session_group_3 [gui_sg_generate_new_name]
}
set Group3 "$_wave_session_group_3"

gui_sg_addsignal -group "$_wave_session_group_3" { {V1:testbench.test_master.genblk2[2].cache.clk_i} {V1:testbench.test_master.genblk2[2].cache.reset_i} {V1:testbench.test_master.genblk2[2].cache.v_i} {V1:testbench.test_master.genblk2[2].cache.cache_pkt} {V1:testbench.test_master.genblk2[2].cache.ready_o} {V1:testbench.test_master.genblk2[2].cache.data_o} {V1:testbench.test_master.genblk2[2].cache.v_o} {V1:testbench.test_master.genblk2[2].cache.addr_v_r} {V1:testbench.test_master.genblk2[2].cache.miss_v} {V1:testbench.test_master.genblk2[2].cache.yumi_i} }

set _wave_session_group_4 cache3
if {[gui_sg_is_group -name "$_wave_session_group_4"]} {
    set _wave_session_group_4 [gui_sg_generate_new_name]
}
set Group4 "$_wave_session_group_4"

gui_sg_addsignal -group "$_wave_session_group_4" { {V1:testbench.test_master.genblk2[3].cache.clk_i} {V1:testbench.test_master.genblk2[3].cache.reset_i} {V1:testbench.test_master.genblk2[3].cache.v_i} {V1:testbench.test_master.genblk2[3].cache.cache_pkt} {V1:testbench.test_master.genblk2[3].cache.ready_o} {V1:testbench.test_master.genblk2[3].cache.data_o} {V1:testbench.test_master.genblk2[3].cache.v_o} {V1:testbench.test_master.genblk2[3].cache.addr_v_r} {V1:testbench.test_master.genblk2[3].cache.data_v_r} {V1:testbench.test_master.genblk2[3].cache.ld_op_v_r} {V1:testbench.test_master.genblk2[3].cache.st_op_v_r} {V1:testbench.test_master.genblk2[3].cache.miss_v} {V1:testbench.test_master.genblk2[3].cache.yumi_i} {V1:testbench.test_master.genblk2[3].cache.miss.miss_state_r} }

set _wave_session_group_5 dma_pkt
if {[gui_sg_is_group -name "$_wave_session_group_5"]} {
    set _wave_session_group_5 [gui_sg_generate_new_name]
}
set Group5 "$_wave_session_group_5"

gui_sg_addsignal -group "$_wave_session_group_5" { {V1:testbench.DUT.rr_v_lo} {V1:testbench.DUT.rr_tag_lo} {V1:testbench.DUT.rr_yumi_li} {V1:testbench.DUT.dma_pkt} {V1:testbench.DUT.app_en_o} {V1:testbench.DUT.app_rdy_i} {V1:testbench.DUT.app_cmd_o} {V1:testbench.DUT.app_addr_o} }

set _wave_session_group_6 rx
if {[gui_sg_is_group -name "$_wave_session_group_6"]} {
    set _wave_session_group_6 [gui_sg_generate_new_name]
}
set Group6 "$_wave_session_group_6"

gui_sg_addsignal -group "$_wave_session_group_6" { {V1:testbench.DUT.rx.tag_fifo_v_lo} {V1:testbench.DUT.rx.tag_fifo_yumi_li} {V1:testbench.DUT.rx.tag_fifo_data_lo} {V1:testbench.DUT.rx.count_lo} {V1:testbench.DUT.rx.app_rd_data_valid_i} {V1:testbench.DUT.rx.app_rd_data_end_i} {V1:testbench.DUT.rx.app_rd_data_i} }

set _wave_session_group_7 tx
if {[gui_sg_is_group -name "$_wave_session_group_7"]} {
    set _wave_session_group_7 [gui_sg_generate_new_name]
}
set Group7 "$_wave_session_group_7"

gui_sg_addsignal -group "$_wave_session_group_7" { {V1:testbench.DUT.tx.tag_fifo_data_lo} {V1:testbench.DUT.tx.tag_fifo_v_lo} {V1:testbench.DUT.tx.tag_fifo_yumi_li} {V1:testbench.DUT.tx.count_lo} {V1:testbench.DUT.tx.app_wdf_wren_o} {V1:testbench.DUT.tx.app_wdf_data_o} {V1:testbench.DUT.tx.app_wdf_end_o} {V1:testbench.DUT.tx.app_wdf_rdy_i} }

set _wave_session_group_8 test_master
if {[gui_sg_is_group -name "$_wave_session_group_8"]} {
    set _wave_session_group_8 [gui_sg_generate_new_name]
}
set Group8 "$_wave_session_group_8"

gui_sg_addsignal -group "$_wave_session_group_8" { {V1:testbench.test_master.tr_done_lo} }

set _wave_session_group_9 mobile_ddr0
if {[gui_sg_is_group -name "$_wave_session_group_9"]} {
    set _wave_session_group_9 [gui_sg_generate_new_name]
}
set Group9 "$_wave_session_group_9"

gui_sg_addsignal -group "$_wave_session_group_9" { {V1:testbench.genblk3[0].mobile_ddr_inst.Clk} {V1:testbench.genblk3[0].mobile_ddr_inst.Clk_n} {V1:testbench.genblk3[0].mobile_ddr_inst.Cke} {V1:testbench.genblk3[0].mobile_ddr_inst.Cs_n} {V1:testbench.genblk3[0].mobile_ddr_inst.Ras_n} {V1:testbench.genblk3[0].mobile_ddr_inst.Cas_n} {V1:testbench.genblk3[0].mobile_ddr_inst.We_n} {V1:testbench.genblk3[0].mobile_ddr_inst.Addr} {V1:testbench.genblk3[0].mobile_ddr_inst.Ba} {V1:testbench.genblk3[0].mobile_ddr_inst.Dq} {V1:testbench.genblk3[0].mobile_ddr_inst.Dqs} {V1:testbench.genblk3[0].mobile_ddr_inst.Dm} }

set _wave_session_group_10 mobile_ddr1
if {[gui_sg_is_group -name "$_wave_session_group_10"]} {
    set _wave_session_group_10 [gui_sg_generate_new_name]
}
set Group10 "$_wave_session_group_10"

gui_sg_addsignal -group "$_wave_session_group_10" { {V1:testbench.genblk3[1].mobile_ddr_inst.Clk} {V1:testbench.genblk3[1].mobile_ddr_inst.Clk_n} {V1:testbench.genblk3[1].mobile_ddr_inst.Cke} {V1:testbench.genblk3[1].mobile_ddr_inst.Cs_n} {V1:testbench.genblk3[1].mobile_ddr_inst.Ras_n} {V1:testbench.genblk3[1].mobile_ddr_inst.Cas_n} {V1:testbench.genblk3[1].mobile_ddr_inst.We_n} {V1:testbench.genblk3[1].mobile_ddr_inst.Addr} {V1:testbench.genblk3[1].mobile_ddr_inst.Ba} {V1:testbench.genblk3[1].mobile_ddr_inst.Dq} {V1:testbench.genblk3[1].mobile_ddr_inst.Dqs} {V1:testbench.genblk3[1].mobile_ddr_inst.Dm} }
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
gui_marker_create -id ${Wave.1} M1 231326500
gui_marker_create -id ${Wave.1} M2 266786500
gui_marker_create -id ${Wave.1} M3 488702500
gui_marker_create -id ${Wave.1} M4 792052500
gui_marker_create -id ${Wave.1} M5 811006500
gui_marker_set_ref -id ${Wave.1}  C1
gui_wv_zoom_timerange -id ${Wave.1} 4299178291 4299222012
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group1}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group2}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group3}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group4}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group5}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group6}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group7}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group8}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group9}]
gui_list_add_group -id ${Wave.1} -after {New Group} [list ${Group10}]
gui_list_collapse -id ${Wave.1} ${Group1}
gui_list_collapse -id ${Wave.1} ${Group2}
gui_list_collapse -id ${Wave.1} ${Group3}
gui_list_collapse -id ${Wave.1} ${Group7}
gui_list_collapse -id ${Wave.1} ${Group8}
gui_list_collapse -id ${Wave.1} ${Group9}
gui_list_collapse -id ${Wave.1} ${Group10}
gui_list_select -id ${Wave.1} {testbench.DUT.rx.app_rd_data_i }
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
gui_list_set_insertion_bar  -id ${Wave.1} -group ${Group3}  -position in

gui_marker_move -id ${Wave.1} {C1} 4299202102
gui_view_scroll -id ${Wave.1} -vertical -set 0
gui_show_grid -id ${Wave.1} -enable false
#</Session>

