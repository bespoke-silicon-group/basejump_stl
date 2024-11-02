puts "RM-Info: Running script [info script]\n"

##########################################################################################
# Variables common to all RM scripts
# Script: common_setup.tcl
# Version: F-2011.09-SP4 (April 2, 2012)
# Copyright (C) 2007-2012 Synopsys, Inc. All rights reserved.
##########################################################################################

# The name of the top-level design
set DESIGN_NAME                  "[getenv DESIGN_NAME]"

# Absolute path prefix variable for library/design data.
# Use this variable to prefix the common absolute path to the common variables
# defined below. Absolute paths are mandatory for hierarchical RM flow.
set DESIGN_REF_DATA_PATH         ""

##########################################################################################
# Library Setup Variables
##########################################################################################

# For the following variables, use a blank space to separate multiple entries
# Example: set TARGET_LIBRARY_FILES "lib1.db lib2.db lib3.db"

# Additional search path to be added to the default search path
set ADDITIONAL_SEARCH_PATH        [join "/gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/synopsys
                                         ./../src
                                         ./dc_scripts
                                         ../"]

# Setting common cad path
set COMMON_PATH                 "../../../common"

# Target technology logical libraries
# set TARGET_LIBRARY_FILES          [join "fast.db
set TARGET_LIBRARY_FILES  [join "typical.db"] 
                       #             slow.db"]

# Extra link logical libraries not included in TARGET_LIBRARY_FILES
set ADDITIONAL_LINK_LIB_FILES    ""

# List of max min library pairs "max1 min1 max2 min2 max3 min3"...
set MIN_LIBRARY_FILES            ""

# Milkyway reference libraries (include IC Compiler ILMs here)
set MW_REFERENCE_LIB_DIRS        [join "${COMMON_PATH}/milkyway/std_cells
                                        ${COMMON_PATH}/milkyway/io_pads"]

# Reference Control file to define the MW ref libs
set MW_REFERENCE_CONTROL_FILE    ""

# Milkyway technology file
set TECH_FILE                    " /gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/apollo/tf/tsmc25_5lm.tf"
                                 #  /gro/cad/mosis/pdk/std_cells/Rev_2004q2v1/aci/sc/apollo/tf/tsmc25_5lm.tf"
# Mapping file for TLUplus
set MAP_FILE                     "${COMMON_PATH}/tluplus/t25.map"
# Max TLUplus file
set TLUPLUS_MAX_FILE             "${COMMON_PATH}/tluplus/t025s5ml.tluplus"
# Min TLUplus file
set TLUPLUS_MIN_FILE             "${COMMON_PATH}/tluplus/t025s5ml.tluplus"

set MW_POWER_NET                 "VDD"
set MW_POWER_PORT                "VDD"
set MW_GROUND_NET                "VSS"
set MW_GROUND_PORT               "VSS"

# Min routing layer
set MIN_ROUTING_LAYER            ""
# Max routing layer
set MAX_ROUTING_LAYER            ""
# Tcl file with library modifications for dont_use
set LIBRARY_DONT_USE_FILE        ""

##########################################################################################
# Multi-Voltage Common Variables
#
# Define the following MV common variables for the RM scripts for multi-voltage flows.
# Use as few or as many of the following definitions as needed by your design.
##########################################################################################

# Name of power domain/voltage area  1
set PD1                          ""
# Instances to include in power domain/voltage area 1
set PD1_CELLS                    ""
# Coordinates for voltage area 1
set VA1_COORDINATES              {}
# Power net for voltage area 1
set MW_POWER_NET1                "VDD1"
# Power port for voltage area 1
set MW_POWER_PORT1               "VDD"

# Name of power domain/voltage area  2
set PD2                          ""
# Instances to include in power domain/voltage area 2
set PD2_CELLS                    ""
# Coordinates for voltage area 2
set VA2_COORDINATES              {}
# Power net for voltage area 2
set MW_POWER_NET2                "VDD2"
# Power port for voltage area 2
set MW_POWER_PORT2               "VDD"

# Name of power domain/voltage area  3
set PD3                          ""
# Instances to include in power domain/voltage area 3
set PD3_CELLS                    ""
# Coordinates for voltage area 3
set VA3_COORDINATES              {}
# Power net for voltage area 3
set MW_POWER_NET3                "VDD3"
# Power port for voltage area 3
set MW_POWER_PORT3               "VDD"

# Name of power domain/voltage area  4
set PD4                          ""
# Instances to include in power domain/voltage area 4
set PD4_CELLS                    ""
# Coordinates for voltage area 4
set VA4_COORDINATES              {}
# Power net for voltage area 4
set MW_POWER_NET4                "VDD4"
# Power port for voltage area 4
set MW_POWER_PORT4               "VDD"

puts "RM-Info: Completed script [info script]\n"
