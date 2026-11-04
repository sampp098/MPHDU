################################################################
# This is a generated script based on design: SDR
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]



################################################################
# START
################################################################

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project Example_MHDU ./myMHDU -part xck26-sfvc784-2LV-c
   set_property board_part xilinx.com:kv260_som:part0:1.4 [current_project]
   set_property target_language VHDL [current_project]
}
##################################################################
# Imports
##################################################################

#Add Core files for GPHDC
add_files -norecurse {./MPHDC/HDL/ADD_1bit.vhd ./MPHDC/HDL/MCache_BRAM.vhd ./MPHDC/HDL/findMin.vhd ./MPHDC/HDL/update.vhd ./MPHDC/HDL/shift.vhd ./MPHDC/HDL/UHDC_Reg.vhd ./MPHDC/HDL/bcache_In_MUX.vhd ./MPHDC/HDL/HmmD.vhd ./MPHDC/HDL/ROT_PE.vhd ./MPHDC/HDL/HD_Package.vhd ./MPHDC/HDL/LFSR.vhd ./MPHDC/HDL/XOR_PE.vhd ./MPHDC/HDL/MCache.vhd ./MPHDC/HDL/PSUM_PE.vhd ./MPHDC/HDL/ACC.vhd ./MPHDC/HDL/MAJ_PE.vhd ./MPHDC/HDL/binary_cache.vhd ./MPHDC/HDL/control.vhd ./MPHDC/HDL/MAJ_1bit.vhd ./MPHDC/HDL/RAM.vhd ./MPHDC/HDL/HD_PE.vhd ./MPHDC/HDL/XOR_slice.vhd ./MPHDC/HDL/int_ram.vhd ./MPHDC/HDL/PSUM.vhd ./MPHDC/HDL/HDC_Interconnect.vhd ./MPHDC/HDL/inst_cache.vhd}

source ./MPHDC/GPHDC_Core.tcl
current_bd_design [get_bd_designs GPHDC_Core]
assign_bd_address
validate_bd_design -force
save_bd_design
close_bd_design [get_bd_designs GPHDC_Core]

make_wrapper -files [get_files ./myMHDU/Example_MHDU.srcs/sources_1/bd/GPHDC_Core/GPHDC_Core.bd] -top
add_files -norecurse ./myMHDU/Example_MHDU.gen/sources_1/bd/GPHDC_Core/hdl/GPHDC_Core_wrapper.vhd

source ./MPHDC/MHDU.tcl
make_wrapper -files [get_files ./myMHDU/Example_MHDU.srcs/sources_1/bd/MHDU/MHDU.bd] -top
add_files -norecurse ./myMHDU/Example_MHDU.gen/sources_1/bd/MHDU/hdl/MHDU_wrapper.vhd
set_property top MHDU_wrapper [current_fileset]
