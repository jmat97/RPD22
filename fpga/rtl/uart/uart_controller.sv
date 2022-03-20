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

module uart_controller (
    input logic         i_clk,
    input logic         i_nrst,
    input logic [7:0]   i_rx_data,
    input logic         i_rx_data_valid,
    output logic        o_tx_data_valid,
    output [2:0]        o_rwaddr,
    output              o_rd_req,
    output              o_rw_req
);


/**
 * Local variables and signals
 */
    typedef enum logic [2:0] {INIT, IDLE, DECODE, SEND_REG, UPDATE_REG} state_t;
    state_t state, state_nxt;

/**
 * Signals assignments
 */
 
 assign rwaddr = rx_data[3:1];

/**
 * FSM state management
 */
    always_ff @(posedge i_clk, negedge i_nrst) begin
        if (!i_nrst)
            state <= INIT;
        else
            state <= state_nxt;
    end

/**
 * Next state logic
 */
    always_comb begin
        case (state)
            INIT:       state_nxt = IDLE;
            IDLE:       state_nxt = i_rx_data_valid ? DECODE : IDLE;
            DECODE:     state_nxt = i_rx_data[0] ? UPDATE_REG : SEND_REG;
            SEND_REG:   state_nxt = IDLE;
            UPDATE_REG: state_nxt = IDLE;
        endcase
    end


/**
 * Tasks and functions definitions
 */

/**
 * Properties and assertions
 */

/**
 * Send data logic
 */ 
 
 always @(i_clk) begin
    tx_data <= 
 end


endmodule
