`timescale 1ns / 1ps

module tb_alg_core();

parameter CLOCK_PERIOD = 10; // in ns
parameter NR_OF_SAMPLES = 650000;
parameter PATH = "100.csv";
parameter DATA_WIDTH = 11;
parameter CTR_WIDTH = 22;
parameter DATA_OFFSET = 1024;

//Algorithm parameters
parameter N_SHORT = 16;
parameter N_LONG  = 32;

logic clk = 1'b0;
logic nrst = 1'b0, ce =1'b1;
logic sig_valid, mitbih_data_req;
int sample_counter = 0;
logic [CTR_WIDTH-1:0] ctr = 0;
logic [CTR_WIDTH-1:0] r_peak_sample_num;

logic [DATA_WIDTH-1:0] mitbih_data, rr_period;
logic rr_period_updated;
logic signed [DATA_WIDTH-1:0] sample_in;


initial begin
    #10 nrst  <= 1'b1;
    //#10 ce    <= 1'b1;
end

always #(CLOCK_PERIOD/2) clk = ~clk;



mitbih_read #(
    .PATH(PATH),
    .LENGTH(NR_OF_SAMPLES),
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH)
    )
    mitbih_read_inst(
    .clk(clk),
    .nrst(nrst),
    .counter(),
    .signal_req(!fifo_full),
    .signal_out(din_fifo_wdata),
    .signal_valid(din_fifo_push)
);

fifo #(
    .SIZE(NR_OF_SAMPLES),
    .WIDTH(DATA_WIDTH)
) u_fifo (
    .clk(clk),
    .rst_n(nrst),
    .full(fifo_full),
    .empty(din_fifo_empty),
    .rdata(din_fifo_rdata),
    .rdata_valid(din_fifo_rdata_valid),
    .push(din_fifo_push),
    .pop(din_fifo_req),
    .wdata(din_fifo_wdata)
);


logic din_fifo_full, din_fifo_empty, din_fifo_push, din_fifo_rdata_valid, din_fifo_data_req;
logic [DATA_WIDTH-1:0] din_fifo_wdata, din_fifo_rdata;
logic [DATA_WIDTH-1:0] ecg_signal;
logic ecg_signal_valid;

sample_mgmt #(
        .DATA_WIDTH(DATA_WIDTH),
        .CTR_WIDTH(CTR_WIDTH)
    )
    sample_mgmt_inst (
        .i_clk(clk),
        .i_nrst(nrst),
        .i_clk_adc_convst('0),
        .i_ecg_src(ECG_SRC_UART),
        .i_new_record('0),
        /* FIFO */
        .o_fifo_req(din_fifo_req),
        .i_fifo_data(din_fifo_rdata),
        .i_fifo_empty(din_fifo_empty),
        .i_fifo_rd_valid(din_fifo_rdata_valid),
        /* ADC */
        .o_adc_convst(),
        .i_adc_data('0),
        .i_adc_busy('0),
        .i_adc_rd_valid('0),

        .o_ecg_signal(ecg_signal),
        .o_ecg_signal_valid(ecg_signal_valid),
        .o_ctr(ctr)
    );



alg_core #(
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH),
    .DATA_OFFSET(DATA_OFFSET),
    .NAVG_SHORT(N_SHORT),
    .NAVG_LONG(N_LONG)
    )
    alg_core_inst(
    .i_clk(clk),
    .i_nrst(nrst),
    .i_ce(ce),
    .i_ecg_signal(ecg_signal),
    .i_ecg_signal_valid(ecg_signal_valid),
    .o_rr_period(rr_period),
    .o_rr_period_updated(rr_period_updated),
    .o_rpeak_location(r_peak_sample_num),
    .i_ctr(ctr),
    .o_ma_long_valid(),
    .o_ma_short_valid(),
    .o_th_initialised(),
    .o_alg_active()

);


endmodule
