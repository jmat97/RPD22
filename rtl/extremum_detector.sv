`timescale 1ns / 1ps

module	extremum_detector #(
        parameter DATA_WIDTH = 11
	) (
        input	logic	i_clk,
        input	logic	i_nrst,
        input	logic	i_ce,
        input	logic	i_qrs_win_active,
        input	logic signed [DATA_WIDTH-1:0]       i_signal,
        input   logic   i_signal_valid,
        output  logic   o_extremum_found,
        output  logic   o_refractory_win_active
	);
/**
 * Local variables and signals
 */
logic signed [DATA_WIDTH-1:0] signal_prev, diff, diff_prev;
/**
 * Signals assignments
 */
assign diff = signal_prev - i_signal;

/**
 *
 */
always_ff @ (posedge i_clk) begin
    if(!i_nrst) begin
        signal_prev <= '0;
    end
    else begin
        signal_prev <= i_signal_valid ? i_signal : '0;
    end
end

always_ff @ (posedge i_clk) begin
    if(!i_nrst) begin
        diff_prev <= '0;
    end
    else begin
        diff_prev <= i_signal_valid ? diff : '0;
    end
end

always_ff @ (posedge i_clk) begin
    if ( extremum_found(i_qrs_win_active, o_refractory_win_active, diff_prev, diff) ) begin
        o_extremum_found <= 1'b1;
    end
    else begin
        o_extremum_found <= 1'b0;
    end
end
/**
 *
 */
    counter_fsm #(
		.MAX_VAL (72),
        .MAX_VAL_SIZE(7)
    ) refractory_win_counter (
		.i_clk(i_clk),
		.i_nrst(i_nrst),
		.i_ce(i_ce),
		.i_start(o_extremum_found),
        .o_active(o_refractory_win_active)
	);
/**
 *
 */
function logic extremum_found(  input logic qrs_win_active,
                                input logic refractory_win_active,
                                input logic signed [DATA_WIDTH-1:0] diff_prev,
                                input logic signed [DATA_WIDTH-1:0] diff
                                );
    return qrs_win_active && (diff_prev < 0) && (diff >= 0) && (!refractory_win_active);
endfunction

endmodule


