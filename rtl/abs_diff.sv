`timescale 1ns / 1ps

module	abs_diff #(
        parameter DATA_WIDTH = 11,
        parameter DATA_OFFSET = 1024
    ) (
        input   logic                           i_clk,
        input   logic                           i_nrst,
        input   logic                           i_ce,
        input   logic                           i_ma_long_valid,
        input   logic                           i_ma_short_valid,
        input   logic signed [DATA_WIDTH-1:0]   i_ecg_sample,
        input   logic signed [DATA_WIDTH-1:0]   i_ma_long,
        input   logic signed [DATA_WIDTH-1:0]   i_ma_short,
        output  logic signed [DATA_WIDTH-1:0]   o_ecg_sample,
        output  logic signed [DATA_WIDTH-1:0]   o_abs_diff_long,
        output  logic signed [DATA_WIDTH-1:0]   o_abs_diff_short,
        output  logic signed                    o_abs_diff_short_valid,
        output  logic signed                    o_abs_diff_long_valid
    );
/**
 * Local variables and signals
 */
//logic signed [DATA_WIDTH-1:0]    diff_short, diff_long;

//assign diff_short = i_ecg_sample - i_ma_short;
//assign diff_long  = i_ecg_sample - i_ma_long;

/**
 *
 */
always_ff @(posedge i_clk) begin :abs_diff_short_blk
    if (i_ma_short_valid) begin
        //o_abs_diff_short <= (diff_short <0)? -diff_short : diff_short;
        o_abs_diff_short <= calc_abs_diff(i_ecg_sample, i_ma_short);
        o_abs_diff_short_valid <= 1'b1;
    end
    else begin
        o_abs_diff_short <= '0;
        o_abs_diff_short_valid <= 1'b0;
    end
end
/**
 *
 */
always_ff @(posedge i_clk) begin :abs_diff_long_blk
    if (i_ma_long_valid) begin
        //o_abs_diff_long <= (diff_long < 0) ? -diff_long : diff_long;
        o_abs_diff_long <= calc_abs_diff(i_ecg_sample, i_ma_long);
        o_abs_diff_long_valid <= '1;
    end
    else begin
        o_abs_diff_long <= '0;
        o_abs_diff_long_valid <= 1'b0;
    end
end

/**
 * Delay input sample
 */
always_ff @(posedge i_clk) begin :sample_delay_blk
    o_ecg_sample <= i_ecg_sample;
end

function logic signed [DATA_WIDTH-1:0] calc_abs_diff(  input logic signed [DATA_WIDTH-1:0] ecg_sample,
                                                       input logic signed [DATA_WIDTH-1:0] moving_avg);
    logic signed [DATA_WIDTH-1:0] diff, abs_diff;
    diff = ecg_sample - moving_avg;
    abs_diff = (diff <0) ? -diff : diff;
    return abs_diff;
endfunction


endmodule


