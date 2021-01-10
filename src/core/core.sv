`timescale 1ns/1ps

`include "../../include/global.svh"
`include "../../include/config.svh"

module core(
    input clk,
    input rst,
    input [5:0] interrupt,
    //AXI
    //sram
    `ifndef CACHE_ENABLE
        //rom
        output rom_en,
        output [`ADDR_BUS] rom_addr,
        input [`DATA_BUS] id_inst,
        //ram
        output ram_en,
        output [3:0] ram_sel,
        output [`ADDR_BUS] ram_addr,
        output [`DATA_BUS] ram_wdata,
        input [`DATA_BUS] ram_rdata,
    `endif
    //debug
    output `DEBUG [`ADDR_BUS] debug_write_pc,
    output `DEBUG reg_write_en,
    output `DEBUG [`REG_ADDR] reg_write_addr,
    output `DEBUG [`DATA_BUS] reg_write_data
);

//wire outside
wire ex_reg_wen,mem_reg_wen,mem_done_wen,wb_reg_wen;
wire [`REG_ADDR] ex_reg_waddr,mem_reg_waddr,mem_done_waddr,wb_reg_waddr;
wire [`DATA_BUS] ex_reg_wdata,mem_reg_wdata,mem_done_wdata,wb_reg_wdata;

//hilo outside
wire [1:0] ex_hilo_wen;
wire [`DW_BUS] ex_hilo_wdata;

//cp0 outside
wire ex_cp0_wen,mem_cp0_wen;
wire [`CP0_ADDR] ex_cp0_waddr,mem_cp0_waddr;
wire [`DATA_BUS] ex_cp0_wdata,mem_cp0_wdata;
wire [`DATA_BUS] mem_exception_type;
wire [`ADDR_BUS] mem_badaddr;

//ex stall signal
wire ex_stall_req;

wire [`ADDR_BUS] wb_pc;

//load related
wire [3:0] rr_mem_func;
wire rr_mem_imm_flag;

wire [3:0] ex_mem_func;
wire ex_mem_imm_flag;

wire [3:0] mem_mem_func;
wire mem_mem_imm_flag;

wire [1:0] load_related_flag;
wire load_related_done;

//tmp
assign mem_done_wen = 0;
assign mem_done_waddr = 0;
assign mem_done_wdata = 0;

//wire for branch
wire ex_br_flag;
wire [`ADDR_BUS] ex_br_addr;
wire id_br_flag;
wire [`ADDR_BUS] id_br_addr;

//control signal
wire [4:0] flush;
wire [4:0] stall;
wire exception_flag;
wire [`ADDR_BUS] exc_pc;

//debug output
assign reg_write_en = wb_reg_wen;
assign reg_write_addr = wb_reg_waddr;
assign reg_write_data = wb_reg_wdata;
assign debug_write_pc = wb_pc;

//cp0 regs outside
wire [`DATA_BUS] cp0_count_o,cp0_compare_o,cp0_status_o,
                 cp0_cause_o,cp0_epc_o,cp0_config_o,cp0_prid_o,cp0_badvaddr_o;
wire timer_int_o;

//MEM outputs
wire [`ADDR_BUS] mem_pc;
wire [`ADDR_BUS] mem_addr;
wire mem_is_delay_slot;

// if Outputs
wire  [`ADDR_BUS] if_pc;
wire [`DATA_BUS] if_exception_type;
IF u_IF(
    clk,rst,stall[`IF],
    //exception input
    exception_flag,
    exc_pc,
    //branch input
    id_br_flag,
    id_br_addr,
    ex_br_flag,
    ex_br_addr,

    //outputs
    rom_en,
    if_pc,
    if_exception_type
);    

assign rom_addr = if_pc;

`ifdef CACHE_ENABLE
    //icache inputs

    always_ff @(posedge clk) begin
        if(!rst) begin
            
        end
        else begin

        end
    end

    icache u_icache();

    //icache outputs

`endif

//ID inputs

