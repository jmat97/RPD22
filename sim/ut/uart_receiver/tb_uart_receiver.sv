/**
 * Copyright (C) 2020  AGH University of Science and Technology
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

module tb_uart_receiver ();


/**
 * Local variables and signals
 */

logic       clk, rst_n;
logic       busy, error;
logic [7:0] rx_data;
logic       sin;
logic       sck_rising_edge, sck;
logic       en, rx_data_valid;

logic [7:0] test_vectors [$];


/**
 * Interfaces instantiation
 */

clk_if u_clk_if (
    .clk
);

rst_if u_rst_if (
    .rst_n,
    .clk
);

uart_if u_uart_if (
    .sin,
    .tx_data_valid(),
    .tx_data(),
    .clk,
    .rst_n,
    .sout(),
    .sck,
    .sck_rising_edge,
    .tx_busy(),
    .rx_busy(busy),
    .rx_data_valid,
    .rx_data,
    .rx_error(error)
);


/**
 * Submodules placement
 */

serial_clock_generator u_serial_clock_generator (
    .sck,
    .rising_edge(sck_rising_edge),
    .falling_edge(),
    .clk,
    .rst_n,
    .en(1'b1)
);

uart_receiver u_uart_receiver (
    .busy,
    .rx_data_valid,
    .rx_data,
    .error,
    .clk,
    .rst_n,
    .sck_rising_edge,
    .sin
);


/**
 * Tasks and functions definitions
 */

task test_vectors_init();
    test_vectors.push_back(8'h00);
    test_vectors.push_back(8'hff);
    for (int i = 0; i < 10; ++i)
        test_vectors.push_back($urandom);
endtask

task test_sending_to_uart();
    input logic [7:0] data;
begin
    logic [7:0] received_data;

    if (busy)
        @(negedge busy) ;

    u_uart_if.send_data_to_uart(received_data, data);

    assert (received_data == data) else
        $error("received_data: rcv: %x, exp: %x", received_data, data);
end
endtask

task test_receiving_from_uart();
    input logic [7:0] data;
begin
    logic [7:0] received_data;

    if (busy)
        @(negedge busy) ;

    u_uart_if.send_data_to_uart(received_data, data);

    assert (received_data == data) else
        $error("received_data: rcv: %x, exp: %x", received_data, data);
end
endtask

/**
 * Test
 */

initial begin
    test_vectors_init();
    u_rst_if.init();

    fork
        u_uart_if.init();
        u_rst_if.reset();
    join

    foreach (test_vectors[j]) begin
        test_sending_to_uart(test_vectors[j]);
    end

    $finish;
end


/**
 * Clock generation
 */

initial begin
    u_clk_if.init();
    u_clk_if.run();
end

endmodule
