source -echo -verbose ./dc_scripts/common_setup.tcl
source -echo -verbose ./dc_scripts/dc_setup_filenames.tcl

puts "RM-Info: Running script [info script]\n"

#################################################################################
# Design Compiler Reference Methodology Setup for Top-Down Flow
# Script: dc_setup.tcl
# Version: F-2011.09-SP4 (April 2, 2012)
# Copyright (C) 2007-2012 Synopsys, Inc. All rights reserved.
#################################################################################


#################################################################################
# Setup Variables
#
# Modify settings in this section to customize your DC-RM run.
# Portions of dc_setup.tcl may be used by other tools so program name checks
# are performed where necessary.
#################################################################################

# The following setting removes new variable info messages from the end of the log file
set_app_var sh_new_variable_message false

if {$synopsys_program_name == "dc_shell"}  {

  #################################################################################
  # Design Compiler Specific Setup Variables
  #################################################################################

  # Use the set_host_options command to enable multicore optimization to improve runtime.
  # Note that this feature has special usage and license requirements.  Please refer
  # to the "Support for Multicore Technology" section in the Design Compiler User Guide
  # for multicore usage guidelines.
  # Note: This is a DC Ultra feature and is not supported in DC Expert.

  # set_host_options -max_cores 4

  # Change alib_library_analysis_path to point to a central cache of analyzed libraries
  # to save some runtime and disk space.  The following setting only reflects the
  # the default value and should be changed to a central location for best results.

  set_app_var alib_library_analysis_path .

  # Add any additional DC variables needed here
}

# The following variables are used by scripts in dc_scripts to direct the location
# of the output files

set REPORTS_DIR "reports"
set RESULTS_DIR "results"
set ENABLE_DC_GUI 0

if {![file isdirectory ${REPORTS_DIR}]} {
  file mkdir ${REPORTS_DIR}
}
if {![file isdirectory ${RESULTS_DIR}]} {
  file mkdir ${RESULTS_DIR}
}

#################################################################################
# Search Path Setup
#
# Set up the search path to find the libraries and design files.
#################################################################################

set_app_var search_path ". ${ADDITIONAL_SEARCH_PATH} $search_path"

#################################################################################
# Library Setup
#
# This section is designed to work with the settings from common_setup.tcl
# without any additional modification.
#################################################################################

# Milkyway variable settings

# Make sure to define the following Milkyway library variables
# mw_logic1_net, mw_logic0_net and mw_design_library are needed by write_milkyway

set_app_var mw_logic1_net   ${MW_POWER_NET}
set_app_var mw_logic0_net   ${MW_GROUND_NET}

set mw_reference_library    ${MW_REFERENCE_LIB_DIRS}
set mw_design_library       ${DCRM_MW_LIBRARY_NAME}

set mw_site_name_mapping    { {CORE unit} {Core unit} {core unit} }

# The remainder of the setup below should only be performed in Design Compiler
if {$synopsys_program_name == "dc_shell"}  {

  set_app_var target_library ${TARGET_LIBRARY_FILES}
  set_app_var synthetic_library dw_foundation.sldb
  set_app_var link_library "* $target_library $ADDITIONAL_LINK_LIB_FILES $synthetic_library"

  # Set min libraries if they exist
  foreach {max_library min_library} $MIN_LIBRARY_FILES {
    set_min_library $max_library -min_version $min_library
  }

  if {[shell_is_in_topographical_mode]} {

    # Only create new Milkyway design library if it doesn't already exist
    if {![file isdirectory $mw_design_library]} {
      create_mw_lib -technology $TECH_FILE \
                    -mw_reference_library $mw_reference_library \
                    $mw_design_library
    } else {
      # If Milkyway design library already exists, ensure that it is consistent with specified Milkyway reference libraries
      set_mw_lib_reference $mw_design_library -mw_reference_library $mw_reference_library
    }

    open_mw_lib     $mw_design_library

    check_library > ${REPORTS_DIR}/${DCRM_CHECK_LIBRARY_REPORT}

    set_tlu_plus_files -max_tluplus $TLUPLUS_MAX_FILE \
                       -min_tluplus $TLUPLUS_MIN_FILE \
                       -tech2itf_map $MAP_FILE

    check_tlu_plus_files
  }

  #################################################################################
  # Library Modifications
  #
  # Apply library modifications here after the libraries are loaded.
  #################################################################################

  if {[file exists [which ${LIBRARY_DONT_USE_FILE}]]} {
    puts "RM-Info: Sourcing script file [which ${LIBRARY_DONT_USE_FILE}]\n"
    source -echo -verbose ${LIBRARY_DONT_USE_FILE}
  }
}

puts "RM-Info: Completed script [info script]\n"

