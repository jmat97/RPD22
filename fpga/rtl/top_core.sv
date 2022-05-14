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

import alg_pkg::*;
import uart_pkg::*;

module top_core (
    input   logic                   i_clk_100MHz,
    input   logic                   i_clk_36MHz,
    output  logic                   o_sout,
    input   logic                   i_sin,
    input   logic                   i_nrst,

    input   ecg_sample              i_adc_data,
    input   logic                   i_adc_data_rdy,
    input   logic                   i_adc_busy,
    output  logic                   o_adc_convst,
    output  logic                   o_adc_en
);

/**
 * Local variables and signals
 */

logic tx_data_valid, rx_data_valid, tx_busy, rx_busy, rx_error, alg_en;
logic rd_req, wr_req;
byte tx_data, rx_data, read_reg, write_reg;
reg_rwaddr rw_addr;
logic   ma_long_valid,
        ma_short_valid,
        th_initialised,
        alg_active;
logic fifo_full, fifo_empty, fifo_rdata_valid, fifo_data_req;
ecg_sample fifo_rdata;
ecg_src ecg_data_src;
logic alg_rst;
sample_num r_peak_sample_num;
logic dout_fifo_pop;
logic [DATA_WIDTH-1:0]  din_fifo_rdata, ecg_value;

logic clk_360Hz;
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

//assign led[7] = !gpio_bus.oe_n[15] ? gpio_bus.dout[15] : 1'b0;  /* bootloader finished */
//assign led[6:4] = 3'b0;
//assign led[3] = !gpio_bus.oe_n[3] ? gpio_bus.dout[3] : 1'b0;
//assign led[2] = !gpio_bus.oe_n[2] ? gpio_bus.dout[2] : 1'b0;
//assign led[1] = !gpio_bus.oe_n[1] ? gpio_bus.dout[1] : 1'b0;
//assign led[0] = !gpio_bus.oe_n[0] ? gpio_bus.dout[0] : 1'b0;

//assign gpio_bus.din[17] = 1'b0;                                 /* codeload skipping */
//assign gpio_bus.din[16] = sw;                                   /* codeload source */
//assign gpio_bus.din[3:0] = led[3:0];

/**
 * Submodules placement
 */

clk_divider #(
    .I_FREQ(36_000_000),
    .O_FREQ(ACQUISITION_RATE)
) u_clk_divider
    (
        .i_clk(i_clk_36MHz),      // input clock
        .i_nrst,     // async reset active low
        .o_clk_div(clk_360Hz)   // output clock
    );


uart u_uart(
    .sin(i_sin),
    .sout(o_sout),
    .clk(i_clk_100MHz),
    .rst_n(i_nrst),
    .tx_data_valid,
    .tx_data,
    .rx_data_valid,
    .rx_data,
    .tx_busy,
    .rx_busy,
    .rx_error
    //.sck(),
    //.sck_rising_edge()

/*
    .clk(i_clk_100MHz), // The master clock for this module
    .rst(~i_nrst), // Synchronous reset.
    .rx(i_sin), // Incoming serial line
    .tx(o_sout), // Outgoing serial line
    .transmit(tx_data_valid), // Signal to transmit
    .tx_byte(tx_data), // Byte to transmit
    .received(rx_data_valid), // Indicated that a byte has been received.
    .rx_byte(rx_data), // Byte received
    .is_receiving(rx_busy), // Low when receive line is idle.
    .is_transmitting(tx_busy), // Low when transmit line is idle.
    .recv_error(rx_error) // Indicates error in receiving packet.
    */
);
command_manager u_command_manager(
    .i_clk(i_clk_100MHz),
    .i_rst_n(i_nrst),
    .i_read_reg(read_reg),
    .i_rx_data(rx_data),
    .i_rx_data_valid(rx_data_valid),
    .o_write_reg(write_reg),
    .o_tx_data(tx_data),
    .o_tx_data_valid(tx_data_valid),
    .o_rwaddr(rw_addr),
    .o_rd_req(rd_req),
    .o_wr_req(wr_req),
    .o_fifo_fetch(dout_fifo_pop)
);


