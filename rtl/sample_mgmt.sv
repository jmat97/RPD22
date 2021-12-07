`timescale 1ns / 1ps
//`default_nettype	none

module	sample_mgmt #(
        parameter DATA_WIDTH = 11,
        parameter CTR_WIDTH = 24
	) (
		input	logic	i_clk,	
		input	logic	i_nrst,
		input	logic	i_ce,
        input   logic   i_new_record,
        input   logic   i_signal_valid,
        output  logic [CTR_WIDTH-1:0] ctr
	);


always @ (posedge i_clk) begin
    if((!i_nrst) | (i_nrst && i_new_record)) begin
        ctr <= 0;
    end
    else if (i_signal_valid) begin
        ctr <= ctr+1;
    end
end


endmodule