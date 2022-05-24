`timescale 1ns / 1ps

module	counter_fsm #(
		parameter COUNT_VALUE = 0,
        parameter CTR_WIDTH = 22
	) (
		input	logic	              i_clk,
		input	logic	              i_nrst,
		input	logic	              i_ce,
		input   logic [CTR_WIDTH-1:0] i_ctr,
		input	logic	              i_start,
        output  logic                 o_active
	);

typedef enum logic  {IDLE, COUNT} state_t;
state_t state, nxt_state;

logic [CTR_WIDTH-1:0] ctr_target;

always @ (posedge i_clk) begin
    if (!i_nrst) begin
        state <= IDLE;
    end
    else begin
        state <= nxt_state;
    end
end

always_comb begin
	case(state)
		IDLE: begin
            nxt_state <= i_start? COUNT: IDLE;
            ctr_target <= i_ctr + COUNT_VALUE;
        end
		COUNT: begin
            nxt_state <= (i_ctr == (ctr_target-1)) ? IDLE : COUNT;
            ctr_target <= ctr_target;
        end
	endcase
end

always @ (posedge i_clk) begin
    if (!i_nrst) begin
        o_active <= 0;
    end
    else if (state == COUNT) begin
        o_active <= 1;
    end
    else begin
        o_active <= 0;
    end
end

endmodule
