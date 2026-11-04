
################################################################
# This is a generated script based on design: GPHDC_Core
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
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2024.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source GPHDC_Core_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# XOR_PE, ROT_PE, PSUM_PE, MAJ_PE, binary_cache, bcache_In_MUX, control, int_ram, HmmD, bcache_In_MUX, HDC_Interconnect, update, MCache_BRAM

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xck26-sfvc784-2LV-c
   set_property BOARD_PART xilinx.com:k26c:part0:1.4 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name GPHDC_Core

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:xlconcat:2.1\
xilinx.com:ip:xlconstant:1.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
XOR_PE\
ROT_PE\
PSUM_PE\
MAJ_PE\
binary_cache\
bcache_In_MUX\
control\
int_ram\
HmmD\
bcache_In_MUX\
HDC_Interconnect\
update\
MCache_BRAM\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set m_axi_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {128} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {0} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $m_axi_0

  set S_AXI_0 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {16} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {0} \
   CONFIG.HAS_CACHE {0} \
   CONFIG.HAS_LOCK {0} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {0} \
   CONFIG.HAS_REGION {0} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $S_AXI_0


  # Create ports
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset
  set resetn [ create_bd_port -dir I -type rst resetn ]
  set irq [ create_bd_port -dir O -type intr irq ]
  set clk [ create_bd_port -dir I -type clk -freq_hz 100000000 clk ]
  set_property -dict [ list \
   CONFIG.CLK_DOMAIN {UHDC_v1_1_clk} \
 ] $clk

  # Create instance: XOR_PE_0, and set properties
  set block_name XOR_PE
  set block_cell_name XOR_PE_0
  if { [catch {set XOR_PE_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $XOR_PE_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: ROT_PE_0, and set properties
  set block_name ROT_PE
  set block_cell_name ROT_PE_0
  if { [catch {set ROT_PE_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $ROT_PE_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: PSUM_PE_0, and set properties
  set block_name PSUM_PE
  set block_cell_name PSUM_PE_0
  if { [catch {set PSUM_PE_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $PSUM_PE_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.int_size {2} $PSUM_PE_0


  # Create instance: MAJ_PE_0, and set properties
  set block_name MAJ_PE
  set block_cell_name MAJ_PE_0
  if { [catch {set MAJ_PE_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $MAJ_PE_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property CONFIG.int_size {2} $MAJ_PE_0


  # Create instance: binary_cache_0, and set properties
  set block_name binary_cache
  set block_cell_name binary_cache_0
  if { [catch {set binary_cache_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $binary_cache_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: bcache_In_MUX_0, and set properties
  set block_name bcache_In_MUX
  set block_cell_name bcache_In_MUX_0
  if { [catch {set bcache_In_MUX_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $bcache_In_MUX_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property CONFIG.NUM_PORTS {4} $xlconcat_0


  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {32} \
  ] $xlconstant_0


  # Create instance: control_0, and set properties
  set block_name control
  set block_cell_name control_0
  if { [catch {set control_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $control_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.i_cache_depth {256} \
    CONFIG.i_cache_depth_clogb2 {8} \
    CONFIG.int_cache_depth {4} \
    CONFIG.int_cache_depth_clogb2 {2} \
    CONFIG.int_size {2} \
  ] $control_0


  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
 ] [get_bd_pins $control_0/clk]

  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins $control_0/rst]

  # Create instance: xlconstant_1, and set properties
  set xlconstant_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1 ]

  # Create instance: int_ram_0, and set properties
  set block_name int_ram
  set block_cell_name int_ram_0
  if { [catch {set int_ram_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $int_ram_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.RAM_DATA_SIZE {2} \
    CONFIG.RAM_DEPTH {4} \
    CONFIG.RAM_DEPTH_CLOG2 {2} \
  ] $int_ram_0


  # Create instance: HmmD_0, and set properties
  set block_name HmmD
  set block_cell_name HmmD_0
  if { [catch {set HmmD_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $HmmD_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.G_LOG2_SLICE_WIDTH {6} \
    CONFIG.G_LOG2_VECTOR_WIDTH {11} \
  ] $HmmD_0


  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins $HmmD_0/rst]

  # Create instance: HmmD_In_MUX_1, and set properties
  set block_name bcache_In_MUX
  set block_cell_name HmmD_In_MUX_1
  if { [catch {set HmmD_In_MUX_1 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $HmmD_In_MUX_1 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: xlconcat_1, and set properties
  set xlconcat_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_1 ]
  set_property CONFIG.NUM_PORTS {4} $xlconcat_1


  # Create instance: xlconstant_2, and set properties
  set xlconstant_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_2 ]
  set_property -dict [list \
    CONFIG.CONST_VAL {0} \
    CONFIG.CONST_WIDTH {32} \
  ] $xlconstant_2


  # Create instance: HDC_Interconnect_0, and set properties
  set block_name HDC_Interconnect
  set block_cell_name HDC_Interconnect_0
  if { [catch {set HDC_Interconnect_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $HDC_Interconnect_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
    set_property -dict [list \
    CONFIG.Icache_base_addr {0x40002000} \
    CONFIG.Icache_depth {2} \
    CONFIG.Icache_depth_clogb2 {1} \
    CONFIG.Instcache_base_addr {0x40000000} \
    CONFIG.Mcache_base_addr {0x40003000} \
    CONFIG.Mcache_depth {56} \
    CONFIG.Mcache_depth_clogb2 {6} \
    CONFIG.Mcache_result_addr {0x40004000} \
    CONFIG.instcache_depth {64} \
    CONFIG.instcache_depth_clogb2 {6} \
  ] $HDC_Interconnect_0


  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins $HDC_Interconnect_0/rst]

  # Create instance: xlconstant_3, and set properties
  set xlconstant_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_3 ]
  set_property CONFIG.CONST_VAL {0} $xlconstant_3


  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_2 ]
  set_property -dict [list \
    CONFIG.IN0_WIDTH {112} \
    CONFIG.IN1_WIDTH {16} \
    CONFIG.NUM_PORTS {2} \
  ] $xlconcat_2


  # Create instance: update_0, and set properties
  set block_name update
  set block_cell_name update_0
  if { [catch {set update_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $update_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: MCache_BRAM_0, and set properties
  set block_name MCache_BRAM
  set block_cell_name MCache_BRAM_0
  if { [catch {set MCache_BRAM_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $MCache_BRAM_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create interface connections
  connect_bd_intf_net -intf_net HDC_Interconnect_0_m_axi [get_bd_intf_ports m_axi_0] [get_bd_intf_pins HDC_Interconnect_0/m_axi]
  connect_bd_intf_net -intf_net S_AXI_0_1 [get_bd_intf_ports S_AXI_0] [get_bd_intf_pins control_0/S_AXI]

  # Create port connections
  connect_bd_net -net HDC_Interconnect_0_Icache_addr  [get_bd_pins HDC_Interconnect_0/Icache_addr] \
  [get_bd_pins int_ram_0/addr1]
  connect_bd_net -net HDC_Interconnect_0_Icache_rd_en  [get_bd_pins HDC_Interconnect_0/Icache_rd_en] \
  [get_bd_pins int_ram_0/rd_en1]
  connect_bd_net -net HDC_Interconnect_0_Icache_wr_en  [get_bd_pins HDC_Interconnect_0/Icache_wr_en] \
  [get_bd_pins int_ram_0/wr_en1]
  connect_bd_net -net HDC_Interconnect_0_Instcache_addr  [get_bd_pins HDC_Interconnect_0/Instcache_addr] \
  [get_bd_pins control_0/addr1]
  connect_bd_net -net HDC_Interconnect_0_Instcache_wr_en  [get_bd_pins HDC_Interconnect_0/Instcache_wr_en] \
  [get_bd_pins control_0/wr_en1]
  connect_bd_net -net HDC_Interconnect_0_Mcache_addr  [get_bd_pins HDC_Interconnect_0/Mcache_addr] \
  [get_bd_pins MCache_BRAM_0/port1_Addr]
  connect_bd_net -net HDC_Interconnect_0_Mcache_rd_en  [get_bd_pins HDC_Interconnect_0/Mcache_rd_en] \
  [get_bd_pins MCache_BRAM_0/port1_rd_en]
  connect_bd_net -net HDC_Interconnect_0_Mcache_wr_en  [get_bd_pins HDC_Interconnect_0/Mcache_wr_en] \
  [get_bd_pins MCache_BRAM_0/port1_wr_en]
  connect_bd_net -net HamDist_outputs  [get_bd_pins HmmD_0/HamDist_outputs] \
  [get_bd_pins MCache_BRAM_0/HamDist_inputs]
  connect_bd_net -net HmmD_0_argMin  [get_bd_pins HmmD_0/argMin] \
  [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net HmmD_MHV_Slices  [get_bd_pins MCache_BRAM_0/port2_out_Data] \
  [get_bd_pins HmmD_0/MHV] \
  [get_bd_pins update_0/MHV]
  connect_bd_net -net HmmD_MHV_index  [get_bd_pins control_0/ctrl_HmmD_MHV_index] \
  [get_bd_pins update_0/MHV_addr] \
  [get_bd_pins MCache_BRAM_0/port2_Addr]
  connect_bd_net -net HmmD_clear  [get_bd_pins control_0/ctrl_HmmD_clear] \
  [get_bd_pins HmmD_0/acc_clear]
  connect_bd_net -net HmmD_en  [get_bd_pins control_0/ctrl_HmmD_en] \
  [get_bd_pins HmmD_0/read_en]
  connect_bd_net -net MAJ_PE_0_output  [get_bd_pins MAJ_PE_0/dout] \
  [get_bd_pins xlconcat_0/In2] \
  [get_bd_pins xlconcat_1/In2]
  connect_bd_net -net MCache_BRAM_0_port1_out_Data  [get_bd_pins MCache_BRAM_0/port1_out_Data] \
  [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net PSUM_PE_0_output  [get_bd_pins PSUM_PE_0/dout] \
  [get_bd_pins int_ram_0/din2]
  connect_bd_net -net QHV_slice  [get_bd_pins HmmD_In_MUX_1/dout] \
  [get_bd_pins HmmD_0/QHV] \
  [get_bd_pins update_0/QHV]
  connect_bd_net -net ROT_PE_0_output  [get_bd_pins ROT_PE_0/dout] \
  [get_bd_pins xlconcat_0/In1] \
  [get_bd_pins xlconcat_1/In1]
  connect_bd_net -net S_AXI_ARESETN_1  [get_bd_ports resetn] \
  [get_bd_pins control_0/S_AXI_ARESETN]
  connect_bd_net -net XOR_dout  [get_bd_pins XOR_PE_0/dout] \
  [get_bd_pins xlconcat_0/In0] \
  [get_bd_pins xlconcat_1/In0]
  connect_bd_net -net binary_addr1  [get_bd_pins HDC_Interconnect_0/Bcache_addr] \
  [get_bd_pins binary_cache_0/addr1]
  connect_bd_net -net binary_addr2  [get_bd_pins control_0/ctrl_addr1] \
  [get_bd_pins binary_cache_0/addr2]
  connect_bd_net -net binary_din1  [get_bd_pins HDC_Interconnect_0/data_out] \
  [get_bd_pins binary_cache_0/din1] \
  [get_bd_pins control_0/din1] \
  [get_bd_pins int_ram_0/din1] \
  [get_bd_pins MCache_BRAM_0/port1_in_Data]
  connect_bd_net -net binary_din2  [get_bd_pins bcache_In_MUX_0/dout] \
  [get_bd_pins binary_cache_0/din2]
  connect_bd_net -net binary_dout1  [get_bd_pins binary_cache_0/dout1] \
  [get_bd_pins HDC_Interconnect_0/Bcache_In_Data]
  connect_bd_net -net binary_dout2  [get_bd_pins binary_cache_0/dout2] \
  [get_bd_pins PSUM_PE_0/din] \
  [get_bd_pins ROT_PE_0/din] \
  [get_bd_pins XOR_PE_0/din]
  connect_bd_net -net binary_rd_en1  [get_bd_pins HDC_Interconnect_0/Bcache_rd_en] \
  [get_bd_pins binary_cache_0/rd_en1]
  connect_bd_net -net binary_rd_en2  [get_bd_pins control_0/ctrl_rd_en_1] \
  [get_bd_pins binary_cache_0/rd_en2]
  connect_bd_net -net binary_wr_en1  [get_bd_pins HDC_Interconnect_0/Bcache_wr_en] \
  [get_bd_pins binary_cache_0/wr_en1]
  connect_bd_net -net binary_wr_en2  [get_bd_pins control_0/ctrl_wr_en_1] \
  [get_bd_pins binary_cache_0/wr_en2]
  connect_bd_net -net clk_1  [get_bd_ports clk] \
  [get_bd_pins HDC_Interconnect_0/clk] \
  [get_bd_pins HmmD_0/clk] \
  [get_bd_pins MAJ_PE_0/clk] \
  [get_bd_pins PSUM_PE_0/clk] \
  [get_bd_pins ROT_PE_0/clk] \
  [get_bd_pins XOR_PE_0/clk] \
  [get_bd_pins binary_cache_0/clk] \
  [get_bd_pins control_0/clk] \
  [get_bd_pins control_0/S_AXI_ACLK] \
  [get_bd_pins int_ram_0/clk] \
  [get_bd_pins update_0/clk] \
  [get_bd_pins MCache_BRAM_0/clk]
  connect_bd_net -net control_0_ctrl_HmmD_QHV_sel  [get_bd_pins control_0/ctrl_HmmD_QHV_sel] \
  [get_bd_pins HmmD_In_MUX_1/in_select]
  connect_bd_net -net control_0_ctrl_UPD_Penalty  [get_bd_pins control_0/ctrl_UPD_Penalty] \
  [get_bd_pins update_0/Penalty]
  connect_bd_net -net control_0_ctrl_UPD_argMin  [get_bd_pins control_0/ctrl_UPD_argMin] \
  [get_bd_pins update_0/argMin_in]
  connect_bd_net -net control_0_ctrl_UPD_en  [get_bd_pins control_0/ctrl_UPD_en] \
  [get_bd_pins update_0/update_en]
  connect_bd_net -net control_0_ctrl_UPD_wr  [get_bd_pins control_0/ctrl_UPD_wr] \
  [get_bd_pins update_0/update_wr]
  connect_bd_net -net control_0_ctrl_addr2  [get_bd_pins control_0/ctrl_addr2] \
  [get_bd_pins int_ram_0/addr2]
  connect_bd_net -net control_0_ctrl_bcache_In_sels  [get_bd_pins control_0/ctrl_bcache_In_sels] \
  [get_bd_pins bcache_In_MUX_0/in_select]
  connect_bd_net -net control_0_ctrl_maj_T  [get_bd_pins control_0/ctrl_maj_T] \
  [get_bd_pins MAJ_PE_0/T]
  connect_bd_net -net control_0_ctrl_maj_in_valids  [get_bd_pins control_0/ctrl_maj_in_valids] \
  [get_bd_pins MAJ_PE_0/in_valid]
  connect_bd_net -net control_0_ctrl_maj_load_Ts  [get_bd_pins control_0/ctrl_maj_load_Ts] \
  [get_bd_pins MAJ_PE_0/load_T]
  connect_bd_net -net control_0_ctrl_psum_in_valids  [get_bd_pins control_0/ctrl_psum_in_valids] \
  [get_bd_pins PSUM_PE_0/in_valid]
  connect_bd_net -net control_0_ctrl_psum_reloads  [get_bd_pins control_0/ctrl_psum_reloads] \
  [get_bd_pins PSUM_PE_0/reload]
  connect_bd_net -net control_0_ctrl_rd_en_2  [get_bd_pins control_0/ctrl_rd_en_2] \
  [get_bd_pins int_ram_0/rd_en2]
  connect_bd_net -net control_0_ctrl_rot_amounts  [get_bd_pins control_0/ctrl_rot_amounts] \
  [get_bd_pins ROT_PE_0/rot_amount]
  connect_bd_net -net control_0_ctrl_rot_in_valids  [get_bd_pins control_0/ctrl_rot_in_valids] \
  [get_bd_pins ROT_PE_0/in_valid]
  connect_bd_net -net control_0_ctrl_rot_load_carry_in  [get_bd_pins control_0/ctrl_rot_load_carry_in] \
  [get_bd_pins ROT_PE_0/reload_carry_in]
  connect_bd_net -net control_0_ctrl_sw_bcache_base_addr  [get_bd_pins control_0/ctrl_sw_bcache_base_addr] \
  [get_bd_pins HDC_Interconnect_0/ctrl_bcache_base_addr]
  connect_bd_net -net control_0_ctrl_sw_bcache_depth  [get_bd_pins control_0/ctrl_sw_bcache_depth] \
  [get_bd_pins HDC_Interconnect_0/ctrl_bcache_depth]
  connect_bd_net -net control_0_ctrl_sw_bcache_start  [get_bd_pins control_0/ctrl_sw_bcache_start] \
  [get_bd_pins HDC_Interconnect_0/ctrl_bcache_start]
  connect_bd_net -net control_0_ctrl_wr_en_2  [get_bd_pins control_0/ctrl_wr_en_2] \
  [get_bd_pins int_ram_0/wr_en2]
  connect_bd_net -net control_0_dout1  [get_bd_pins control_0/dout1] \
  [get_bd_pins HDC_Interconnect_0/Instcache_In_Data]
  connect_bd_net -net control_0_irq  [get_bd_pins control_0/irq] \
  [get_bd_ports irq]
  connect_bd_net -net control_0_rst  [get_bd_pins control_0/rst] \
  [get_bd_pins HDC_Interconnect_0/rst] \
  [get_bd_pins HmmD_0/rst] \
  [get_bd_pins MAJ_PE_0/rst] \
  [get_bd_pins PSUM_PE_0/rst] \
  [get_bd_pins ROT_PE_0/rst] \
  [get_bd_pins XOR_PE_0/rst] \
  [get_bd_pins binary_cache_0/rst] \
  [get_bd_pins int_ram_0/rst] \
  [get_bd_pins MCache_BRAM_0/rst]
  connect_bd_net -net ctrl_sw_cmd_valid  [get_bd_pins control_0/ctrl_sw_cmd_valid] \
  [get_bd_pins HDC_Interconnect_0/cmd_valid]
  connect_bd_net -net ctrl_sw_mem_select  [get_bd_pins control_0/ctrl_sw_mem_select] \
  [get_bd_pins HDC_Interconnect_0/mem_select]
  connect_bd_net -net ctrl_sw_wr_nrd  [get_bd_pins control_0/ctrl_sw_wr_nrd] \
  [get_bd_pins HDC_Interconnect_0/wr_nrd]
  connect_bd_net -net icache_rd_Dout  [get_bd_pins HDC_Interconnect_0/Instcache_rd_en] \
  [get_bd_pins control_0/rd_en1]
  connect_bd_net -net int_ram_0_dout1  [get_bd_pins int_ram_0/dout1] \
  [get_bd_pins HDC_Interconnect_0/Icache_In_Data]
  connect_bd_net -net int_ram_0_dout2  [get_bd_pins int_ram_0/dout2] \
  [get_bd_pins MAJ_PE_0/din]
  connect_bd_net -net reset_1  [get_bd_ports reset] \
  [get_bd_pins control_0/reset]
  connect_bd_net -net switch_busy  [get_bd_pins HDC_Interconnect_0/busy] \
  [get_bd_pins control_0/ctrl_sw_busy]
  connect_bd_net -net update_0_Updated_MHV_slice  [get_bd_pins update_0/Updated_MHV_slice] \
  [get_bd_pins MCache_BRAM_0/port2_UPDATE_Data]
  connect_bd_net -net update_0_argMin_out  [get_bd_pins update_0/argMin_out] \
  [get_bd_pins MCache_BRAM_0/port2_UPDATE_Addr]
  connect_bd_net -net update_0_update_valid  [get_bd_pins update_0/update_valid] \
  [get_bd_pins MCache_BRAM_0/port2_wr_en]
  connect_bd_net -net xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  [get_bd_pins bcache_In_MUX_0/inputs]
  connect_bd_net -net xlconcat_1_dout  [get_bd_pins xlconcat_1/dout] \
  [get_bd_pins HmmD_In_MUX_1/inputs]
  connect_bd_net -net xlconcat_2_dout  [get_bd_pins xlconcat_2/dout] \
  [get_bd_pins HDC_Interconnect_0/Mcache_In_Data]
  connect_bd_net -net xlconstant_0_dout  [get_bd_pins xlconstant_0/dout] \
  [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net xlconstant_1_dout  [get_bd_pins xlconstant_1/dout] \
  [get_bd_pins HmmD_In_MUX_1/en] \
  [get_bd_pins bcache_In_MUX_0/en] \
  [get_bd_pins MCache_BRAM_0/port2_rd_en]
  connect_bd_net -net xlconstant_2_dout  [get_bd_pins xlconstant_2/dout] \
  [get_bd_pins xlconcat_1/In3]
  connect_bd_net -net xlconstant_3_dout  [get_bd_pins xlconstant_3/dout] \
  [get_bd_pins int_ram_0/ram_sel]
  connect_bd_net -net xor_Load_A_nBs  [get_bd_pins control_0/ctrl_xor_Load_A_nBs] \
  [get_bd_pins XOR_PE_0/load_A_nB]
  connect_bd_net -net xor_in_valids  [get_bd_pins control_0/ctrl_xor_in_valids] \
  [get_bd_pins XOR_PE_0/in_valid]
  connect_bd_net -net xor_rstB  [get_bd_pins control_0/ctrl_xor_rstB] \
  [get_bd_pins XOR_PE_0/rstB]

  # Create address segments
  assign_bd_address -offset 0x40000000 -range 0x00008000 -target_address_space [get_bd_addr_spaces HDC_Interconnect_0/m_axi] [get_bd_addr_segs m_axi_0/Reg] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


