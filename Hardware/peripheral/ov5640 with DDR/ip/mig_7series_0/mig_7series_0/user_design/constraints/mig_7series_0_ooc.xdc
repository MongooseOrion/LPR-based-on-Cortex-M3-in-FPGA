###################################################################################################
## This constraints file contains default clock frequencies to be used during creation of a 
## Synthesis Design Checkpoint (DCP). For best results the frequencies should be modified 
## to match the target frequencies. 
## This constraints file is not used in top-down/global synthesis (not the default flow of Vivado).
###################################################################################################


##################################################################################################
## 
##  Xilinx, Inc. 2010            www.xilinx.com 
##  Thu May 13 17:22:41 2021

##  Generated by MIG Version 4.2
##  
##################################################################################################
##  File name :       mig_7series_0.xdc
##  Details :     Constraints file
##                    FPGA Family:       ARTIX7
##                    FPGA Part:         XC7A100T-CSG324
##                    Speedgrade:        -3
##                    Design Entry:      VERILOG
##                    Frequency:         324.99000000000001 MHz
##                    Time Period:       3077 ps
##################################################################################################

##################################################################################################
## Controller 0
## Memory Device: DDR2_SDRAM->Components->MT47H64M16XX-25
## Data Width: 16
## Time Period: 3077
## Data Mask: 1
##################################################################################################

create_clock -period 3.077 [get_ports sys_clk_i]
          
create_clock -period 5 [get_ports clk_ref_i]
          