`ifndef _DECODE_
`define _DECODE_

//注释掉的为MIPS 1架构视作异常的指令

    //special_op
    `define OP_SPECIAL 6'b0
    `define OP_REGIMM  6'b000001
    `define OP_SPECIAL2 6'b011100
    `define OP_COP0 6'b010000
    `define OP_COP1 6'b010001

    //common op
    `define OP_ADDI 6'b001000
    `define OP_ADDIU 6'b001001
    `define OP_ANDI 6'b001100
    `define OP_LUI 6'b001111
    `define OP_SLTI 6'b001010
    `define OP_SLTIU 6'b001011
    `define OP_ORI 6'b001101
    `define OP_XORI 6'b001110

    //common branch op
    `define OP_BEQ 6'b000100
    //`define OP_BEQL 6'b010100
    `define OP_BGTZ 6'b000111
    //`define OP_BGTZL 6'b010111
    `define OP_BLEZ 6'b000110
    `define OP_BNE 6'b000101

    //common mem op
    `define OP_LB 6'b100000
    `define OP_LBU 6'b100100
    `define OP_LH 6'b100001
    `define OP_LHU 6'b100101
    `define OP_LW 6'b100011
    `define OP_SB 6'b101000
    `define OP_SH 6'b101001
    `define OP_SW 6'b101011
    
    //common jmp op
    `define OP_J 6'b000010
    `define OP_JAL 6'b000011
    
    //inst_funct
    //special
    `define FUNCT_ADD 6'b100000
    `define FUNCT_ADDU 6'b100001
    `define FUNCT_AND 6'b100100
    `define FUNCT_SUB 6'b100010
    `define FUNCT_SUBU 6'b100011
    `define FUNCT_SLT 6'b101010
    `define FUNCT_SLTU 6'b101011
    `define FUNCT_NOR 6'b100111
    `define FUNCT_OR 6'b100101
    `define FUNCT_XOR 6'b100110
    `define FUNCT_JR 6'b001000
    `define FUNCT_JALR 6'b001001
    `define FUNCT_SLLV 6'b000100
    `define FUNCT_SLL 6'b0
    `define FUNCT_SRAV 6'b000111
    `define FUNCT_SRA 6'b000011
    `define FUNCT_SRLV 6'b000110
    `define FUNCT_SRL 6'b000010
    //exception related
    `define FUNCT_SYSCALL 6'b001100
    `define FUNCT_BREAK 6'b001101
    
    //hilo
    `define FUNCT_DIV 6'b011010
    `define FUNCT_DIVU 6'b011011
    `define FUNCT_MULT 6'b011000
    `define FUNCT_MULTU 6'b011001
    `define FUNCT_MFHI 6'b010000
    `define FUNCT_MFLO 6'b010010
    `define FUNCT_MTHI 6'b010001
    `define FUNCT_MTLO 6'b010011
    
    //regimm func
    `define FUNCT_BGEZ 5'b00001
    `define FUNCT_BGEZAL 5'b10001
    //`define FUNCT_BGEZALL 5'b10011
    //`define FUNCT_BGEZL 5'b00011
    `define FUNCT_BLTZ 5'b00000
    `define FUNCT_BLTZAL 5'b10000

    //special2 func
    `define FUNCT_CLO 6'b100001
    `define FUNCT_CLZ 6'b100000
    
    //others
    `define FUNCT_ERET 6'b011000
`endif