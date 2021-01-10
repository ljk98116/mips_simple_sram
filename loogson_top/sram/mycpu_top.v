`timescale 1ns/1ps

`include "../../include/global.svh"
`include "../../include/config.svh"

module mycpu_top(
    input clk,
    input resetn,
    input [5:0] ext_int,
    //inst sram
    output inst_sram_en,
    output [3:0] inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input [31:0] inst_sram_rdata,
    //data sram
    output data_sram_en,
    output [3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input [31:0] data_sram_rdata,
    //debug
    output [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
    wire debug_write_wen;
    wire [31:0] inst_sram_addr_b,data_sram_addr_b;
    assign inst_sram_wen = 0;
    assign inst_sram_wdata = 0;
    assign debug_wb_rf_wen = {4{debug_write_wen}};
    assign inst_sram_addr = inst_sram_addr_b[31:28] >= 4'hA ? inst_sram_addr_b - 32'hA000_0000 : inst_sram_addr_b - 32'h8000_0000;
    assign data_sram_addr = data_sram_addr_b[31:28] >= 4'hA ? data_sram_addr_b - 32'hA000_0000 : data_sram_addr_b - 32'h8000_0000;
    
    core sram_test(
        clk,resetn,
        ext_int,
        inst_sram_en,
        inst_sram_addr_b,
        inst_sram_rdata,
        data_sram_en,
        data_sram_wen,
        data_sram_addr_b,
        data_sram_wdata,
        data_sram_rdata,
        debug_wb_pc,
        debug_write_wen,
        debug_wb_rf_wnum,
        debug_wb_rf_wdata
    );

endmodule