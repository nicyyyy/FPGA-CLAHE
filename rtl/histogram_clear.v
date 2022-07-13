module histogram_clear(
	input clk,
	input rst_n,
	input clear_en,
	input area_flag,
	
	output reg [7:0] portb_addr,
	output reg [31:0] portb_clear_wren_bus,
	output reg portb_clear_flag,
	output reg [15:0] portb_clear_data,
	output reg clear_done
);//同时选中16片ram，依次将256个bin清零
	//均衡化的完成 信号延迟一个周期后开始清零，清零消耗256+1个周期
	//clear_en 延迟256个周期
	reg [255:0] clear_en_delay;
	reg clear_en_r;
	wire clear_en_256;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			clear_en_delay <= 0;
			clear_en_r <= 0;
		end
		else
		begin
			clear_en_delay <= {clear_en_delay[254:0], clear_en};
			clear_en_r <= clear_en;
		end
	end
	assign clear_en_256 = clear_en_delay[255];
	
	reg clear_start;
	reg [7:0] bin_cnt;
	wire clear;
	assign clear = clear_en | clear_en_256;
	always@(posedge clear or negedge rst_n)
	begin
		if(~rst_n)
			clear_start <= 0;
		else
			clear_start <= ~clear_start;
	end
	
	//计数器
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			bin_cnt <= 0;
		else if(clear_start == 1)
			bin_cnt <= bin_cnt + 1;
		else
			bin_cnt <= 0;
	end
	
	//产生启动信号要延迟一个周期，addr是cnt延迟一个周期
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			portb_clear_wren_bus <= 32'bz;
			portb_clear_flag <= 1'b0;
		end
		else if(clear_start == 1'b1)
		begin
			portb_clear_flag <= 1;
			if(area_flag == 1'b0)
				portb_clear_wren_bus <= 32'h0000_ffff;
			else
				portb_clear_wren_bus <= 32'hffff_0000;
		end
		else
		begin
			portb_clear_wren_bus <= 32'bz;
			portb_clear_flag <= 1'b0;
		end
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			portb_addr <= 8'hzz;
		else if(clear_start == 1)
			portb_addr <= bin_cnt;
		else
			portb_addr <= 8'hzz;
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			portb_clear_data <= 16'bz;
		else if(clear_start == 1'b1)
			portb_clear_data <= 16'd0;
		else
			portb_clear_data <= 16'bz;
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			clear_done <= 0;
		else if(portb_addr == 8'd255)
			clear_done <= 1;
		else 
			clear_done <= 0;
	end
	
	
endmodule 