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
    #1000 nrst  <= 1'b1;
    //#10 ce    <= 1'b1;
end

always #(CLOCK_PERIOD/2) clk = ~clk;

always @ (posedge clk) begin
    sample_counter++;
    if (sample_counter == NR_OF_SAMPLES)
    $finish;
end

mitbih_read #(
    .PATH(PATH),
    .LENGTH(NR_OF_SAMPLES),
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH)
    )
    mitbih_read_inst(
    .clk(clk),
    .nrst(nrst),
    .signal_req(mitbih_data_req),
    .signal_out(mitbih_data),
    .signal_valid(sig_valid)
    //.counter(ctr)
);



assign sample_in  = mitbih_data[DATA_WIDTH-1] ? mitbih_data[DATA_WIDTH-2:0] : mitbih_data - DATA_OFFSET;

alg_core #(
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH),
    .DATA_OFFSET(DATA_OFFSET),
    .N_SHORT(N_SHORT),
    .N_LONG(N_LONG)
    )
    alg_core_inst(
    .clk(clk),
    .nrst(nrst),
    .ce(ce),
    .ecg_value(sample_in),
    .ext_data_req(mitbih_data_req),
    .ext_data_valid(sig_valid),
    .rr_period(rr_period),
    .rr_period_updated(rr_period_updated),
    .r_peak_sample_num(r_peak_sample_num)
);

endmodule
