module excess_ram_32x16bit(
	input clk,
	input [4:0] excess_addr,//对应的block
	input [15:0] excess_wr_data,
	input excess_wren,
	
	//同时读4位
	input excess_4block_rden,
	input [4:0] excess_addr_rd1,
	input [4:0] excess_addr_rd2,
	input [4:0] excess_addr_rd3,
	input [4:0] excess_addr_rd4,
	output reg [15:0] excess_rd_data1,
	output reg [15:0] excess_rd_data2,
	output reg [15:0] excess_rd_data3,
	output reg [15:0] excess_rd_data4
);
	reg [15:0] excess_mem[31:0];
	integer i;
	initial
	begin
		for(i = 0;i<32;i = i + 1)
		begin
			excess_mem[i] = 16'd0;
		end
	end
	
	always@(posedge clk)
	begin
		if(excess_wren == 1'b1)
			excess_mem[excess_addr] <= excess_wr_data;
		else;
	end
	
	always@(posedge clk)
	begin
		if(excess_4block_rden == 1'b1)
		begin
			excess_rd_data1 <= excess_mem[excess_addr_rd1];
			excess_rd_data2 <= excess_mem[excess_addr_rd2];
			excess_rd_data3 <= excess_mem[excess_addr_rd3];
			excess_rd_data4 <= excess_mem[excess_addr_rd4];
		end
		else
		begin
			excess_rd_data1 <= 16'bz;
			excess_rd_data2 <= 16'bz;
			excess_rd_data3 <= 16'bz;
			excess_rd_data4 <= 16'bz;
		end
	end
endmodule 