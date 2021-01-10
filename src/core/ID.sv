`timescale 1ns/1ps

//reg_ren -> reg_wen -> funct -> shamt ->
//reg_raddr -> reg_waddr ->imm_data
`include "../../include/global.svh"
`include "../../include/decode.svh"
`include "../../include/config.svh"
`include "../../include/exception.svh"
//inst 
`define OP 31:26
`define RS 25:21
`define RT 20:16
`define RD 15:11
`define SHAMT 10:6
`define FUNCT 5:0
`define IMM 15:0
`define SEL 2:0
/*
    mem_func
    10 -write 01-read
    the other 2 bits:
    01 = 1B
    10 = 2B
    11 = 4B
    others means invalid
*/
module ID(
    input clk,
    input rst,
    input stall,
    input [`DATA_BUS] exception_type_i,
    input flush,
    input [`ADDR_BUS] pc_i,
    input [`DATA_BUS] inst_i,
    //output pc
    output [`ADDR_BUS] pc_o,
    //inst decode res
    output reg reg_wen,
    output reg reg_ren_1,
    output reg reg_ren_2,

    output reg [`REG_ADDR] reg_waddr,
    output reg [`REG_ADDR] reg_raddr_1,
    output reg [`REG_ADDR] reg_raddr_2,
    
    output reg [`DATA_BUS] imm_data,
    output reg [`FUNCT] funct,
    output reg [4:0] shamt,
    output [5:0] inst_op,
    output [4:0] regimm_func,

    output reg [3:0] mem_func,
    output reg mem_imm_flag,
    output is_delay_slot,
    //jmp 
    output reg id_br_flag,
    output reg [`ADDR_BUS] id_br_addr,
    //hilo
    output reg hi_wen,
    output reg lo_wen,
    output reg hi_ren,
    output reg lo_ren,
    //cp0
    output reg cp0_ren,
    output reg [`CP0_ADDR] cp0_raddr,
    output reg cp0_wen,
    output reg [`CP0_ADDR] cp0_waddr,
    output reg [`DATA_BUS] exception_type
);
    reg instValid,sys_flag,eret_flag,break_flag;
    reg delay_slot;

    assign pc_o = rst & ~flush ? pc_i : 0;
    assign inst_op = rst & ~flush ? inst_i[31:26] : 0;
    assign regimm_func = rst & ~flush ? inst_i[`RT] : 0;
    assign is_delay_slot = rst & ~flush ? delay_slot : 0;

    always_ff @(posedge clk) begin
        if(!rst ||flush) begin
            delay_slot <= 0;
        end
        else if(!stall) begin
            case(inst_i[`OP])
                `OP_SPECIAL:begin
                    delay_slot <= inst_i[`FUNCT] == `FUNCT_JR || inst_i[`FUNCT] == `FUNCT_JALR;
                end
                `OP_BEQ,`OP_BNE,`OP_BGTZ,`OP_BLEZ,`OP_J,`OP_JAL:begin
                    delay_slot <= 1;
                end
                `OP_REGIMM:begin
                    case (inst_i[`RT])
                        `FUNCT_BGEZ,`FUNCT_BGEZAL,`FUNCT_BLTZ,`FUNCT_BLTZAL:begin
                            delay_slot <= 1;
                        end
                        default:delay_slot <= 0;
                    endcase
                end
                default:delay_slot <= 0;
            endcase
        end
    end

    //jmp
    always_comb begin
        if(!rst || flush) begin
            id_br_flag <= 0;
            id_br_addr <= 0;
        end
        else begin
            case(inst_i[`OP])
                `OP_JAL,`OP_J:begin
                    id_br_flag <= 1;
                    id_br_addr <= {pc_i[31:28],inst_i[25:0],2'b0};
                end
                default begin
                    id_br_flag <= 0;
                    id_br_addr <= 0;
                end
            endcase
        end
    end

    //reg_ren gen
    always_comb begin
        if(!rst || flush) begin
            reg_ren_1 <= 0;
            reg_ren_2 <= 0;
            instValid <= flush;
        end
        else begin
            case (inst_i[`OP])
                `OP_SPECIAL,`OP_SPECIAL2:begin
                    reg_ren_1 <= ~(inst_i[`RS] == 0 );
                    reg_ren_2 <= ~(inst_i[`RT] == 0 );
                    instValid <= 1;
                end
                `OP_REGIMM:begin
                    reg_ren_1 <= ~(inst_i[`RS] == 0);
                    reg_ren_2 <= 0;
                    instValid <= 1;
                end
                `OP_ADDI,`OP_ADDIU,`OP_LUI,
                `OP_ANDI,`OP_ORI,`OP_XORI,
                `OP_SLTI,`OP_SLTIU,
                `OP_BGTZ,`OP_BLEZ,
                `OP_LB,`OP_LBU,`OP_LH,`OP_LHU,`OP_LW:begin
                    reg_ren_1 <= ~(inst_i[`RS] == 0 );
                    reg_ren_2 <= 0;
                    instValid <= 1;
                end
                `OP_BEQ,`OP_BNE,
                `OP_SB,`OP_SH,`OP_SW:begin
                    reg_ren_1 <= 1;
                    reg_ren_2 <= 1;
                    instValid <= 1;
                end
                //mt
                `OP_COP0:begin
                    reg_ren_1 <= 0;
                    reg_ren_2 <= inst_i[23];
                    instValid <= 1;
                end
                default:begin
                    reg_ren_1 <= 0;
                    reg_ren_2 <= 0;
                    instValid <= inst_i[`OP] == `OP_J || inst_i[`OP] == `OP_JAL;
                end
            endcase
        end
    end

    //reg_wen gen
    always_comb begin
        if(!rst || flush) begin
            reg_wen <= 0;
        end
        else begin
            case (inst_i[`OP])
                `OP_SPECIAL,`OP_SPECIAL2:begin
                    reg_wen <= ~(inst_i[`RD] == 0);
                end
                `OP_ADDI,`OP_ADDIU,`OP_LUI,
                `OP_ANDI,`OP_ORI,`OP_XORI,
                `OP_SLTI,`OP_SLTIU,
                `OP_LB,`OP_LBU,`OP_LH,`OP_LHU,`OP_LW:begin
                    reg_wen <= ~(inst_i[`RT] == 0);                    
                end
                //the 25th bit is 1 means BLTZAL & BGEZAL
                `OP_REGIMM:begin
                    reg_wen <= inst_i[20];
                end
                `OP_JAL:begin
                    reg_wen <= 1;
                end
                //mf
                `OP_COP0:begin
                    reg_wen <= ~inst_i[23];
                end
                default:begin
                    reg_wen <= 0;
                end
            endcase
        end
    end

    //funct gen
    always_comb begin
        if(!rst || flush) begin
            funct <= 0;
        end
        else begin
            case(inst_i[`OP])
                `OP_SPECIAL,`OP_SPECIAL2:begin
                    funct <= inst_i[`FUNCT];
                end
                `OP_ADDI:begin
                    funct <= `FUNCT_ADD;
                end
                `OP_ADDIU,`OP_LUI,`OP_JAL,
                `OP_LB,`OP_LBU,`OP_LH,`OP_LHU,`OP_LW,
                `OP_SB,`OP_SH,`OP_SW:begin
                    funct <= `FUNCT_ADDU;
                end
                `OP_ANDI:begin
                    funct <= `FUNCT_AND;
                end
                `OP_SLTI:begin
                    funct <= `FUNCT_SLT;
                end
                `OP_SLTIU:begin
                    funct <= `FUNCT_SLTU;
                end
                `OP_ORI:begin
                    funct <= `FUNCT_OR;
                end
                `OP_XORI:begin
                    funct <= `FUNCT_XOR;
                end
                default:begin
                    funct <= 6'b111111;
                end
            endcase
        end
    end

    //shamt gen
    always_comb begin
        if(!rst || flush) begin
            shamt <= 0;
        end
        else begin
            case(inst_i[`OP])
                `OP_SPECIAL,`OP_SPECIAL2:begin
                    shamt <= inst_i[`SHAMT];
                end
                default:begin
                    shamt <= 0;
                end
            endcase
        end
    end

    //reg_raddr
    always_comb begin
        if(!rst || flush) begin
            reg_raddr_1 <= 0;
            reg_raddr_2 <= 0;
        end
        else begin
            case(inst_i[`OP])
                `OP_SPECIAL,`OP_SPECIAL2,
                `OP_BEQ,`OP_BNE,
                `OP_SB,`OP_SH,`OP_SW:begin
                    reg_raddr_1 <= inst_i[`RS];
                    reg_raddr_2 <= inst_i[`RT];
                end
                `OP_ADDI,`OP_ADDIU,`OP_LUI,
                `OP_REGIMM,
                `OP_ANDI,`OP_ORI,`OP_XORI,
                `OP_SLTI,`OP_SLTIU,
                `OP_BGTZ,`OP_BLEZ,
                `OP_LB,`OP_LBU,`OP_LH,`OP_LHU,`OP_LW:begin
                    reg_raddr_1 <= inst_i[`RS];
                    reg_raddr_2 <= 0;                    
                end
                //mt
                `OP_COP0:begin
                    reg_raddr_1 <= 0;
                    reg_raddr_2 <= inst_i[`RT];
                end
                default:begin
                    reg_raddr_1 <= 0;
                    reg_raddr_2 <= 0;
                end
            endcase
        end
    end

    //reg_waddr
    always_comb begin
        if(!rst || flush) begin
            reg_waddr <= 0;
        end
        else begin
            case(inst_i[`OP])
                `OP_SPECIAL,`OP_SPECIAL2:begin
                    reg_waddr <= inst_i[`RD];
                end
                `OP_ADDI,`OP_ADDIU,`OP_LUI,
                `OP_ANDI,`OP_ORI,`OP_XORI,
                `OP_SLTI,`OP_SLTIU,
                `OP_LB,`OP_LBU,`OP_LH,`OP_LHU,`OP_LW:begin
                    reg_waddr <= inst_i[`RT];
                end
                //默认取31，非写寄存器不影响结果
                `OP_REGIMM,`OP_JAL:begin
                    reg_waddr <= 31;
                end
                //mf
                `OP_COP0:begin
                    reg_waddr <= inst_i[`RT];
                end
                default:begin
                    reg_waddr <= 0;
                end
            endcase
        end
    end

    //imm_data
    always_comb begin
        if(!rst || flush) begin
            imm_data <= 0;
        end
        else begin
            case(inst_i[`OP])
                `OP_SPECIAL,`OP_SPECIAL2:begin
                    imm_data <= 0;
                end
                `OP_ADDI,`OP_ADDIU,
                `OP_SLTI,`OP_SLTIU,
                `OP_LB,`OP_LBU,`OP_LH,`OP_LHU,`OP_LW,
                `OP_SB,`OP_SH,`OP_SW:begin
                    imm_data <= {{16{inst_i[15]}},inst_i[15:0]};
                end
                `OP_ANDI,`OP_ORI,`OP_XORI:begin
                    imm_data <= {16'b0,inst_i[15:0]};
                end
                `OP_REGIMM,
                `OP_BEQ,`OP_BNE,
                `OP_BGTZ,`OP_BLEZ:begin
                    imm_data <= {{14{inst_i[15]}},inst_i[15:0],2'b0};
                end
                `OP_LUI:begin
                    imm_data <= {inst_i[15:0],16'b0};
                end
                `OP_JAL:begin
                    imm_data <= pc_i + 8;
                end
                default:begin
                    imm_data <= 0;
                end
            endcase
        end
    end

    //mem
    always_comb begin
        if(!rst ||flush) begin
            mem_func <= 0;
            mem_imm_flag <= 0;
        end
        else begin
            case (inst_i[`OP])
                `OP_LB:begin
                    mem_func <= 4'b0101;
                    mem_imm_flag <= 1;
                end
                `OP_LBU:begin
                    mem_func <= 4'b0101;
                    mem_imm_flag <= 0;
                end
                `OP_LH:begin
                    mem_func <= 4'b0110;
                    mem_imm_flag <= 1;
                end
                `OP_LHU:begin
                    mem_func <= 4'b0110;
                    mem_imm_flag <= 0;
                end
                `OP_LW:begin
                    mem_func <= 4'b0111;
                    mem_imm_flag <= 1;
                end
                `OP_SB:begin
                    mem_func <= 4'b1001;
                    mem_imm_flag <= 0;
                end
                `OP_SH:begin
                    mem_func <= 4'b1010;
                    mem_imm_flag <= 0;
                end
                `OP_SW:begin
                    mem_func <= 4'b1011;
                    mem_imm_flag <= 0;
                end
                default begin
                    mem_func <= 0;
                    mem_imm_flag <= 0;
                end
            endcase
        end
    end

    always_comb begin
        if(!rst) begin
            hi_wen <= 0;
            lo_wen <= 0;
            hi_ren <= 0;
            lo_ren <= 0;
        end
        else if(inst_i[`OP] == `OP_SPECIAL) begin
            hi_wen <= 0;
            lo_wen <= 0;
            hi_ren <= 0;
            lo_ren <= 0;
            case (inst_i[`FUNCT])
                `FUNCT_MULT,`FUNCT_MULTU,`FUNCT_DIV,`FUNCT_DIVU:begin
                    hi_wen <= 1;
                    lo_wen <= 1;
                end
                `FUNCT_MFHI:begin
                    hi_ren <= 1;
                end
                `FUNCT_MFLO:begin
                    lo_ren <= 1;
                end
                `FUNCT_MTHI:begin
                    hi_wen <= 1;
                end
                `FUNCT_MTLO:begin
                    lo_wen <= 1;
                end
            endcase
        end
        else begin
            hi_wen <= 0;
            lo_wen <= 0;
            hi_ren <= 0;
            lo_ren <= 0;
        end
    end

    //cp0 write
    always_comb begin
        if(!rst) begin
            cp0_wen <= 0;
            cp0_waddr <= 0;
        end
        else begin
            case(inst_i[`OP])
                //mt
                `OP_COP0:begin
                    cp0_wen <= inst_i[23];
                    cp0_waddr <= {inst_i[`RD],inst_i[`SEL]};
                end
                default begin
                    cp0_wen <= 0;
                    cp0_waddr <= 0;
                end
            endcase
        end
    end

    //cp0 read
    always_comb begin
        if(!rst) begin
            cp0_ren <= 0;
            cp0_raddr <= 0;
        end
        else begin
            case (inst_i[`OP])
                //mf
                `OP_COP0:begin
                    cp0_ren <= ~inst_i[23];
                    cp0_raddr <= {inst_i[`RD],inst_i[`SEL]};
                end
                default begin
                    cp0_ren <= 0;
                    cp0_raddr <= 0;
                end
            endcase
        end
    end

    //exception
    always_comb begin
        if(!rst) begin
            sys_flag <= 0;
            eret_flag <= 0;
            break_flag <= 0;
        end
        else if (inst_i[`OP] == `OP_SPECIAL) begin
            sys_flag <= inst_i[`FUNCT] == `FUNCT_SYSCALL;
            eret_flag <= 0;
            break_flag <= inst_i[`FUNCT] == `FUNCT_BREAK;
        end
        else if (inst_i[`OP] == `OP_COP0) begin
            sys_flag <= 0;
            eret_flag <= inst_i[`FUNCT] == `FUNCT_ERET;
            break_flag <= 0;
        end
        else begin
            sys_flag <=0;
            eret_flag <= 0;
            break_flag <= 0;
        end
    end

    always_comb begin
        if(!rst) begin
            exception_type <= 0;
        end
        else begin
            exception_type <= exception_type_i;
            exception_type[`EXE_SYSCALL] <= sys_flag;
            exception_type[`EXE_Eret] <= eret_flag;
            exception_type[`EXE_BREAK] <= break_flag;
            exception_type[`EXE_InstValid] <= ~instValid;
        end
    end

endmodule