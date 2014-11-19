proc bsg_check_not_null {check_me error_string} {
  if {$check_me==""} {
    echo "### BSG ### $error_string"
    exit
  }
  return $check_me
}


file mkdir ./core_lib
define_design_lib core_LIB -path ./core_lib
set SRC_PATH ../src

set core_rtl_files [list $SRC_PATH/two_in_one_out_fifo.v \
	  						         $SRC_PATH/mesosyncIO.v]

analyze -format sverilog $core_rtl_files

elaborate mesosyncIO

current_design mesosyncIO
