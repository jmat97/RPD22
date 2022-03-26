`timescale 1ns / 1ps

module tb_command_manager();


logic   clk, rst_n;
logic   rd_req, wr_req, rx_data_valid, tx_data_valid;
logic [2:0] rwaddr;
logic [7:0] read_reg, rx_data, write_reg, tx_data;


rst_if u_rst_if(
    .clk(clk),
    .rst_n(rst_n)
);

clk_if u_clk_if(
    .clk(clk)
);


command_manager u_command_manager(
    .i_clk(clk),
    .i_rst_n(rst_n),
    .i_read_reg(read_reg),
    .i_rx_data(rx_data),
    .i_rx_data_valid(rx_data_valid),
    .o_write_reg(write_reg),
    .o_tx_data(tx_data),
    .o_tx_data_valid(tx_data_valid),
    .o_rwaddr(rwaddr),
    .o_rd_req(rd_req),
    .o_wr_req(wr_req)
);

initial begin
    u_clk_if.init();
    u_clk_if.run();
end


initial begin
    $assertoff;
    u_rst_if.init();
    u_rst_if.reset();
    rx_data_valid = 1'b0;
    read_reg= 8;

    $asserton;
    #200;
    transmit_command(0, UART_SR_OFFSET);
    receive_data();
    #200;
    transmit_command(1, UART_CR_OFFSET);
    transmit_data(8'hAA);
    #100;
    $display("nice");
    $finish;

end

task transmit_command(input logic rw, input logic[2:0]addr);
        transmit_data({4'b0000,addr,rw});
endtask

task transmit_data(input logic [7:0] data);
    @ (posedge clk) begin
        rx_data <= data;
        rx_data_valid <= 1'b1;
    end
    @ (posedge clk) begin
        rx_data_valid <= 1'b0;
    end
endtask

task receive_data();
    @ (posedge tx_data_valid) begin
        $display(tx_data);
    end
endtask

endmodule
