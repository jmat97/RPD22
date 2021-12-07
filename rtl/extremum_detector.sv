`timescale 1ns / 1ps
//`default_nettype	none

module	extremum_detector #(
        parameter DATA_WIDTH = 11
	) (
		input	logic	i_clk,	
		input	logic	i_nrst,
		input	logic	i_ce,
        input	logic	i_qrs_win_active,
        input	logic signed	[DATA_WIDTH-1:0] i_signal,
		input   logic       	i_signal_valid,
        output  logic   o_extremum,
        output  logic   o_refractory_win_active
	);

logic signed [DATA_WIDTH-1:0] signal_prev, diff, diff_prev;

always @ (posedge i_clk) begin
    if(!i_nrst) begin
        signal_prev <= 0;
    end
    else begin
        signal_prev <= i_signal_valid ? i_signal : 0;
    end
end
assign diff = signal_prev - i_signal;

always @ (posedge i_clk) begin
    if(!i_nrst) begin
        diff_prev <= 0;
    end
    else begin
        diff_prev <= i_signal_valid ? diff : 0;
    end
end

always @ (*) begin
    if ( i_qrs_win_active & (diff_prev < 0) & (diff >= 0) & (!o_refractory_win_active) ) begin
        o_extremum = 1;
    end
    else begin
        o_extremum = 0;
    end
end

    counter_fsm #(
		.MAX_VAL (72),
        .MAX_VAL_SIZE(7)
    ) refractory_win_counter (
		.i_clk(i_clk),	
		.i_nrst(i_nrst),
		.i_ce(i_ce),
		.i_start(o_extremum),
        .o_active(o_refractory_win_active)
	);

endmodule