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

module serial_clock_generator (
    output logic      sck,
    output logic      rising_edge,

    input logic       clk,
    input logic       rst_n,
    input logic       en
);


/**
 * Local variables and signals
 */

logic       sck_nxt, rising_edge_nxt;
logic [9:0] counter, counter_nxt, counter_target, counter_target_nxt;


/**
 * Module internal logic
 */

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        sck <= 1'b0;
        rising_edge <= 1'b0;
        counter_target <= 9'b0;
        counter <= 9'b0;
    end else begin
        sck <= sck_nxt;
        rising_edge <= rising_edge_nxt;
        counter_target <= counter_target_nxt;
        counter <= counter_nxt;
    end
end

always_comb begin
    sck_nxt = 1'b0;
    rising_edge_nxt = 1'b0;
    counter_target_nxt = 9'd27;
    counter_nxt = 9'b0;

    if (en) begin
        sck_nxt = sck;
        counter_nxt = counter + 1;

        if (counter_target == 9'b0) begin
            sck_nxt = ~sck;
            rising_edge_nxt = ~sck;
            counter_nxt = 9'b0;
        end else if (counter == counter_target) begin
            sck_nxt = ~sck;
            rising_edge_nxt = ~sck;
            counter_nxt = 9'b0;
        end
    end
end

endmodule
