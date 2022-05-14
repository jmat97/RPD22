`timescale 1ns / 1ps

module	counter_fsm #(
		parameter MAX_VAL = 0,
        parameter MAX_VAL_SIZE = 0
	) (
		input	logic	i_clk,
		input	logic	i_nrst,
		input	logic	i_ce,
		input	logic	i_start,
        output  logic   o_active
	);

typedef enum logic  {IDLE, COUNT} state_t;

state_t state, nxt_state;
logic [MAX_VAL_SIZE-1:0] counter;

always @ (posedge i_clk) begin
    if (!i_nrst) begin
        state <= IDLE;
    end
    else begin
        state <= nxt_state;
    end
end

always@(state, i_start, counter)begin
	//nxt_state = 'bx;
	case(state)
		IDLE: begin
            nxt_state <= i_start? COUNT: IDLE;
        end
		COUNT: begin
            nxt_state <= (counter == (MAX_VAL-1)) ? IDLE : COUNT;
        end
	endcase
end

always @ (posedge i_clk) begin
    if (!i_nrst) begin
        counter <= 0;
        o_active <= 0;
    end
    else if (state == COUNT) begin
        counter <= counter + 1;
        o_active <= 1;
    end
    else begin
        counter  <= 0;
        o_active <= 0;
    end
end

endmodule
