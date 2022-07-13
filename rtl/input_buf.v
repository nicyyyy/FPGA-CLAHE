module input_buf(
	input clk,
	input rst_n,
	input in_H_SYNC,
	input in_V_SYNC,
	input in_data_en,
	input [7:0] data_in,
	input TVALID_in,
	input V_SYNC,

	output o_H_SYNC,
	output o_V_SYNC,
	output o_data_en,
	output o_data_en_4363,
	output [7:0] data_out_4363,
	output [7:0] data_out_4364,
	
	output data_en_1,
	output data_en_2,
	output TVALID_input_buf1,
	output TVALID_input_buf2
);
	parameter delay_time = 300;
	
	reg [delay_time*8 - 1:0] data_in_shift_reg;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			data_in_shift_reg <= 0;
		else
//		    if(TVALID_in)
			     data_in_shift_reg <= {data_in_shift_reg[delay_time*8 -9:0],data_in};
//			else
//			     data_in_shift_reg <= data_in_shift_reg;
	end
	assign data_out_4364 = data_in_shift_reg[delay_time*8 -1 : delay_time*8 -8];
	assign data_out_4363 = data_in_shift_reg[(delay_time - 1)*8 -1 : (delay_time - 1)*8 -8];
	
	 
	 reg [delay_time - 1:0] data_en_r;
	 assign o_data_en = data_en_r[delay_time - 1];
	 assign o_data_en_4363 = data_en_r[delay_time - 2];
	 always@(posedge clk or negedge rst_n)
	 begin
		if(~rst_n)
		begin
//			H_SYNC_r <= 0;
//			V_SYNC_r <= 0;
			data_en_r <= 0;
		end
		else
		begin
		    if(TVALID_in == 0)
		    begin
//		      H_SYNC_r <= H_SYNC_r;
//              V_SYNC_r <= V_SYNC_r; 
              data_en_r <=data_en_r;
		    end
		    else
		    begin
//			H_SYNC_r <= {H_SYNC_r[delay_time - 2:0],in_H_SYNC};
//			V_SYNC_r <= {V_SYNC_r[delay_time - 2:0],in_V_SYNC};
			data_en_r <= {data_en_r[delay_time - 2:0],in_data_en};
			end
		end
	end
	
	reg [8:0] cnt;
	always@(posedge clk or negedge rst_n)
	begin
		if(~rst_n)
			cnt <= 0;
		else if(V_SYNC == 0)
			cnt <= 1;
		else
		begin
			if(cnt < 9'd300)
				cnt <= cnt + 1;
			else
				cnt <= cnt;
		end
	end
	 assign data_en_1 = cnt >= 299 ? 1 : 0;
	 assign data_en_2 = cnt >= 300 ? 1 : 0;
	 
	 reg [delay_time - 1 :0] TVALID_r;
	 reg [delay_time - 1:0] H_SYNC_r;
	 reg [delay_time - 1:0] V_SYNC_r;
	 always@(posedge clk or negedge rst_n)
	 begin
			if(~rst_n)
			begin
				H_SYNC_r <= 0;
				V_SYNC_r <= 0;
				TVALID_r <= 0;
			end
			else
			begin
				TVALID_r <= {TVALID_r[delay_time - 2 : 0],TVALID_in};
				H_SYNC_r <= {H_SYNC_r[delay_time - 2:0],in_H_SYNC};
				V_SYNC_r <= {V_SYNC_r[delay_time - 2:0],in_V_SYNC};
			end
	 end
	 assign TVALID_input_buf1 = TVALID_r[delay_time - 1];//300个
	 assign TVALID_input_buf2 = TVALID_r[delay_time - 2];//299个
	 assign o_H_SYNC = H_SYNC_r[delay_time - 3];
	 assign o_V_SYNC = V_SYNC_r[delay_time - 2];
endmodule 