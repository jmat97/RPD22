`timescale 1ns / 1ps
//`default_nettype    none

module    moving_avg #(
        parameter   DATA_WIDTH = 11,
        parameter   NAVG_LONG = 32,
        parameter   NAVG_LONG_WIDTH = $clog2(NAVG_LONG+1),
        parameter   NAVG_SHORT = 16,
        parameter   NAVG_SHORT_WIDTH = $clog2(NAVG_SHORT+1)
    ) (
        input   logic                           i_clk,
        input   logic                           i_nrst,
        input   logic                           i_ce,
        input   logic signed [DATA_WIDTH-1:0]   i_sample,
        input   logic                           i_sample_valid,
        output  logic signed [DATA_WIDTH-1:0]   o_sample,
        output  logic signed [DATA_WIDTH-1:0]   o_ma_long,
        output  logic signed [DATA_WIDTH-1:0]   o_ma_short,
        output  logic                           o_ma_long_valid,
        output  logic                           o_ma_short_valid
    );

/**
 * Local variables and signals
 */
logic full_long, full_short, a_full_long, a_full_short, delta_long_valid, delta_short_valid, acc_long_valid, acc_short_valid;
logic unsigned [NAVG_LONG_WIDTH-2:0]    rdaddr_long, rdaddr_short, wraddr;
logic signed [DATA_WIDTH-1:0]   mem [0:NAVG_LONG-1];
logic signed [DATA_WIDTH-1:0]   preval_long, memval_long, sample,
                                preval_short, memval_short,
                                sample_del1, sample_del2, sample_del3;
logic signed [DATA_WIDTH-1:0]   delta_long, delta_short;
logic signed [DATA_WIDTH+NAVG_LONG-1:0] acc_long;
logic signed [DATA_WIDTH+NAVG_SHORT-1:0] acc_short;

/**
 * Signals assignments
 */
assign sample = i_sample_valid ? i_sample : 0;

always @(posedge i_clk) begin
    if (!i_nrst) begin
        wraddr <= NAVG_LONG-1;
    end
    else if (i_ce) begin
        wraddr <= wraddr + 1'b1;
    end
end

always @(posedge i_clk) begin
    if (!i_nrst) begin
        rdaddr_long  <= 0;
        rdaddr_short <= NAVG_SHORT-1;
    end
    else if (i_ce) begin
        rdaddr_long <= rdaddr_long + 1'b1;
        rdaddr_short <= rdaddr_short + 1'b1;
    end
end

// Stage one
always @(posedge i_clk) begin
    if (!i_nrst) begin
        preval_long  <= 0;
        preval_short <= 0;
    end
    else if (i_ce & i_sample_valid) begin
        preval_long  <= sample;
        preval_short <= sample;
    end
end

always @(posedge i_clk) begin
    if (i_ce) begin
        mem[wraddr] <= sample;
    end
end

always @(posedge i_clk) begin
    if (i_ce) begin
        memval_long <= mem[rdaddr_long];
        memval_short <= mem[rdaddr_short];
    end
end

always @(posedge i_clk) begin
    if (!i_nrst) begin
        full_long <= 1'b0;
        full_short <= 1'b0;
        a_full_long <= 1'b0;
        a_full_short <= 1'b0;
    end
    else if (i_ce) begin
        a_full_long  <= (a_full_long)||(rdaddr_long==(NAVG_LONG-1));
        a_full_short <= (a_full_short)||(rdaddr_short==(NAVG_LONG-1));
        full_long  <= a_full_long;
        full_short <= a_full_short;
    end
end

// Stage two
always @(posedge i_clk) begin
    if (!i_nrst) begin
        delta_long <= 0;
        delta_long_valid <= 0;
    end
    else if (i_ce) begin
        if (full_long) begin
            delta_long <= preval_long - memval_long;
            delta_long_valid <= 1;
        end
        else begin
            delta_long <= 0;
            delta_long_valid <= 0;
        end
    end
end

always @(posedge i_clk) begin
    if (!i_nrst) begin
        delta_short <= 0;
        delta_short_valid <= 0;
    end
    else if (i_ce)begin
        if (full_short) begin
            delta_short <= preval_short - memval_short;
            delta_short_valid <= 1;
        end
        else begin
            delta_short <= 0;
            delta_short_valid <= 0;
        end
    end
end

// Stage three
always @(posedge i_clk) begin
    if (!i_nrst) begin
        acc_long <= 0;
        acc_long_valid <= 0;
    end
    else if (i_ce) begin
        if (delta_long_valid) begin
            acc_long  <=  (acc_long +  delta_long);
            acc_long_valid <= 1;
        end
        else begin
            acc_long  <=  0;
            acc_long_valid <= 0;
        end
    end
end

always @(posedge i_clk) begin
    if (!i_nrst) begin
        acc_short <= 0;
        acc_short_valid <= 0;
    end
    else if (i_ce) begin
        if (delta_short_valid) begin
            acc_short  <=  (acc_short +  delta_short);
            acc_short_valid <= 1;
        end
        else begin
            acc_short  <=  0;
            acc_short_valid <= 0;
        end
    end
end

// Stage four
always @(posedge i_clk) begin
    if (!i_nrst) begin
        o_ma_long <= 0;
        o_ma_long_valid <= 0;
    end
    else if (i_ce) begin
        if (acc_long_valid) begin
            o_ma_long <= acc_long >> (NAVG_LONG_WIDTH-1);
            o_ma_long_valid <= 1;
        end
        else begin
            o_ma_long <= 0;
            o_ma_long_valid <= 0;
        end
    end
end

always @(posedge i_clk) begin
    if (!i_nrst) begin
        o_ma_short <= 0;
        o_ma_short_valid <= 0;
    end
    else if (i_ce) begin
        if (acc_long_valid) begin
            o_ma_short <= acc_short >> (NAVG_SHORT_WIDTH-1);
            o_ma_short_valid <= 1;
        end
        else begin
            o_ma_short <= 0;
            o_ma_short_valid <= 0;
        end
    end
end

//Input signal delay
always @(posedge i_clk) begin
    if (!i_nrst) begin
        sample_del1 <= 0;
        sample_del2 <= 0;
        sample_del3 <= 0;
        o_sample    <= 0;
    end
    else if (i_ce) begin
        sample_del1 <= sample;
        sample_del2 <= sample_del1;
        sample_del3 <= sample_del2;
        o_sample    <= sample_del3;
    end
end

endmodule
