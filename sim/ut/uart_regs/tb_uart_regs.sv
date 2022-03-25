`timescale 1ns / 1ps

module tb_uart_regs();


logic   clk, rst_n;
logic   rd_req,
        wr_req,
        mas_valid,
        mal_valid,
        th_inited,
        alg_active,
        tx_fifo_e,
        tx_fifo_f,
        rx_fifo_e,
        rx_fifo_f,
        alg_rst,
        alg_en,
        src_sel,
        ecg_value_vld;
logic [2:0] rw_addr;
logic [7:0] write_data, read_data;
logic [10:0] rr_period, ecg_value;


rst_if u_rst_if(
    .clk(clk),
    .rst_n(rst_n)
);

clk_if u_clk_if(
    .clk(clk)
);


uart_regs u_uart_regs(
    .i_clk(clk),
    .i_rst_n(rst_n),
    .i_rwaddr(rw_addr),
    .i_write_data(write_data),
    .i_rr_period(rr_period),
    .i_rd_req(rd_req),
    .i_wr_req(wr_req),
    .i_mas_valid(mas_valid),
    .i_mal_valid(mal_valid),
    .i_th_inited(th_inited),
    .i_alg_active(alg_active),
    .i_tx_fifo_e(tx_fifo_e),
    .i_tx_fifo_f(tx_fifo_f),
    .i_rx_fifo_e(rx_fifo_e),
    .i_rx_fifo_f(rx_fifo_f),
    .o_read_data(read_data),
    .o_ecg_value(ecg_value),
    .o_ecg_value_vld(ecg_value_vld),
    .o_alg_rst(alg_rst),
    .o_alg_en(alg_en),
    .o_src_sel(src_sel)
);

initial begin
    u_clk_if.init();
    u_clk_if.run();
end


initial begin
    $assertoff;
    u_rst_if.init();
    u_rst_if.reset();
    apply_data();
    $asserton;
    #200;
    write_reg(UART_CR_OFFSET, 8'hAA);
    #20;
    read_reg(UART_DOUTL_OFFSET);
    #40;
    write_reg(UART_DINL_OFFSET, 8'hFF);
    #20;
    write_reg(UART_DINH_OFFSET, 8'h07);
    #20;
    $display("nice");
    $finish;

end

task write_reg(input logic [2:0] w_addr, input logic [7:0] w_data);
    @ (posedge clk) begin
        rw_addr <= w_addr;
        write_data <= w_data;
        wr_req <= 1'b1;

    end
    @ (posedge clk) begin
        wr_req <= 1'b0;
    end
endtask

task read_reg(input logic [2:0] r_addr);
    @ (posedge clk) begin
        rw_addr <= r_addr;
        rd_req <= 1'b1;
    end
    @ (posedge clk) begin
        rd_req <= 1'b0;
        $display("read reg = %d",read_data);
    end
endtask

task apply_data();
    rr_period = 11'h7FF;
    mas_valid = 0;
    mal_valid = 1;
    th_inited = 0;
    alg_active = 0;
    tx_fifo_e = 1;
    tx_fifo_f = 0;
    rx_fifo_e = 0;
    rx_fifo_f = 1;
endtask

endmodule
