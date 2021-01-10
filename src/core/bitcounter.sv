`timescale 1ns/1ps

`include "../../include/global.svh"
//calculate the front 0 or 1,high to low
//cnt_en = 0 means count the num of zeroes
module bitcounter(
    input rst,
    input cnt_en,
    input [`DATA_BUS] val_i,
    output reg [`DATA_BUS] val_o
);
    logic [`DATA_BUS] count0,count1,count2,count3;

    bit_byte_counter u_counter0(
        rst,cnt_en,val_i[7:0],count0
    );
    bit_byte_counter u_counter1(
        rst,cnt_en,val_i[15:8],count1
    );
    bit_byte_counter u_counter2(
        rst,cnt_en,val_i[23:16],count2
    );
    bit_byte_counter u_counter3(
        rst,cnt_en,val_i[31:24],count3
    );


    always_comb begin
        if(!rst) begin
            val_o <= 0;
        end
        else begin
            if(count3 == 0) begin
                val_o <= 0;
            end
            else if(count3 < 8) begin
                val_o <= count3;
            end
            else if(count2 < 8) begin
                val_o <= count2 + 8;
            end
            else if(count1 < 8) begin
                val_o <= count1 + 16;
            end
            else begin
                val_o <= count0 + 24;
            end
        end
    end

    module bit_byte_counter(
        input rst,
        input cnt_en,
        input [7:0] val_i,
        output reg [`DATA_BUS] val_o
    );
        always_comb begin
            if(!rst) begin
                val_o <= 0;
            end
            else begin
                val_o <= 0;
                if(cnt_en) begin
                    casez(val_i)
                        8'b0???_????:val_o <= 0;
                        8'b10??_????:val_o <= 1;
                        8'b110?_????:val_o <= 2;
                        8'b1110_????:val_o <= 3;
                        8'b1111_0???:val_o <= 4;
                        8'b1111_10??:val_o <= 5;
                        8'b1111_110?:val_o <= 6;
                        8'b1111_1110:val_o <= 7;
                        8'b1111_1111:val_o <= 8;
                    endcase
                end
                else begin
                    casez(val_i)
                        8'b1???_????:val_o <= 0;
                        8'b01??_????:val_o <= 1;
                        8'b001?_????:val_o <= 2;
                        8'b0001_????:val_o <= 3;
                        8'b0000_1???:val_o <= 4;
                        8'b0000_01??:val_o <= 5;
                        8'b0000_001?:val_o <= 6;
                        8'b0000_0001:val_o <= 7;
                        8'b0000_0000:val_o <= 8;
                    endcase                    
                end
            end
        end
    endmodule
endmodule