`timescale 1ns / 1ps

module tb_alg_core();

parameter CLOCK_PERIOD = 10; // in ns
parameter NR_OF_SAMPLES = 650000;
// parameter recording_num = "100";
// parameter path = {recording_num,".csv"};
parameter DATA_WIDTH = 11;
parameter CTR_WIDTH = 22;
parameter DATA_OFFSET = 1024;
parameter RECORDING_COUNT = 48;
//Algorithm parameters
parameter N_SHORT = 16;
parameter N_LONG  = 32;

logic clk = 1'b0;
logic nrst = 1'b0, ce =1'b1;
logic sig_valid, mitbih_data_req;
int sample_counter = 0;
logic [CTR_WIDTH-1:0] ctr = 0;
logic [CTR_WIDTH-1:0] r_peak_sample_num, r_peak_count, rr_period;

logic [DATA_WIDTH-1:0] mitbih_data;
logic rr_period_updated;
logic signed [DATA_WIDTH-1:0] sample_in;
logic alg_done = 1'b0, new_rpeak = 1'b0;

string recordings [RECORDING_COUNT] = {"100", "101", "102", "103", "104", "105", "106", "107", "108", "109", "111", "112", "113", "114", "115", "116", "117", "118", "119", "121", "122", "123", "124", "200", "201", "202", "203", "205", "207", "208", "209", "210", "212", "213", "214", "215", "217", "219", "220", "221", "222", "223", "228", "230", "231", "232", "233", "234"};
string recording_num = "100";
string path = {recording_num, ".csv"};

initial begin
    r_peak_count = '0;
    for (int i = 0; i<RECORDING_COUNT; i++) begin
        recording_num = recordings [i];
        path = {recording_num, ".csv"};
        #10 nrst  = 1'b0;
        #50 nrst  = 1'b1;
        $display("Current recording start: %s",path);
        write_to_file(recording_num);
        $display("stop");
    end

    $finish;

end

always #(CLOCK_PERIOD/2) clk = ~clk;

always @(posedge rr_period_updated) begin
    //$display(r_peak_sample_num);
    new_rpeak = 1'b1;
end

task write_to_file(string recording_num);
    int fd;
    string filename = {"../../../../../results/",recording_num,".txt"};
    fd = $fopen(filename, "wb");
    if (fd == 0) begin
        $finish;
    end
    while (1) begin
        @(posedge rr_period_updated, posedge alg_done) begin
            if (alg_done) begin
                break;
            end
            $fwrite(fd,"%d,%d\x0d\n",r_peak_count,r_peak_sample_num);
            r_peak_count +=1;
            new_rpeak = 1'b0;
        end
    end
    r_peak_count = 0;
    alg_done = 0;
    $display("end of file writing block");
    $fclose(fd);
endtask



always @(posedge din_fifo_empty) begin
    if(ctr != 0 ) begin
        #1000 alg_done = 1'b1;
    end
end



mitbih_read #(
    .LENGTH(NR_OF_SAMPLES),
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH)
    )
    mitbih_read_inst(
    .path(path),
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