uart_regs u_uart_regs(
    .i_clk(i_clk_100MHz),
    .i_rst_n(i_nrst),
    .i_rwaddr(rw_addr),
    .i_write_data(write_reg),
    .i_r_peak_sample_num(dout_fifo_rdata),
    .i_rd_req(rd_req),
    .i_wr_req(wr_req),
    .i_mas_valid(ma_short_valid),
    .i_mal_valid(ma_long_valid),
    .i_th_inited(th_initialised),
    .i_alg_active(alg_active),
    .i_tx_fifo_e(dout_fifo_empty),
    .i_tx_fifo_f(dout_fifo_full),
    .i_rx_fifo_e(din_fifo_empty),
    .i_rx_fifo_f(din_fifo_full),
    .o_read_data(read_reg),
    .o_ecg_value(ecg_value),
    .o_ecg_value_vld(ecg_value_vld),
    .o_alg_rst(alg_rst),
    .o_alg_en(alg_en),
    .o_src_sel(ecg_data_src)
);

fifo #(
    .SIZE(DIN_FIFO_SIZE),
    .WIDTH(DATA_WIDTH)
) u_din_fifo (
    .clk(i_clk_100MHz),
    .rst_n(i_nrst),
    .full(din_fifo_full),
    .empty(din_fifo_empty),
    .rdata(din_fifo_rdata),
    .rdata_valid(din_fifo_rdata_valid),
    .push(ecg_value_vld),
    .pop(din_fifo_req),
    .wdata(ecg_value)
);



sample_mgmt #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTR_WIDTH(CTR_WIDTH)
    )
    sample_mgmt_inst (
        .i_clk(i_clk_100MHz),
        .i_nrst(i_nrst),
        .i_clk_adc_convst(clk_360Hz),
        .i_ecg_src(ecg_data_src),
        .i_new_record(new_record),
        /* FIFO */
        .o_fifo_req(din_fifo_req),
        .i_fifo_data(din_fifo_rdata),
        .i_fifo_empty(din_fifo_empty),
        .i_fifo_rd_valid(din_fifo_rdata_valid),
        /* ADC */
        .o_adc_convst(o_adc_convst),
        .i_adc_data(i_adc_data),
        .i_adc_busy(i_adc_busy),
        .i_adc_rd_valid(i_adc_data_rdy),

        .o_ecg_signal(ecg_signal),
        .o_ecg_signal_valid(ecg_signal_valid),
        .o_ctr(ctr)
    );


alg_core #(
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH),
    .DATA_OFFSET(DATA_OFFSET),
    .NAVG_SHORT(NAVG_SHORT),
    .NAVG_LONG(NAVG_LONG)
    )
    alg_core_inst(
    .i_clk(i_clk_100MHz),
    .i_nrst(i_nrst),
    .i_ce(alg_en),
    .i_ecg_signal(sample_in),
    .i_ecg_signal_valid(ecg_signal_valid),
    .o_rr_period(rr_period),
    .o_rr_period_updated(out_data_updated),
    .o_r_peak_location(r_peak_sample_num),
    .o_ma_long_valid(ma_long_valid),
    .o_ma_short_valid(ma_short_valid),
    .o_th_initialised(th_initialised),
    .o_alg_active(alg_active)
);


fifo #(
    .SIZE(DOUT_FIFO_SIZE),
    .WIDTH(CTR_WIDTH)
) u_dout_fifo (
    .clk(i_clk_100MHz),
    .rst_n(i_nrst),
    .full(dout_fifo_full),
    .empty(dout_fifo_empty),
    .rdata(dout_fifo_rdata),
    .rdata_valid(dout_fifo_rdata_valid),
    .push(out_data_updated),
    .pop(dout_fifo_pop),
    .wdata(r_peak_sample_num)
);



endmodule
