`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Yang Qingyao 
// 
// Create Date: 2022/06/03 12:50:30
// Design Name: 
// Module Name: AXI2VGA
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AXI2VGA(
    input ACLK,
    input ARESTN,
    input [7:0] TDATA,
    input TSTRB,
    input TLAST,
    input TVALID,
    input TUSER,
    output TREADY,
    
    output reg H_SYNC,
    output reg V_SYNC,
    output  DATA_EN,
    output [7:0] pixel
    );
    
//    wire [7:0] pixel;
//    reg H_SYNC, V_SYNC, DATA_EN;
    
    assign TREADY = 1'b1;
    assign pixel = TDATA;
    
    always@(*)
    begin
        if(~ARESTN)
            V_SYNC = 1'b0;
        else 
        begin
            if(TVALID == 1'b1)
                V_SYNC = ~TUSER;
            else
                V_SYNC = V_SYNC;
        end   
    end
    
    always@(*)
    begin
        if(~ARESTN)
            H_SYNC = 1'b0;
        else 
        begin
            if(TVALID == 1'b1)
                H_SYNC = ~TLAST;
            else
                H_SYNC = H_SYNC;
        end      
    end
    
    assign DATA_EN = TVALID;
//    always
//        DATA_EN = H_SYNC & V_SYNC;
endmodule
