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

interface ram_if (
    output logic        req,
    output logic [31:0] addr,
    output logic        we,
    output logic [3:0]  be,
    output logic [31:0] wdata,
    input logic         clk,
    input logic [31:0]  rdata
);


/**
 * Tasks and functions definitions
 */

function void init();
    req = 1'b0;
    addr = 32'h0;
    we = 1'b0;
    be = 4'b0;
    wdata = 32'h0;
endfunction

task read();
    output logic [31:0] data;
    input logic [31:0] address;
begin
    @(negedge clk) ;
    req = 1'b1;
    addr = address;
    we = 1'b0;
    be = 4'hF;

    @(negedge clk) ;
    req = 1'b0;
    be = 4'h0;

    data = rdata;
end
endtask

task write();
    input logic [31:0] address;
    input logic [31:0] data;
begin
    @(negedge clk) ;
    req = 1'b1;
    addr = address;
    we = 1'b1;
    be = 4'hF;
    wdata = data;

    @(negedge clk) ;
    req = 1'b0;
    we = 1'b0;
    be = 4'h0;
end
endtask

task masked_write();
    input logic [31:0] address;
    input logic [31:0] data;
    input logic [3:0]  mask;
begin
    @(negedge clk) ;
    req = 1'b1;
    addr = address;
    we = 1'b1;
    be = mask;
    wdata = data;

    @(negedge clk) ;
    req = 1'b0;
    we = 1'b0;
    be = 4'h0;
end
endtask

endinterface
