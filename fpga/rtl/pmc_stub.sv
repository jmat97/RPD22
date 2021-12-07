/**
 * Copyright (C) 2021  AGH University of Science and Technology
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

module pmc (
    input logic                  clk,
    input logic                  rst_n,
    ibex_data_bus.slave          data_bus,
    soc_pmc_bus.master           pmc_bus,
    soc_pm_ctrl.master           pm_ctrl,
    soc_pm_data.master           pm_data,
    soc_pm_analog_config.master  pm_analog_config,
    soc_pm_digital_config.master pm_digital_config
);


/**
 * Signals assignments
 */

assign data_bus.gnt = 1'b0;
assign data_bus.rvalid = 1'b0;
assign data_bus.rdata = 32'b0;
assign data_bus.rdata_intg = 7'b0;
assign data_bus.err = 1'b0;

assign pm_ctrl.store = 1'b0;
assign pm_ctrl.strobe = 1'b0;
assign pm_ctrl.gate = 1'b0;
assign pm_ctrl.sh_b = 1'b0;
assign pm_ctrl.sh_a = 1'b0;
assign pm_ctrl.clk_sh = 1'b0;

assign pm_data.din = 64'b0;

assign pm_analog_config.res = 128'b0;

assign pm_digital_config.res = 24'b0;
assign pm_digital_config.th = 8'b0;

endmodule
