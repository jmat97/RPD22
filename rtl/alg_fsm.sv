`timescale 1ns / 1ps

module	alg_fsm #(
        parameter DATA_WIDTH = 11,
        parameter CTR_WIDTH = 24
    ) (
        input   logic                               i_clk,
        input   logic                               i_nrst,
        input   logic                               i_ce,
        input   logic [CTR_WIDTH-1:0]               i_ctr,
        input   logic signed [DATA_WIDTH-1:0]       i_abs_diff_short_max,
        input   logic                               i_abs_diff_short_valid,
        input   logic                               i_extremum_found,
        output  logic                               o_qrs_search_en,
        output  logic [DATA_WIDTH-1:0]              o_rr_period,
        output  logic                               o_rr_period_updated,
        output  logic [CTR_WIDTH-1:0]               o_r_peak_location,
        output  logic [DATA_WIDTH-1:0]              o_qrs_threshold,
        output  logic                               o_th_initialised,
        output  logic                               o_alg_active
    );

/**
 * Local variables and signals
 */
typedef enum logic [2:0] {INIT, ALG_INIT, TH_INIT, RUN, ALG_UPDATE_1, ALG_UPDATE_2} state_t;
state_t state, state_nxt;
logic signed [DATA_WIDTH-1:0]qrs_threshold_prv;
logic th_updated, r_peak_sample_updated;
logic [CTR_WIDTH-1:0] r_peak_sample_num_prev, r_peak_sample_num, ctr_init_target, ctr_init_target_nxt;

/**
 * Signals assignments
 */
assign o_r_peak_location = r_peak_sample_num;
assign o_alg_active = state != INIT;


/**
 * Algorithm initialisation
 */
always_comb begin
    case (state)
    INIT: ctr_init_target_nxt = i_ctr + 'd1080; // 3s worth of samples
    default: ctr_init_target_nxt = ctr_init_target_nxt;
    endcase
end

always_ff @(posedge i_clk, negedge i_nrst) begin
    if (!i_nrst)
        ctr_init_target <= 'b0;
    else
        ctr_init_target <= ctr_init_target_nxt;
end

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
    INIT:           state_nxt = i_abs_diff_short_valid ? ALG_INIT : INIT;
    ALG_INIT:       state_nxt = init_period_elapsed() ? TH_INIT : ALG_INIT;
    TH_INIT :       state_nxt = o_th_initialised ? RUN : TH_INIT;
    RUN:            state_nxt = i_extremum_found ? ALG_UPDATE_1 : RUN;
    ALG_UPDATE_1:   state_nxt = ALG_UPDATE_2;
    ALG_UPDATE_2:   state_nxt = o_rr_period_updated & th_updated ? RUN : ALG_UPDATE_2;
    default:        state_nxt = INIT;
    endcase
end

/**
 * QRS threshold logic
 */
always @ (posedge i_clk)begin
    if (!i_nrst) begin
        qrs_threshold_prv <= 0;
        o_qrs_threshold <= 0;
        o_th_initialised <= 1'b0;
    end
    else begin
    case (state)
    INIT : begin
        qrs_threshold_prv <= 0;
        o_qrs_threshold <= 0;
        o_th_initialised <= 1'b0;
        th_updated <= 1'b0;
        end
    TH_INIT : begin
        qrs_threshold_prv <= i_abs_diff_short_max >> 1;
        o_qrs_threshold <= i_abs_diff_short_max >> 1;
        o_th_initialised <= 1'b1;
        th_updated <= 1'b0;
    end
    ALG_UPDATE_1 : begin
        qrs_threshold_prv <= o_qrs_threshold;
        o_qrs_threshold <= update_th(o_qrs_threshold, i_abs_diff_short_max);
        $display("%d,%d, %d",qrs_threshold_prv, i_abs_diff_short_max, o_qrs_threshold);
        o_th_initialised <= o_th_initialised;
        th_updated <= 1'b0;
    end
    ALG_UPDATE_2 : begin
        qrs_threshold_prv <= qrs_threshold_prv;
        o_qrs_threshold <= o_qrs_threshold;
        o_th_initialised <= o_th_initialised;
        th_updated <= 1'b1;
    end
    default : begin
        qrs_threshold_prv <= qrs_threshold_prv;
        o_qrs_threshold <= o_qrs_threshold;
        o_th_initialised <= o_th_initialised;
        th_updated <= 1'b0;
        end
    endcase
    end
end

/**
 * R-peak sample & RR period update logic
 */
always @ (posedge i_clk)begin
    if (!i_nrst) begin
        r_peak_sample_num_prev <= 11'b0;
        r_peak_sample_num <= 11'b0;
        o_rr_period <= 11'b0;
        o_rr_period_updated <= 1'b0;
    end
    else begin
    case (state)
    ALG_UPDATE_1 : begin
        r_peak_sample_num_prev <= r_peak_sample_num;
        r_peak_sample_num <= i_ctr;
        o_rr_period <= o_rr_period;
        r_peak_sample_updated <= 1'b1;
        o_rr_period_updated <= 1'b0;
    end
    ALG_UPDATE_2 : begin
        r_peak_sample_num_prev <= r_peak_sample_num_prev;
        r_peak_sample_num <= r_peak_sample_num;
        o_rr_period <= calc_rr_period(r_peak_sample_num_prev, r_peak_sample_num, o_rr_period);
        r_peak_sample_updated <= 1'b0;
        o_rr_period_updated <= 1'b1;
    end
    default : begin
        r_peak_sample_num_prev <= r_peak_sample_num_prev;
        r_peak_sample_num <= r_peak_sample_num;
        o_rr_period <= o_rr_period;
        r_peak_sample_updated <= 1'b0;
        o_rr_period_updated <= 1'b0;
        end
    endcase
    end
end

/**
 * QRS window search enable logic
 */
always @ (posedge i_clk)begin
    if (!i_nrst)
        o_qrs_search_en <= 1'b0;
    else begin
        case (state)
        RUN:        o_qrs_search_en <= 1'b1;
        ALG_UPDATE_1: o_qrs_search_en <= 1'b1; //????????
        default:    o_qrs_search_en <= 1'b0;
        endcase
    end
end


function logic init_period_elapsed();
    return i_ctr >= ctr_init_target;
endfunction


function logic [DATA_WIDTH-1:0] update_th(  input logic [DATA_WIDTH-1:0] qrs_threshold,
                                            input logic [DATA_WIDTH-1:0] abs_diff_short_max );
    return (qrs_threshold - (qrs_threshold >> 5)) +  ((abs_diff_short_max >>5) >> 1);
endfunction


function logic [DATA_WIDTH-1:0] calc_rr_period( input logic [CTR_WIDTH-1:0] r_peak_sample_num_prev,
                                                input logic [CTR_WIDTH-1:0] r_peak_sample_num,
                                                input logic [DATA_WIDTH-1:0] rr_period );
    return r_peak_sample_num_prev ? (r_peak_sample_num - r_peak_sample_num_prev) : rr_period;
endfunction

endmodule
