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
    output  logic [15:0]    led,
    output  logic           sout,
    output  logic           sout_spy,
    input   logic           clk_io,
    input   logic [15:0]    sw,
    input   logic           btnC,
    input   logic           sin,
    output  logic           sin_spy,
    input   logic           xa4_n,
    input   logic           xa4_p,
    output  logic           sck_re,
    output  logic           sck_spy
);

import alg_pkg::*;
/**
 * Local variables and signals
 */

logic   clk, rst_n, rst_n_generated, adc_en;

logic [16-1:0] adc_raw;
ecg_sample ecg_adc_sample;
logic sin_int;

//soc_gpio_bus          gpio_bus ();
//soc_pmc_bus           pmc_bus ();
//soc_spi_bus           spi_bus ();
//uart_bus          uart_bus ();

//soc_pm_ctrl           pm_ctrl ();
//soc_pm_data           pm_data ();
//soc_pm_analog_config  pm_analog_config ();
//soc_pm_digital_config pm_digital_config ();


/**
 * Signals assignments
 */
//assign sck_re = u_top_core.u_uart.sck_rising_edge;
//assign  sck_spy = u_top_core.u_uart.sck;

assign rst_n = ~(btnC | ~locked);
assign ecg_adc_sample = adc_raw[15:5];
assign led = {u_top_core.u_uart_regs.regs.sr, 5'b0 ,u_top_core.u_uart_regs.regs.cr};

//assign sin_int = sin;
assign sin_spy = sin_int;
assign sout_spy = sout;

  IBUF io_clk_ibuf(
    .I (sin),
    .O (sin_int)
  );

//assign led[7] = !gpio_bus.oe_n[15] ? gpio_bus.dout[15] : 1'b0;  /* bootloader finished */
//assign led[6:4] = 3'b0;
//assign led[3] = !gpio_bus.oe_n[3] ? gpio_bus.dout[3] : 1'b0;
//assign led[2] = !gpio_bus.oe_n[2] ? gpio_bus.dout[2] : 1'b0;
//assign led[1] = !gpio_bus.oe_n[1] ? gpio_bus.dout[1] : 1'b0;
//assign led[0] = !gpio_bus.oe_n[0] ? gpio_bus.dout[0] : 1'b0;

//assign gpio_bus.din[17] = 1'b0;                                 /* codeload skipping */
//assign gpio_bus.din[16] = sw;                                   /* codeload source */
//assign gpio_bus.din[3:0] = led[3:0];



//assign sout = uart_bus.sout;
//assign uart_bus.sin = sin;


/**
 * Submodules placement
 */

clk_wiz_0 u_clk_wiz_0
   (
    // Clock out ports
    .clk_100MHz(clk_100MHz),     // output clk_100MHz
    .clk_36MHz(clk_36MHz),     // output clk_36MHz
    .clk_10MHz(),     // output clk_10MHz
    // Status and control signals
    .reset(btnC), // input reset
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(clk_io)     // input clk_in1
    );
/*
reset_generator u_reset_generator (
    .rst_n_generated,
    .clk,
    .rst_n,
    .trigger(~btnc))
);
*/
xadc_wiz_0 u_xadc_wiz_0(
    .m_axis_aclk(clk_100MHz),
    .s_axis_aclk(clk_100MHz),
    .m_axis_resetn(rst_n),
    .m_axis_tvalid(m_axis_tvalid),
    .m_axis_tready(adc_en),
    .m_axis_tdata(adc_raw),
    .m_axis_tid(),
    .convst_in(adc_convst),
    .vp_in(1'b0),
    .vn_in(1'b0),
    .vauxp15(xa4_p),
    .vauxn15(xa4_n),
    .channel_out(),
    .eoc_out(),
    .alarm_out(),
    .eos_out(),
    .busy_out(adc_busy)
    );



top_core u_top_core (
    .i_clk_100MHz(clk_100MHz),
    .i_clk_36MHz(clk_36MHz),
    .o_sout(sout),
    .i_sin(sin_int),
    .i_nrst(rst_n),

    .i_adc_data(ecg_adc_sample),
    .i_adc_data_rdy(m_axis_tvalid),
    .i_adc_busy(adc_busy),
    .o_adc_convst(adc_convst),
    .o_adc_en(adc_en)
);






endmodule
