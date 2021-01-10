`timescale 1ns/1ps

`define INSTNUMSIZE 256
`define INSTLOG2 8

module inst_rom (
    input clk,
    input rst,
    input rom_en,
    input [31:0] rom_addr,
    output reg [31:0] rom_data
);

    reg [31:0] rom[0:`INSTNUMSIZE-1];

    initial begin
        $readmemh("E:/mips_simple/soft/inst_rom.coe",rom);
    end

    always_ff @(posedge clk) begin
        if(!rst) begin
            rom_data <= 0;
        end
        else if( rom_en )begin
            rom_data <= rom[rom_addr[`INSTLOG2+1:2]];
        end
    end

endmodule