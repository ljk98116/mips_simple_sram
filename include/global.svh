`ifndef _GLOBAL_
`define _GLOBAL_
    //debug
    `define DEBUG 
    //pc reg
    `define INIT_PC 32'hbfc00000

    //width
    `define ADDR_BUS 31:0
    `define DATA_BUS 31:0
    `define REG_ADDR 4:0
    `define DW_BUS 63:0
    `define CP0_ADDR 7:0

    //cache width
    `define CACHE_BLOCK 255:0
    `define CACHE_TAG 19:0
    `define CACHE_INDEX 6:0
    
    //for stall and flush
    `define IF 0
    `define ID 1
    `define RR 2
    `define EX 3
    `define MEM 4
    
    //hilo
    `define HI 63:32
    `define LO 31:0
    
`endif