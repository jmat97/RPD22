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

interface uart_if (
    output logic       sin,
    output logic       tx_data_valid,
    output logic [7:0] tx_data,
    input logic        clk,
    input logic        rst_n,
    input logic        sout,
    input logic        sck,
    input logic        sck_rising_edge,
    input logic        tx_busy,
    input logic        rx_busy,
    input logic        rx_data_valid,
    input logic [7:0]  rx_data,
    input logic        rx_error
);


/**
 * Tasks and functions definitions
 */

task init();
    @(negedge clk) ;
    @(negedge rst_n) ;
    sin = 1'b1;
    tx_data = 8'b0;
    tx_data_valid = 1'b0;
endtask


task send_bit_to_uart();
    input logic data;
begin
    sin = data;
    for (int i = 0; i < 16; ++i)
        @(posedge sck_rising_edge) ;
end
endtask

task send_frame_to_uart();
    input logic        start_bit;
    input logic [7:0]  data_to_send;
    input logic        stop_bit;
begin
    send_bit_to_uart(start_bit);
    for (int i = 0; i < 8; ++i)
        send_bit_to_uart(data_to_send[i]);
    send_bit_to_uart(stop_bit);
end
endtask

task send_data_to_uart();
    output logic [7:0] received_data;
    input logic [7:0]  data_to_send;
begin
    send_frame_to_uart(1'b0, data_to_send, 1'b1);
    received_data = rx_data;
end
endtask

task receive_bit_from_uart();
    output logic received_bit;
begin
    for (int i = 0; i < 16; ++i) begin
        @(posedge sck_rising_edge) ;
        if (i == 7)
            received_bit = sout;
    end
end
endtask

task receive_frame_from_uart();
    output logic       start_bit;
    output logic [7:0] data;
    output logic       stop_bit;
begin
    @(negedge sout) ;

    receive_bit_from_uart(start_bit);
    for (int i = 0; i < 8; ++i)
        receive_bit_from_uart(data[i]);
    receive_bit_from_uart(stop_bit);
end
endtask

task receive_data_from_uart();
    output logic [7:0] received_data;
    input logic [7:0]  data_to_send;
begin
    logic start_bit, stop_bit;

    if (tx_busy)
        @(negedge tx_busy) ;

    @(negedge clk) ;
    tx_data = data_to_send;
    tx_data_valid = 1'b1;

    @(negedge clk) ;
    tx_data_valid = 1'b0;

    receive_frame_from_uart(start_bit, received_data, stop_bit);
end
endtask

task send_data();
    input logic [7:0] data;
begin
    send_frame_to_uart(1'b0, data, 1'b1);
end
endtask

task receive_data();
    output logic [7:0] data;
begin
    logic start_bit, stop_bit;

    receive_frame_from_uart(start_bit, data, stop_bit);
end
endtask


/* API for system tests */

task read_byte();
    output byte data;
begin
    receive_data(data);
end
endtask

task read_word();
    output int data;
begin
    for (int i = 0; i < 4; ++i) begin
        data <<= 8;
        read_byte(data[7:0]);
    end
end
endtask

task read();
    output string message;
begin
    byte data;

    message = "";
    while (1) begin
        receive_data(data);
        if (data != "\n")
            message = {message, data};
        else
            break;
    end
end
endtask

task write_byte();
    input byte data;
begin
    send_frame_to_uart(1'b0, data, 1'b1);
end
endtask

task write_word();
    input int data;
begin
    for (int i = 0; i < 4; ++i) begin
        write_byte(data[7:0]);
        data >>= 8;
    end
end
endtask

task write();
    input string message;
begin
    message = {message, "\n"};
    foreach (message[i])
        write_byte(message[i]);
end
endtask

endinterface
