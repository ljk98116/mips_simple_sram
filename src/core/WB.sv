`timescale 1ns/1ps

`include "../../include/global.svh"
`include "../../include/config.svh"

module WB(
    input rst,
    input [`ADDR_BUS] wb_pc_i,
    input wb_reg_wen_i,
    input [`REG_ADDR] wb_reg_waddr_i,
    input [`DATA_BUS] wb_reg_wdata_i,
    //control output 
    output load_related_done,
    //mem input 
    input [3:0] mem_func,
    input mem_imm_flag,
    input [`ADDR_BUS] mem_addr,
    input [`DATA_BUS] ram_rdata,
    input [`DATA_BUS] cp0_wdata_i,
    //output
    output [`ADDR_BUS] wb_pc_o,
    output wb_reg_wen_o,
    output [`REG_ADDR] wb_reg_waddr_o,
    output reg [`DATA_BUS] wb_reg_wdata_o
);

    assign wb_pc_o = rst && wb_reg_wen_i ? wb_pc_i : 0;
    assign wb_reg_wen_o = rst && wb_reg_wen_i ? wb_reg_wen_i : 0;
    assign wb_reg_waddr_o = rst && wb_reg_wen_i ? wb_reg_waddr_i : 0;

    //signal for load insts done
    assign load_related_done = rst ? mem_func[3:2] == 2'b01 : 0;
    
    //wb_reg_data_o
    always_comb begin
        if(!rst) begin
            wb_reg_wdata_o <= 0;
        end
        else if(cp0_wdata_i != 0) begin
            wb_reg_wdata_o <= cp0_wdata_i;
        end
        else begin
            case ({mem_func,mem_addr[1:0]})
                //LB & LBU
                6'b010100:begin
                    wb_reg_wdata_o <= mem_imm_flag ? {{24{ram_rdata[7]}},ram_rdata[7:0]} : ram_rdata[7:0];
                end
                6'b010101:begin
                    wb_reg_wdata_o <= mem_imm_flag ? {{24{ram_rdata[15]}},ram_rdata[15:8]} : ram_rdata[15:8];
                end
                6'b010110:begin
                    wb_reg_wdata_o <= mem_imm_flag ? {{24{ram_rdata[23]}},ram_rdata[23:16]} : ram_rdata[23:16];
                end
                6'b010111:begin
                    wb_reg_wdata_o <= mem_imm_flag ? {{24{ram_rdata[31]}},ram_rdata[31:24]} : ram_rdata[31:24];
                end
                //LH & LHU
                6'b011000:begin
                    wb_reg_wdata_o <= mem_imm_flag ? {{16{ram_rdata[15]}},ram_rdata[15:0]} : ram_rdata[15:0];
                end
                6'b011010:begin
                    wb_reg_wdata_o <= mem_imm_flag ? {{24{ram_rdata[31]}},ram_rdata[31:16]} : ram_rdata[31:16];
                end
                6'b011100:begin
                    wb_reg_wdata_o <= ram_rdata;
                end
                default begin
                    wb_reg_wdata_o <= wb_reg_wen_i ? wb_reg_wdata_i : 0;
                end
            endcase
        end
    end

endmodule