`ifndef CACHE_ENABLE

    reg [`ADDR_BUS] if_id_pc;
    reg flush_id;
    reg [`DATA_BUS] if_id_exception_type;

    always_ff @(posedge clk) begin
        if(!rst || flush[`IF]) begin
            if_id_pc <= 0;
            flush_id <= flush[`IF];
            if_id_exception_type <= 0;
        end
        else if(stall[`IF] && ~stall[`ID]) begin
            if_id_pc <= 0;
            flush_id <= 0;
            if_id_exception_type <= 0;          
        end
        else if(!stall[`IF])begin
            if_id_pc <= if_pc;
            flush_id <= 0;
            if_id_exception_type <= if_exception_type;
        end
    end
    
`endif

//ID outputs
wire [`ADDR_BUS] id_pc;
wire id_reg_wen,id_reg_ren_1,id_reg_ren_2;
wire [`REG_ADDR] id_reg_waddr,id_reg_raddr_1,id_reg_raddr_2;
wire [`DATA_BUS] id_imm_data;
wire [5:0] id_funct;
wire [4:0] id_shamt;
wire [5:0] id_instop;
wire [4:0] id_regimm_func;
wire id_is_delay_slot;

//mem
wire [3:0] id_mem_func;
wire id_mem_imm_flag;
//hilo
wire id_hi_wen,id_lo_wen,id_hi_ren,id_lo_ren;
//cp0
wire id_cp0_ren,id_cp0_wen;
wire [`CP0_ADDR] id_cp0_raddr,id_cp0_waddr;
wire [`DATA_BUS] id_exception_type;

