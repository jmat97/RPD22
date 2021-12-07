`timescale 1ns / 1ps
//`default_nettype	none

module	abs_diff #(
		parameter DATA_WIDTH = 11,
        parameter DATA_OFFSET = 1024
	) (
		input	logic	i_clk,	
		input	logic	i_nrst,
		input	logic	i_ce,
        input	logic signed	[DATA_WIDTH-1:0]	i_ecg_sample,	
		input	logic signed	[DATA_WIDTH-1:0]	i_ma_long,
        input	logic signed	[DATA_WIDTH-1:0]	i_ma_short,
        input   logic	i_ma_long_valid, 
		input   logic	i_ma_short_valid,
        output	logic signed	[DATA_WIDTH-1:0]	o_ecg_sample,	
		output	logic signed	[DATA_WIDTH-1:0]	o_abs_diff_long,
		output	logic signed	[DATA_WIDTH-1:0]	o_abs_diff_short,
		output  logic signed	o_abs_diff_short_valid,
		output  logic signed	o_abs_diff_long_valid
	);

logic signed [DATA_WIDTH-1:0]    diff_short, diff_long;

assign diff_short = i_ecg_sample - i_ma_short;
assign diff_long  = i_ecg_sample - i_ma_long;

always @(posedge i_clk) begin
    if (i_ma_short_valid) begin
        o_abs_diff_short <= (diff_short <0)? -diff_short : diff_short;
        o_abs_diff_short_valid <= 1'd1;
    end
    else begin
        o_abs_diff_short <= 1'd0;
        o_abs_diff_short_valid <= 1'd0;
    end
end

always @(posedge i_clk) begin
    if (i_ma_long_valid) begin
        o_abs_diff_long <= (diff_long <0) ? -diff_long : diff_long;
        o_abs_diff_long_valid <= 1'd1;
    end
    else begin
        o_abs_diff_long <= 1'd0;
        o_abs_diff_long_valid <= 1'd0;
    end
end

always @(posedge i_clk) begin
    o_ecg_sample <= i_ecg_sample;
end

endmodule
