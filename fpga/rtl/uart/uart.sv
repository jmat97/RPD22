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

import uart_pkg::*;

module uart (
    input logic         clk,
    input logic         rst_n,
    
    input logic [7:0]   read_data,
    input logic [10:0]  rr_period,
    input logic         mas_valid,
    input logic         mal_valid,
    input logic         th_inited,
    input logic         alg_active,
    input logic         tx_fifo_e,
    input logic         tx_fifo_f,
    input logic         rx_fifo_e,
    input logic         rx_fifo_f,
    output logic        irq,
    output logic [10:0] ecg_value,
    output logic        alg_rst,
    output logic        alg_en,
    output logic        src_sel,
    uart_bus.master     uart_bus
);


/**
 * Local variables and signals
 */

uart_regs_t regs, regs_nxt;
logic [7:0] rx_data, tx_data, read_reg_data;
logic [2:0] rwaddr;
logic       tx_data_valid, rx_data_valid, tx_busy, rx_error,
            sck_rising_edge, sck, rd_req, wr_req;


/**
 * Signals assignments
 */
assign ecg_value = {regs.dinhr,regs.dinlr};
assign alg_rst = regs.cr.rst;
assign alg_en = regs.cr.en;
assign src_sel = regs.cr.src_sel;
assign en = regs.cr.src_sel;
/**
 * Submodules placement
 */

serial_clock_generator u_serial_clock_generator (
    .sck,
    .rising_edge(sck_rising_edge),
    .falling_edge(),
    .clk,
    .rst_n,
    .en(1),
    .clk_divider_valid(0),
    .clk_divider(0)
);

uart_transmitter u_uart_transmitter (
    .busy(tx_busy),
    .sout(uart_bus.sout),
    .clk,
    .rst_n,
    .sck_rising_edge,
    .tx_data_valid,
    .tx_data
);

uart_receiver u_uart_receiver (
    .busy(),
    .rx_data_valid,
    .rx_data,
    .error(rx_error),
    .clk,
    .rst_n,
    .sck_rising_edge,
    .sin(uart_bus.sin)
);

uart_controller u_uart_controller (
    .i_clk(clk),
    .i_nrst(rst_n),
    .i_rx_data(rx_data),
    .i_rx_data_valid(rx_data_valid),
    .o_tx_data(tx_data),
    .o_tx_data_valid(tx_data_valid),
    .o_rwaddr(rwaddr),
    .o_rd_req(rd_req),
    .o_rw_req(rw_req)
    
);


/**
 * Tasks and functions definitions
 */

function automatic logic is_offset_valid(logic [2:0] offset);
    return offset inside {
        UART_CR_OFFSET, UART_SR_OFFSET, UART_DINL_OFFSET, UART_DINH_OFFSET, UART_DOUTL_OFFSET, UART_DOUTH_OFFSET
    };
endfunction
/**
 * Properties and assertions
 */

assert property (@(negedge clk) req |-> is_offset_valid(rwaddr)) else
    $warning("incorrect offset requested: 0x%x", rwaddr);


/**
 * Module internal logic
 */

/* Registers update */

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        regs <= {{7{8'b0}}};
        //tx_data_valid <= 1'b0;
    end else begin
        regs <= regs_nxt;
        //tx_data_valid <= is_reg_written(UART_TDR_OFFSET);
    end
end

always_comb begin
    regs_nxt = regs;

    if (wr_req) begin
        case (rwaddr)
        UART_CR_OFFSET:     regs_nxt.cr = rx_data;
        UART_DINL_OFFSET:   regs_nxt.dinlr = rx_data;
        UART_DINH_OFFSET:   regs_nxt.dinhr = rx_data;
        endcase
    end

    /* 0x004: status reg */
    if (rx_error)
        regs_nxt.sr.rxerr = 1'b1;

    regs_nxt.sr.txact = tx_busy;

    if (rx_data_valid)
        regs_nxt.sr.rxne = 1'b1;
    else if (is_reg_read(UART_RDR_OFFSET))
        regs_nxt.sr.rxne = 1'b0;

    /* 0x00c: receiver data reg */
    if (rx_data_valid)
        regs_nxt.rdr.data = rx_data;


end

/* Registers readout */

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rdata <= 8'b0;
    end else begin
        if (rd_req) begin
            case (rwaddr)
            UART_CR_OFFSET:     rdata <= regs.cr;
            UART_SR_OFFSET:     rdata <= regs.sr;
            UART_DOUTL_OFFSET:  rdata <= regs.doutlr;
            UART_DOUTH_OFFSET:  rdata <= regs.douthr;
            endcase
        end
    end
end

endmodule
