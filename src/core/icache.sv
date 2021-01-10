`timescale 1ns/1ps

`include "../../include/global.svh"

module icache(
    input rst,
    input flush,
    input [`ADDR_BUS] pc_i,
    input [`DATA_BUS] inst_i,
    output [`ADDR_BUS] pc_o,
    output [`DATA_BUS] inst_o
);
    assign pc_o = rst && ~flush ? pc_i : 0;
    assign inst_o = rst && ~flush ? inst_i : 0;
    
endmodule