module clipper(
	input clk,
	input rst_n,
	input area_flag,
	input clear_done,
	input [15:0] constract_th,
	
	//读端口a
	input [15:0] hist_stat_rd_a,
	output reg [7:0] porta_addr,
	output reg [4:0] porta_rd_block,
	//写端口b
	output reg [7:0] portb_addr,
	output reg [15:0] portb_wr_data,
	output reg [4:0] portb_wr_block,
	//写excess
	output reg [4:0] excess_addr,
	output reg [15:0] excess_wr_data,
	output reg excess_wren,
	
	output reg clip_done,
	output cilp_start_r2_out//测试端口
);
//	parameter constract_th = 576;//0.01*57600
	
	//启动信号
	
	reg cilp_start;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			cilp_start <= 0;
		else if(portb_addr == 8'd255 && portb_wr_block[3:0] == 4'd15)
			cilp_start <= ~cilp_start;
		else if(clear_done == 1)
			cilp_start <= ~cilp_start;
		else
			cilp_start <= cilp_start;
	end
	//启动信号延迟3个周期
	reg [2:0] cilp_start_r;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			cilp_start_r <= 0;
		else
			cilp_start_r <= {cilp_start_r[1:0],cilp_start};
	end
	wire cilp_start_r1, cilp_start_r2, cilp_start_r3;
	assign cilp_start_r1 = cilp_start_r[0];
	assign cilp_start_r2 = cilp_start_r[1];
	assign cilp_start_r3 = cilp_start_r[2];
	assign cilp_start_r2_out = cilp_start_r[2];
	//T1,
	///计数器，并生成地址
	reg [7:0] bin_cnt;//bin计数器0-255
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			bin_cnt <= 0;
		else if(cilp_start)
			bin_cnt <= bin_cnt + 1;
		else
			bin_cnt <= 0;
	end
	
	reg [3:0] block_cnt;//block计数器
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			block_cnt <= 0;
		else
		begin
			if(cilp_start)
			begin
				if(bin_cnt == 8'b1111_1111)
					block_cnt <= block_cnt + 1;
				else
					block_cnt <= block_cnt;
			end
			else
				block_cnt <= 0;
		end
	end
	
	//T2 产生地址
	reg [3:0] block_cnt_r1;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			block_cnt_r1 <= 0;
		else
			block_cnt_r1 <= block_cnt;
	end
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			porta_rd_block <= 5'bzzzzz;
			porta_addr <= 8'bzzzzzzzz;
		end
		else if(cilp_start == 1)
		begin
			porta_rd_block <= {area_flag, block_cnt_r1};
			porta_addr <= bin_cnt;
		end
		else
		begin
			porta_rd_block <= 5'bzzzzz;
			porta_addr <= 8'bzzzzzzzz;
		end
	end
	
	//T3
	//从a口读取直方图统计值，并累加
	reg [15:0] hist_sum;
	reg [15:0] excess;
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			hist_sum <= 0;
			excess <= 0;
		end
		else if(cilp_start_r3 == 1)
		begin
			if(porta_addr == 8'd1)
			begin
				if(hist_stat_rd_a <= constract_th)//判断是否大于阈值
				begin
					hist_sum <= hist_stat_rd_a;
					excess <= 0;
				end
				else
				begin
					hist_sum <= constract_th;
					excess <= hist_stat_rd_a - constract_th; 
				end	
			end
			else
			begin
				if(hist_stat_rd_a <= constract_th)//判断是否大于阈值
					hist_sum <= hist_sum + hist_stat_rd_a;
				else
				begin
					hist_sum <= hist_sum + constract_th;
					excess <= excess + (hist_stat_rd_a - constract_th); 
				end
			end
		end
		else
		begin
			hist_sum <= 0;
			excess <= 0;
		end
	end
	
	//地址延迟2个周期
	reg [7:0] port_addr_r1,port_addr_r2;
	reg [4:0] port_block_r1,port_block_r2;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			port_addr_r1 <= 8'hzz;
			port_block_r1 <= 5'bzzzzz;
			port_addr_r2 <= 8'hzz;
			port_block_r2 <= 5'bzzzzz;
		end
		else
		begin
			port_addr_r1 <= porta_addr;
			port_block_r1 <= porta_rd_block;
			port_addr_r2 <= port_addr_r1;
			port_block_r2 <= port_block_r1;
		end
	end
	
	//T4
	//累加值从b口写入ram
	
	//写数据
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			portb_addr <= 8'hzz;
			portb_wr_data <= 16'hzzzz;
			portb_wr_block <= 5'bzzzzz;
		end
		else if(cilp_start_r3 == 1)
		begin
			portb_addr <= port_addr_r2;
			portb_wr_data <= hist_sum;
			portb_wr_block <= port_block_r2;
		end
		else
		begin
			portb_addr <= 8'hzz;
			portb_wr_data <= 16'hzzzz;
			portb_wr_block <= 5'bzzzzz;
		end
	end
	
	//写入excess
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			excess_addr <= 5'bzzzzz;
			excess_wr_data <= 16'hzzzz;
			excess_wren <= 0;
		end
		else if(port_addr_r2 == 8'd255)
		begin
			excess_addr <= port_block_r2;
			excess_wr_data <= (excess + 16'd128) >> 8;
			excess_wren <= 1;
		end
		else
		begin
			excess_addr <= 5'bzzzzz;
			excess_wr_data <= 16'hzzzz;
			excess_wren <= 0;
		end
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			clip_done <= 0;
		else if(portb_addr == 8'd255 && portb_wr_block[3:0] == 4'd15)
			clip_done <= 1;
		else
			clip_done <= 0;
	end
endmodule 