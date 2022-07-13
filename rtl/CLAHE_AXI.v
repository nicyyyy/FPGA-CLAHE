module CLAHE_AXI(
	input ACLK_in,
   input ARESTN_in,
   input [7:0] TDATA_in,
   input TSTRB_in,
   input TLAST_in,
   input TVALID_in,
   input TUSER_in,
   output TREADY_out,
    
	input [10:0] width_in,
	input [10:0] height_in,
	input [15:0] constract_th_in,
	input CLAHE_EN,
	
	output ACLK_out,
   output ARESTN_out,
   output [7:0] TDATA_out,
   output TSTRB_out,
   output TLAST_out,
   output TVALID_out,
   output TUSER_out,
   input TREADY_in,
   output equ_complete,
   //test port
   output [15:0] hist_stat_rd_a_out,
	output cilp_start_r2_out
);
	wire clk;
    wire rst_n;
    wire [8 - 1:0] data_in;
    wire in_H_SYNC;
    wire in_V_SYNC;
    wire in_data_en;
    assign clk = ACLK_in;
    assign rst_n = ARESTN_in;
    AXI2VGA AXI2VGA_init(
        .ACLK(ACLK_in),
        .ARESTN(ARESTN_in),
        .TDATA(TDATA_in),
        .TSTRB(TSTRB_in),
        .TLAST(TLAST_in),
        .TVALID(TVALID_in),
        .TUSER(TUSER_in),
//        .TREADY(TREADY_out),
       
        
        .H_SYNC(in_H_SYNC),
        .V_SYNC(in_V_SYNC),
        .DATA_EN(in_data_en),
        .pixel(data_in)
    );
	 ///////////////////////////
	 wire o_H_SYNC;
	 wire o_V_SYNC;
	 wire o_data_en;
	 wire [7:0] data_out;
	 
	 CLAHE CLAHE_AXI_init(
		.clk(clk),
		.rst_n(rst_n),
		.in_H_SYNC(in_H_SYNC),
		.in_V_SYNC(in_V_SYNC),
		.in_data_en(in_data_en),
		.data_in(data_in),
		
		.CLAHE_EN(CLAHE_EN),
		.width_in(width_in),
		.height_in(height_in),
		.constract_th_in(constract_th_in),
		
		.o_H_SYNC(o_H_SYNC),
		.o_V_SYNC(o_V_SYNC),
		.o_data_en(o_data_en),
		.data_out(data_out),
		.TREADY_out(TREADY_out),
		.equ_complete_o(equ_complete),
      //
      .hist_stat_rd_a_out(hist_stat_rd_a_out),
      .cilp_start_r2_out(cilp_start_r2_out)
	 );
	 //////////////////////////
	 VGA2AXI VGA2AXI_init(
        .ACLK(ACLK_out),
        .ARESTN(ARESTN_out),
        .TDATA(TDATA_out),
        .TSTRB(TSTRB_out),
        .TLAST(TLAST_out),
        .TVALID(TVALID_out),
        .TUSER(TUSER_out),
        .TREADY(TREADY_in),
        
			.TUSER_in(TUSER_in),
         .TVALID_in(TVALID_input_buf2),
			.width(width),
			.height(height),
		
        .clk(clk),
        .rst_n(rst_n),
        .H_SYNC(o_H_SYNC),
        .V_SYNC(o_V_SYNC),
        .DATA_EN(o_data_en),
        .pixel(data_out)
    );
endmodule 