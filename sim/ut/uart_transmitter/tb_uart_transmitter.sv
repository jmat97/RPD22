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

module tb_uart_transmitter ();


/**
 * Local variables and signals
 */

logic       clk, rst_n;
logic       tx_data_valid, busy, sout;
logic [7:0] tx_data;
logic       sck_rising_edge, sck;
logic       en, clk_divider_valid;
logic [7:0] clk_divider;

logic [7:0] test_vectors [$];
logic [7:0] dividers [$];


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
    .sin(),
    .en,
    .clk_divider_valid,
    .clk_divider,
    .tx_data_valid,
    .tx_data,
    .clk,
    .rst_n,
    .sout,
    .sck,
    .sck_rising_edge,
    .transmitter_busy(busy),
    .receiver_busy(),
    .rx_data_valid(),
    .rx_data(),
    .rx_error()
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
    .en,
    .clk_divider_valid,
    .clk_divider
);

uart_transmitter u_uart_transmitter (
    .busy,
    .sout,
    .clk,
    .rst_n,
    .sck_rising_edge,
    .tx_data_valid,
    .tx_data
);


/**
 * Tasks and functions definitions
 */

task dividers_init();
    dividers.push_back(8'h01);
    dividers.push_back(8'hff);
    for (int i = 0; i < 10; ++i)
        dividers.push_back($urandom_range(1, 255));
endtask

task test_vectors_init();
    test_vectors.push_back(8'h00);
    test_vectors.push_back(8'hff);
    for (int i = 0; i < 10; ++i)
        test_vectors.push_back($urandom);
endtask

task test_receiving_from_uart();
    input int divider;
    input logic [7:0] data;
begin
    logic [7:0] received_data;

    u_uart_if.receive_data_from_uart(received_data, data);

    assert (received_data == data) else
        $error("divider: %x, received_data: rcv: %x, exp: %x", divider, received_data, data);
end
endtask


/**
 * Test
 */

initial begin
    test_vectors_init();
    dividers_init();
    u_rst_if.init();

    fork
        u_uart_if.init();
        u_rst_if.reset();
    join

    foreach (dividers[i]) begin
        u_uart_if.set_divider(dividers[i]);

        foreach (test_vectors[j])
            test_receiving_from_uart(dividers[i], test_vectors[j]);
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
