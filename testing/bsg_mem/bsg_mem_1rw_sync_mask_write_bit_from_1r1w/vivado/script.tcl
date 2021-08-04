create_project project_1 -part xc7z020clg400-1
set_property board_part xilinx.com:zc702:part0:1.4 [current_project]
set TOP ../../../..
set BSG_TEST ${TOP}/bsg_test
add_files -norecurse -scan_for_includes ${BSG_TEST}/bsg_nonsynth_random_gen.v
add_files -norecurse -scan_for_includes ${TOP}/bsg_misc/bsg_defines.v
add_files -norecurse -scan_for_includes ${BSG_TEST}/bsg_nonsynth_clock_gen.v
add_files -norecurse -scan_for_includes ${BSG_TEST}/bsg_nonsynth_reset_gen.v
add_files -norecurse -scan_for_includes ${TOP}/bsg_mem/bsg_mem_1r1w_sync.v
add_files -norecurse -scan_for_includes ${TOP}/bsg_mem/bsg_mem_1r1w_sync_synth.v
add_files -norecurse -scan_for_includes ${TOP}/bsg_misc/bsg_dff_en_bypass.v
add_files -norecurse -scan_for_includes ${TOP}/bsg_misc/bsg_dff_en.v
add_files -norecurse -scan_for_includes ${TOP}/bsg_misc/bsg_dff.v
add_files -norecurse -scan_for_includes test_bsg.v
add_files -norecurse -scan_for_includes ${TOP}/hard/ultrascale_plus/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_from_1r1w.v
set_property file_type SystemVerilog [get_files {bsg_mem_1rw_sync_mask_write_bit_from_1r1w.v bsg_nonsynth_clock_gen.v bsg_nonsynth_random_gen.v test_bsg.v}]
set_property file_type SystemVerilog [get_files {bsg_mem_1r1w_sync.v bsg_mem_1r1w_sync_synth.v}]
set_property file_type SystemVerilog [get_files {bsg_dff.v bsg_dff_en.v bsg_dff_en_bypass.v}]
set_property file_type {Verilog Header} [get_files bsg_defines.v]
set_property file_type SystemVerilog [get_files bsg_nonsynth_reset_gen.v]
set_property used_in_synthesis false [get_files test_bsg.v]
set_property top bsg_mem_1rw_sync_mask_write_bit_from_1r1w [current_fileset]
update_compile_order -fileset sources_1
set_property -name {xsim.simulate.runtime} -value {20us} -objects [get_filesets sim_1]
start_gui
