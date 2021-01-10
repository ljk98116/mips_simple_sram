`timescale 1ns/1ps

`include "../include/global.svh"

module mycpu_sram(
    input clk,
    input rst,
    output tmp
);
//wires
wire cpu_clk;

//rom
wire rom_en;
wire [`ADDR_BUS] rom_addr;
wire [`DATA_BUS] rom_rdata;

//ram
wire ram_en;
wire [`ADDR_BUS] ram_addr;
wire [3:0] ram_sel;
wire [`DATA_BUS] ram_rdata;
wire [`DATA_BUS] ram_wdata;

wire [`ADDR_BUS] debug_write_pc;
wire reg_write_en;
wire [`REG_ADDR] reg_write_addr;
wire [`DATA_BUS] reg_write_data;

assign tmp = reg_write_en;

core u_core(
    cpu_clk,rst,6'b0,
    `ifndef CACHE_ENABLE
        rom_en,
        rom_addr,
        rom_rdata,
        //ram
        ram_en,
        ram_sel,
        ram_addr,
        ram_wdata,
        ram_rdata,        
    `endif
    debug_write_pc,
    reg_write_en,
    reg_write_addr,
    reg_write_data
);

inst_rom u_rom(
    cpu_clk,
    rst,
    //rom
    rom_en,
    rom_addr,
    rom_rdata
);

pll u_pll(
    cpu_clk,
    clk
);

data_sram u_ram(
    cpu_clk,
    ram_en,
    ram_sel,
    ram_addr[15:0],
    ram_wdata,
    ram_rdata
);

endmodule