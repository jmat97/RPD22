`timescale 1ns / 1ps

module tb_top_core();

import uart_pkg::*;
import alg_pkg::*;

//parameter CLOCK_PERIOD = 100; // in ns
parameter NR_OF_SAMPLES = 650000;
parameter DATA_WIDTH = 11;
parameter CTR_WIDTH = 22;
parameter DATA_OFFSET = 1024;


//Uart related params
parameter BIT_PERIOD = 8625; //1/baudrate in ns

//Algorithm parameters
parameter N_SHORT = 16;
parameter N_LONG  = 32;

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


clk_if u_clk_if (
    .clk
);

rst_if u_rst_if (
    .rst_n,
    .clk
);

/*
always @ (posedge clk) begin
    sample_counter++;
    if (sample_counter == (NR_OF_SAMPLES+10))
    $finish;
end
*/
/*
mitbih_read #(
    .PATH(PATH),
    .LENGTH(NR_OF_SAMPLES),
    .DATA_WIDTH(DATA_WIDTH),
    .CTR_WIDTH(CTR_WIDTH)
    )
    mitbih_read_inst(
    .clk(clk),
    .nrst(nrst),
    .signal_req(1'b1),
    .signal_out(read_sample),
    .signal_valid()
);
*/

top_core u_top_core (
    .o_sout(sout),
    .i_sin(sin),
    .i_nrst(rst_n),
    .i_clk_100MHz(clk),
    .i_clk_36MHz(),
    .i_adc_data(),
    .i_adc_data_rdy(),
    .i_adc_busy(),
    .o_adc_convst(),
    .o_adc_en()
);



/**
 * Test
 */

initial begin
    byte read_byte;
    u_rst_if.init();
    u_rst_if.reset();
    sin <= 1'b1;

    send_ecg_value(mitbih_data);

    //read_reg(UART_SR_OFFSET, read_byte);
    #1000;
    $finish;
/*
    foreach (test_vectors[j]) begin
        //test_sending_to_uart(test_vectors[j]);
        test_receiving_from_uart(test_vectors[j]);
    end

    $finish;

    UART_CR_OFFSET =
UART_SR_OFFSET =
UART_DINL_OFFSET
UART_DINH_OFFSET
UART_DOUTL_OFFSET
UART_DOUTH_OFFSET
    */
end


/**
 * Clock generation
 */

initial begin
    u_clk_if.init();
    u_clk_if.run();
end

/**
 * Testbench tasks
 */

task send_ecg_value();
    input   logic [DATA_WIDTH-1:0]  ecg_value;
begin
    uart_sr_t status_reg;
    read_reg(UART_SR_OFFSET, status_reg);
    if( !status_reg.tx_fifo_full & !status_reg.rx_fifo_full ) begin
        write_reg(UART_DINL_OFFSET, ecg_value[7:0]);
        write_reg(UART_DINH_OFFSET, {5'b0, ecg_value[10:8]});
    end
end
endtask

task receive_r_peak_location();
    output logic [CTR_WIDTH-1:0] r_peak_location;
begin
    byte datal, datam, datah;
    uart_sr_t status_reg;

    read_reg(UART_SR_OFFSET, status_reg);
    if( !(status_reg.tx_fifo_empty) ) begin
        read_reg(UART_DOUTL_OFFSET, datal);
        read_reg(UART_DOUTM_OFFSET, datam);
        read_reg(UART_DOUTH_OFFSET, datah);
    end
    r_peak_location = {datah, datam, datal};
end
endtask

task write_reg();
    input   logic [2:0] waddr;
    input   byte        wdata;
begin
    send_byte_to_uart({4'b0,waddr,1'b1});
    #(10*BIT_PERIOD);
    send_byte_to_uart(wdata);
end
endtask

task read_reg();
    input   logic [2:0] raddr;
    output  byte        rdata;
begin
    send_byte_to_uart({4'b0,raddr,1'b0});
    read_byte_from_uart(rdata);
end
endtask


task send_bit_to_uart();
    input   logic   data_bit;
begin
    sin <= data_bit;
    #(BIT_PERIOD);
end
endtask

task read_bit_from_uart();
    output  logic   data_bit;
begin
    #(BIT_PERIOD/2);
    data_bit <= sout;
    #(BIT_PERIOD/2);
end
endtask

task send_byte_to_uart();
    input   byte    data;
begin
    send_bit_to_uart(1'b0);
    for (int i = 0; i < 8; ++i)
        send_bit_to_uart(data[i]);
    send_bit_to_uart(1'b1);

end
endtask

task read_byte_from_uart();
    output  byte    data;
begin
    logic start_bit, stop_bit;
    @(negedge sout);
    read_bit_from_uart(start_bit);
    for (int i = 0; i < 8; ++i)
        read_bit_from_uart(data[i]);
    read_bit_from_uart(stop_bit);
end
endtask

endmodule