ID u_ID(
    clk,
    rst,
    stall[`ID],
    if_id_exception_type,
    flush_id,
    if_id_pc,id_inst,
    id_pc,
    id_reg_wen,id_reg_ren_1,id_reg_ren_2,
    id_reg_waddr,id_reg_raddr_1,id_reg_raddr_2,
    id_imm_data,
    id_funct,id_shamt,id_instop,
    id_regimm_func,
    id_mem_func,
    id_mem_imm_flag,
    id_is_delay_slot,
    id_br_flag,
    id_br_addr,
    id_hi_wen,
    id_lo_wen,
    id_hi_ren,
    id_lo_ren,
    id_cp0_ren,
    id_cp0_raddr,
    id_cp0_wen,
    id_cp0_waddr,
    id_exception_type
);

//read_reg inputs
reg [`ADDR_BUS] id_rr_pc;
reg id_rr_reg_wen,id_rr_reg_ren_1,id_rr_reg_ren_2;
reg [`REG_ADDR] id_rr_reg_waddr,id_rr_reg_raddr_1,id_rr_reg_raddr_2;
reg [`DATA_BUS] id_rr_imm_data;
reg [5:0] id_rr_funct;
reg [4:0] id_rr_shamt;
reg [5:0] id_rr_instop;
reg [4:0] id_rr_regimm_func;
reg id_rr_is_delay_slot;

//mem
reg [3:0] id_rr_mem_func;
reg id_rr_mem_imm_flag;
//hilo
reg id_rr_hi_wen,id_rr_lo_wen,id_rr_hi_ren,id_rr_lo_ren;
//cp0
reg id_rr_cp0_ren,id_rr_cp0_wen;
reg [`CP0_ADDR] id_rr_cp0_raddr,id_rr_cp0_waddr;
reg [`DATA_BUS] id_rr_exception_type;

always_ff @(posedge clk) begin
    if(!rst || flush[`ID]) begin
        id_rr_pc <= 0;
        id_rr_reg_wen <= 0;
        id_rr_reg_ren_1 <= 0;
        id_rr_reg_ren_2 <= 0;
        id_rr_reg_waddr <= 0;
        id_rr_reg_raddr_1 <= 0;
        id_rr_reg_raddr_2 <= 0;
        id_rr_imm_data <= 0;
        id_rr_funct <= 0;
        id_rr_shamt <= 0;
        id_rr_instop <= 0;
        id_rr_regimm_func <= 0;
        id_rr_mem_func <= 0;
        id_rr_mem_imm_flag <= 0;
        id_rr_hi_wen <= 0;
        id_rr_lo_wen <= 0;
        id_rr_hi_ren <= 0;
        id_rr_lo_ren <= 0;
        id_rr_cp0_ren <= 0;
        id_rr_cp0_raddr <= 0;
        id_rr_cp0_wen <= 0;
        id_rr_cp0_waddr <= 0;
        id_rr_exception_type <= 0;
        id_rr_is_delay_slot <= 0;
    end
    else if((stall[`ID] && ~stall[`RR])) begin
        id_rr_pc <= 0;
        id_rr_reg_wen <= 0;
        id_rr_reg_ren_1 <= 0;
        id_rr_reg_ren_2 <= 0;
        id_rr_reg_waddr <= 0;
        id_rr_reg_raddr_1 <= 0;
        id_rr_reg_raddr_2 <= 0;
        id_rr_imm_data <= 0;
        id_rr_funct <= 0;
        id_rr_shamt <= 0;
        id_rr_instop <= 0;
        id_rr_regimm_func <= 0;
        id_rr_mem_func <= 0;
        id_rr_mem_imm_flag <= 0;
        id_rr_hi_wen <= 0;
        id_rr_lo_wen <= 0;
        id_rr_hi_ren <= 0;
        id_rr_lo_ren <= 0;    
        id_rr_cp0_ren <= 0;
        id_rr_cp0_raddr <= 0;
        id_rr_cp0_wen <= 0;
        id_rr_cp0_waddr <= 0;
        id_rr_exception_type <= 0;    
        id_rr_is_delay_slot <= 0;
    end
    else if(!stall[`ID]) begin
        id_rr_pc <= id_pc;
        id_rr_reg_wen <= id_reg_wen;
        id_rr_reg_ren_1 <= id_reg_ren_1;
        id_rr_reg_ren_2 <= id_reg_ren_2;
        id_rr_reg_waddr <= id_reg_waddr;
        id_rr_reg_raddr_1 <= id_reg_raddr_1;
        id_rr_reg_raddr_2 <= id_reg_raddr_2;
        id_rr_imm_data <= id_imm_data;
        id_rr_funct <= id_funct;
        id_rr_shamt <= id_shamt;
        id_rr_instop <= id_instop;
        id_rr_regimm_func <= id_regimm_func;
        id_rr_mem_func <= id_mem_func;
        id_rr_mem_imm_flag <= id_mem_imm_flag;
        id_rr_hi_wen <= id_hi_wen;
        id_rr_lo_wen <= id_lo_wen;
        id_rr_hi_ren <= id_hi_ren;
        id_rr_lo_ren <= id_lo_ren;
        id_rr_cp0_ren <= id_cp0_ren;
        id_rr_cp0_raddr <= id_cp0_raddr;
        id_rr_cp0_wen <= id_cp0_wen;
        id_rr_cp0_waddr <= id_cp0_waddr;
        id_rr_exception_type <= id_exception_type;
        id_rr_is_delay_slot <= id_is_delay_slot;
    end
end

//read_reg outputs
wire [`ADDR_BUS] rr_pc;
wire rr_reg_wen;
wire [`REG_ADDR] rr_reg_waddr;
wire [5:0] rr_funct;
wire [4:0] rr_shamt;
wire [5:0] rr_instop;
wire [`DATA_BUS] rr_reg_rdata_1,rr_reg_rdata_2;
wire [`DATA_BUS] rr_br_imm_data;
wire [4:0] rr_regimm_func;
wire rr_regimm_en,rr_special2_en;
wire [`DATA_BUS] rr_mem_wdata;
wire rr_is_delay_slot;

//hilo
wire rr_hi_wen,rr_lo_wen;
wire [`DATA_BUS] rr_hi_rdata,rr_lo_rdata;
//cp0
wire rr_cp0_wen,rr_cp0_ren;
wire [`CP0_ADDR] rr_cp0_waddr;
wire [`DATA_BUS] rr_cp0_rdata;
wire [`DATA_BUS] rr_exception_type;

read_reg u_read_reg(
    clk,rst,flush[`RR],
    `ifndef CACHE_ENABLE
        load_related_done,
    `endif
    //from id
    id_rr_pc,
    id_rr_reg_wen,id_rr_reg_ren_1,id_rr_reg_ren_2,
    id_rr_reg_waddr,id_rr_reg_raddr_1,id_rr_reg_raddr_2,
    id_rr_imm_data,
    id_rr_funct,id_rr_shamt,
    id_rr_instop,
    id_rr_exception_type,
    id_rr_is_delay_slot,
    //regimm
    id_rr_regimm_func,
    id_rr_mem_func,
    id_rr_mem_imm_flag,
    id_rr_hi_wen,
    id_rr_lo_wen,
    id_rr_hi_ren,
    id_rr_lo_ren,
    id_rr_cp0_ren,
    id_rr_cp0_raddr,
    id_rr_cp0_wen,
    id_rr_cp0_waddr,
    //from ex
    ex_reg_wen,
    ex_reg_waddr,
    ex_reg_wdata,
    ex_mem_func,
    ex_hilo_wen,
    ex_hilo_wdata,
    ex_cp0_waddr,
    ex_cp0_wdata,
    //from mem
    mem_reg_wen,
    mem_reg_waddr,
    mem_reg_wdata,
    mem_mem_func,
    //from dcache
    //from wb
    wb_reg_wen,
    wb_reg_waddr,
    wb_reg_wdata,
    //output
    rr_pc,
    rr_reg_wen,
    rr_reg_waddr,
    rr_funct,rr_shamt,
    rr_instop,
    rr_reg_rdata_1,rr_reg_rdata_2,
    rr_br_imm_data,
    rr_exception_type,
    rr_is_delay_slot,
    //hilo
    rr_hi_wen,
    rr_lo_wen,
    rr_hi_rdata,
    rr_lo_rdata,
    //regimm
    rr_regimm_en,
    rr_regimm_func,
    //mem
    rr_mem_func,
    rr_mem_imm_flag,
    rr_mem_wdata,
    //special2
    rr_special2_en,
    //load related
    load_related_flag,
    //cp0
    mem_cp0_wen,
    mem_cp0_waddr,
    mem_cp0_wdata,
    interrupt,
    mem_exception_type,
    mem_pc,
    mem_badaddr,
    mem_is_delay_slot,
    //output cp0
    rr_cp0_ren,
    rr_cp0_wen,
    rr_cp0_waddr,
    rr_cp0_rdata,
    //cp0 regs
    cp0_count_o,
    cp0_compare_o,
    cp0_status_o,
    cp0_cause_o,
    cp0_epc_o,
    cp0_config_o,
    cp0_prid_o,
    cp0_badvaddr_o
);

