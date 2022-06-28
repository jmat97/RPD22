`timescale 1ns / 1ps
//`default_nettype	none

module	qrs_detector #(
		parameter DATA_WIDTH = 11,
		parameter CTR_WIDTH = 22
	) (
		input	logic	                           i_clk,
		input	logic	                           i_nrst,
		input	logic	                           i_ce,
		input   logic [CTR_WIDTH-1:0]              i_ctr,
        input	logic signed	[DATA_WIDTH-1:0]   i_signal_in,
		input	logic signed	[DATA_WIDTH-1:0]   i_threshold,
		input	logic i_refractory_win_active,
		input	logic i_qrs_search_en,
		output	logic o_qrs_win_active
	);

    logic ctr_start;

	always @( posedge i_clk) begin
		if ( (i_signal_in > i_threshold) &&
			(!o_qrs_win_active) &&
			(!i_refractory_win_active) &&
			i_qrs_search_en ) begin
			ctr_start <= 1;
		end
		else begin
			ctr_start <= 0;
		end
	end

    counter_fsm #(
		.COUNT_VALUE(72),
        .CTR_WIDTH(CTR_WIDTH)
    ) qrs_win_counter (
		.i_clk(i_clk),
		.i_nrst(i_nrst),
		.i_ce(i_ce),
		.i_ctr(i_ctr),
		.i_start(ctr_start),
        .o_active(o_qrs_win_active)
	);



endmodule
