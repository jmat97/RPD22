`timescale 1ns / 1ps

module tb_basys3_top_core();

import uart_pkg::*;
import alg_pkg::*;

`define EMULATE_UART

parameter CLOCK_PERIOD = 10; // in ns
parameter NR_OF_SAMPLES = 650000;
parameter DATA_WIDTH = 11;
parameter CTR_WIDTH = 22;
parameter DATA_OFFSET = 1024;


//Uart related params
parameter BIT_PERIOD = 8625; //1/baudrate in ns

//Algorithm parameters
parameter N_SHORT = 16;
parameter N_LONG  = 32;
parameter PATH = "100.csv";

logic clk;
logic rst_n, ce =1'b1;
logic sig_valid, mitbih_data_req;
int sample_counter = 0;
logic [CTR_WIDTH-1:0] ctr = 0;
logic [CTR_WIDTH-1:0] r_peak_sample_num;

logic [DATA_WIDTH-1:0] mitbih_data, rr_period, read_sample;
logic rr_period_updated;
logic signed [DATA_WIDTH-1:0] sample_in;

logic sin, sout;
logic clk_io;
logic [15:0]    led, sw;

rst_if u_rst_if (
    .rst_n,
    .clk(clk_io)
);

mitbih_read_to_mem #(
    .PATH(PATH),
    .LENGTH(NR_OF_SAMPLES),
    .DATA_WIDTH(DATA_WIDTH)
    )
    u_mitbih_read_to_mem();

top_rpd_basys_3 u_top_rpd_basys_3(
    .led,
    .sout,
    .sout_spy(),
    .clk_io,
    .sw,
    .btnC(1'b0),
    .sin,
    .sin_spy(),
    .xa4_n(),
    .xa4_p(),
    .sck_re(),
    .sck_spy()
);

/**
 * Test
 */

initial begin
    byte read_byte, datal, datam, datah;
    sin <= 1'b1;
    u_rst_if.init();
    u_rst_if.reset();
    u_top_rpd_basys_3.u_top_core.rx_data_valid = 1'b0;
    $display("post reset");
    //send_ecg_value(mitbih_data);
    #600;
    read_reg(UART_SR_OFFSET, read_byte);
    write_reg(CR,1<<1);

    //send_ecg_value(11'd1011);

    //$display("%x", read_byte);
    for (int i = 0; i < 650000; ++i) begin
        send_ecg_value(u_mitbih_read_to_mem.recording_file[i]);
        if(i % 25000 == 0) begin
            collect_dout();
        end
    end

    collect_dout();

    //send_ecg_value(2047);
    //read_reg(UART_SR_OFFSET, read_byte);
    //$display(read_byte);
    $finish;

end


/**
 * Clock generation
 */

initial begin
    clk_io = 1'b0;
    forever begin
        #5 clk_io <= ~clk_io;
    end
end


task send_ecg_value();
    input   logic [DATA_WIDTH-1:0]  ecg_value;
begin
    uart_sr_t status_reg;
    if( 1 ) begin
        write_reg(UART_DINL_OFFSET, ecg_value[7:0]);
        write_reg(UART_DINH_OFFSET, {5'b0, ecg_value[10:8]});
    end
end
endtask

task read_DOUT();
    output logic [CTR_WIDTH-1:0] r_peak_location;
begin
    byte datal, datam, datah;
    read_reg(UART_DOUTL_OFFSET, datal);
    read_reg(UART_DOUTM_OFFSET, datam);
    read_reg(UART_DOUTH_OFFSET, datah);
    r_peak_location = {datah, datam, datal};
end
endtask

task collect_dout();
    uart_sr_t sr;
    sample_num rpeak_location;
    read_reg(UART_SR_OFFSET, sr);
    while (sr.tx_fifo_empty == 0) begin
        read_DOUT(rpeak_location);
        read_reg(UART_SR_OFFSET, sr);
        if (sr.tx_fifo_empty) begin
            break;
        end
    end
endtask

task write_reg();
    input   logic [2:0] waddr;
    input   byte        wdata;
begin
    send_byte_to_uart({4'b0,waddr,1'b1});
    send_byte_to_uart(wdata);
end
endtask

task read_reg();
    input   logic [2:0] raddr;
    output  byte        rdata;
begin
    send_byte_to_uart({4'b0,raddr,1'b0});
    $display("addr sent ");
    read_byte_from_uart(rdata);
    $display("byte read ");
end
endtask

task send_byte_to_uart();
    input   byte    data;
    @(posedge clk_io)
    begin
        u_top_rpd_basys_3.u_top_core.rx_data_valid <= 1'b1;
        u_top_rpd_basys_3.u_top_core.rx_data <= data;
    end
    @(posedge clk_io)
    begin
        u_top_rpd_basys_3.u_top_core.rx_data_valid <= 1'b0;
        u_top_rpd_basys_3.u_top_core.rx_data <= data;
    end
endtask

task read_byte_from_uart();
    output  byte    data;
begin
    @(posedge u_top_rpd_basys_3.u_top_core.tx_data_valid);
    if(u_top_rpd_basys_3.u_top_core.tx_data_valid)
        data = u_top_rpd_basys_3.u_top_core.tx_data;
end
endtask

endmodule
