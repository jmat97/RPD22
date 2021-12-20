`timescale 1ns / 1ps

module	alg_fsm #(
        parameter DATA_WIDTH = 11,
        parameter CTR_WIDTH = 24
    ) (
        input	logic                               i_clk,
        input	logic                               i_nrst,
        input	logic                               i_ce,
        input   logic [CTR_WIDTH-1:0]               i_ctr,
        input	logic signed [DATA_WIDTH-1:0]       i_abs_diff_short_max,
        input   logic                               i_abs_diff_short_valid,
        input   logic                               i_extremum_found,
        output	logic                               o_qrs_search_en,
        output  logic [DATA_WIDTH-1:0]              o_rr_period,
        output  logic [CTR_WIDTH-1:0]               o_r_peak_sample_num,
        output  logic [DATA_WIDTH-1:0]              o_qrs_threshold
	);

/**
 * Local variables and signals
 */
    typedef enum logic [2:0] {INIT, ALG_INIT, TH_INIT, RUN, ALG_UPDATE_1, ALG_UPDATE_2} state_t;
    state_t state, state_nxt;

    logic signed [DATA_WIDTH-1:0]qrs_threshold_prv;
    logic init_period_active, th_initialised, th_updated, init_ctr_start, rr_period_updated, r_peak_sample_updated;

    logic [CTR_WIDTH-1:0] r_peak_sample_num_prev, r_peak_sample_num;

/**
 * Signals assignments
 */
    assign o_r_peak_sample_num = r_peak_sample_num;

/**
 * Submodules placement
 */
    counter_fsm #(
    .MAX_VAL (360*3),
    .MAX_VAL_SIZE(11)
    ) init_counter (
    .i_clk(i_clk),
    .i_nrst(i_nrst),
    .i_ce(i_ce),
    .i_start(init_ctr_start),
    .o_active(init_period_active)
);

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
            ALG_INIT:       state_nxt = !init_period_active ? TH_INIT : ALG_INIT;
            TH_INIT :       state_nxt = !th_initialised ? TH_INIT : RUN;
            RUN:            state_nxt = i_extremum_found ? ALG_UPDATE_1 : RUN;
            ALG_UPDATE_1:   state_nxt = ALG_UPDATE_2;
            ALG_UPDATE_2:   state_nxt = rr_period_updated & th_updated ? RUN : ALG_UPDATE_2;
        endcase
    end

/**
 * QRS threshold logic
 */
    always @ (posedge i_clk)begin
        if (!i_nrst) begin
            qrs_threshold_prv <= 0;
            o_qrs_threshold <= 0;
            th_initialised <= 1'b0;
        end
        else begin
        case (state)
            INIT : begin
                qrs_threshold_prv <= 0;
                o_qrs_threshold <= 0;
                th_initialised <= 1'b0;
                th_updated <= 1'b0;
            end
            TH_INIT : begin
                qrs_threshold_prv <= 0;
                o_qrs_threshold <= i_abs_diff_short_max >> 1;
                th_initialised <= 1'b1;
                th_updated <= 1'b0;
            end
            ALG_UPDATE_1 : begin
                qrs_threshold_prv <= o_qrs_threshold;
                o_qrs_threshold <= (qrs_threshold_prv - (qrs_threshold_prv >> 5)) + ( (i_abs_diff_short_max >>5) >> 1);
                th_initialised <= th_initialised;
                th_updated <= 1'b0;
            end
            ALG_UPDATE_2 : begin
                qrs_threshold_prv <= qrs_threshold_prv;
                o_qrs_threshold <= o_qrs_threshold;
                th_initialised <= th_initialised;
                th_updated <= 1'b1;
            end
            default : begin
                qrs_threshold_prv <= qrs_threshold_prv;
                o_qrs_threshold <= o_qrs_threshold;
                th_initialised <= th_initialised;
                th_updated <= 1'b0;
                end
        endcase
        end
    end

/**
 * Initialisation counter control
 */
    always @ (posedge i_clk)begin
        if (!i_nrst)
            init_ctr_start <= 0;
        else begin
        case (state)
        INIT:       init_ctr_start <= 1;
        default:    init_ctr_start <= 0;
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
                rr_period_updated <= 1'b0;
        end
        else begin
        case (state)
        ALG_UPDATE_1 : begin
            r_peak_sample_num_prev <= r_peak_sample_num;
            r_peak_sample_num <= i_ctr;
            o_rr_period <= o_rr_period;
            r_peak_sample_updated <= 1'b1;
            rr_period_updated <= 1'b0;
        end
        ALG_UPDATE_2 : begin
            r_peak_sample_num_prev <= r_peak_sample_num_prev;
            r_peak_sample_num <= r_peak_sample_num;
            o_rr_period <= r_peak_sample_num_prev ? (r_peak_sample_num - r_peak_sample_num_prev) : o_rr_period;
            r_peak_sample_updated <= 1'b0;
            rr_period_updated <= 1'b1;
        end
        default : begin
            r_peak_sample_num_prev <= r_peak_sample_num_prev;
            r_peak_sample_num <= r_peak_sample_num;
            o_rr_period <= o_rr_period;
            r_peak_sample_updated <= 1'b0;
            rr_period_updated <= 1'b0;
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

endmodule
