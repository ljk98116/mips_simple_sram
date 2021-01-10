`ifndef _EXCEPTION_
`define _EXCEPTION_
    //bitmap
    `define EXE_Int 7:0
    `define EXE_SYSCALL 8
    `define EXE_InstValid 9
    `define EXE_Trap 10
    `define EXE_OF 11
    `define EXE_Eret 12
    `define EXE_AdEl 13
    `define EXE_AdEs 14
    `define EXE_BREAK 15

    //exception type
    `define EX_Int 32'h0000_00FF
    `define EX_SYSCALL 32'h0000_0100
    `define EX_ERET 32'h0000_1000
    `define EX_BREAK 32'h0000_8000
    `define EX_OF 32'h0000_0800
    `define EX_AdEl 32'h0000_2000
    `define EX_AdEs 32'h0000_4000
    `define EX_InstValid 32'h0000_0200
`endif