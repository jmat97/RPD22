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

module reset_generator (
    output logic rst_n_generated,
    input logic  clk,
    input logic  rst_n,
    input logic  trigger
);


/**
 * User defined types
 */

typedef enum logic {
    IDLE,
    ACTIVE
} state_t;


/**
 * Local variables and signals
 */

state_t     state, state_nxt;
logic [6:0] counter, counter_nxt;


/**
 * Signals assignments
 */

assign rst_n_generated = (state == ACTIVE) ? 1'b0 : 1'b1;


/**
 * Module internal logic
 */

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        counter <= 7'b0;
    end
    else begin
        state <= state_nxt;
        counter <= counter_nxt;
    end
end

always_comb begin
    state_nxt = state;
    counter_nxt = counter;

    case (state)
    IDLE: begin
        if (trigger)
            state_nxt = ACTIVE;
    end
    ACTIVE:
        if (counter == 99) begin
            state_nxt = IDLE;
            counter_nxt = 7'b0;
        end else begin
            counter_nxt = counter + 1;
        end
    endcase
end

endmodule
