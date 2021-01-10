`timescale 1ns/1ps

`include "../../include/global.svh"
`include "../../include/config.svh"

module pipeline_ctrl(
    input rst,
    input exception_flag,
    //branch inputs
    input ex_br_flag,
    //load related inputs
    input [1:0] load_related_flag,
    //ex stall req
    input ex_stall_req,
    //outputs
    output reg [4:0] stall,
    output reg [4:0] flush
);
    always_comb begin
        if(!rst) begin
            flush <= 0;
        end
        else begin
            if(exception_flag) begin
                flush <= 5'b01111;
            end
            else if(ex_br_flag) begin
                flush <= 5'b00011;
            end
            else begin
                flush <= 0;
            end
        end
    end

    always_comb begin
        if(!rst) begin
            stall <= 0;
        end
        else if(ex_stall_req) begin
            stall <= 5'b01111;
        end
        else if(load_related_flag) begin
            stall <= 5'b00111;
        end
        else begin
            stall <= 0;
        end
    end
    
endmodule