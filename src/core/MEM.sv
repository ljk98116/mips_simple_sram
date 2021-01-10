`timescale 1ns/1ps

`include "../../include/global.svh"
`include "../../include/config.svh"
`include "../../include/exception.svh"
`include "../../include/cp0.svh"

//check exception and send right mem_req
module MEM(
    input rst,
    input [`ADDR_BUS] mem_pc_i,
    input mem_reg_wen_i,
    input [`REG_ADDR] mem_reg_waddr_i,
    input [`DATA_BUS] mem_reg_wdata_i,
    input is_delay_slot_i,
    //mem_control
    input [3:0] mem_func_i,
    input mem_imm_flag_i,
    input [`DATA_BUS] mem_wdata_i,
    //cp0
    input cp0_wen_i,
    input [`CP0_ADDR] cp0_waddr_i,
    input [`DATA_BUS] cp0_wbdata_i,
    input [`DATA_BUS] cp0_wdata_i,
    input [`DATA_BUS] exception_type_i,
    //output ram control
    output reg ram_en,
    output reg [3:0] ram_sel,
    output reg [`ADDR_BUS] ram_addr,
    output reg [`DATA_BUS] ram_wdata,
    //output for RAW and load related
    output [`ADDR_BUS] mem_pc_o,
    output mem_reg_wen_o,
    output [`REG_ADDR] mem_reg_waddr_o,
    output [`DATA_BUS] mem_reg_wdata_o,
    //for wb to operate
    output [3:0] mem_func_o,
    output mem_imm_flag_o,
    //only for sram test
    output `DEBUG [`ADDR_BUS] mem_addr_o,
    //cp0
    output cp0_wen_o,
    output [`CP0_ADDR] cp0_waddr_o,
    output [`DATA_BUS] cp0_wbdata_o,
    //cp0 regs
    input [`DATA_BUS] cp0_count,
    input [`DATA_BUS] cp0_cause,
    input [`DATA_BUS] cp0_compare,
    input [`DATA_BUS] cp0_config,
    input [`DATA_BUS] cp0_epc,
    input [`DATA_BUS] cp0_status,
    //exception control
    output reg [`DATA_BUS] exception_type_o,
    output exception_flag,
    output reg [`ADDR_BUS] exc_pc,
    output is_delay_slot_o,
    output [`DATA_BUS] mem_cp0_wdata,
    output reg [`ADDR_BUS] mem_badaddr
);
    assign mem_pc_o = rst ? mem_pc_i : 0;
    assign mem_reg_wen_o = rst ? mem_reg_wen_i & ~exception_flag : 0;
    assign mem_reg_waddr_o = rst ? mem_reg_waddr_i : 0;

    //to do,need to modify
    assign mem_reg_wdata_o = rst ? mem_reg_wdata_i : 0;

    //for wb to operate
    assign mem_func_o = rst ? mem_func_i : 0; 
    assign mem_imm_flag_o = rst ? mem_imm_flag_i : 0;

    //only for sram test
    assign mem_addr_o = rst ? mem_reg_wdata_i : 0;
    assign is_delay_slot_o = rst ? is_delay_slot_i : 0;

    //cp0
    assign cp0_wen_o = rst ? cp0_wen_i : 0;
    assign cp0_waddr_o = rst ? cp0_waddr_i : 0;
    assign cp0_wbdata_o = rst ? cp0_wbdata_i : 0;
    assign mem_cp0_wdata = cp0_wen_i ? cp0_wdata_i: 0;

    always_comb begin
        if(!rst) begin
            ram_en <= 0;
        end
        else begin
            case (mem_func_i)
                //LB,LBU,LH,LHU,LW,SB,SH,SW
                4'b0101,4'b0110,4'b0111,4'b1001,4'b1010,4'b1011:begin
                    ram_en <= ~exception_flag;
                end
                default:begin
                    ram_en <= 0;
                end
            endcase
        end
    end

    //only be valid if you write mem
    always_comb begin
        if(!rst) begin
            ram_sel <= 0;
        end
        else begin
            `ifndef CACHE_ENABLE
            case ({mem_func_i,mem_reg_wdata_i[1:0]})
                //SB
                6'b100100:begin
                    ram_sel <= 4'b0001;
                end
                6'b100101:begin
                    ram_sel <= 4'b0010;
                end
                6'b100110:begin
                    ram_sel <= 4'b0100;
                end
                6'b100111:begin
                    ram_sel <= 4'b1000;
                end
                //SH
                6'b101000:begin
                    ram_sel <= 4'b0011;
                end
                6'b101010:begin
                    ram_sel <= 4'b1100;
                end
                //SW
                6'b101100:begin
                    ram_sel <= 4'b1111;
                end
                default begin
                    ram_sel <= 0;
                end
            endcase
            `else
            `endif
        end
    end

    //ram_addr
    always_comb begin
        if(!rst) begin
            mem_badaddr <= 0;
        end
        else if(exception_type_i[`EXE_AdEl]) begin
            mem_badaddr <= mem_pc_i;
        end
        else begin
            `ifndef CACHE_ENABLE
                case (mem_func_i)//LH,LW,SH,SW,LHU
                    4'b1010,4'b0110:mem_badaddr <= mem_reg_wdata_i[0] ? mem_reg_wdata_i : 0;
                    4'b1011,4'b0111:mem_badaddr <= mem_reg_wdata_i[1:0] != 2'b0 ? mem_reg_wdata_i : 0;
                    default:begin
                        mem_badaddr <= 0;
                    end
                endcase
            `else
            `endif
        end
    end

    always_comb begin
        if(!rst) begin
            ram_addr <= 0;
        end
        else begin
            `ifndef CACHE_ENABLE
                case (mem_func_i)
                    //LB,LBU,LH,LHU,LW,SB,SH,SW
                    4'b0101,4'b0110,4'b0111,4'b1001,4'b1010,4'b1011:begin
                        ram_addr <= {mem_reg_wdata_i[31:2],2'b0};
                    end
                    default:begin
                        ram_addr <= 0;
                    end
                endcase
            `else
            `endif
        end
    end
    //ram_wdata
    always_comb begin
        if(!rst) begin
            ram_wdata <= 0;
        end
        else begin
            case({mem_func_i,mem_reg_wdata_i[1:0]})
                //SB
                6'b100100:ram_wdata <= mem_wdata_i[7:0];
                6'b100101:ram_wdata <= mem_wdata_i[7:0] << 8;
                6'b100110:ram_wdata <= mem_wdata_i[7:0] << 16;
                6'b100111:ram_wdata <= mem_wdata_i[7:0] << 24;
                //SH
                6'b101000:ram_wdata <= mem_wdata_i[15:0];
                6'b101010:ram_wdata <= mem_wdata_i[15:0] << 16;
                //SW
                6'b101100:ram_wdata <= mem_wdata_i;
                default:ram_wdata <= 0;
            endcase
        end
    end

    //exception
    assign exception_flag = rst ? exception_type_o != 0 : 0;

    always_comb begin
        if(!rst) begin
            exception_type_o <= 0;
        end
        else begin
            exception_type_o <= exception_type_i;
            //open interrupt
            if(cp0_cause[15:8] & (cp0_status[15:8]) && cp0_status[`IE] && cp0_status[`EXL] == 0) begin
                exception_type_o <= `EX_Int;
            end
            case(mem_func_i)
                4'b0110:exception_type_o[`EXE_AdEl] <= mem_reg_wdata_i[0];
                4'b0111:exception_type_o[`EXE_AdEl] <= mem_reg_wdata_i[1:0] != 2'b00;
                4'b1010:exception_type_o[`EXE_AdEs] <= mem_reg_wdata_i[0];
                4'b1011:exception_type_o[`EXE_AdEs] <= mem_reg_wdata_i[1:0] != 2'b00;
            endcase
        end
    end

    //exc_pc
    //to do
    always_comb begin
        if(!rst) begin
            exc_pc <= 0;
        end
        else if(exception_type_i[`EXE_Eret]) begin
            exc_pc <= cp0_epc;
        end
        else if(exception_type_i != 0 || exception_flag) begin
            exc_pc <= 32'hbfc0_0380;
        end
        else begin
            exc_pc <= 0;
        end
    end

    //branch_error 

endmodule