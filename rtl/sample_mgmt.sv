`timescale 1ns / 1ps
//`default_nettype	none

import alg_pkg::*;

module	sample_mgmt #(
        parameter DATA_WIDTH = 11,
        parameter CTR_WIDTH = 24
    ) (
        input   logic                           i_clk,
        input   logic                           i_clk_adc_convst,
        input   logic                           i_nrst,
        input   ecg_src                         i_ecg_src,
        input   logic                           i_new_record,
        /* FIFO */
        output  logic                           o_fifo_req,
        input   logic [DATA_WIDTH-1:0]          i_fifo_data,
        input   logic                           i_fifo_empty,
        input   logic                           i_fifo_rd_valid,
        /* ADC */
        output  logic                           o_adc_convst,
        input   logic [DATA_WIDTH-1:0]          i_adc_data,
        input   logic                           i_adc_busy,
        input   logic                           i_adc_rd_valid,
        /* OUTPUT */
        output  logic signed [DATA_WIDTH-1:0]   o_ecg_signal,
        output  logic                           o_ecg_signal_valid,
        output  logic [CTR_WIDTH-1:0]           o_ctr
	);

/**
 * Local variables and signals
 */
typedef enum logic [2:0] {INIT, IDLE, SAMPLE_REQ, SAMPLE_WAIT, SAMPLE_VALID} state_t;
state_t state, state_nxt;
logic [CTR_WIDTH-1:0] ctr;
logic data_valid, data_req, adc_req, fifo_req, req_possible;
logic [DATA_WIDTH-1:0] ecg_signal;
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
    INIT:           state_nxt = IDLE;
    IDLE: begin
        if(i_new_record)
            state_nxt = INIT;
        else
            state_nxt = req_possible ? SAMPLE_REQ : IDLE;
    end
    SAMPLE_REQ:     state_nxt = SAMPLE_WAIT;
    SAMPLE_WAIT:    state_nxt = data_valid ? SAMPLE_VALID : SAMPLE_WAIT;
    SAMPLE_VALID:   state_nxt = IDLE;
    endcase
end

/**
 * State logic
 */
 /*
always_comb begin
    case(state)
    SAMPLE_VALID:   o_ecg_signal_valid = 1'b1;
    default:        o_ecg_signal_valid = 1'b0;
    endcase
end
*/
always_comb begin
    ctr = o_ctr;
    case(state)
    INIT:           ctr = '0;
    SAMPLE_VALID:   ctr = ctr+1;
    default:        ctr = ctr;
    endcase
end

always_comb begin
    case(state)
    SAMPLE_REQ:     data_req = 1'b1;
    default:        data_req = 1'b0;
    endcase
end

/**
 * Register logic
 */
always_ff @( posedge i_clk) begin
    if(!i_nrst) begin
        o_ctr <= '0;
        o_ecg_signal <= 'b0;
        o_ecg_signal_valid <= '0;
        o_adc_convst <= 1'b0;
        o_fifo_req <= 1'b0;
    end
    else begin
        o_ctr <= ctr;
        o_ecg_signal <= (state_nxt == SAMPLE_WAIT) ? ecg_signal : o_ecg_signal;
        o_ecg_signal_valid <= data_valid;
        o_adc_convst <= adc_req;
        o_fifo_req <= fifo_req;
    end
end


/**
 * Signal multiplexing
 */

always_comb begin
    case(i_ecg_src)
    ECG_SRC_ADC: begin
        adc_req = i_clk_adc_convst;
        fifo_req = fifo_req;
        ecg_signal = convert_to_signed(i_adc_data);
        req_possible = !i_adc_busy;
        data_valid = i_adc_rd_valid;
   end
    ECG_SRC_UART:   begin
        adc_req = adc_req;
        fifo_req  = data_req;
        ecg_signal = convert_to_signed(i_fifo_data);
        req_possible = !i_fifo_empty;
        data_valid = i_fifo_rd_valid;
    end
    default: begin
        adc_req = 1'b0;
        fifo_req  = 1'b0;
        ecg_signal = 'b0;;
        req_possible = 1'b0;
        data_valid = 1'b0;;
    end
    endcase
end

function logic signed [DATA_WIDTH-1:0] convert_to_signed(input logic  [DATA_WIDTH-1:0] input_data);
    return  input_data[DATA_WIDTH-1] ? input_data[DATA_WIDTH-2:0] : input_data - DATA_OFFSET;
endfunction


endmodule
