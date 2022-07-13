module interpolation_cntl(
	input clk,
	input rst_n,
	input in_H_SYNC,
	input in_V_SYNC,
	input in_data_en,
	input [7:0] data_in,
	input area_flag,
	input [10:0] width,
	input [10:0] height,
	input TVALID_in,
	
	output reg [4:0] porta_rd_block1,//读直方图ram的block地址
	output reg [4:0] porta_rd_block2,
	output reg [4:0] porta_rd_block3,
	output reg [4:0] porta_rd_block4,
	output reg [7:0] portb_addr,//灰度值
//	output reg [4:0] portb_wr_block,

	
	output reg [21:0] w1,
	output reg [21:0] w2,
	output reg [21:0] w3,
	output reg [21:0] w4,
	
	//读excess
	output reg [4:0] excess_addr_rd1,
	output reg [4:0] excess_addr_rd2,
	output reg [4:0] excess_addr_rd3,
	output reg [4:0] excess_addr_rd4,
	output excess_rden,
	
	output o_H_SYNC,
	output o_V_SYNC,
	output o_data_en,
	output reg [7:0] inter_data_out,
	output reg inter_complete,
	output TVALID_inter
);
//除法器
	function [10:0] div(//先把除数左移10位,变成20位除法器
		input [9:0] a,
		input [9:0] b
	);
		reg [39:0] temp_a;
		reg [39:0] temp_b;
		integer i;
	begin
			temp_a = {20'd0, a, 10'd0};
			temp_b = {10'd0, b, 20'd0};
			
			for(i = 0;i < 20;i = i + 1)  
			begin  
            temp_a = {temp_a[38:0],1'b0};  
            if(temp_a[39:20] >= b)  
                temp_a = temp_a - temp_b + 1'b1;  
            else  
                temp_a = temp_a;  
         end
			div = temp_a[10:0];
	end
	endfunction

//第二个周期输出地址，第3个周期输出权重，利用第三个周期的时间读取ram中的灰度映射
//行、列计数器
//	parameter wb_size = width/4;
//	parameter hb_size = height/4;
	reg [10:0] wb_size,hb_size;
	always@(*)
	begin
		wb_size = width >> 2;
		hb_size = height >> 2;
	end
	
	reg [10:0] height_cnt;
	reg [10:0] width_cnt;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			width_cnt <= 1;
		else if(in_data_en == 1)
		begin
		    if(TVALID_in)
		    begin
			     if(width_cnt < width)
			     	width_cnt <= width_cnt + 1;
			     else
			     	width_cnt <= 1;
		    end
		    else
				width_cnt <= width_cnt;
		end
		// else if(width_cnt == width)
		// 	width_cnt <= 1;
		else
			width_cnt <= 1;
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			height_cnt <= 1;
		else if(in_data_en == 1)
		begin
		    if(TVALID_in)
		    begin
			     if(width_cnt == width)
			     begin
			     	if(height_cnt < height)
			     		height_cnt <= height_cnt + 1;
			     	else
			     		height_cnt <= 1;
			     end
			     else
			     	height_cnt <= height_cnt;
		    end
		    else
				height_cnt <= height_cnt;
		end
		else
			height_cnt <= 1;
	end
	
	/////////////////////////////////////////////////
	//生成地址信号，取映射后的灰度值
	//使用状态机判断像素点的位置，生成对应的地址信号
	//第一个周期判断状态和block，并且把输入像素缓存，第二个周期产生地址
	reg [1:0] block_flag_height;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			block_flag_height <= 0;
		else if(height_cnt <= hb_size)
			block_flag_height <= 2'b00;
		else if(height_cnt > hb_size && height_cnt <= hb_size*2)
			block_flag_height <= 2'b01;
		else if(height_cnt > hb_size*2 && height_cnt <= hb_size*3)
			block_flag_height <= 2'b10;
		else if(height_cnt > hb_size*3 && height_cnt <= height)
			block_flag_height <= 2'b11;
		else;
	end
	
	reg [1:0] block_flag_width;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			block_flag_width <= 0;
		else if(width_cnt <= wb_size)
			block_flag_width <= 2'b00;
		else if(width_cnt > wb_size && width_cnt <= wb_size*2)
			block_flag_width <= 2'b01;
		else if(width_cnt > wb_size*2 && width_cnt <= wb_size*3)
			block_flag_width <= 2'b10;
		else if(width_cnt > wb_size*3 && width_cnt <= width)
			block_flag_width <= 2'b11;
		else;
	end
	
	//输入像素点灰度值缓存一个周期
	reg [7:0] data_in_r;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			data_in_r <= 0;
			portb_addr <= 8'hzz;
		end
		else if(in_data_en == 1)
		begin
		    if(TVALID_in)
		    begin
			data_in_r <= data_in;
			portb_addr <= data_in_r;
			end
			else;
		end
		else
		begin
//			data_in_r <= data_in;//////////////////////////////////////////////////////////////////////////////////
			portb_addr <= 8'hzz;
		end
	end
	//状态转移
	reg [4:0] state;
	// parameter zone_non = 9'b000000001,
	// 			 zone_linear_v = 9'b000000010,
	// 			 zone_linear_h = 9'b000000100,
				 
	// 			 zone_bilinear_r = 9'b000001000,
	// 			 zone_bilinear_ru = 9'b000010000,
	// 			 zone_bilinear_ld = 9'b000100000,
	// 			 zone_bilinear_l = 9'b001000000,
				 
	// 			 zone_linear_hl = 9'b010000000,
	// 			 zone_linear_vu = 9'b100000000;
	parameter 	 zone_non = 5'd0,
				//  zone_linear_v = 5'd1,
				//  zone_linear_h = 5'd2,
				 
				//  zone_linear_hl = 5'd3,
				//  zone_linear_vu = 5'd4,

				 zone_bilinear_r1 = 5'd5,
				 zone_bilinear_r2 = 5'd6,
				 zone_bilinear_r3 = 5'd7,
				 zone_bilinear_r4 = 5'd8,
				 zone_bilinear_r5 = 5'd9,
				 zone_bilinear_r6 = 5'd10,
				 zone_bilinear_r7 = 5'd11,
				 zone_bilinear_r8 = 5'd12,
				 zone_bilinear_r9 = 5'd13,

				 zone_bilinear_r71 = 5'd14,
				 zone_bilinear_r81 = 5'd15,
				 zone_bilinear_r91 = 5'd16,
				 zone_bilinear_r11 = 5'd17,
				 zone_bilinear_r21 = 5'd18,
				 zone_bilinear_r31 = 5'd19,

				zone_bilinear_r12 = 5'd20,
				zone_bilinear_r42 = 5'd21,
				zone_bilinear_r72 = 5'd22,

				zone_bilinear_r32 = 5'd23,
				zone_bilinear_r62 = 5'd24,
				zone_bilinear_r92 = 5'd25;

	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			state <= 0;
		else
		begin
			if(((height_cnt <= hb_size/2) && (width_cnt <= wb_size/2)) || 
				((height_cnt > (hb_size*3 + hb_size/2)) && (width_cnt <= wb_size/2)) ||
				((height_cnt <= hb_size/2) && (width_cnt > (wb_size*3 + wb_size/2))) ||
				((height_cnt > (hb_size*3 + hb_size/2)) && (width_cnt > (wb_size*3 + wb_size/2))) )
				state <= zone_non;
				
			// else if(((height_cnt > hb_size/2) && (height_cnt <= hb_size*3) && (width_cnt <= wb_size/2)) || 
			// 		  ((height_cnt > hb_size/2) && (height_cnt <= hb_size*3) && (width_cnt > (wb_size*3+wb_size/2))) )
			// 	state <= zone_linear_v;
				
			// else if(((height_cnt <= hb_size/2) && (width_cnt > wb_size/2) && (width_cnt < wb_size*3)) ||
			// 		  ((height_cnt > (hb_size*3+hb_size /2)) && (width_cnt > wb_size/2) && (width_cnt <= wb_size*3)) )
			// 	state <= zone_linear_h;

			
			else if(((height_cnt > hb_size/2) && (height_cnt <= hb_size*3/2)) && ((width_cnt > wb_size/2) && (width_cnt <= wb_size*3/2)))
				state <= zone_bilinear_r1;
			else if(((height_cnt > hb_size/2) && (height_cnt <= hb_size*3/2)) && ((width_cnt > wb_size*3/2) && (width_cnt <= wb_size*5/2)))
				state <= zone_bilinear_r2;
			else if(((height_cnt > hb_size/2) && (height_cnt <= hb_size*3/2)) && ((width_cnt > wb_size*5/2) && (width_cnt <= wb_size*7/2)))
				state <= zone_bilinear_r3;

			else if(((height_cnt > hb_size*3/2) && (height_cnt <= hb_size*5/2)) && ((width_cnt > wb_size/2) && (width_cnt <= wb_size*3/2)))
				state <= zone_bilinear_r4;
			else if(((height_cnt > hb_size*3/2) && (height_cnt <= hb_size*5/2)) && ((width_cnt > wb_size*3/2) && (width_cnt <= wb_size*5/2)))
				state <= zone_bilinear_r5;
			else if(((height_cnt > hb_size*3/2) && (height_cnt <= hb_size*5/2)) && ((width_cnt > wb_size*5/2) && (width_cnt <= wb_size*7/2)))
				state <= zone_bilinear_r6;
			
			else if(((height_cnt > hb_size*5/2) && (height_cnt <= hb_size*7/2)) && ((width_cnt > wb_size/2) && (width_cnt <= wb_size*3/2)))
				state <= zone_bilinear_r7;
			else if(((height_cnt > hb_size*5/2) && (height_cnt <= hb_size*7/2)) && ((width_cnt > wb_size*3/2) && (width_cnt <= wb_size*5/2)))
				state <= zone_bilinear_r8;
			else if(((height_cnt > hb_size*5/2) && (height_cnt <= hb_size*7/2)) && ((width_cnt > wb_size*5/2) && (width_cnt <= wb_size*7/2)))
				state <= zone_bilinear_r9;
			
			else if(((height_cnt > hb_size*7/2) && (height_cnt <= hb_size*4)) && ((width_cnt > wb_size/2) && (width_cnt <= wb_size*3/2)))
				state <= zone_bilinear_r71;
			else if(((height_cnt > hb_size*7/2) && (height_cnt <= hb_size*4)) && ((width_cnt > wb_size*3/2) && (width_cnt <= wb_size*5/2)))
				state <= zone_bilinear_r81;
			else if(((height_cnt > hb_size*7/2) && (height_cnt <= hb_size*4)) && ((width_cnt > wb_size*5/2) && (width_cnt <= wb_size*7/2)))
				state <= zone_bilinear_r91;

			else if((height_cnt <= hb_size/2) && ((width_cnt > wb_size/2) && (width_cnt <= wb_size*3/2)))
				state <= zone_bilinear_r11;
			else if((height_cnt <= hb_size/2) && ((width_cnt > wb_size*3/2) && (width_cnt <= wb_size*5/2)))
				state <= zone_bilinear_r21;
			else if((height_cnt <= hb_size/2) && ((width_cnt > wb_size*5/2) && (width_cnt <= wb_size*7/2)))
				state <= zone_bilinear_r31;

			else if(((height_cnt > hb_size/2) && (height_cnt <= hb_size*3/2)) && (width_cnt <= wb_size/2))
				state <= zone_bilinear_r12;
			else if(((height_cnt > hb_size*3/2) && (height_cnt <= hb_size*5/2)) && (width_cnt <= wb_size/2))
				state <= zone_bilinear_r42;
			else if(((height_cnt > hb_size*5/2) && (height_cnt <= hb_size*7/2)) && (width_cnt <= wb_size/2))
				state <= zone_bilinear_r72;

			else if(((height_cnt > hb_size/2) && (height_cnt <= hb_size*3/2)) && (width_cnt > wb_size*7/2))
				state <= zone_bilinear_r32;
			else if(((height_cnt > hb_size*3/2) && (height_cnt <= hb_size*5/2)) && (width_cnt > wb_size*7/2))
				state <= zone_bilinear_r62;
			else if(((height_cnt > hb_size*5/2) && (height_cnt <= hb_size*7/2)) && (width_cnt > wb_size*7/2))
				state <= zone_bilinear_r92;
			// else if(((height_cnt > hb_size*3) && (height_cnt <= (hb_size*3+hb_size /2)) && (width_cnt <= wb_size/2)) || 
			// 		  ((height_cnt > hb_size*3) && (height_cnt <= (hb_size*3+hb_size /2)) && (width_cnt > (wb_size*3+wb_size/2))) )
			// 	state <= zone_linear_vu;
			// else
			// 	state <= zone_bilinear_l;
		end
	end
	
	//第二个周期根据状态产生地址
	wire excess_wr_en_en;
	assign excess_rden = 1;
//	always@(posedge clk or negedge rst_n)
//	begin
//		if(~rst_n)
//		begin
//			excess_rden <= 1'b0;
//		end
//		else if(excess_wr_en_en)
//		begin
//			excess_rden <= 1;
//		end
//		else
//		begin
//			excess_rden <= 1'b0;
//		end
//	end
	
	reg [4:0] porta_rd_block1_r,
				 porta_rd_block2_r,
				 porta_rd_block3_r,
				 porta_rd_block4_r;
				 
	reg [4:0] porta_rd_block1_r2,
				 porta_rd_block2_r2,
				 porta_rd_block3_r2,
				 porta_rd_block4_r2;
				 
	reg [4:0] porta_rd_block1_r3,
				 porta_rd_block2_r3,
				 porta_rd_block3_r3,
				 porta_rd_block4_r3;
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			porta_rd_block1_r <= 5'bz;
			porta_rd_block2_r <= 5'bz;
			porta_rd_block3_r <= 5'bz;
			porta_rd_block4_r <= 5'bz;
		end
		else
		begin
			case(state)
			zone_non://四个都是一样
				begin
					porta_rd_block1_r <= {area_flag, block_flag_height, block_flag_width};
					porta_rd_block2_r <= {area_flag, block_flag_height, block_flag_width};
					porta_rd_block3_r <= {area_flag ,block_flag_height, block_flag_width};
					porta_rd_block4_r <= {area_flag, block_flag_height, block_flag_width};
				end
			// zone_linear_v://1和2一样，3和4一样，取列方向下一个block
			// 	begin
					
			// 		porta_rd_block1_r <= {area_flag, block_flag_height, block_flag_width};
			// 		porta_rd_block2_r <= {area_flag, block_flag_height, block_flag_width};
			// 		porta_rd_block3_r <= {area_flag, (block_flag_height + 1'b1), block_flag_width};
			// 		porta_rd_block4_r <= {area_flag, (block_flag_height + 1'b1), block_flag_width};
			// 	end
			// zone_linear_vu:
			// 	begin
			// 		porta_rd_block1_r <= {area_flag, block_flag_height, block_flag_width};
			// 		porta_rd_block2_r <= {area_flag, block_flag_height, block_flag_width};
			// 		porta_rd_block3_r <= {area_flag, (block_flag_height - 1'b1), block_flag_width};
			// 		porta_rd_block4_r <= {area_flag, (block_flag_height - 1'b1), block_flag_width};
			// 	end
			
			zone_bilinear_r1:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0000};
					porta_rd_block2_r <= {area_flag, 4'b0001};
					porta_rd_block3_r <= {area_flag, 4'b0100};
					porta_rd_block4_r <= {area_flag, 4'b0101};
				end
			zone_bilinear_r2:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0001};
					porta_rd_block2_r <= {area_flag, 4'b0010};
					porta_rd_block3_r <= {area_flag, 4'b0101};
					porta_rd_block4_r <= {area_flag, 4'b0110};
				end
			zone_bilinear_r3:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0010};
					porta_rd_block2_r <= {area_flag, 4'b0011};
					porta_rd_block3_r <= {area_flag, 4'b0110};
					porta_rd_block4_r <= {area_flag, 4'b0111};
				end

			zone_bilinear_r4:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0100};
					porta_rd_block2_r <= {area_flag, 4'b0101};
					porta_rd_block3_r <= {area_flag, 4'b1000};
					porta_rd_block4_r <= {area_flag, 4'b1001};
				end
			zone_bilinear_r5:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0101};
					porta_rd_block2_r <= {area_flag, 4'b0110};
					porta_rd_block3_r <= {area_flag, 4'b1001};
					porta_rd_block4_r <= {area_flag, 4'b1010};
				end
			zone_bilinear_r6:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0110};
					porta_rd_block2_r <= {area_flag, 4'b0111};
					porta_rd_block3_r <= {area_flag, 4'b1010};
					porta_rd_block4_r <= {area_flag, 4'b1011};
				end

			zone_bilinear_r7:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1000};
					porta_rd_block2_r <= {area_flag, 4'b1001};
					porta_rd_block3_r <= {area_flag, 4'b1100};
					porta_rd_block4_r <= {area_flag, 4'b1101};
				end
			zone_bilinear_r8:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1001};
					porta_rd_block2_r <= {area_flag, 4'b1010};
					porta_rd_block3_r <= {area_flag, 4'b1101};
					porta_rd_block4_r <= {area_flag, 4'b1110};
				end
			zone_bilinear_r9:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1010};
					porta_rd_block2_r <= {area_flag, 4'b1011};
					porta_rd_block3_r <= {area_flag, 4'b1110};
					porta_rd_block4_r <= {area_flag, 4'b1111};
				end
			
			zone_bilinear_r71:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1000};
					porta_rd_block2_r <= {area_flag, 4'b1001};
					porta_rd_block3_r <= {area_flag, 4'b1100};
					porta_rd_block4_r <= {area_flag, 4'b1101};
				end
			zone_bilinear_r81:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1001};
					porta_rd_block2_r <= {area_flag, 4'b1010};
					porta_rd_block3_r <= {area_flag, 4'b1101};
					porta_rd_block4_r <= {area_flag, 4'b1110};
				end
			zone_bilinear_r91:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1010};
					porta_rd_block2_r <= {area_flag, 4'b1011};
					porta_rd_block3_r <= {area_flag, 4'b1110};
					porta_rd_block4_r <= {area_flag, 4'b1111};
				end
			
			zone_bilinear_r11:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0000};
					porta_rd_block2_r <= {area_flag, 4'b0001};
					porta_rd_block3_r <= {area_flag, 4'b0100};
					porta_rd_block4_r <= {area_flag, 4'b0101};
				end
			zone_bilinear_r21:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0001};
					porta_rd_block2_r <= {area_flag, 4'b0010};
					porta_rd_block3_r <= {area_flag, 4'b0101};
					porta_rd_block4_r <= {area_flag, 4'b0110};
				end
			zone_bilinear_r31:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0010};
					porta_rd_block2_r <= {area_flag, 4'b0011};
					porta_rd_block3_r <= {area_flag, 4'b0110};
					porta_rd_block4_r <= {area_flag, 4'b0111};
				end

			zone_bilinear_r12:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0000};
					porta_rd_block2_r <= {area_flag, 4'b0001};
					porta_rd_block3_r <= {area_flag, 4'b0100};
					porta_rd_block4_r <= {area_flag, 4'b0101};
				end
			zone_bilinear_r42:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0100};
					porta_rd_block2_r <= {area_flag, 4'b0101};
					porta_rd_block3_r <= {area_flag, 4'b1000};
					porta_rd_block4_r <= {area_flag, 4'b1001};
				end
			zone_bilinear_r72:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1000};
					porta_rd_block2_r <= {area_flag, 4'b1001};
					porta_rd_block3_r <= {area_flag, 4'b1100};
					porta_rd_block4_r <= {area_flag, 4'b1101};
				end

			zone_bilinear_r32:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0010};
					porta_rd_block2_r <= {area_flag, 4'b0011};
					porta_rd_block3_r <= {area_flag, 4'b0110};
					porta_rd_block4_r <= {area_flag, 4'b0111};
				end
			zone_bilinear_r62:
				begin
					porta_rd_block1_r <= {area_flag, 4'b0110};
					porta_rd_block2_r <= {area_flag, 4'b0111};
					porta_rd_block3_r <= {area_flag, 4'b1010};
					porta_rd_block4_r <= {area_flag, 4'b1011};
				end
			zone_bilinear_r92:
				begin
					porta_rd_block1_r <= {area_flag, 4'b1010};
					porta_rd_block2_r <= {area_flag, 4'b1011};
					porta_rd_block3_r <= {area_flag, 4'b1110};
					porta_rd_block4_r <= {area_flag, 4'b1111};
				end
			endcase
		end
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			porta_rd_block1_r2 <= 5'dz;
			porta_rd_block2_r2 <= 5'dz;
			porta_rd_block3_r2 <= 5'dz;
			porta_rd_block4_r2 <= 5'dz;
			
			porta_rd_block1_r3 <= 5'dz;
			porta_rd_block2_r3 <= 5'dz;
			porta_rd_block3_r3 <= 5'dz;
			porta_rd_block4_r3 <= 5'dz;
			
			porta_rd_block1 <= 5'dz;
			porta_rd_block2 <= 5'dz;
			porta_rd_block3 <= 5'dz;
			porta_rd_block4 <= 5'dz;
		end
		else
		begin
		    if(TVALID_in)
		    begin
			porta_rd_block1_r2 <= porta_rd_block1_r;
			porta_rd_block2_r2 <= porta_rd_block2_r;
			porta_rd_block3_r2 <= porta_rd_block3_r;
			porta_rd_block4_r2 <= porta_rd_block4_r;
			
			porta_rd_block1_r3 <= porta_rd_block1_r2;
			porta_rd_block2_r3 <= porta_rd_block2_r2;
			porta_rd_block3_r3 <= porta_rd_block3_r2;
			porta_rd_block4_r3 <= porta_rd_block4_r2;
			
			porta_rd_block1 <= porta_rd_block1_r3;
			porta_rd_block2 <= porta_rd_block2_r3;
			porta_rd_block3 <= porta_rd_block3_r3;
			porta_rd_block4 <= porta_rd_block4_r3;
			end
			else;
		end
	end
	
	
	reg [4:0] excess_addr_rd1_r1,
				 excess_addr_rd2_r1,
				 excess_addr_rd3_r1,
				 excess_addr_rd4_r1;
				 
	reg [4:0] excess_addr_rd1_r2,
				 excess_addr_rd2_r2,
				 excess_addr_rd3_r2,
				 excess_addr_rd4_r2;
	
	always@(posedge clk or negedge rst_n)
	begin
	    if(~rst_n)
	    begin
	       excess_addr_rd1_r1  <= 5'dz;
           excess_addr_rd2_r1  <= 5'dz;
           excess_addr_rd3_r1  <= 5'dz;
           excess_addr_rd4_r1  <= 5'dz;
	    end
	    else
	    begin
		case(state)
			zone_non://四个都是一样
				begin
					excess_addr_rd1_r1 <= {area_flag, block_flag_height, block_flag_width};
					excess_addr_rd2_r1 <= {area_flag, block_flag_height, block_flag_width};
					excess_addr_rd3_r1 <= {area_flag ,block_flag_height, block_flag_width};
					excess_addr_rd4_r1 <= {area_flag, block_flag_height, block_flag_width};
				end
			
			zone_bilinear_r1:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0000};
					excess_addr_rd2_r1 <= {area_flag, 4'b0001};
					excess_addr_rd3_r1 <= {area_flag, 4'b0100};
					excess_addr_rd4_r1 <= {area_flag, 4'b0101};
				end
			zone_bilinear_r2:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0001};
					excess_addr_rd2_r1 <= {area_flag, 4'b0010};
					excess_addr_rd3_r1 <= {area_flag, 4'b0101};
					excess_addr_rd4_r1 <= {area_flag, 4'b0110};
				end
			zone_bilinear_r3:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0010};
					excess_addr_rd2_r1 <= {area_flag, 4'b0011};
					excess_addr_rd3_r1 <= {area_flag, 4'b0110};
					excess_addr_rd4_r1 <= {area_flag, 4'b0111};
				end

			zone_bilinear_r4:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0100};
					excess_addr_rd2_r1 <= {area_flag, 4'b0101};
					excess_addr_rd3_r1 <= {area_flag, 4'b1000};
					excess_addr_rd4_r1 <= {area_flag, 4'b1001};
				end
			zone_bilinear_r5:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0101};
					excess_addr_rd2_r1 <= {area_flag, 4'b0110};
					excess_addr_rd3_r1 <= {area_flag, 4'b1001};
					excess_addr_rd4_r1 <= {area_flag, 4'b1010};
				end
			zone_bilinear_r6:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0110};
					excess_addr_rd2_r1 <= {area_flag, 4'b0111};
					excess_addr_rd3_r1 <= {area_flag, 4'b1010};
					excess_addr_rd4_r1 <= {area_flag, 4'b1011};
				end

			zone_bilinear_r7:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1000};
					excess_addr_rd2_r1 <= {area_flag, 4'b1001};
					excess_addr_rd3_r1 <= {area_flag, 4'b1100};
					excess_addr_rd4_r1 <= {area_flag, 4'b1101};
				end
			zone_bilinear_r8:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1001};
					excess_addr_rd2_r1 <= {area_flag, 4'b1010};
					excess_addr_rd3_r1 <= {area_flag, 4'b1101};
					excess_addr_rd4_r1 <= {area_flag, 4'b1110};
				end
			zone_bilinear_r9:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1010};
					excess_addr_rd2_r1 <= {area_flag, 4'b1011};
					excess_addr_rd3_r1 <= {area_flag, 4'b1110};
					excess_addr_rd4_r1 <= {area_flag, 4'b1111};
				end
			
			zone_bilinear_r71:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1000};
					excess_addr_rd2_r1 <= {area_flag, 4'b1001};
					excess_addr_rd3_r1 <= {area_flag, 4'b1100};
					excess_addr_rd4_r1 <= {area_flag, 4'b1101};
				end
			zone_bilinear_r81:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1001};
					excess_addr_rd2_r1 <= {area_flag, 4'b1010};
					excess_addr_rd3_r1 <= {area_flag, 4'b1101};
					excess_addr_rd4_r1 <= {area_flag, 4'b1110};
				end
			zone_bilinear_r91:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1010};
					excess_addr_rd2_r1 <= {area_flag, 4'b1011};
					excess_addr_rd3_r1 <= {area_flag, 4'b1110};
					excess_addr_rd4_r1 <= {area_flag, 4'b1111};
				end
			
			zone_bilinear_r11:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0000};
					excess_addr_rd2_r1 <= {area_flag, 4'b0001};
					excess_addr_rd3_r1 <= {area_flag, 4'b0100};
					excess_addr_rd4_r1 <= {area_flag, 4'b0101};
				end
			zone_bilinear_r21:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0001};
					excess_addr_rd2_r1 <= {area_flag, 4'b0010};
					excess_addr_rd3_r1 <= {area_flag, 4'b0101};
					excess_addr_rd4_r1 <= {area_flag, 4'b0110};
				end
			zone_bilinear_r31:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0010};
					excess_addr_rd2_r1 <= {area_flag, 4'b0011};
					excess_addr_rd3_r1 <= {area_flag, 4'b0110};
					excess_addr_rd4_r1 <= {area_flag, 4'b0111};
				end
			
			zone_bilinear_r12:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0000};
					excess_addr_rd2_r1 <= {area_flag, 4'b0001};
					excess_addr_rd3_r1 <= {area_flag, 4'b0100};
					excess_addr_rd4_r1 <= {area_flag, 4'b0101};
				end
			zone_bilinear_r42:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0100};
					excess_addr_rd2_r1 <= {area_flag, 4'b0101};
					excess_addr_rd3_r1 <= {area_flag, 4'b1000};
					excess_addr_rd4_r1 <= {area_flag, 4'b1001};
				end
			zone_bilinear_r72:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1000};
					excess_addr_rd2_r1 <= {area_flag, 4'b1001};
					excess_addr_rd3_r1 <= {area_flag, 4'b1100};
					excess_addr_rd4_r1 <= {area_flag, 4'b1101};
				end

			zone_bilinear_r32:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0010};
					excess_addr_rd2_r1 <= {area_flag, 4'b0011};
					excess_addr_rd3_r1 <= {area_flag, 4'b0110};
					excess_addr_rd4_r1 <= {area_flag, 4'b0111};
				end
			zone_bilinear_r62:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b0110};
					excess_addr_rd2_r1 <= {area_flag, 4'b0111};
					excess_addr_rd3_r1 <= {area_flag, 4'b1010};
					excess_addr_rd4_r1 <= {area_flag, 4'b1011};
				end
			zone_bilinear_r92:
				begin
					excess_addr_rd1_r1 <= {area_flag, 4'b1010};
					excess_addr_rd2_r1 <= {area_flag, 4'b1011};
					excess_addr_rd3_r1 <= {area_flag, 4'b1110};
					excess_addr_rd4_r1 <= {area_flag, 4'b1111};
				end
			endcase
			end
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			excess_addr_rd1_r2 <= 0;
			excess_addr_rd2_r2 <= 0;
			excess_addr_rd3_r2 <= 0;
			excess_addr_rd4_r2 <= 0;
			
			excess_addr_rd1 <= 5'dz;
			excess_addr_rd2 <= 5'dz;
			excess_addr_rd3 <= 5'dz;
			excess_addr_rd4 <= 5'dz;
		end
		else
		begin
		    if(TVALID_in)
		    begin
			excess_addr_rd1_r2 <= excess_addr_rd1_r1;
			excess_addr_rd2_r2 <= excess_addr_rd2_r1;
			excess_addr_rd3_r2 <= excess_addr_rd3_r1;
			excess_addr_rd4_r2 <= excess_addr_rd4_r1;
			
			excess_addr_rd1 <= excess_addr_rd1_r2;
			excess_addr_rd2 <= excess_addr_rd2_r2;
			excess_addr_rd3 <= excess_addr_rd3_r2;
			excess_addr_rd4 <= excess_addr_rd4_r2;
			end
			else;
		end
	end
	
	//计数器延迟一个周期
	reg [10:0] height_cnt_r1;
	reg [10:0] width_cnt_r1;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			height_cnt_r1 <= 0;
			width_cnt_r1 <= 0;
		end
		else
		begin
			height_cnt_r1 <= height_cnt;
			width_cnt_r1 <= width_cnt;
		end
	end
	//生成权重系数，左移9位
	reg [10:0] u1, u2;
	reg [10:0] v1, v2;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			u1 <= 0;
			u2 <= 0;
			v1 <= 0;
			v2 <= 0;
		end
		else
		begin
			case(state)
			zone_non:
				begin
					u1 <= 11'd512;//0.5左移9位 11'd512
					u2 <= 11'd512;
					v1 <= 11'd512;
					v2 <= 11'd512;
				end
			// zone_linear_v:
			// 	begin
			// 		if(height_cnt_r1 < ((block_flag_height + 1)*hb_size - hb_size/2))
			// 			begin
			// 				u1 <= div(((block_flag_height + 2)*hb_size -hb_size/2 - height_cnt_r1), (2*(block_flag_height + 1)*hb_size - 2*height_cnt_r1));
			// 				u2 <= div(((block_flag_height + 1)*hb_size -hb_size/2 - height_cnt_r1), (2*(block_flag_height + 1)*hb_size - 2*height_cnt_r1));
			// 				v1 <= 11'd512;//
			// 				v2 <= 11'd512;
			// 			end
			// 		else
			// 			begin
			// 				u1 <= div(((block_flag_height + 2)*hb_size -hb_size/2 - height_cnt_r1), hb_size);
			// 				u2 <= div((height_cnt_r1 - (block_flag_height + 1)*hb_size + hb_size/2), hb_size);
			// 				v1 <= 11'd512;
			// 				v2 <= 11'd512;
			// 			end
			// 	end
			// zone_linear_vu:
			// 	begin
			// 		u1 <= div((height_cnt_r1 - (block_flag_height)*hb_size + hb_size/2), hb_size);
			// 		u2 <= div(((block_flag_height + 1)*hb_size - hb_size/2 - height_cnt_r1), hb_size);
			// 		v1 <= 11'd512;
			// 		v2 <= 11'd512;
			// 	end
			////////////////////////////////////////
			zone_bilinear_r1:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
				end
			
			zone_bilinear_r2:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*3/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*3/2),wb_size);
				end
			
			zone_bilinear_r3:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*5/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*5/2),wb_size);
				end
			//////////////////////////////////
			zone_bilinear_r4:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*3/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*3/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
				end
			
			zone_bilinear_r5:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*3/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*3/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*3/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*3/2),wb_size);
				end
			
			zone_bilinear_r6:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*3/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*3/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*5/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*5/2),wb_size);
				end
			////////////////////////////////////
			zone_bilinear_r7:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
				end
			
			zone_bilinear_r8:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*3/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*3/2),wb_size);
				end
			
			zone_bilinear_r9:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*5/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*5/2),wb_size);
				end
			////////////////////////////////////
			zone_bilinear_r71:
				begin
					//竖直方向的值
					u1 <= div((height_cnt_r1 - hb_size*7/2),(height_cnt_r1 - hb_size*7/2 + height_cnt_r1 - hb_size*5/2));
					u2 <= div((height_cnt_r1 - hb_size*5/2),(height_cnt_r1 - hb_size*7/2 + height_cnt_r1 - hb_size*5/2));
					// u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					// u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
				end
			
			zone_bilinear_r81:
				begin
					//竖直方向的值
					u1 <= div((height_cnt_r1 - hb_size*7/2),(height_cnt_r1 - hb_size*7/2 + height_cnt_r1 - hb_size*5/2));
					u2 <= div((height_cnt_r1 - hb_size*5/2),(height_cnt_r1 - hb_size*7/2 + height_cnt_r1 - hb_size*5/2));
					// u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					// u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*3/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*3/2),wb_size);
				end
			
			zone_bilinear_r91:
				begin
					//竖直方向的值
					u1 <= div((height_cnt_r1 - hb_size*7/2),(height_cnt_r1 - hb_size*7/2 + height_cnt_r1 - hb_size*5/2));
					u2 <= div((height_cnt_r1 - hb_size*5/2),(height_cnt_r1 - hb_size*7/2 + height_cnt_r1 - hb_size*5/2));
					// u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					// u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*5/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*5/2),wb_size);
				end
			
			////////////////////////////////////////
			zone_bilinear_r11:
				begin
					//竖直方向的值
					u1 <= div((hb_size*3/2 - height_cnt_r1),(hb_size/2 - height_cnt_r1 + hb_size*3/2 - height_cnt_r1));
					u2 <= div((hb_size/2 - height_cnt_r1),(hb_size/2 - height_cnt_r1 + hb_size*3/2 - height_cnt_r1));
					// u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					// u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
				end
			
			zone_bilinear_r21:
				begin
					//竖直方向的值
					u1 <= div((hb_size*3/2 - height_cnt_r1),(hb_size/2 - height_cnt_r1 + hb_size*3/2 - height_cnt_r1));
					u2 <= div((hb_size/2 - height_cnt_r1),(hb_size/2 - height_cnt_r1 + hb_size*3/2 - height_cnt_r1));
					// u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					// u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*3/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*3/2),wb_size);
				end
			
			zone_bilinear_r31:
				begin
					//竖直方向的值
					u1 <= div((hb_size*3/2 - height_cnt_r1),(hb_size/2 - height_cnt_r1 + hb_size*3/2 - height_cnt_r1));
					u2 <= div((hb_size/2 - height_cnt_r1),(hb_size/2 - height_cnt_r1 + hb_size*3/2 - height_cnt_r1));
					// u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					// u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					v1 <= div((wb_size - (width_cnt_r1 - wb_size*5/2)),wb_size);
					v2 <= div((width_cnt_r1 - wb_size*5/2),wb_size);
				end
			///////////////////////////////////////////////
			zone_bilinear_r12:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					// v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					// v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
					v1 <= div((wb_size*3/2 - width_cnt_r1),(wb_size*3/2 - width_cnt_r1 + wb_size/2 - width_cnt_r1));
					v2 <= div((wb_size/2 - width_cnt_r1),(wb_size*3/2 - width_cnt_r1 + wb_size/2 - width_cnt_r1));
				end
			
			zone_bilinear_r42:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*3/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*3/2),hb_size);
					
					//水平方向的值
					// v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					// v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
					v1 <= div((wb_size*3/2 - width_cnt_r1),(wb_size*3/2 - width_cnt_r1 + wb_size/2 - width_cnt_r1));
					v2 <= div((wb_size/2 - width_cnt_r1),(wb_size*3/2 - width_cnt_r1 + wb_size/2 - width_cnt_r1));
				end
			
			zone_bilinear_r72:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					// v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					// v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
					v1 <= div((wb_size*3/2 - width_cnt_r1),(wb_size*3/2 - width_cnt_r1 + wb_size/2 - width_cnt_r1));
					v2 <= div((wb_size/2 - width_cnt_r1),(wb_size*3/2 - width_cnt_r1 + wb_size/2 - width_cnt_r1));
				end
			///////////////////////////////////////////////
			zone_bilinear_r32:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size/2),hb_size);
					
					//水平方向的值
					// v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					// v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
					v1 <= div((width_cnt_r1 - wb_size*7/2),(width_cnt_r1 - wb_size*5/2 + width_cnt_r1 - wb_size*7/2));
					v2 <= div((width_cnt_r1 - wb_size*5/2),(width_cnt_r1 - wb_size*5/2 + width_cnt_r1 - wb_size*7/2));
				end
			
			zone_bilinear_r62:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*3/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*3/2),hb_size);
					
					//水平方向的值
					// v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					// v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
					v1 <= div((width_cnt_r1 - wb_size*7/2),(width_cnt_r1 - wb_size*5/2 + width_cnt_r1 - wb_size*7/2));
					v2 <= div((width_cnt_r1 - wb_size*5/2),(width_cnt_r1 - wb_size*5/2 + width_cnt_r1 - wb_size*7/2));
				end
			
			zone_bilinear_r92:
				begin
					//竖直方向的值
					u1 <= div((hb_size - (height_cnt_r1 - hb_size*5/2)),hb_size);
					u2 <= div((height_cnt_r1 - hb_size*5/2),hb_size);
					
					//水平方向的值
					// v1 <= div((wb_size - (width_cnt_r1 - wb_size/2)),wb_size);
					// v2 <= div((width_cnt_r1 - wb_size/2),wb_size);
					v1 <= div((width_cnt_r1 - wb_size*7/2),(width_cnt_r1 - wb_size*5/2 + width_cnt_r1 - wb_size*7/2));
					v2 <= div((width_cnt_r1 - wb_size*5/2),(width_cnt_r1 - wb_size*5/2 + width_cnt_r1 - wb_size*7/2));
				end
			endcase
		end
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			w1 <= 0;
			w2 <= 0;
			w3 <= 0;
			w4 <= 0;
		end
		else
		begin
		    if(TVALID_in)
		    begin
			w1 <= u1*v1;
			w2 <= u1*v2;
			w3 <= u2*v1;
			w4 <= u2*v2;
			end
			else;
		end	
	end
	//data_in延迟两个周期
	reg [7:0] data_reg1, data_reg2,data_reg3,data_reg4;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			data_reg1 <= 0;
			data_reg2 <= 0;
			data_reg3 <= 0;
			data_reg4 <= 0;
			inter_data_out <= 0;
		end
		else
		begin
		    if(TVALID_in)
		    begin
			data_reg1 <= data_in;
			data_reg2 <= data_reg1;
			data_reg3 <= data_reg2;
			data_reg4 <= data_reg3;
			inter_data_out <= data_reg3;
			end
			else;
		end
	end
	
	//产生计算完成信号
	wire TVALID_in_r;
	always@(*)
	begin
		if(~rst_n)
			inter_complete <= 0;
		else if(height_cnt_r1 == height && width_cnt_r1 == width)
		begin
			if(TVALID_in_r == 0)
				inter_complete <= 0;
			else
				inter_complete <= 1;
		end
		else
			inter_complete <= 0;
	end
	
	//
	 parameter delay_time = 3;//输出延迟为3个周期
	 reg [delay_time - 1:0] H_SYNC_r;
	 reg [delay_time - 1:0] V_SYNC_r;
	 reg [delay_time - 1:0] data_en_r;
	 assign o_H_SYNC = H_SYNC_r[delay_time - 1];
	 assign o_V_SYNC = V_SYNC_r[delay_time - 1];
	 assign o_data_en = data_en_r[delay_time - 2];
	 assign in_data_en_r = data_en_r[1];
	 assign excess_wr_en_en = data_en_r[delay_time - 1];
	 always@(posedge clk or negedge rst_n)
	 begin
		if(~rst_n)
		begin
			H_SYNC_r <= 0;
			V_SYNC_r <= 0;
			data_en_r <= 0;
		end
		else
		begin
		    if(TVALID_in == 0)
		    begin
		    H_SYNC_r <= H_SYNC_r;
		    V_SYNC_r <= V_SYNC_r;
		    data_en_r <= data_en_r;
		    end
		    else
		    begin
			H_SYNC_r <= {H_SYNC_r[delay_time - 2:0],in_H_SYNC};
			V_SYNC_r <= {V_SYNC_r[delay_time - 2:0],in_V_SYNC};
			data_en_r <= {data_en_r[delay_time - 2:0],in_data_en};
			end
		end
	end
	
	 reg [delay_time - 1 :0] TVALID_r;
	 always@(posedge clk or negedge rst_n)
	 begin
			if(~rst_n)
				TVALID_r <= 0;
			else
				TVALID_r <= {TVALID_r[delay_time - 2 : 0],TVALID_in};
	 end
	assign TVALID_inter = TVALID_r[delay_time - 1];
	assign TVALID_in_r = TVALID_r[1];
endmodule 