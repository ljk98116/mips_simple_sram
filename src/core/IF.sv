`timescale 1ns/1ps

`include "../../include/global.svh"
`include "../../include/config.svh"
`include "../../include/exception.svh"

module IF(
    input clk,
    input rst,
    input stall_if,
    //exception input
    input exception_flag,
    input [`ADDR_BUS] exc_pc,
    //branch input
    input id_br_flag,
    input [`ADDR_BUS] id_br_addr,
    input ex_br_flag,
    input [`ADDR_BUS] ex_br_addr,
    //output
    output rom_en_o,
    output reg [`ADDR_BUS] pc,
    output reg [`DATA_BUS] exception_type_o
);
    reg rom_en;
    assign rom_en_o = rom_en && ~stall_if;

    always_ff @(posedge clk) begin
        rom_en <= rst;
    end

    always_ff @(posedge clk) begin
        casez ({rom_en,exception_flag,stall_if,ex_br_flag,id_br_flag})
            5'b0????:pc <= `INIT_PC;
            5'b11???:pc <= exc_pc;
            5'b101??:pc <= pc;
            5'b1001?:pc <= ex_br_addr;
            5'b10001:pc <= id_br_addr;
            5'b10000:pc <= pc + 4;
        endcase
    end
    
    always_comb begin
        if(!rst) begin
            exception_type_o <= 0;
        end
        else begin
            exception_type_o <= 0;
            exception_type_o[`EXE_AdEl] <= pc[1:0] != 2'b0;
        end
    end
    
endmodule