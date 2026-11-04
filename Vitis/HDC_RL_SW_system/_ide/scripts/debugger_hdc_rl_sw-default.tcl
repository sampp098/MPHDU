# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\VITIS_PRJ\HDC_RL_SW_system\_ide\scripts\debugger_hdc_rl_sw-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\VITIS_PRJ\HDC_RL_SW_system\_ide\scripts\debugger_hdc_rl_sw-default.tcl
# 
connect -url tcp:127.0.0.1:3121
source C:/Xilinx/Vitis/2024.1/scripts/vitis/util/zynqmp_utils.tcl
targets -set -nocase -filter {name =~"APU*"}
reset_apu
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-HS3 210299BC734F" && level==0 && jtag_device_ctx=="jsn-JTAG-HS3-210299BC734F-04724093-0"}
fpga -file C:/VITIS_PRJ/HDC_RL_SW/_ide/bitstream/HDC_RL_V1.4.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw C:/VITIS_PRJ/HDC_RL_HW/export/HDC_RL_HW/hw/HDC_RL_V1.4.xsa -mem-ranges [list {0x80000000 0xbfffffff} {0x400000000 0x5ffffffff} {0x1000000000 0x7fffffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source C:/VITIS_PRJ/HDC_RL_SW/_ide/psinit/psu_init.tcl
psu_init
after 1000
psu_ps_pl_isolation_removal
after 1000
psu_ps_pl_reset_config
catch {psu_protection}
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow C:/VITIS_PRJ/HDC_RL_SW/Debug/HDC_RL_SW.elf
configparams force-mem-access 0
bpadd -addr &main
