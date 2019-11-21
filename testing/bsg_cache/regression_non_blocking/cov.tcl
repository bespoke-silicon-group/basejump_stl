# Begin_DVE_Session_Save_Info
# DVE full session
# Saved on Thu Nov 14 13:57:53 2019
# Designs open: 1
# Toplevel windows open: 1
# 	CovTopLevel.1
#   Group count = 0
# End_DVE_Session_Save_Info

# DVE version: L-2016.06-SP2-15_Full64
# DVE build date: Mar 11 2018 22:07:39


#<Session mode="Full" path="/mnt/users/ssd1/homes/dcjung/bsg/basejump_stl/testing/bsg_cache/regression_non_blocking/cov.tcl" type="Coverage">

gui_set_loading_session_type Post
gui_continuetime_set

# Close design
if { [gui_sim_state -check active] } {
    gui_sim_terminate
}
gui_close_db -all
gui_expr_clear_all

# Close all windows
gui_close_window -type Console
gui_close_window -type Wave
gui_close_window -type Source
gui_close_window -type Schematic
gui_close_window -type Data
gui_close_window -type DriverLoad
gui_close_window -type List
gui_close_window -type Memory
gui_close_window -type HSPane
gui_close_window -type DLPane
gui_close_window -type Assertion
gui_close_window -type CovHier
gui_close_window -type CoverageTable
gui_close_window -type CoverageMap
gui_close_window -type CovDetail
gui_close_window -type Local
gui_close_window -type Stack
gui_close_window -type Watch
gui_close_window -type Group
gui_close_window -type Transaction



# Application preferences
gui_set_pref_value -key app_default_font -value {Helvetica,10,-1,5,50,0,0,0,0,0}
gui_src_preferences -tabstop 8 -maxbits 24 -windownumber 1
#<WindowLayout>

# DVE top-level session


# Create and position top-level window: CovTopLevel.1

if {![gui_exist_window -window CovTopLevel.1]} {
    set CovTopLevel.1 [ gui_create_window -type CovTopLevel \
       -icon $::env(DVE)/auxx/gui/images/toolbars/dvewin.xpm] 
} else { 
    set CovTopLevel.1 CovTopLevel.1
}
gui_show_window -window ${CovTopLevel.1} -show_state normal -rect {{1630 670} {3870 1766}}

# ToolBar settings
gui_set_toolbar_attributes -toolbar {&File} -dock_state top
gui_set_toolbar_attributes -toolbar {&File} -offset 0
gui_show_toolbar -toolbar {&File}
gui_set_toolbar_attributes -toolbar {&Edit} -dock_state top
gui_set_toolbar_attributes -toolbar {&Edit} -offset 0
gui_show_toolbar -toolbar {&Edit}
gui_set_toolbar_attributes -toolbar {Exclusion} -dock_state top
gui_set_toolbar_attributes -toolbar {Exclusion} -offset 0
gui_show_toolbar -toolbar {Exclusion}
gui_set_toolbar_attributes -toolbar {Treemap} -dock_state top
gui_set_toolbar_attributes -toolbar {Treemap} -offset 0
gui_show_toolbar -toolbar {Treemap}
gui_set_toolbar_attributes -toolbar {Navigation} -dock_state top
gui_set_toolbar_attributes -toolbar {Navigation} -offset 0
gui_show_toolbar -toolbar {Navigation}
gui_set_toolbar_attributes -toolbar {PathNavigation} -dock_state top
gui_set_toolbar_attributes -toolbar {PathNavigation} -offset 0
gui_show_toolbar -toolbar {PathNavigation}
gui_set_toolbar_attributes -toolbar {Review} -dock_state top
gui_set_toolbar_attributes -toolbar {Review} -offset 0
gui_show_toolbar -toolbar {Review}
gui_set_toolbar_attributes -toolbar {ReviewScope} -dock_state top
gui_set_toolbar_attributes -toolbar {ReviewScope} -offset 0
gui_show_toolbar -toolbar {ReviewScope}
gui_set_toolbar_attributes -toolbar {&Window} -dock_state top
gui_set_toolbar_attributes -toolbar {&Window} -offset 0
gui_show_toolbar -toolbar {&Window}
gui_set_toolbar_attributes -toolbar {Zoom} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom} -offset 0
gui_show_toolbar -toolbar {Zoom}
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -dock_state top
gui_set_toolbar_attributes -toolbar {Zoom And Pan History} -offset 0
gui_show_toolbar -toolbar {Zoom And Pan History}

# End ToolBar settings

