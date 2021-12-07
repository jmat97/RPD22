`timescale 1ns / 1ps
//`default_nettype	none

module	maximum_hold #(
		parameter DATA_WIDTH = 11
	) (
		input	logic	i_clk,	
		input	logic	i_nrst,
		input	logic	i_ce,
        input	logic signed	[DATA_WIDTH-1:0]	i_signal,	
        output	logic signed	[DATA_WIDTH-1:0]	o_signal_max,	
        input   logic	i_signal_valid, 
		output  logic 	o_signal_max_valid
	);

//logic signed	[DATA_WIDTH-1:0]	signal_max;
//logic signal_max_valid;

always @(posedge i_clk) begin
    if (!i_nrst) begin
        o_signal_max <= 1'd0;
        o_signal_max_valid <= 1'd0;
    end
    if (i_signal_valid) begin
        o_signal_max <= (i_signal > o_signal_max) ? i_signal : o_signal_max;
        o_signal_max_valid <= 1'd1;
    end
    else begin
        o_signal_max <= 1'd0;
        o_signal_max_valid <= 1'd0;
    end
end

//assign o_signal_max = signal_max;
//assign o_signal_max_valid = signal_max_valid;

endmodule
