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

module uart_regs (
    input logic         i_clk,
    input logic         i_rst_n,
    input reg_rwaddr    i_rwaddr,
    input byte          i_write_data,
    input sample_num    i_r_peak_sample_num,
    input logic         i_rd_req,
    input logic         i_wr_req,
    input logic         i_mas_valid,
    input logic         i_mal_valid,
    input logic         i_th_inited,
    input logic         i_alg_active,
    input logic         i_tx_fifo_e,
    input logic         i_tx_fifo_f,
    input logic         i_rx_fifo_e,
    input logic         i_rx_fifo_f,
    output byte         o_read_data,
    output ecg_sample   o_ecg_value,
    output logic        o_ecg_value_vld,
    output logic        o_alg_rst,
    output logic        o_alg_en,
    output ecg_src      o_src_sel
);


/**
 * Local variables and signals
 */

uart_regs_t regs, regs_nxt;


/**
 * Signals assignments
 */
assign o_ecg_value = {regs.dinhr,regs.dinlr};
assign o_alg_rst = regs.cr.rst;
assign o_alg_en = regs.cr.en;
assign o_src_sel = ecg_src'(regs.cr.src_sel);
assign o_ecg_value_vld = regs.din_vld;

/**
 * Tasks and functions definitions
 */

function automatic logic is_offset_valid(input reg_rwaddr offset);
    return offset inside {
        UART_CR_OFFSET,
        UART_SR_OFFSET,
        UART_DINL_OFFSET,
        UART_DINH_OFFSET,
        UART_DOUTL_OFFSET,
        UART_DOUTM_OFFSET,
        UART_DOUTH_OFFSET
    };
endfunction
/**
 * Properties and assertions
 *//*
assert property (@(negedge i_clk) is_offset_valid(i_rwaddr)) else
    $warning("incorrect offset requested: 0x%x", i_rwaddr);
*/

/**
 * Module internal logic
 */

/* Registers update */

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        regs <= {{7{8'b0}}};
        //tx_data_valid <= 1'b0;
    end else begin
        regs <= regs_nxt;
        //tx_data_valid <= is_reg_written(UART_TDR_OFFSET);
    end
end

always_comb begin
    regs_nxt = regs;
    if (i_wr_req) begin
        case (i_rwaddr)
        UART_CR_OFFSET:     regs_nxt.cr = i_write_data;
        UART_DINL_OFFSET:   regs_nxt.dinlr = i_write_data;
        UART_DINH_OFFSET:   begin
            regs_nxt.dinhr = i_write_data;
            regs_nxt.din_vld = 1'b1;
        end
        default;
        endcase
    end
    else begin
        regs_nxt.din_vld = 1'b0;
        regs_nxt.doutlr = i_r_peak_sample_num[7:0];
        regs_nxt.doutmr = i_r_peak_sample_num[15:8];
        regs_nxt.douthr = {2'b0, i_r_peak_sample_num[CTR_WIDTH-1:16]};
        regs_nxt.sr.ma_s_vld = i_mas_valid;
        regs_nxt.sr.ma_l_vld = i_mal_valid;
        regs_nxt.sr.th_inited = i_th_inited;
        regs_nxt.sr.alg_active = i_alg_active;
        regs_nxt.sr.tx_fifo_empty = i_tx_fifo_e;
        regs_nxt.sr.tx_fifo_full = i_tx_fifo_f;
        regs_nxt.sr.rx_fifo_empty = i_rx_fifo_e;
        regs_nxt.sr.rx_fifo_full = i_rx_fifo_f;
    end
end

/* Registers readout */

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_read_data <= 8'b0;
    end else begin
        if (i_rd_req) begin
            case (i_rwaddr)
            UART_CR_OFFSET:     o_read_data <= regs.cr;
            UART_SR_OFFSET:     o_read_data <= regs.sr;
            UART_DOUTL_OFFSET:  o_read_data <= regs.doutlr;
            UART_DOUTM_OFFSET:  o_read_data <= regs.doutmr;
            UART_DOUTH_OFFSET:  o_read_data <= regs.douthr;
            endcase
        end
    end
end

endmodule
