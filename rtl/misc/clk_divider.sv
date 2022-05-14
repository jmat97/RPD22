`timescale 1ns / 1ns
/******************************************************************************
 * (C) Copyright 2016 AGH UST All Rights Reserved
 *******************************************************************************/
module clk_divider #(  
    parameter   I_FREQ = 100_000_000,
    parameter   O_FREQ  = 100
    )(
        input   logic   i_clk,      // input clock
        input   logic   i_nrst,     // async reset active low
        output  logic   o_clk_div   // output clock
    );

    // when the counter should restart from zero
    localparam LOOP_COUNTER_AT = (I_FREQ/ O_FREQ) / 2 ;

    logic [$clog2(LOOP_COUNTER_AT)-1:0] count;

    always @( posedge(i_clk), negedge(i_nrst) )
    begin

        if(!i_nrst)
        begin : counter_reset
            count       <= '0;
            o_clk_div   <= 1'b0;
        end

        else
        begin : counter_operate

            if (count == (LOOP_COUNTER_AT - 1))
            begin : counter_loop
                count       <=  0;
                o_clk_div   <=  ~o_clk_div;
            end

            else
            begin : counter_increment
                count       <= count + 1;
                o_clk_div     <= o_clk_div;
            end

        end
    end

endmodule
