module equalizer(
	input clk,
	input rst_n,
	input in_H_SYNC,
	input in_V_SYNC,
	input in_data_en,
	input inter_complete,
	input [7:0] data_in,
	input [15:0] block_size,
	input TVALID_in,
	
	input [15:0] porta_data_out_1,///直方图灰度映射值
	input [15:0] porta_data_out_2,
	input [15:0] porta_data_out_3,
	input [15:0] porta_data_out_4,
	input [15:0] excess_rd_data1,
	input [15:0] excess_rd_data2,
	input [15:0] excess_rd_data3,
	input [15:0] excess_rd_data4,
	
	input [21:0] w1,
	input [21:0] w2,
	input [21:0] w3,
	input [21:0] w4,
	
	output o_H_SYNC,
	output o_V_SYNC,
	output o_data_en,
	output [7:0] data_out,
	output equ_complete
);
//该模块计算均衡化和差值，延迟2个周期

	function [7:0] Get_gray(//左移8位后，除以57600
		input [15:0] ram_data,
		input [15:0] block_size
	);
		reg [51:0] temp_a;
		reg [51:0] temp_b;
		integer i;
	begin
			temp_a = {26'd0, ram_data, 8'd0};
			temp_b = {8'd0, block_size, 26'd0};
			
			for(i = 0;i < 26;i = i + 1)  
			begin  
            temp_a = {temp_a[50:0],1'b0};  
            if(temp_a[51:26] >= block_size)  
                temp_a = temp_a - temp_b + 1'b1;  
            else  
                temp_a = temp_a;  
         end
			Get_gray = temp_a[25:8] >= 1? 8'hff : temp_a[7:0];
	end
	endfunction
	
//	parameter block_size = 57600;
	
	reg [7:0] gray_1, gray_2,
				 gray_3, gray_4;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			gray_1 <= 0;
			gray_2 <= 0;
			gray_3 <= 0;
			gray_4 <= 0;
		end
		else if(in_data_en)
		begin
		    if(TVALID_in)
		    begin
			gray_1 <= Get_gray(porta_data_out_1 + excess_rd_data1*(data_in),block_size);
			gray_2 <= Get_gray(porta_data_out_2 + excess_rd_data2*(data_in),block_size);
			gray_3 <= Get_gray(porta_data_out_3 + excess_rd_data3*(data_in),block_size);
			gray_4 <= Get_gray(porta_data_out_4 + excess_rd_data4*(data_in),block_size);
			end
			else;
		end
		else
		begin
			gray_1 <= 0;
			gray_2 <= 0;
			gray_3 <= 0;
			gray_4 <= 0;
		end
	end
	//权重缓存一个周期
	reg [21:0] w1_r, w2_r,
				  w3_r, w4_r;
				  
	reg [21:0] w1_r2, w2_r2,
				  w3_r2, w4_r2;
				  
	reg [21:0] w1_r3, w2_r3,
				  w3_r3, w4_r3;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			w1_r <= 0;
			w2_r <= 0;
			w3_r <= 0;
			w4_r <= 0;
			
			w1_r2 <= 0;
			w2_r2 <= 0;
			w3_r2 <= 0;
			w4_r2 <= 0;
			
			w1_r3 <= 0;
			w2_r3 <= 0;
			w3_r3 <= 0;
			w4_r3 <= 0;
		end
		else
		begin
		    if(TVALID_in)
		    begin
			w1_r <= w1;
			w2_r <= w2;
			w3_r <= w3;
			w4_r <= w4;
			
			w1_r2 <= w1_r;
			w2_r2 <= w2_r;
			w3_r2 <= w3_r;
			w4_r2 <= w4_r;
			
			w1_r3 <= w1_r2;
			w2_r3 <= w2_r2;
			w3_r3 <= w3_r2;
			w4_r3 <= w4_r2;
			end
			else;
		end
	end
	
	reg [29:0] data_out_r;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			data_out_r <= 0;
		else 
		    if(TVALID_in)
			data_out_r <= w1_r3*gray_1 + w2_r3*gray_2 + 
							  w3_r3*gray_3 + w4_r3*gray_4 + 20'd524288;
			else;
	end
//	assign data_out = data_out_r[27:20];
	assign data_out = data_out_r[29:28] >= 1 ? 8'hff : data_out_r[27:20];
	
	//
	 parameter delay_time = 5;//输出延迟为5个周期
	
	 reg [delay_time - 1:0] H_SYNC_r;
	 reg [delay_time - 1:0] V_SYNC_r;
	 reg [delay_time - 1:0] data_en_r;
	 reg [delay_time - 1:0]	complete_r;
	 assign o_H_SYNC = H_SYNC_r[delay_time - 1];
	 assign o_V_SYNC = V_SYNC_r[delay_time - 1];
	 assign o_data_en = data_en_r[delay_time - 1];
	 assign equ_complete = complete_r[delay_time - 1];
	 always@(posedge clk or negedge rst_n)
	 begin
		if(~rst_n)
		begin
			H_SYNC_r <= 0;
			V_SYNC_r <= 0;
			data_en_r <= 0;
			complete_r <= 0;
		end
		else
		begin
		    if(TVALID_in == 0)
		    begin
		    H_SYNC_r <= H_SYNC_r;
			V_SYNC_r <= V_SYNC_r;
			data_en_r <= data_en_r;
//			complete_r <= complete_r;
		    end
		    else
		    begin
			H_SYNC_r <= {H_SYNC_r[delay_time - 2:0],in_H_SYNC};
			V_SYNC_r <= {V_SYNC_r[delay_time - 2:0],in_V_SYNC};
			data_en_r <= {data_en_r[delay_time - 2:0],in_data_en};
//			complete_r <= {complete_r[delay_time - 2:0],inter_complete};
			end
			complete_r <= {complete_r[delay_time - 2:0],inter_complete};
		end
	end
endmodule 