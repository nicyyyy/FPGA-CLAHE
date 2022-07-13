
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/08 15:11:55
// Design Name: 
// Module Name: VGA2AXI
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


module VGA2AXI(
    input H_SYNC,
    input V_SYNC,
    input DATA_EN,
    input [7:0] pixel,
    input clk,
    input rst_n,
    input TVALID_in,
	 input TUSER_in,
    input [10:0] width,
	 input [10:0] height,
	
    output ACLK,
    output ARESTN,
    output [7:0] TDATA,
    output TSTRB,
    output reg TLAST,
    output TVALID,
    output reg TUSER,
    input TREADY
    );
    //parameter delay_time = 3;
//    parameter cycle_delay = 4*height - 3 + 2 + 3;
//    parameter cycle_complete = height*width + 4*height - 3 + 2 + 3;

//    reg [19:0] cnt;
	 
//    assign TVALID = cnt <= (8) ? 0 : 
//                           ((cnt < (height*width + 8) && cnt > (height*width))? 1 : TVALID_in);
//	 assign TVALID =  (cnt < (height*width + 8) && cnt > (height*width))? 1 : TVALID_in;
    assign TDATA = (TVALID == 1 && TREADY == 1)? pixel : 8'd0;
    assign ACLK = clk;
    assign ARESTN = rst_n;
    assign TVALID = DATA_EN;
    
    always@(*)
    begin
        if(~ARESTN)
            TLAST = 0;
        else
        begin
            if(TVALID == 1 && TREADY == 1)
                TLAST = ~H_SYNC;
            else
                TLAST = 0;
        end
    end
    
    always@(*)
    begin
        if(~ARESTN)
            TUSER = 0;
        else
        begin
            if(TVALID == 1 && TREADY == 1)
                TUSER = ~V_SYNC;
            else
                TUSER = 0;
        end
    end
    
    
//    always@(posedge clk or negedge rst_n)
//    begin
//        if(~rst_n)
//            cnt <= 0;
//			else if(TUSER_in)
//				cnt <= 1;
//         else
//         begin
//            if(TVALID_in == 1)
//                cnt <= cnt + 1;
//            else if(cnt > height*width)
//                cnt <= cnt + 1;
//            else
//                cnt <= cnt;
//         end
//    end
endmodule
