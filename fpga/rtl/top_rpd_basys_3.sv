/**
 * Copyright (C) 2020  AGH University of Science and Technology
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

module top_rpd_basys_3 (
    output logic [7:0] led,
    output logic       sout,
    input logic        clk_io,
    input logic        sw,
    input logic        btnC,
    input logic        sin
);


/**
 * Local variables and signals
 */

logic                 clk, rst_n, rst_n_generated;

//soc_gpio_bus          gpio_bus ();
//soc_pmc_bus           pmc_bus ();
//soc_spi_bus           spi_bus ();
uart_bus          uart_bus ();

//soc_pm_ctrl           pm_ctrl ();
//soc_pm_data           pm_data ();
//soc_pm_analog_config  pm_analog_config ();
//soc_pm_digital_config pm_digital_config ();


/**
 * Signals assignments
 */

//assign led[7] = !gpio_bus.oe_n[15] ? gpio_bus.dout[15] : 1'b0;  /* bootloader finished */
//assign led[6:4] = 3'b0;
//assign led[3] = !gpio_bus.oe_n[3] ? gpio_bus.dout[3] : 1'b0;
//assign led[2] = !gpio_bus.oe_n[2] ? gpio_bus.dout[2] : 1'b0;
//assign led[1] = !gpio_bus.oe_n[1] ? gpio_bus.dout[1] : 1'b0;
//assign led[0] = !gpio_bus.oe_n[0] ? gpio_bus.dout[0] : 1'b0;

//assign gpio_bus.din[17] = 1'b0;                                 /* codeload skipping */
//assign gpio_bus.din[16] = sw;                                   /* codeload source */
//assign gpio_bus.din[3:0] = led[3:0];



assign sout = uart_bus.sout;
assign uart_bus.sin = sin;


/**
 * Submodules placement
 */

alg_core u_alg_core (
    .clk,
    .nrst(rst_n & rst_n_generated),
    .ce(1'b1),
    .ecg_value(11'b1),
    .data_valid(1'b1),
    .rr_period(),
    .r_peak_sample_num()
);


clkgen_xil7series u_clkgen_xil7series (
    .IO_CLK(clk_io),
    .IO_RST_N(~btnC),
    .clk_sys(clk),
    .rst_sys_n(rst_n)
);

reset_generator u_reset_generator (
    .rst_n_generated,
    .clk,
    .rst_n
    //.trigger(gpio_bus.dout[31])
);

endmodule
