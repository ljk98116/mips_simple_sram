`timescale 1ns/1ps

//registers here

`include "../../include/global.svh"
`include "../../include/config.svh"
`include "../../include/decode.svh"
`include "../../include/cp0.svh"
`include "../../include/exception.svh"

//br_imm_data 专指指令偏移加4，用来简化EX段计算分支地址的电路
//优先级load_related > current EX >current MEM > current dcache(to do)
//从EX级向后排查是否有前置load指令，若有则为load_related,暂停RR及前面所有级
//加cache前在wb段获得load_related_done 取数并恢复执行,
//加dcache后，选择在dcache段解除load_related暂停，取数并恢复执行
//解除信号由load指令从内存中取数完成时给出

//hilo only takes ex's res to simplify the design
//cp0 writes on mem stage

module read_reg(
    input clk,
    input rst,
    input flush,
    `ifndef CACHE_ENABLE
        //load related done from wb
        input load_related_done,
    `endif
    //from id
    input [`ADDR_BUS] id_pc_i,
    input id_reg_wen_i,
    input id_reg_ren_1_i,id_reg_ren_2_i,
    input [`REG_ADDR] id_reg_waddr_i,id_reg_raddr_1_i,id_reg_raddr_2_i,
    input [`DATA_BUS] id_imm_data_i,
    input [5:0] id_funct_i,
    input [4:0] id_shamt_i,
    input [5:0] id_instop_i,
    input [`DATA_BUS] id_exception_type_i,
    input is_delay_slot_i,
    //regimm
    input [4:0] id_regimm_func,
    //mem
    input [3:0] id_mem_func,
    input id_mem_imm_flag,
    //hilo
    input id_hi_wen,
    input id_lo_wen,
    input id_hi_ren,
    input id_lo_ren,
    //cp0
    input id_cp0_ren,
    input [`CP0_ADDR] id_cp0_raddr,
    input id_cp0_wen,
    input [`CP0_ADDR] id_cp0_waddr,
    //from ex
    input ex_reg_wen,
    input [`REG_ADDR] ex_reg_waddr,
    input [`DATA_BUS] ex_reg_wdata,
    //ex mem
    input [3:0] ex_mem_func,
    //ex hilo
    input [1:0] ex_hilo_wen,
    input [`DW_BUS] ex_hilo_wdata,
    //ex cp0
    input [`CP0_ADDR] ex_cp0_waddr,
    input [`DATA_BUS] ex_cp0_wdata,
    //from mem
    input mem_reg_wen,
    input [`REG_ADDR] mem_reg_waddr,
    input [`DATA_BUS] mem_reg_wdata,
    input [3:0] mem_mem_func,
    //from dcache
    //from wb
    input wb_reg_wen,
    input [`REG_ADDR] wb_reg_waddr,
    input [`DATA_BUS] wb_reg_wdata,
    //output
    output [`ADDR_BUS] pc_o,
    output reg_wen_o,
    output [`REG_ADDR] reg_waddr_o,
    output [5:0] funct_o,
    output [4:0] shamt_o,
    output [5:0] instop_o,
    output reg [`DATA_BUS] reg_rdata_1,reg_rdata_2,
    output reg [`DATA_BUS] br_imm_data,
    output [`DATA_BUS] exception_type_o,
    output is_delay_slot_o,
    //hilo
    output hi_wen,
    output lo_wen,
    output reg [`DATA_BUS] hi_rdata,
    output reg [`DATA_BUS] lo_rdata,
    //output for regimm
    output regimm_en,
    output [4:0] regimm_func,
    //output for mem
    output [3:0] mem_func,
    output mem_imm_flag,
    output reg [`DATA_BUS] mem_wdata,
    //output for special2
    output special2_en,
    //output load related
    output [1:0] load_related_flag,
    //cp0
    input mem_cp0_wen,
    input [`CP0_ADDR] mem_cp0_waddr,
    input [`DATA_BUS] mem_cp0_wdata,
    input [5:0] interrupt_i,
    input [`DATA_BUS] mem_exception_type,
    input [`ADDR_BUS] mem_pc,
    input [`ADDR_BUS] mem_badaddr,
    input mem_is_delay_slot,
    //output cp0
    output cp0_ren_o,
    output cp0_wen_o,
    output [`CP0_ADDR] cp0_waddr_o,
    output reg [`DATA_BUS] cp0_rdata,
    //cp0 regs
    output reg [`DATA_BUS] cp0_count_o,
    output reg [`DATA_BUS] cp0_compare_o,
    output reg [`DATA_BUS] cp0_status_o,
    output reg [`DATA_BUS] cp0_cause_o,
    output reg [`DATA_BUS] cp0_epc_o,
    output reg [`DATA_BUS] cp0_config_o,
    output reg [`DATA_BUS] cp0_prid_o,
    output reg [`DATA_BUS] cp0_badvaddr_o
);
    reg [`DW_BUS] hilo;
    reg [`DATA_BUS] regfile[0:31];
    reg load_related_flag_1,load_related_flag_2;

    //outputs
    assign pc_o = rst? id_pc_i : 0;
    assign reg_wen_o = rst ? id_reg_wen_i : 0;
    assign reg_waddr_o = rst ? id_reg_waddr_i : 0;
    assign funct_o = rst ? id_funct_i : 0;
    assign shamt_o = rst ? id_shamt_i : 0;
    assign instop_o = rst ? id_instop_i : 0;
    assign regimm_func = rst ? id_regimm_func : 0;
    assign regimm_en = rst & id_instop_i == `OP_REGIMM;
    assign mem_func = rst ? id_mem_func : 0;
    assign mem_imm_flag = rst ? id_mem_imm_flag : 0;
    assign special2_en = rst ? id_instop_i == `OP_SPECIAL2 : 0;
    assign hi_wen = rst ? id_hi_wen : 0;
    assign lo_wen = rst ? id_lo_wen : 0;
    assign cp0_wen_o = rst ? id_cp0_wen : 0;
    assign cp0_waddr_o = rst ? id_cp0_waddr : 0;
    assign exception_type_o = rst ? id_exception_type_i : 0;
    assign is_delay_slot_o = rst ? is_delay_slot_i : 0;
    assign cp0_ren_o = rst ? id_cp0_ren : 0;
    
    reg load_related_1,load_related_2;

    wire ex1,ex2,mem1,mem2,wb1,wb2,imm,mem;
    wire addr2_zero_flag;

    assign ex1 = id_reg_raddr_1_i == ex_reg_waddr;
    assign mem1 = id_reg_raddr_1_i == mem_reg_waddr;
    assign wb1 = id_reg_raddr_1_i == wb_reg_waddr;

    assign ex2 = id_reg_raddr_2_i == ex_reg_waddr;
    assign mem2 = id_reg_raddr_2_i == mem_reg_waddr;
    assign wb2 = id_reg_raddr_2_i == wb_reg_waddr;

    assign imm = id_mem_func[3] || ~id_reg_ren_2_i;
    assign mem = !rst && ~id_mem_func[3];
    assign addr2_zero_flag = id_reg_raddr_2_i == 0;
    assign load_related_flag = {load_related_flag_1,load_related_flag_2};

    always_ff @(posedge clk) begin
        if(!rst && ~load_related_flag_1) begin
            load_related_1 <= 0;
        end
        else begin
            load_related_1 <= load_related_flag_1;
        end
    end

    //load related flag
    always_comb begin
        casez ({rst && id_reg_ren_1_i,ex_mem_func[2],mem_mem_func[2],load_related_done})
            4'b0???:load_related_flag_1 <= 0;
            4'b11??:load_related_flag_1 <= load_related_1 || ex1;
            4'b101?:load_related_flag_1 <= load_related_1 || mem1;
            4'b1001:load_related_flag_1 <= 0;
            4'b1000:load_related_flag_1 <= load_related_1;
        endcase
    end

    always_ff @(posedge clk) begin
        if(!rst && ~load_related_flag_2) begin
            load_related_2 <= 0;
        end
        else begin
            load_related_2 <= load_related_flag_2;
        end
    end

    //load related flag
    always_comb begin
        casez ({rst && id_reg_ren_2_i,ex_mem_func[2],mem_mem_func[2],load_related_done})
            4'b0???:load_related_flag_2 <= 0;
            4'b11??:load_related_flag_2 <= load_related_2 || ex2;
            4'b101?:load_related_flag_2 <= load_related_2 || mem2;
            4'b1001:load_related_flag_2 <= 0;
            4'b1000:load_related_flag_2 <= load_related_2;
        endcase
    end
    //br_imm data
    always_comb begin
        if(!rst) begin
            br_imm_data <= 0;
        end
        else begin
            case(id_instop_i)
                `OP_BEQ,`OP_BNE,
                `OP_REGIMM,
                `OP_BGTZ,
                `OP_BLEZ:begin
                    br_imm_data <= id_imm_data_i + 4;
                end
                default:begin
                    br_imm_data <= 0;
                end
            endcase
        end
    end
    
    //.decide rdata_1
    always_comb begin
        casez ({rst,id_reg_ren_1_i,ex1,mem1,wb1})
            5'b0????:reg_rdata_1 <= 0;
            5'b10???:reg_rdata_1 <= 0;
            5'b111??:reg_rdata_1 <= ex_reg_wdata;
            5'b1101?:reg_rdata_1 <= mem_reg_wdata;
            5'b11001:reg_rdata_1 <= wb_reg_wdata;
            5'b11000:reg_rdata_1 <= regfile[id_reg_raddr_1_i];
            default begin
                reg_rdata_1 <= 0;
            end
        endcase
    end

    //.decide rdata2
    always_comb begin
        casez ({rst,imm,ex2,mem2,wb2})
            5'b0????:reg_rdata_2 <= 0;
            5'b11???:reg_rdata_2 <= id_imm_data_i;
            5'b101??:reg_rdata_2 <= ex_reg_wdata;
            5'b1001?:reg_rdata_2 <= mem_reg_wdata;
            5'b10001:reg_rdata_2 <= wb_reg_wdata;
            5'b10000:reg_rdata_2 <= regfile[id_reg_raddr_2_i];
            default begin
                reg_rdata_2 <= 0;
            end
        endcase        
    end
    
    //mem_wdata
    always_comb begin       
        casez ({mem,addr2_zero_flag,ex2,mem2,wb2})
            5'b1????,5'b11???:mem_wdata <= 0;
            5'b001??:mem_wdata <= ex_reg_wdata;
            5'b0001?:mem_wdata <= mem_reg_wdata;
            5'b00001:mem_wdata <= wb_reg_wdata;
            5'b0:mem_wdata <= regfile[id_reg_raddr_2_i];
            default:mem_wdata <= 0;
        endcase
    end

    //hi_rdata
    always_comb begin
        if(!rst) begin
            hi_rdata <= 0;
        end
        else if(ex_hilo_wen[1]) begin
            hi_rdata <= ex_hilo_wdata[`HI];
        end
        else begin
            hi_rdata <= hilo[`HI];
        end
    end

    //lo_rdata
    always_comb begin
        if(!rst) begin
            lo_rdata <= 0;
        end
        else if(ex_hilo_wen[0]) begin
            lo_rdata <= ex_hilo_wdata[`LO];
        end
        else begin
            lo_rdata <= hilo[`LO];
        end
    end

    //.update regfile
    always_ff @(posedge clk) begin
        if(!rst) begin
            for(int i=0;i<32;i++) begin
                regfile[i] <= 0;
            end
        end
        else if(wb_reg_wen) begin
            regfile[wb_reg_waddr] <= wb_reg_wdata;
        end
    end

    //update hilo
    always_ff @(posedge clk) begin
        if(!rst) begin
            hilo <= 0;
        end
        else if(~flush) begin
            case (ex_hilo_wen)
                2'b11:hilo <= ex_hilo_wdata;
                2'b10:hilo[`HI] <= ex_hilo_wdata[`HI];
                2'b01:hilo[`LO] <= ex_hilo_wdata[`LO];
            endcase
        end
    end

    //read cp0
    always_comb begin
        if(!rst || ~id_cp0_ren) begin
            cp0_rdata <= 0;
        end
        else if (ex_cp0_waddr == id_cp0_raddr) begin
            cp0_rdata <= ex_cp0_wdata;
        end
        else if (mem_cp0_waddr == id_cp0_raddr && mem_cp0_wen) begin
            cp0_rdata <= mem_cp0_wdata;
        end
        else begin
            case (id_cp0_raddr)
                `CP0_COUNT:cp0_rdata <= cp0_count_o;
                `CP0_COMPARE:cp0_rdata <= cp0_compare_o;
                `CP0_STATUS:cp0_rdata <= cp0_status_o;
                `CP0_CAUSE:cp0_rdata <= cp0_cause_o;
                `CP0_EPC:cp0_rdata <= cp0_epc_o;
                `CP0_PRID:cp0_rdata <= cp0_prid_o;
                `CP0_CONFIG:cp0_rdata <= cp0_config_o;
                `CP0_BADVADDR:cp0_rdata <= cp0_badvaddr_o;
                default:cp0_rdata <= 0;
            endcase
        end
    end

    reg cp0_cnt;
    always_ff @(posedge clk) begin
        if(!rst) begin
            cp0_cnt <= 0;
        end
        else begin
            cp0_cnt <= cp0_cnt + 1;
        end
    end

    //cp0 config 
    always_ff @(posedge clk) begin
        if(!rst) begin
            cp0_count_o <= 0;
            cp0_compare_o <= 0;
            cp0_status_o <= 0;
            cp0_cause_o <= 0;
            cp0_epc_o <= 0;
            cp0_config_o <= 0;
            cp0_prid_o <= 0;
            cp0_badvaddr_o <= 0;
            //CP0_config init
            `ifndef FixedMapping_MMU
                cp0_config_o[`MT] <= `TLB;
                cp0_config_o[`K0] <= `Cache_off;
            `else
                cp0_config_o[`MT] <= `FixedMapping;
                cp0_config_o[`K0] <= `Cache_off;
                cp0_config_o[`K23] <= `Cache_off;
                cp0_config_o[`KU] <= cp0_status_o[`ERL] ? 0:`Cache_off;
            `endif
            //CP0_status config
            cp0_status_o[`BEV] <= 1'b1;
            cp0_status_o[`ERL] <= 1'b1;
        end
        else begin
            if(cp0_cnt) begin
                cp0_count_o <= cp0_count_o + 1;
            end
            if(mem_cp0_wen) begin
                case(mem_cp0_waddr)
                    `CP0_COUNT:cp0_count_o <= mem_cp0_wdata;
                    `CP0_COMPARE:begin
                        cp0_compare_o <= mem_cp0_wdata;
                    end
                    `CP0_STATUS:begin
                        cp0_status_o <= mem_cp0_wdata;
                    end
                    `CP0_EPC:cp0_epc_o <= mem_cp0_wdata;
                    `CP0_CAUSE:begin
                        cp0_cause_o[`IV] <= mem_cp0_wdata[`IV];
                        cp0_cause_o[`WP] <= mem_cp0_wdata[`WP];
                        cp0_cause_o[`IP10] <= mem_cp0_wdata[`IP10];
                    end
                endcase
            end
            casez (mem_exception_type)
                `EX_Int:begin
                    if(mem_is_delay_slot) begin
                        cp0_epc_o <= mem_pc - 4;
                        cp0_cause_o[`BD] <= 1'b1;
                    end
                    else begin
                        cp0_epc_o <= mem_pc;
                        cp0_cause_o[`BD] <= 1'b0;
                    end
                    cp0_status_o[`EXL] <= 1'b1;
                    cp0_cause_o[`EXCCODE] <= `EXC_Int;
                end
                `EX_SYSCALL:begin
                    if(mem_is_delay_slot) begin
                        cp0_epc_o <= mem_pc - 4;
                        cp0_cause_o[`BD] <= 1'b1;
                    end
                    else begin
                        cp0_epc_o <= mem_pc;
                        cp0_cause_o[`BD] <= 1'b0;
                    end
                    cp0_status_o[`EXL] <= 1'b1;
                    cp0_cause_o[`EXCCODE] <= `EXC_Sys;                    
                end
                `EX_InstValid:begin
                    if(mem_is_delay_slot) begin
                        cp0_epc_o <= mem_pc - 4;
                        cp0_cause_o[`BD] <= 1'b1;
                    end
                    else begin
                        cp0_epc_o <= mem_pc;
                        cp0_cause_o[`BD] <= 1'b0;
                    end
                    cp0_status_o[`EXL] <= 1'b1;
                    cp0_cause_o[`EXCCODE] <= `EXC_RI;                    
                end
                `EX_BREAK:begin
                    if(mem_is_delay_slot) begin
                        cp0_epc_o <= mem_pc - 4;
                        cp0_cause_o[`BD] <= 1'b1;
                    end
                    else begin
                        cp0_epc_o <= mem_pc;
                        cp0_cause_o[`BD] <= 1'b0;
                    end
                    cp0_status_o[`EXL] <= 1'b1;
                    cp0_cause_o[`EXCCODE] <= `EXC_Bp;                   
                end
                `EX_OF:begin
                    if(mem_is_delay_slot) begin
                        cp0_epc_o <= mem_pc - 4;
                        cp0_cause_o[`BD] <= 1'b1;
                    end
                    else begin
                        cp0_epc_o <= mem_pc;
                        cp0_cause_o[`BD] <= 1'b0;
                    end
                    cp0_status_o[`EXL] <= 1'b1;
                    cp0_cause_o[`EXCCODE] <= `EXC_Ov;                    
                end
                `EX_AdEl:begin
                    if(mem_is_delay_slot) begin
                        cp0_epc_o <= mem_pc - 4;
                        cp0_cause_o[`BD] <= 1'b1;
                    end
                    else begin
                        cp0_epc_o <= mem_pc;
                        cp0_cause_o[`BD] <= 1'b0;
                    end
                    cp0_status_o[`EXL] <= 1'b1;
                    cp0_cause_o[`EXCCODE] <= `EXC_AdEL;
                    cp0_badvaddr_o <= mem_badaddr;
                end
                `EX_AdEs:begin
                    if(mem_is_delay_slot) begin
                        cp0_epc_o <= mem_pc - 4;
                        cp0_cause_o[`BD] <= 1'b1;
                    end
                    else begin
                        cp0_epc_o <= mem_pc;
                        cp0_cause_o[`BD] <= 1'b0;
                    end
                    cp0_status_o[`EXL] <= 1'b1;
                    cp0_cause_o[`EXCCODE] <= `EXC_AdES;
                    cp0_badvaddr_o <= mem_badaddr;
                end

                `EX_ERET:begin
                    cp0_status_o[`EXL] <= 0;
                end
            endcase
        end
    end

endmodule