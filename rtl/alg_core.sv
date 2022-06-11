`timescale 1ns/1ps
//`default_nettype	none

module alg_core #(
    parameter DATA_WIDTH = 11,
    parameter CTR_WIDTH = 22,
    parameter DATA_OFFSET = 1024,
    parameter NAVG_SHORT = 16,
    parameter NAVG_LONG = 32
    )(
    input   logic                           i_clk,
    input   logic                           i_nrst,
    input   logic                           i_ce,
    input   logic signed [DATA_WIDTH-1:0]   i_ecg_signal,
    input   logic                           i_ecg_signal_valid,
    output  logic [CTR_WIDTH-1:0]           o_rr_period,
    output  logic                           o_rr_period_updated,
    output  logic [CTR_WIDTH-1:0]           o_rpeak_location,
    input   logic [CTR_WIDTH-1:0]           i_ctr,
    output  logic                           o_ma_long_valid,
    output  logic                           o_ma_short_valid,
    output  logic                           o_th_initialised,
    output  logic                           o_alg_active
);

/**
 * Local variables and signals
 */

logic signed [DATA_WIDTH-1:0] ma_short, ma_long, abs_diff_short, abs_diff_long;
logic signed [DATA_WIDTH-1:0] ecg_sample, ecg_sample_ma_ad;
logic signed [DATA_WIDTH-1:0] abs_diff_short_max, qrs_threshold;
logic signed ma_short_valid, ma_long_valid;
logic signed abs_diff_short_valid, abs_diff_long_valid;
logic signed abs_diff_short_max_valid;
logic qrs_win_state, abs_diff_long_extremum_found, refractory_win_active, qrs_search_en;

assign o_ma_long_valid = ma_long_valid;
assign o_ma_short_valid = ma_short_valid;

moving_avg #(
    .DATA_WIDTH(DATA_WIDTH),
    .NAVG_LONG(NAVG_LONG),
    .NAVG_SHORT(NAVG_SHORT)
    )
    moving_avg_inst (
        .i_clk,
        .i_nrst,
        .i_ce(i_ecg_signal_valid),
        .i_sample(i_ecg_signal),
        .i_sample_valid(i_ecg_signal_valid),
        .o_sample(ecg_sample_ma_ad),
        .o_ma_long(ma_long),
        .o_ma_short(ma_short),
        .o_ma_long_valid(ma_long_valid),
        .o_ma_short_valid(ma_short_valid)
    );

abs_diff #(
    .DATA_WIDTH(DATA_WIDTH),
    .DATA_OFFSET(DATA_OFFSET)
    )
    abs_diff_inst (
        .i_clk,
        .i_nrst,
        .i_ce,
        .i_ecg_sample(ecg_sample_ma_ad),
        .i_ma_long(ma_long),
        .i_ma_short(ma_short),
        .i_ma_long_valid(ma_long_valid),
        .i_ma_short_valid(ma_short_valid),
        .o_ecg_sample(ecg_sample),
        .o_abs_diff_long(abs_diff_long),
        .o_abs_diff_short(abs_diff_short),
        .o_abs_diff_short_valid(abs_diff_short_valid),
        .o_abs_diff_long_valid(abs_diff_long_valid)
    );


maximum_hold #(
    .DATA_WIDTH(DATA_WIDTH)
    )
     maximum_hold_inst(
        .i_clk,
        .i_nrst,
        .i_ce,
        .i_signal(abs_diff_short),
        .o_signal_max(abs_diff_short_max),
        .i_signal_valid(abs_diff_short_valid),
        .o_signal_max_valid(abs_diff_short_max_valid)
    );

qrs_detector #(
    .DATA_WIDTH(DATA_WIDTH)
    )
    qrs_detector_inst (
        .i_clk,
        .i_nrst,
        .i_ce,
        .i_ctr(i_ctr),
        .i_signal_in(abs_diff_short),
        .i_threshold(qrs_threshold),
        .i_refractory_win_active(refractory_win_active),
        .i_qrs_search_en(qrs_search_en),
        .o_qrs_win_active(qrs_win_state)
    );

extremum_detector #(
    .DATA_WIDTH(DATA_WIDTH)
    )
    extremum_detector_inst (
        .i_clk,
        .i_nrst,
        .i_ce,
        .i_ctr(i_ctr),
        .i_qrs_win_active(qrs_win_state),
        .i_signal(abs_diff_long),
        .i_signal_valid(abs_diff_long_valid),
        .o_extremum_found(abs_diff_long_extremum_found),
        .o_refractory_win_active(refractory_win_active)
);

alg_fsm #(
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH)
    )
    alg_fsm_inst (
        .i_clk,
        .i_nrst,
        .i_ce,
        .i_ctr(i_ctr),
        .i_abs_diff_short_max(abs_diff_short_max),
        .i_abs_diff_short_valid(abs_diff_short_valid),
        .i_extremum_found(abs_diff_long_extremum_found),
        .o_qrs_search_en(qrs_search_en),
        .o_rr_period(o_rr_period),
        .o_rr_period_updated(o_rr_period_updated),
        .o_rpeak_location(o_rpeak_location),
        .o_qrs_threshold(qrs_threshold),
        .o_th_initialised(o_th_initialised),
        .o_alg_active(o_alg_active)
    );


endmodule
