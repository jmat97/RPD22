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
    input logic         sin,
    output logic        sout,
    input logic         clk,
    input logic         rst_n,

    input logic         tx_data_valid,
    input logic [7:0]   tx_data,
    output logic        rx_data_valid,
    output logic [7:0]  rx_data,

    output logic        tx_busy,
    output logic        rx_busy,
    output logic        rx_error
);


/**
 * Local variables and signals
 */




/**
 * Signals assignments
 */

/**
 * Submodules placement
 */

serial_clock_generator u_serial_clock_generator (
    .sck(),
    .rising_edge(sck_rising_edge),
    .clk,
    .rst_n,
    .en(1'b1)
);

uart_transmitter u_uart_transmitter (
    .busy(tx_busy),
    .sout,
    .clk,
    .rst_n,
    .sck_rising_edge,
    .tx_data_valid,
    .tx_data
);

uart_receiver u_uart_receiver (
    .busy(rx_busy),
    .rx_data_valid,
    .rx_data,
    .error(rx_error),
    .clk,
    .rst_n,
    .sck_rising_edge,
    .sin
);

/**
 * Tasks and functions definitions
 */

/**
 * Properties and assertions
 */


/**
 * Module internal logic
 */

endmodule
