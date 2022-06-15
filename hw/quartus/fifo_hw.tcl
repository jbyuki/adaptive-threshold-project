# TCL File Generated by Component Editor 18.1
# Mon Jun 06 14:38:26 CEST 2022
# DO NOT MODIFY


# 
# fifo "fifo" v1.0
#  2022.06.06.14:38:26
# 
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module fifo
# 
set_module_property DESCRIPTION ""
set_module_property NAME fifo
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME fifo
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL fifo
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file fifo.vhd VHDL PATH fifo.vhd TOP_LEVEL_FILE


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock_reset
# 
add_interface clock_reset clock end
set_interface_property clock_reset clockRate 0
set_interface_property clock_reset ENABLED true
set_interface_property clock_reset EXPORT_OF ""
set_interface_property clock_reset PORT_NAME_MAP ""
set_interface_property clock_reset CMSIS_SVD_VARIABLES ""
set_interface_property clock_reset SVD_ADDRESS_GROUP ""

add_interface_port clock_reset clock clk Input 1


# 
# connection point fifo
# 
add_interface fifo conduit end
set_interface_property fifo associatedClock ""
set_interface_property fifo associatedReset ""
set_interface_property fifo ENABLED true
set_interface_property fifo EXPORT_OF ""
set_interface_property fifo PORT_NAME_MAP ""
set_interface_property fifo CMSIS_SVD_VARIABLES ""
set_interface_property fifo SVD_ADDRESS_GROUP ""

add_interface_port fifo data data Input 32
add_interface_port fifo empty empty Output 1
add_interface_port fifo q q Output 32
add_interface_port fifo rdreq rdreq Input 1
add_interface_port fifo sclr sclr Input 1
add_interface_port fifo usedw usedw Output 7
add_interface_port fifo wrreq wrreq Input 1