//EX inputs
reg [`ADDR_BUS] rr_ex_pc;
reg rr_ex_reg_wen;
reg [`REG_ADDR] rr_ex_reg_waddr;
reg [5:0] rr_ex_funct;
reg [4:0] rr_ex_shamt;
reg [5:0] rr_ex_instop;
reg [`DATA_BUS] rr_ex_reg_rdata_1,rr_ex_reg_rdata_2;
reg [`DATA_BUS] rr_ex_br_imm_data;
reg rr_ex_is_delay_slot;
//regimm
reg rr_ex_regimm_en;
reg [4:0] rr_ex_regimm_func;
//mem
reg [3:0] rr_ex_mem_func;
reg rr_ex_mem_imm_flag;
reg [`DATA_BUS] rr_ex_mem_wdata;
//special2
reg rr_ex_special2_en;
//hilo
reg rr_ex_hi_wen,rr_ex_lo_wen;
reg [`DATA_BUS] rr_ex_hi_rdata,rr_ex_lo_rdata;
//cp0
reg rr_ex_cp0_wen,rr_ex_cp0_ren;
reg [`CP0_ADDR] rr_ex_cp0_waddr;
reg [`DATA_BUS] rr_ex_cp0_rdata;
reg [`DATA_BUS] rr_ex_exception_type;

always_ff @(posedge clk) begin
    if(!rst || flush[`RR]) begin
        rr_ex_pc <= 0;
        rr_ex_reg_wen <= 0;
        rr_ex_reg_waddr <= 0;
        rr_ex_funct <= 0;
        rr_ex_shamt <= 0;  
        rr_ex_reg_rdata_1 <= 0;
        rr_ex_reg_rdata_2 <= 0; 
        rr_ex_instop <= 0;    
        rr_ex_br_imm_data <= 0;
        rr_ex_regimm_en <= 0;
        rr_ex_regimm_func <= 0;
        rr_ex_mem_func <= 0;
        rr_ex_mem_imm_flag <= 0;
        rr_ex_mem_wdata <= 0;
        rr_ex_special2_en <= 0;
        rr_ex_hi_wen <= 0;
        rr_ex_lo_wen <= 0;
        rr_ex_hi_rdata <= 0;
        rr_ex_lo_rdata <= 0;
        rr_ex_cp0_ren <= 0;
        rr_ex_cp0_wen <= 0;
        rr_ex_cp0_waddr <= 0;
        rr_ex_cp0_rdata <= 0;
        rr_ex_exception_type <= 0;
        rr_ex_is_delay_slot <= 0;
    end
    else if((stall[`RR] && ~stall[`EX])) begin
        rr_ex_pc <= 0;
        rr_ex_reg_wen <= 0;
        rr_ex_reg_waddr <= 0;
        rr_ex_funct <= 0;
        rr_ex_shamt <= 0;  
        rr_ex_reg_rdata_1 <= 0;
        rr_ex_reg_rdata_2 <= 0; 
        rr_ex_instop <= 0;    
        rr_ex_br_imm_data <= 0;
        rr_ex_regimm_en <= 0;
        rr_ex_regimm_func <= 0;
        rr_ex_mem_func <= 0;
        rr_ex_mem_imm_flag <= 0;
        rr_ex_mem_wdata <= 0;    
        rr_ex_special2_en <= 0;    
        rr_ex_hi_wen <= 0;
        rr_ex_lo_wen <= 0;
        rr_ex_hi_rdata <= 0;
        rr_ex_lo_rdata <= 0;
        rr_ex_cp0_ren <= 0;
        rr_ex_cp0_wen <= 0;
        rr_ex_cp0_waddr <= 0;
        rr_ex_cp0_rdata <= 0;
        rr_ex_exception_type <= 0;
        rr_ex_is_delay_slot <= 0;
    end
    else if(!stall[`RR])begin
        rr_ex_pc <= rr_pc;
        rr_ex_reg_wen <= rr_reg_wen;
        rr_ex_reg_waddr <= rr_reg_waddr;
        rr_ex_funct <= rr_funct;
        rr_ex_shamt <= rr_shamt;  
        rr_ex_reg_rdata_1 <= rr_reg_rdata_1;
        rr_ex_reg_rdata_2 <= rr_reg_rdata_2;
        rr_ex_instop <= rr_instop;
        rr_ex_br_imm_data <= rr_br_imm_data;
        rr_ex_regimm_en <= rr_regimm_en;
        rr_ex_regimm_func <= rr_regimm_func;
        rr_ex_mem_func <= rr_mem_func;
        rr_ex_mem_imm_flag <= rr_mem_imm_flag;
        rr_ex_mem_wdata <= rr_mem_wdata;
        rr_ex_special2_en <= rr_special2_en;
        rr_ex_hi_wen <= rr_hi_wen;
        rr_ex_lo_wen <= rr_lo_wen;
        rr_ex_hi_rdata <= rr_hi_rdata;
        rr_ex_lo_rdata <= rr_lo_rdata;
        rr_ex_cp0_ren <= rr_cp0_ren;
        rr_ex_cp0_wen <= rr_cp0_wen;
        rr_ex_cp0_waddr <= rr_cp0_waddr;
        rr_ex_cp0_rdata <= rr_cp0_rdata;
        rr_ex_exception_type <= rr_exception_type;
        rr_ex_is_delay_slot <= rr_is_delay_slot;
    end
end

//EX outputs
wire [`ADDR_BUS] ex_pc;
wire [`DATA_BUS] ex_result;
wire [`DATA_BUS] ex_mem_wdata;
wire [`DATA_BUS] ex_exception_type;
wire ex_is_delay_slot;
wire [`DATA_BUS] ex_cp0_wwdata;

EX u_EX(
    clk,
    rst,
    flush[`EX],
    //from read_reg
    rr_ex_pc,
    rr_ex_reg_wen,rr_ex_reg_waddr,
    rr_ex_funct,rr_ex_shamt,
    rr_ex_instop,
    rr_ex_reg_rdata_1,rr_ex_reg_rdata_2,
    rr_ex_br_imm_data,
    rr_ex_is_delay_slot,
    //hilo
    rr_ex_hi_wen,
    rr_ex_lo_wen,
    rr_ex_hi_rdata,
    rr_ex_lo_rdata,
    rr_ex_cp0_ren,
    rr_ex_cp0_wen,
    rr_ex_cp0_waddr,
    rr_ex_cp0_rdata,
    rr_ex_exception_type,
    //regimm input
    rr_ex_regimm_en,
    rr_ex_regimm_func,
    //special2 input
    rr_ex_special2_en,
    //mem input
    rr_ex_mem_func,
    rr_ex_mem_imm_flag,
    rr_ex_mem_wdata,
    //branch_output
    ex_br_flag,
    ex_br_addr,
    //output
    ex_pc,
    ex_reg_wen,
    ex_reg_waddr,
    ex_reg_wdata,
    ex_hilo_wen,
    ex_hilo_wdata,
    ex_cp0_wen,
    ex_cp0_waddr,
    ex_cp0_wdata,
    ex_exception_type,
    //mem
    ex_mem_func,
    ex_mem_imm_flag,
    ex_mem_wdata,
    //control
    ex_stall_req,
    ex_is_delay_slot,
    ex_cp0_wwdata
);

//MEM inputs
reg [`ADDR_BUS] ex_mem_pc;
reg ex_mem_reg_wen;
reg [`REG_ADDR] ex_mem_reg_waddr;
reg [`DATA_BUS] ex_mem_result;
reg [3:0] ex_mem_mem_func;
reg ex_mem_mem_imm_flag;
reg [`DATA_BUS] ex_mem_mem_wdata;
reg ex_mem_cp0_wen;
reg [`CP0_ADDR] ex_mem_cp0_waddr;
reg [`DATA_BUS] ex_mem_cp0_wdata;
reg [`DATA_BUS] ex_mem_exception_type;
reg ex_mem_is_delay_slot;
reg [`DATA_BUS] ex_mem_cp0_wwdata;

always_ff @(posedge clk) begin
    if(!rst || flush[`EX]) begin
        ex_mem_pc <= 0;
        ex_mem_reg_wen <= 0;
        ex_mem_reg_waddr <= 0;
        ex_mem_result <= 0;
        ex_mem_mem_func <= 0;
        ex_mem_mem_imm_flag <= 0;
        ex_mem_mem_wdata <= 0;
        ex_mem_cp0_wen <= 0;
        ex_mem_cp0_waddr <= 0;
        ex_mem_cp0_wdata <= 0;
        ex_mem_exception_type <= 0;
        ex_mem_is_delay_slot <= 0;
        ex_mem_cp0_wwdata <= 0;
    end
    else if(stall[`EX] && ~stall[`MEM]) begin
        ex_mem_pc <= 0;
        ex_mem_reg_wen <= 0;
        ex_mem_reg_waddr <= 0;
        ex_mem_result <= 0;
        ex_mem_mem_func <= 0;
        ex_mem_mem_imm_flag <= 0;
        ex_mem_mem_wdata <= 0;       
        ex_mem_cp0_wen <= 0;
        ex_mem_cp0_waddr <= 0;
        ex_mem_cp0_wdata <= 0; 
        ex_mem_exception_type <= 0;
        ex_mem_is_delay_slot <= 0;
        ex_mem_cp0_wwdata <= 0;
    end
    else if(!stall[`EX])begin
        ex_mem_pc <= ex_pc;
        ex_mem_reg_wen <= ex_reg_wen;
        ex_mem_reg_waddr <= ex_reg_waddr;
        ex_mem_result <= ex_reg_wdata;
        ex_mem_mem_func <= ex_mem_func;
        ex_mem_mem_imm_flag <= ex_mem_imm_flag;
        ex_mem_mem_wdata <= ex_mem_wdata;
        ex_mem_cp0_wen <= ex_cp0_wen;
        ex_mem_cp0_waddr <= ex_cp0_waddr;
        ex_mem_cp0_wdata <= ex_cp0_wdata;
        ex_mem_exception_type <= ex_exception_type;
        ex_mem_is_delay_slot <= ex_is_delay_slot;
        ex_mem_cp0_wwdata <= ex_cp0_wwdata;
    end
end

wire [`DATA_BUS] mem_cp0_wb_data;

MEM u_MEM(
    rst,
    ex_mem_pc,
    ex_mem_reg_wen,
    ex_mem_reg_waddr,
    ex_mem_result,
    ex_mem_is_delay_slot,
    //mem control
    ex_mem_mem_func,
    ex_mem_mem_imm_flag,
    ex_mem_mem_wdata,
    //cp0
    ex_mem_cp0_wen,
    ex_mem_cp0_waddr,
    ex_mem_cp0_wdata,
    ex_mem_cp0_wwdata,
    ex_mem_exception_type,
    //output ram control
    ram_en,
    ram_sel,ram_addr,
    ram_wdata,
    //output for RAW and load related
    mem_pc,
    mem_reg_wen,
    mem_reg_waddr,
    mem_reg_wdata,
    mem_mem_func,
    mem_mem_imm_flag,
    //only fro sram test
    mem_addr,
    mem_cp0_wen,
    mem_cp0_waddr,
    mem_cp0_wb_data,
    //cp0 regs
    cp0_count_o,
    cp0_cause_o,
    cp0_compare_o,
    cp0_config_o,
    cp0_epc_o,
    cp0_status_o,
    //exception control
    mem_exception_type,
    exception_flag,
    exc_pc,
    mem_is_delay_slot,
    mem_cp0_wdata,
    mem_badaddr
);

`ifdef CACHE_ENABLE
    //dcache inputs

    always_ff @(posedge clk) begin
        if(!rst) begin
            
        end
        else begin

        end
    end

    dcache u_dcache();

    //dcache outputs

`endif

//WB inputs
reg [`ADDR_BUS] mem_wb_pc;
reg mem_wb_reg_wen;
reg [`REG_ADDR] mem_wb_reg_waddr;
reg [`DATA_BUS] mem_wb_result;
reg [3:0] mem_wb_mem_func;
reg mem_wb_mem_imm_flag;
reg [`ADDR_BUS] mem_wb_mem_addr;
reg [`DATA_BUS] mem_wb_cp0_wb_data;

always_ff @(posedge clk) begin
    if(!rst || flush[`MEM]) begin
        mem_wb_pc <= 0;
        mem_wb_reg_wen <= 0;
        mem_wb_reg_waddr <= 0;
        mem_wb_result <= 0;
        mem_wb_mem_func <= 0;
        mem_wb_mem_imm_flag <= 0;
        mem_wb_mem_addr <= 0;
        mem_wb_cp0_wb_data <= 0;
    end
    else begin
        mem_wb_pc <= mem_pc;
        mem_wb_reg_wen <= mem_reg_wen;
        mem_wb_reg_waddr <= mem_reg_waddr;
        mem_wb_result <= mem_reg_wdata;
        mem_wb_mem_func <= mem_mem_func;
        mem_wb_mem_imm_flag <= mem_mem_imm_flag;
        mem_wb_mem_addr <= mem_addr;
        mem_wb_cp0_wb_data <= mem_cp0_wb_data;
    end
end

WB u_WB(
    rst,
    mem_wb_pc,
    mem_wb_reg_wen,
    mem_wb_reg_waddr,
    mem_wb_result,
    //control output
    load_related_done,
    //mem input
    mem_wb_mem_func,
    mem_wb_mem_imm_flag,
    mem_wb_mem_addr,
    ram_rdata,
    mem_wb_cp0_wb_data,
    //output
    wb_pc,
    wb_reg_wen,
    wb_reg_waddr,
    wb_reg_wdata    
);

pipeline_ctrl u_ctrl(
    rst,
    exception_flag,
    //branch inputs
    ex_br_flag,
    load_related_flag,
    ex_stall_req,
    stall,
    flush
);

endmodule