# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\VITIS_PRJ\HDC_RL_HW\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\VITIS_PRJ\HDC_RL_HW\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {HDC_RL_HW}\
-hw {C:\GITHUB\HDC_RL\HDC_RL_V1.xsa}\
-arch {64-bit} -fsbl-target {psu_cortexa53_0} -out {C:/VITIS_PRJ}

platform write
domain create -name {standalone_psu_cortexa53_0} -display-name {standalone_psu_cortexa53_0} -os {standalone} -proc {psu_cortexa53_0} -runtime {cpp} -arch {64-bit} -support-app {hello_world}
platform generate -domains 
platform active {HDC_RL_HW}
domain active {zynqmp_fsbl}
domain active {zynqmp_pmufw}
domain active {standalone_psu_cortexa53_0}
platform generate -quick
bsp reload
bsp reload
platform generate
platform generate
platform clean
platform active {HDC_RL_HW}
platform config -updatehw {C:/GITHUB/HDC_RL/HDC_RL_V1.2.xsa}
platform generate
platform clean
platform config -updatehw {C:/GITHUB/HDC_RL/HDC_RL_V1.2.xsa}
platform generate
platform clean
platform generate
platform clean
platform config -updatehw {C:/GITHUB/HDC_RL/HDC_RL_V1.3.xsa}
platform generate
platform clean
platform clean
platform config -updatehw {C:/GITHUB/HDC_RL/HDC_RL_V1.4.xsa}
platform generate
platform write
platform clean
platform active {HDC_RL_HW}
