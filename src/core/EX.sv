`timescale 1ns/1ps

`include "../../include/global.svh"
`include "../../include/decode.svh"
`include "../../include/config.svh"
`include "../../include/exception.svh"

module EX(
    input clk,
    input rst,
    input flush,
    //from read_reg
    input [`ADDR_BUS] pc_i,
    input reg_wen_i,
    input [`REG_ADDR] reg_waddr_i,
    input [5:0] funct,
    input [4:0] shamt,
    input [5:0] inst_op,
    input [`DATA_BUS] reg_rdata_1,
    input [`DATA_BUS] reg_rdata_2,
    input [`DATA_BUS] br_imm_data,
    input is_delay_slot_i,
    //hilo
    input hi_wen,
    input lo_wen,
    input [`DATA_BUS] hi_rdata,
    input [`DATA_BUS] lo_rdata,
    //cp0
    input cp0_ren_i,
    input cp0_wen_i,
    input [`CP0_ADDR] cp0_waddr_i,
    input [`DATA_BUS] cp0_rdata_i,
    input [`DATA_BUS] exception_type_i,
    //regimm input
    input regimm_en,
    input [4:0] regimm_func,
    //special2 input
    input special2_en,
    //mem input 
    input [3:0] mem_func_i,
    input mem_imm_flag_i,
    input [`DATA_BUS] mem_wdata_i,
    //branch_output
    output reg ex_br_flag,
    output reg [`ADDR_BUS] ex_br_addr,

    //output
    output [`ADDR_BUS] pc_o,
    output reg_wen_o,
    output [`REG_ADDR] reg_waddr_o,
    output [`DATA_BUS] result_o,
    output reg [1:0] ex_hilo_wen,
    output reg [`DW_BUS] ex_hilo_wdata,
    output cp0_wen_o,
    output [`CP0_ADDR] cp0_waddr_o,
    output [`DATA_BUS] cp0_rdata_o,
    output reg [`DATA_BUS] exception_type_o,
    //mem
    output [3:0] mem_func_o,
    output mem_imm_flag_o,
    output [`DATA_BUS] mem_wdata_o,

    //control
    output reg ex_stall_req,
    output is_delay_slot_o,
    output [`DATA_BUS] cp0_wdata
);
    reg [`DATA_BUS] result;
    reg [32:0] res_33;
    assign pc_o = rst ? pc_i : 0;
    assign reg_wen_o = rst ? reg_wen_i & (res_33[32] == res_33[31]): 0;
    assign reg_waddr_o = rst ? reg_waddr_i : 0;
    assign mem_func_o = rst ? mem_func_i : 0;
    assign mem_imm_flag_o = rst ? mem_imm_flag_i : 0;
    assign mem_wdata_o = rst ? mem_wdata_i : 0;
    assign cp0_wen_o = rst ? cp0_wen_i : 0;
    assign cp0_waddr_o = rst ? cp0_waddr_i : 0;
    assign cp0_rdata_o = rst ? cp0_rdata_i : 0;
    assign is_delay_slot_o = rst ? is_delay_slot_i : 0;
    assign result_o = cp0_ren_i ? cp0_rdata_i : result;
    assign cp0_wdata = cp0_wen_i ? reg_rdata_2 : 0;

    wire [`DATA_BUS] CLO_res;
    wire [`DATA_BUS] CLZ_res;
    //signed reg_rdata
    wire signed [`DATA_BUS] reg_rdata1,reg_rdata2;
    //signed reg_rdata gen
    assign reg_rdata1 = reg_rdata_1;
    assign reg_rdata2 = reg_rdata_2;
    //div,divu res
    wire div_ok,divu_ok;
    wire [`DW_BUS] div_res,divu_res;
    reg div_en,divu_en;
    //mult,multu res
    wire [`DW_BUS] mult_res,multu_res;
    reg mult_en,multu_en;
    //branch_output
    always_comb begin
        if(!rst || flush) begin
            ex_br_flag <= 0;
            ex_br_addr <= 0;
        end
        else if(regimm_en) begin
            case (regimm_func)
                `FUNCT_BGEZ,`FUNCT_BGEZAL:begin
                    ex_br_flag <= reg_rdata_1[31] == 0;
                    ex_br_addr <= pc_i + br_imm_data;
                end
                `FUNCT_BLTZ,`FUNCT_BLTZAL:begin
                    ex_br_flag <= reg_rdata1 < 0;
                    ex_br_addr <= pc_i + br_imm_data;
                end                
                default:begin
                    ex_br_flag <= 0;
                    ex_br_addr <= 0;
                end
            endcase
        end
        else begin
            case(inst_op)
                `OP_SPECIAL:begin
                    ex_br_flag <= funct == `FUNCT_JR || funct ==`FUNCT_JALR;
                    ex_br_addr <= reg_rdata_1;
                end
                `OP_BEQ:begin
                    ex_br_flag <= reg_rdata_1 == reg_rdata_2;
                    ex_br_addr <= pc_i + br_imm_data;
                end
                `OP_BNE:begin
                    ex_br_flag <= reg_rdata_1 != reg_rdata_2;
                    ex_br_addr <= pc_i + br_imm_data;
                end
                `OP_BGTZ:begin
                    ex_br_flag <= reg_rdata_1[31] == 0 && reg_rdata_1[30:0] != 0;
                    ex_br_addr <= pc_i + br_imm_data;
                end
                `OP_BLEZ:begin
                    ex_br_flag <= reg_rdata1 <= 0;
                    ex_br_addr <= pc_i + br_imm_data;
                end
                default:begin
                    ex_br_flag <= 0;
                    ex_br_addr <= 0;
                end
            endcase
        end
    end

    //calculate result
    always_comb begin
        if(!rst || flush) begin
            result <= 0;
            res_33 <= 0;
        end
        else if(regimm_en) begin
            res_33 <= 0;
            case (regimm_func)
                `FUNCT_BGEZAL,`FUNCT_BLTZAL:begin
                    result <= pc_i + 8;
                end
                default:begin
                    result <= 0;
                end
            endcase
        end
        else if(special2_en) begin
            res_33 <= 0;
            case(funct)
                `FUNCT_CLO:begin
                    result <= CLO_res;
                end
                `FUNCT_CLZ:begin
                    result <= CLZ_res;
                end
                default:begin
                    result <= 0;
                end
            endcase
        end
        else begin
            res_33 <= 0;
            case (funct)
                `FUNCT_ADD:begin
                    result <= reg_rdata1 + reg_rdata2;
                    res_33 <= {reg_rdata1[31],reg_rdata1} + {reg_rdata2[31],reg_rdata2};
                end
                `FUNCT_ADDU: begin
                    result <= reg_rdata_1 + reg_rdata_2;
                end
                `FUNCT_AND:begin
                    result <= reg_rdata_1 & reg_rdata_2;
                end
                `FUNCT_SUBU:begin
                    result <= reg_rdata_1 - reg_rdata_2;
                end
                `FUNCT_SUB:begin
                    result <= reg_rdata1 - reg_rdata2;
                    res_33 <= {reg_rdata1[31],reg_rdata1} - {reg_rdata2[31],reg_rdata2};
                end
                `FUNCT_SLT:begin
                    result <= reg_rdata1 < reg_rdata2;
                end
                `FUNCT_SLTU:begin
                    result <= reg_rdata_1 < reg_rdata_2;
                end
                `FUNCT_NOR:begin
                    result <= ~(reg_rdata_1 | reg_rdata_2);
                end
                `FUNCT_OR:begin
                    result <= reg_rdata_1 | reg_rdata_2;
                end
                `FUNCT_XOR:begin
                    result <= reg_rdata_1 ^ reg_rdata_2;
                end
                `FUNCT_JALR:begin
                    result <= pc_i + 8;
                end
                `FUNCT_SLLV:begin
                    result <= reg_rdata_2 << (reg_rdata_1[4:0]);
                end
                `FUNCT_SLL:begin
                    result <= reg_rdata_2 << shamt;
                end
                `FUNCT_SRAV:begin
                    result <= ({32{reg_rdata_2[31]}} << (6'd32 - {1'b0, reg_rdata_1[4:0]})) | reg_rdata_2 >> reg_rdata_1[4:0];
                end
                `FUNCT_SRA:begin
                    result <= ({32{reg_rdata_2[31]}} << (6'd32 - {1'b0, shamt})) | reg_rdata_2 >> shamt;
                end
                `FUNCT_SRLV:begin
                    result <= reg_rdata_2 >> (reg_rdata_1[4:0]);                    
                end
                `FUNCT_SRL:begin
                    result <= reg_rdata_2 >> shamt;
                end
                `FUNCT_MFHI:begin
                    result <= hi_rdata;
                end
                `FUNCT_MFLO:begin
                    result <= lo_rdata;
                end
                default:begin
                    result <= 0;
                end
            endcase
        end
    end

    //mult,multu timer
    reg [2:0] mul_cnt;
    always_ff @(posedge clk) begin
        if(!rst) begin
            mul_cnt <= 0;
        end
        else if(mul_cnt == 6) begin
            mul_cnt <= 0;
        end
        else if(mult_en || multu_en) begin
            mul_cnt <= mul_cnt + 1;
        end
    end

    //div,divu,mult,multu,mthi,mtlo
    always_comb begin
        if(!rst || flush) begin
            ex_hilo_wen <= 0;
            ex_hilo_wdata <= 0;
            ex_stall_req <= 0;
            mult_en <= 0;
            multu_en <= 0;
            div_en <= 0;
            divu_en <= 0;
        end
        else if(inst_op == `OP_SPECIAL) begin
            case(funct)
                `FUNCT_MTHI:begin
                    ex_hilo_wen <= 2'b10;
                    ex_hilo_wdata <= {reg_rdata_1,32'h0};
                    ex_stall_req <= 0;
                    mult_en <= 0;
                    multu_en <= 0;
                    div_en <= 0;
                    divu_en <= 0;
                end
                `FUNCT_MTLO:begin
                    ex_hilo_wen <= 2'b01;
                    ex_hilo_wdata <= {32'h0,reg_rdata_1};
                    ex_stall_req <= 0;
                    mult_en <= 0;
                    multu_en <= 0;    
                    div_en <= 0;
                    divu_en <= 0;                
                end
                `FUNCT_DIV:begin
                    ex_hilo_wen <= 2'b11;
                    ex_hilo_wdata <= {div_res[31:0],div_res[63:32]};
                    ex_stall_req <= ~div_ok;
                    mult_en <= 0;
                    multu_en <= 0;
                    div_en <= 1;
                    divu_en <= 0;
                end
                `FUNCT_DIVU:begin
                    ex_hilo_wen <= 2'b11;
                    ex_hilo_wdata <= {divu_res[31:0],divu_res[63:32]};
                    ex_stall_req <= ~divu_ok;
                    mult_en <= 0;
                    multu_en <= 0;
                    div_en <= 0;
                    divu_en <= 1;
                end
                `FUNCT_MULT:begin
                    ex_hilo_wen <= 2'b11;
                    ex_hilo_wdata <= mult_res;
                    ex_stall_req <= mul_cnt < 6;
                    mult_en <= 1;
                    multu_en <= 0;
                    div_en <= 0;
                    divu_en <= 0;
                end
                `FUNCT_MULTU:begin
                    ex_hilo_wen <= 2'b11;
                    ex_hilo_wdata <= multu_res;
                    ex_stall_req <= mul_cnt < 6;
                    mult_en <= 0;
                    multu_en <= 1;
                    div_en <= 0;
                    divu_en <= 0;
                end
                default begin
                    ex_hilo_wen <= 0;
                    ex_hilo_wdata <= 0;
                    ex_stall_req <= 0;
                    mult_en <= 0;
                    multu_en <= 0;  
                    div_en <= 0;
                    divu_en <= 0;                  
                end
            endcase
        end
        else begin
            ex_hilo_wen <= 0;
            ex_hilo_wdata <= 0;
            ex_stall_req <= 0;
            mult_en <= 0;
            multu_en <= 0;
            div_en <= 0;
            divu_en <= 0;
        end
    end

    //special2 functions
    bitcounter u_CLO(rst,1'b1,reg_rdata_1,CLO_res);
    bitcounter u_CLZ(rst,1'b0,reg_rdata_1,CLZ_res);
    //div,divu functions
    div u_div(clk,div_en,div_en,div_en,reg_rdata2,div_en,reg_rdata1,div_ok,div_res);
    divu u_divu(clk,divu_en,divu_en,divu_en,reg_rdata_2,divu_en,reg_rdata_1,divu_ok,divu_res);
    //mult,multu functions
    mult u_mult(clk,reg_rdata1,reg_rdata2,mult_en,mult_res);
    multu u_multu(clk,reg_rdata_1,reg_rdata_2,multu_en,multu_res);
    //exception related
    always_comb begin
        if(!rst) begin
            exception_type_o <= 0;
        end
        else begin
            exception_type_o <= exception_type_i;
            exception_type_o[`EXE_OF] <= res_33[32] != res_33[31];
        end
    end
endmodule