# Docked window settings
set CovHier.1 [gui_create_window -type CovHier -parent ${CovTopLevel.1} -dock_state left -dock_on_new_line true -dock_extent 200]
gui_set_window_pref_key -window ${CovHier.1} -key dock_width -value_type integer -value 200
gui_set_window_pref_key -window ${CovHier.1} -key dock_height -value_type integer -value 260
gui_set_window_pref_key -window ${CovHier.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${CovHier.1} {{left 0} {top 0} {width 199} {height 833} {dock_state left} {dock_on_new_line true} {child_covhier_colhier 140} {child_covhier_coltype 100} {child_covhier_col1 1} {child_covhier_col2 2}}
set Console.1 [gui_create_window -type Console -parent ${CovTopLevel.1} -dock_state bottom -dock_on_new_line true -dock_extent 180]
gui_set_window_pref_key -window ${Console.1} -key dock_width -value_type integer -value 689
gui_set_window_pref_key -window ${Console.1} -key dock_height -value_type integer -value 180
gui_set_window_pref_key -window ${Console.1} -key dock_offset -value_type integer -value 0
gui_update_layout -id ${Console.1} {{left 0} {top 0} {width 2240} {height 179} {dock_state bottom} {dock_on_new_line true}}
#### Start - Readjusting docked view's offset / size
set dockAreaList { top left right bottom }
foreach dockArea $dockAreaList {
  set viewList [gui_ekki_get_window_ids -active_parent -dock_area $dockArea]
  foreach view $viewList {
      if {[lsearch -exact [gui_get_window_pref_keys -window $view] dock_width] != -1} {
        set dockWidth [gui_get_window_pref_value -window $view -key dock_width]
        set dockHeight [gui_get_window_pref_value -window $view -key dock_height]
        set offset [gui_get_window_pref_value -window $view -key dock_offset]
        if { [string equal "top" $dockArea] || [string equal "bottom" $dockArea]} {
          gui_set_window_attributes -window $view -dock_offset $offset -width $dockWidth
        } else {
          gui_set_window_attributes -window $view -dock_offset $offset -height $dockHeight
        }
      }
  }
}
#### End - Readjusting docked view's offset / size

# MDI window settings
set CoverageTable.1 [gui_create_window -type {CoverageTable}  -parent ${CovTopLevel.1}]
gui_show_window -window ${CoverageTable.1} -show_state maximized
gui_update_layout -id ${CoverageTable.1} {{show_state maximized} {dock_state undocked} {dock_on_new_line false} {Layout_CoverageTable_covtblFGroupsList_names Group,    , ,  ,   ,Score,Covergroup,} {Layout_CoverageTable_covtblFGroupsList_widths 220,0,25,0,0,125,125,} {Layout_CoverageTable_covtblFGroupsList_orders 4,0,1,2,3,5,6,} {Layout_CoverageTable_covtblInstancesList_names Name,    , ,  ,   ,Score,Line,FSM,Condition,Branch,} {Layout_CoverageTable_covtblInstancesList_widths 220,0,25,0,0,125,125,125,125,125,} {Layout_CoverageTable_covtblInstancesList_orders 4,0,1,2,3,5,6,7,8,9,} {Layout_CoverageTable_covtblModulesList_names Name,    , ,  ,   ,Score,Line,FSM,Condition,Branch,} {Layout_CoverageTable_covtblModulesList_widths 220,0,25,0,0,125,125,125,125,125,} {Layout_CoverageTable_covtblModulesList_orders 4,0,1,2,3,5,6,7,8,9,}}

# End MDI window settings

gui_set_env TOPLEVELS::TARGET_FRAME(CovDetail) ${CovTopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(CoverageTable) ${CovTopLevel.1}
gui_set_env TOPLEVELS::TARGET_FRAME(CoverageMap) ${CovTopLevel.1}
gui_update_statusbar_target_frame ${CovTopLevel.1}

#</WindowLayout>

#<Database>

# DVE Open design session: 

gui_open_cov  -hier {simv.vdb}   -testdir {simv.vdb} -autoopen False  -test { {simv/test_pe_cover} {simv/test_long_interval} {simv/test_ainv} {simv/test_block} {simv/test_random_tagfl} {simv/test_zorder} {simv/test_tag_access} {simv/test_clean_read} {simv/test_random_aflinv2} {simv/test_random_afl} {simv/test_linear} {simv/test_ld_st} {simv/test_invalid_lock2} {simv/test_square} {simv/test_block_ld3} {simv/test_block_ld2} {simv/test_random_flush} {simv/test_burst} {simv/test_block_ld} {simv/test_random_aflinv} {simv/test_invalid_lock} {simv/test_stride} {simv/test_random} {simv/test_byte} {simv/test_alock} } -merge {MergedTest}
gui_cov_show_cond_ids -show off
gui_set_precision 1s
gui_set_time_units 1s
#</Database>

# DVE Global setting session: 


# Global: Bus

# Global: Expressions

# Global: Signal Time Shift

# Global: Signal Compare

# Global: Signal Groups


# Global: Highlighting

# Global: Stack
gui_change_stack_mode -mode list

# Post database loading setting...

# Restore C1 time
gui_set_time -C1_only 0



# Save global setting...

# Wave/List view global setting
## Load User Defined Groups
#reload all efliles:
 gui_exclusion_file -file /mnt/users/ssd1/homes/dcjung/bsg/basejump_stl/testing/bsg_cache/regression_non_blocking/exclusion.el -load
#unmappable review objects:
#mappable review objects:
gui_cov_set_review_status -sync

gui_cov_show_value -switch false

# Close all empty TopLevel windows
foreach __top [gui_ekki_get_window_ids -type TopLevel] {
    if { [llength [gui_ekki_get_window_ids -parent $__top]] == 0} {
        gui_close_window -window $__top
    }
}
gui_set_loading_session_type noSession
# DVE View/pane content session: 

gui_list_set_filter -id ${CovHier.1} -list { {Cover Property 1} {All 1} {Cover Sequence 1} {Assertion 1} {Cover Group 1} }
gui_list_set_filter -id ${CovHier.1} -text {*}
catch {gui_list_expand -id ${CovHier.1} {/<Design Hierarchy>}}
catch {gui_list_expand -id ${CovHier.1} testbench}
catch {gui_list_expand -id ${CovHier.1} testbench}
gui_covtable_show -id CoverageTable.1 -show {Design Hierarchy}  -cumulative 1
# Restore toplevel window zorder
# The toplevel window could be closed if it has no view/pane
if {[gui_exist_window -window ${CovTopLevel.1}]} {
	gui_set_active_window -window ${CovTopLevel.1}
	gui_set_active_window -window ${CoverageTable.1}
	gui_set_active_window -window ${CovHier.1}
}
#</Session>

