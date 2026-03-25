#create_clock -period 10.000 -name txoutclk_x0y1 [get_pins -hierarchical -filter {NAME=~*/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtx_channel.gtxe2_channel_i/TXOUTCLK}]
#
#
set_false_path -to [get_pins -hierarchical -filter NAME=~*/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0]
set_false_path -to [get_pins -hierarchical -filter NAME=~*/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1]
set_property LOC PCIE3_X0Y1 [get_cells u_pcie_app_gen3_belta/u_pcie3_7x_0/inst/pcie_top_i/pcie_7vx_i/PCIE_3_0_i]
#
#create_clock -period 10.000 -name txoutclk_x0y1 [get_pins -hierarchical -filter {NAME =~ */gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i/TXOUTCLK}]
create_clock -period 10.000 -name txoutclk_x0y1 [get_pins u_pcie_app_gen3_belta/u_pcie3_7x_0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gth_channel.gthe2_channel_i/TXOUTCLK]


create_generated_clock -name clk_125mhz_x0y1 [get_pins -hierarchical -filter {NAME =~ */gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT0}]
create_generated_clock -name clk_250mhz_x0y1 [get_pins -hierarchical -filter {NAME =~ */gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/mmcm_i/CLKOUT1}]
create_generated_clock -name clk_125mhz_mux_x0y1 -source [get_pins -hierarchical -filter {NAME =~ */gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I0}] -divide_by 1 [get_pins gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O]
create_generated_clock -name clk_250mhz_mux_x0y1 -source [get_pins -hierarchical -filter {NAME =~ */gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1}] -divide_by 1 -add -master_clock clk_250mhz_x0y1 [get_pins -hierarchical -filter {NAME =~ */gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O}]
set_clock_groups -name pcieclkmux_x0y1 -physically_exclusive -group clk_125mhz_mux_x0y1 -group clk_250mhz_mux_x0y1
set_false_path -to [get_pins -hierarchical -filter {NAME=~*/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0}]
set_false_path -to [get_pins -hierarchical -filter {NAME=~*/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}]
#
set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y1 -group clk_250mhz_mux_x0y1
#
set_clock_groups -name pcieclkmux_x0y1 -physically_exclusive -group clk_125mhz_mux_x0y1 -group clk_250mhz_mux_x0y1
# Timing ignoring the below pins to avoid CDC analysis, but care has been taken in RTL to sync properly to other clock domain.
#
#
set_false_path -through [get_pins -hierarchical -filter NAME=~*/inst/pcie_top_i/pcie_7x_i/pcie_block_i/PLPHYLNKUPN]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/inst/pcie_top_i/pcie_7x_i/pcie_block_i/PLRECEIVEDHOTRST]

#------------------------------------------------------------------------------
# Asynchronous Paths
#------------------------------------------------------------------------------
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXELECIDLE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/TXPHINITDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/TXPHALIGNDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/TXDLYSRESETDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXDLYSRESETDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXPHALIGNDONE]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/RXCDRLOCK]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/CFGMSGRECEIVEDPMETO]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/CPLLLOCK]
set_false_path -through [get_pins -hierarchical -filter NAME=~*/QPLLLOCK]




