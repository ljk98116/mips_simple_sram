`ifndef _CONFIG_
`define _CONFIG_
    //`define CACHE_ENABLE
    `define FixedMapping_MMU

    //interrupts on
    `define INT_ON

    //config MT func
    `define NONE 3'b000
    `define TLB 3'b001
    `define BAT 3'b010
    `define FixedMapping 3'b011
    `define VPTLB 3'b100

    //config K0 func
    `define Cache_on 2'b11
    `define Cache_off 2'b10

`endif