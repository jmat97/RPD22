`timescale 1ns/1ps

module circular_buffer #(
	parameter DATA_WIDTH = 12,
	parameter ADDR_WIDTH = 4
	)(
	input [DATA_WIDTH - 1:0] buffer_in,
	input read,
	input write,
	input clk,
	input nrst,

	output reg [DATA_WIDTH - 1:0] buffer_out,
	output reg full,
	output reg empty,
	output logic wr_ack,
	output logic rd_ack
);

reg [DATA_WIDTH - 1:0] memory [0:ADDR_WIDTH - 1];

integer write_ptr;
integer read_ptr;

always @(posedge clk) begin
	if(!nrst) begin
		full <= 0;
		empty <= 0;
		write_ptr <= 0;
		read_ptr <= 0;
	end
end

always @(posedge clk) begin
	if(write) begin
		if(read_ptr == ((write_ptr + 1) % ADDR_WIDTH)) begin
			full <= 1'b1;
			wr_ack <= 1'b0;
		end
		else begin
			memory[write_ptr] <= buffer_in;
			write_ptr <= (write_ptr + 1)%(ADDR_WIDTH);
			full <= 1'b0;
			empty <= 1'b0;
			wr_ack <= 1'b1;
		end
	end
	else begin
		wr_ack <= 1'b0;
	end
end

always @(posedge clk) begin
	if(read) begin
		if ((write_ptr == read_ptr)) begin
			empty <= 1'b1;
			rd_ack <= 1'b0;
			buffer_out <= 'b0;
		end
		else begin
			buffer_out <= memory[read_ptr];
			read_ptr <= (read_ptr + 1)%(ADDR_WIDTH);
			full <= 1'b0;
			rd_ack <= 1'b0;
		end
	end
	else begin
		buffer_out <= buffer_out;
	end
end

endmodule
