module histogram(
	input clk,
	input rst_n,
	input in_data_en,
	input [7:0] data_in,
	input area_flag,
	input [10:0] width,
	input [10:0] height,
	input TVALID_in,
	
	input [15:0] hist_stat_rd_a,//从a口读数据,b口写数据
	output reg [7:0] porta_addr,
	output reg [7:0] portb_addr,
	output reg [15:0] hist_stat_wr_b,
	output reg [4:0] portb_wr_block,
	output reg [4:0] porta_rd_block
);
	wire data_en1, data_en2;
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
	wire cnt_data_en;
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
		else
			width_cnt <= width_cnt;
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
			height_cnt <= height_cnt;
	end
	
	//生成地址，需要一个周期
	reg [1:0] block_flag_height;
	always@(clk)
	begin
		if(~rst_n)
			block_flag_height = 0;
		else if(height_cnt <= hb_size)
			block_flag_height = 2'b00;
		else if(height_cnt > hb_size && height_cnt <= hb_size*2)
			block_flag_height = 2'b01;
		else if(height_cnt > hb_size*2 && height_cnt <= hb_size*3)
			block_flag_height = 2'b10;
		else if(height_cnt > hb_size*3 && height_cnt <= height)
			block_flag_height = 2'b11;
		else;
	end
	
	reg [1:0] block_flag_width;
	always@(clk)
	begin
		if(~rst_n)
			block_flag_width = 0;
		else if(width_cnt <= wb_size)
			block_flag_width = 2'b00;
		else if(width_cnt > wb_size && width_cnt <= wb_size*2)
			block_flag_width = 2'b01;
		else if(width_cnt > wb_size*2 && width_cnt <= wb_size*3)
			block_flag_width = 2'b10;
		else if(width_cnt > wb_size*3 && width_cnt <= width)
			block_flag_width = 2'b11;
		else;
	end
	//延迟2个周期
	reg [1:0] block_flag_height_r1;
	reg [1:0] block_flag_width_r1;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			block_flag_height_r1 <= 0;
			block_flag_width_r1 <= 0;
		end
		else
		begin
//		    if(TVALID_in)
//		    begin
			block_flag_height_r1 <= block_flag_height;
			block_flag_width_r1 <= block_flag_width;
//			end
//			else
//			begin
//			block_flag_height_r1 <= block_flag_height_r1;
//			block_flag_width_r1 <= block_flag_width_r1;
//			end
		end
	end
	reg [1:0] block_flag_height_r2;
	reg [1:0] block_flag_width_r2;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			block_flag_height_r2 <= 0;
			block_flag_width_r2 <= 0;
		end
		else
		begin
//		    if(TVALID_in)
//		    begin
			block_flag_height_r2 <= block_flag_height_r1;
			block_flag_width_r2 <= block_flag_width_r1;
//		    end
//		    else;
		end
	end
	reg [1:0] block_flag_height_r3;
	reg [1:0] block_flag_width_r3;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			block_flag_height_r3 <= 0;
			block_flag_width_r3 <= 0;
		end
		else
		begin
//		    if(TVALID_in)
//		    begin
			block_flag_height_r3 <= block_flag_height_r2;
			block_flag_width_r3 <= block_flag_width_r2;
//			end
//			else;
		end
	end
	reg [1:0] block_flag_height_r4;
	reg [1:0] block_flag_width_r4;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			block_flag_height_r4 <= 0;
			block_flag_width_r4 <= 0;
		end
		else
		begin
//		    if(TVALID_in)
//		    begin
			block_flag_height_r4 <= block_flag_height_r3;
			block_flag_width_r4 <= block_flag_width_r3;
//			end
//			else;
		end
	end
	/////////////////////////////////////////////////////
	reg [7:0] pexil1,pexil2,pexil3,pexil4;
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			pexil1 <= 0;
			pexil2 <= 0;
			pexil3 <= 0;
			pexil4 <= 0;
		end
		else
		begin
//		    if(TVALID_in)
//		    begin
			pexil1 <= data_in;
			pexil2 <= pexil1;
			pexil3 <= pexil2;
			pexil4 <= pexil3;
