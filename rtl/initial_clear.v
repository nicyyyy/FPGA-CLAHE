module initial_clear(
	input clk,
	input rst_n,
	input in_data_en,
	output reg [7:0] portb_addr,
	output reg portb_clear_flag_initial,
	output reg [15:0] portb_clear_data_initial,
	output reg [31:0] portb_clear_wren_bus_initial
);
	reg [8:0] bin_cnt;
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			bin_cnt <= 0;
		else if(in_data_en == 1)
		begin
			if(bin_cnt == 9'd256)
				bin_cnt <= 9'bz;
			else
				bin_cnt <= bin_cnt + 1;
		end
		else;
	end
	
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
		begin
			portb_clear_flag_initial <= 1'b0;
			portb_clear_data_initial <= 16'bz;
			portb_clear_wren_bus_initial <= 32'bz;
		end
		else if(bin_cnt <= 9'd255)
		begin
			portb_clear_flag_initial <= 1;
			portb_clear_data_initial <= 16'd0;
			portb_clear_wren_bus_initial <= 32'hffff_ffff;
		end
		else
		begin
			portb_clear_flag_initial <= 1'b0;
			portb_clear_data_initial <= 16'bz;
			portb_clear_wren_bus_initial <= 32'bz;
		end
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			portb_addr <= 8'hzz;
		else if(bin_cnt <= 9'd255)
			portb_addr <= bin_cnt[7:0];
		else
			portb_addr <= 8'hzz;
	end
endmodule 