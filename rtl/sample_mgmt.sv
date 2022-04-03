`timescale 1ns / 1ps
//`default_nettype	none

module	sample_mgmt #(
        parameter DATA_WIDTH = 11,
        parameter CTR_WIDTH = 24
    ) (
        input   logic                   i_clk,
        input   logic                   i_nrst,
        input   logic                   i_ce,
        input   logic                   i_new_record,
        input   logic                   i_signal_valid,
        output  logic                   o_signal_valid,
        output  logic                   o_signal_req,
        output  logic [CTR_WIDTH-1:0]   o_ctr
	);

/**
 * Local variables and signals
 */
typedef enum logic [2:0] {INIT, SAMPLE_REQ, WAIT, SAMPLE_VALID} state_t;
state_t state, state_nxt;
logic [CTR_WIDTH-1:0] ctr;
logic signal_valid, signal_req;

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
    INIT:           state_nxt = SAMPLE_REQ;
    SAMPLE_REQ:     state_nxt = WAIT;
    WAIT:           state_nxt = i_signal_valid ? SAMPLE_VALID : WAIT;
    SAMPLE_VALID:   state_nxt = SAMPLE_REQ;
    endcase
end
/*
always @ (posedge i_clk) begin
    if((!i_nrst) | (i_nrst && i_new_record)) begin
        ctr <= 0;
    end
    else if (i_signal_valid) begin
        ctr <= ctr+1;
    end
end
*/
always_comb begin
    case(state)
    SAMPLE_VALID:   signal_valid = 1'b1;
    default:        signal_valid = 1'b0;
    endcase
end

always_comb begin
    case(state)
    INIT:           ctr = '0;
    SAMPLE_VALID:   ctr = ctr++;
    default:        ctr = ctr;
    endcase
end

always_comb begin
    case(state)
    SAMPLE_REQ:   signal_req = 1'b1;
    default:        signal_req = 1'b0;
    endcase
end

always_ff @( posedge i_clk) begin
    if(!i_nrst) begin
        o_ctr <= '0;
        o_signal_valid <= '0;
        o_signal_req <= '0;
    end
    else begin
        o_ctr <= ctr;
        o_signal_valid <= signal_valid;
        o_signal_req <= signal_req;
    end
end

/*
always @ (posedge i_signal_valid, negedge i_signal_valid) begin
    data_valid <= i_signal_valid ? 1'b1 : 1'b0;
end
*/

endmodule