//			end
//			else;
		end
	end
	
	reg [7:0] portb_addr_r1;
	reg [15:0] hist_stat;
	reg [15:0] hist_stat_1;
	reg [15:0] hist_stat_2;
	reg [15:0] hist_stat_wr_b_r1;
	reg [15:0] hist_stat_wr_b_r2;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			hist_stat_1 <= 0;
			hist_stat_2 <= 0;
			portb_addr_r1 <= 0;
			hist_stat_wr_b_r1 <= 0;
			hist_stat_wr_b_r2 <= 0;
		end
		else
		begin
//		    if(TVALID_in)
//		    begin
			hist_stat_1 <= hist_stat;
			hist_stat_2 <= hist_stat_1;
			portb_addr_r1 <= portb_addr;
			hist_stat_wr_b_r1 <= hist_stat_wr_b;
			hist_stat_wr_b_r2 <= hist_stat_wr_b_r1;
//			end
//			else;
		end
	end
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			porta_addr <= 8'hzz;
			porta_rd_block <= 5'bzzzzz;
			hist_stat <= 16'd1;
			
			portb_addr <= 8'hzz;
			hist_stat_wr_b <= 16'hzzzz;
			portb_wr_block <= 5'bzzzzz;
		end
		else if(TVALID_in == 0 && height_cnt == 1 && width_cnt == 1)
		begin
			porta_addr <= 8'hzz;
			porta_rd_block <= 5'bzzzzz;
			hist_stat <= 16'd1;
			
			portb_addr <= 8'hzz;
			hist_stat_wr_b <= 16'hzzzz;
			portb_wr_block <= 5'bzzzzz;
		end
		else if(data_en1 == 1)
		begin
		     if(TVALID_in)
		     begin
			     porta_addr <= pexil1;			
			     porta_rd_block <= {area_flag, block_flag_height_r2, block_flag_width_r2};
			     

			     if(pexil2 == pexil3 && block_flag_height_r2 == block_flag_height_r3)
			     begin
			     //累加，不写入,保持读pexil2
			     	hist_stat <= hist_stat + 1;
			     	portb_wr_block <= 5'dz;
			     	portb_addr <= 8'hzz;
			     end
			     else
			     begin
			     	//写入
			     	hist_stat_wr_b <= hist_stat + hist_stat_rd_a;
			     	
			     	if(pexil1 == pexil3 && pexil1 != pexil2 && block_flag_height_r1 == block_flag_height_r3)
			     	begin
			     		hist_stat <= 1;	
			     		portb_addr <= 8'hzz;				
			     		portb_wr_block <= 5'dz;
			     	end
			     	else
			     	begin
			     		hist_stat <= 1;
			     		portb_addr <= pexil3;
			     		portb_wr_block <= {area_flag, block_flag_height_r3, block_flag_width_r3};
			     	end
			     	
			     	if(pexil2 == pexil4 && pexil2 != pexil3 && block_flag_height_r2 == block_flag_height_r4)
			     		hist_stat <= hist_stat_1 + 1;
			     	else;
			     end
			end
			else;
			// begin
			// 	porta_addr <= porta_addr;
			// 	porta_rd_block <= porta_rd_block;
			// 	hist_stat <= hist_stat;
			
			// 	portb_addr <= portb_addr;
			// 	hist_stat_wr_b <= hist_stat_wr_b;
			// 	portb_wr_block <= portb_wr_block;
			// end
		end
		else
		begin
			porta_addr <= 8'hzz;
			porta_rd_block <= 5'bzzzzz;
			hist_stat <= 16'd1;
			
			portb_addr <= 8'hzz;
			hist_stat_wr_b <= 16'hzzzz;
			portb_wr_block <= 5'bzzzzz;
			// porta_addr <= porta_addr;
			// 	porta_rd_block <= porta_rd_block;
			// 	hist_stat <= hist_stat;
			
			// 	portb_addr <= portb_addr;
			// 	hist_stat_wr_b <= hist_stat_wr_b;
			// 	portb_wr_block <= portb_wr_block;
			
		end
	end
	

	 parameter delay_time = 2;//输出延迟为2个周期
	
	 reg [delay_time - 1:0] data_en_r;
	 assign data_en1 = data_en_r[0];
	 assign data_en2 = data_en_r[1];
	 always@(posedge clk or negedge rst_n)
	 begin
		if(~rst_n)
		begin
			data_en_r <= 0;
		end
		else
		begin
		    if(TVALID_in == 0)
		          data_en_r <= data_en_r;
		    else
			     data_en_r <= {data_en_r[delay_time - 2:0],in_data_en};
		end
	end
endmodule 