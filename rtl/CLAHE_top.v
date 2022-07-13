module CLAHE(
	input clk,
	input rst_n,
	input in_H_SYNC,
	input in_V_SYNC,
	input in_data_en,
	input [7:0] data_in,
//    input ACLK_in,
//    input ARESTN_in,
//    input [7:0] TDATA_in,
//    input TSTRB_in,
//    input TLAST_in,
//    input TVALID_in,
//    input TUSER_in,
    output reg TREADY_out,
    
	input [10:0] width_in,
	input [10:0] height_in,
	input [15:0] constract_th_in,
	input CLAHE_EN,//

	output o_H_SYNC,
	output o_V_SYNC,
	output o_data_en,
	output [7:0] data_out,
//    output ACLK_out,
//    output ARESTN_out,
//    output [7:0] TDATA_out,
//    output TSTRB_out,
//    output TLAST_out,
//    output TVALID_out,
//    output TUSER_out,
//    input TREADY_in,
	
	//
	output [15:0] hist_stat_rd_a_out,
	output cilp_start_r2_out,
	output equ_complete_o
	//test port
//	output data_en_1_o,
//	output data_en_2_o,
//	output data_out_4363_o,
//	output data_out_4364_o
);
	reg [10:0] width;
	reg [10:0] height;
	reg [15:0] constract_th;
//	parameter constract_th = 576;//0.01*57600
//	parameter block_size = height*width/16;
	reg [15:0] block_size;
	always@(*)
		block_size = height*width/16;

	reg area_flag;
	
	//AXI2VGA
//    wire clk;
//    wire rst_n;
//    wire [8 - 1:0] data_in;
//    wire in_H_SYNC;
//    wire in_V_SYNC;
//    wire in_data_en;
//    assign clk = ACLK_in;
//    assign rst_n = ARESTN_in;
//    AXI2VGA AXI2VGA_init(
//        .ACLK(ACLK_in),
//        .ARESTN(ARESTN_in),
//        .TDATA(TDATA_in),
//        .TSTRB(TSTRB_in),
//        .TLAST(TLAST_in),
//        .TVALID(TVALID_in),
//        .TUSER(TUSER_in),
//        //.TREADY(TREADY_out),
//       
//        
//        .H_SYNC(in_H_SYNC),
//        .V_SYNC(in_V_SYNC),
//        .DATA_EN(in_data_en),
//        .pixel(data_in)
//    );
	//
	reg start_CLAHE;
	wire clk_clahe;
	always@(*)
	begin
		if(~rst_n)
		begin
			start_CLAHE = 0;
			width = 0;
			height = 0;
			constract_th = 0;
		end
		else if(in_V_SYNC == 1 && CLAHE_EN == 1)
		begin
			start_CLAHE = 1;
			width = width_in;
			height = height_in;
			constract_th = constract_th_in;
		end
		else if(in_V_SYNC == 1 && CLAHE_EN == 0)
			start_CLAHE = 0;
		else
			start_CLAHE = start_CLAHE;
	   
	    if(CLAHE_EN == 1)
	       TREADY_out = 1;
	    else
	       TREADY_out = 0;
	end
	assign clk_clahe = start_CLAHE & clk;
	//
	wire buf_H_SYNC;
	wire buf_V_SYNC;
	wire buf_data_en;
	wire buf_data_en_4363;
	wire [7:0] data_out_4363;
	wire [7:0] data_out_4364;
	wire data_en_1;
	wire data_en_2;
	wire TVALID_input_buf1;
	wire TVALID_input_buf2;
	
	input_buf input_buf_init(
		.clk(clk_clahe),
		.rst_n(rst_n),
		.in_H_SYNC(in_H_SYNC),
		.in_V_SYNC(in_V_SYNC),
		.in_data_en(in_data_en),
		.data_in(data_in),
		.V_SYNC(in_V_SYNC),
		.TVALID_in(in_data_en),
		
		.o_H_SYNC(buf_H_SYNC),
		.o_V_SYNC(buf_V_SYNC),
		.o_data_en(buf_data_en),
		.o_data_en_4363(buf_data_en_4363),
		.data_out_4363(data_out_4363),
		.data_out_4364(data_out_4364),
		.data_en_1(data_en_1),
		.data_en_2(data_en_2),
		.TVALID_input_buf1(TVALID_input_buf1),
		.TVALID_input_buf2(TVALID_input_buf2)
	);
	//test port
	assign data_out_4363_o = buf_data_en_4363;
	assign data_out_4364_o = buf_data_en;
	assign data_en_1_o = data_en_1;
	assign data_en_2_o = data_en_2;
	
	//RAM inital
	//port a,
	wire [7:0] porta_addr;//
	wire [4:0] porta_wr_block;//
	wire [4:0] porta_rd_block;//
	wire [15:0] porta_data_in;//
	wire [15:0] porta_data_out;//

	//	port b,
	wire [7:0] portb_addr;//
	wire [4:0] porta_rd_block1;
	wire [4:0] porta_rd_block2;
	wire [4:0] porta_rd_block3;
	wire [4:0] porta_rd_block4;
	wire [4:0] portb_wr_block;//译码产生写信号，地址同gray,或写入累计直方图统计��?
	wire [15:0] portb_data_in;
	wire [15:0] porta_data_out_1;
	wire [15:0] porta_data_out_2;
	wire [15:0] porta_data_out_3;
	wire [15:0] porta_data_out_4;
	
	wire portb_clear_flag;//
	wire [31:0] portb_clear_wren_bus;
	
	wire portb_clear_flag_initial;
	
	ram_cntl ram_cntl_init(
		.clk(clk_clahe),
		
		.porta_addr(porta_addr),
		.porta_wr_block(porta_wr_block),
		.porta_rd_block(porta_rd_block),
		.porta_data_in(porta_data_in),
		.porta_data_out(porta_data_out),
		
		.portb_addr(portb_addr),
		.porta_rd_block1(porta_rd_block1),
		.porta_rd_block2(porta_rd_block2),
		.porta_rd_block3(porta_rd_block3),
		.porta_rd_block4(porta_rd_block4),
		.portb_wr_block(portb_wr_block),
		.portb_data_in(portb_data_in),
		.porta_data_out_1(porta_data_out_1),
		.porta_data_out_2(porta_data_out_2),
		.porta_data_out_3(porta_data_out_3),
		.porta_data_out_4(porta_data_out_4),
		
		.portb_clear_flag(portb_clear_flag | portb_clear_flag_initial),
		.portb_clear_wren_bus(portb_clear_wren_bus)
	);
	assign porta_wr_block = 5'bzzzzz;
	
	wire [4:0] excess_addr;//对应的block
	wire [15:0] excess_wr_data;
	wire excess_wren;
	
	//
	wire excess_4block_rden;
	wire [4:0] excess_addr_rd1;
	wire [4:0] excess_addr_rd2;
	wire [4:0] excess_addr_rd3;
	wire [4:0] excess_addr_rd4;
	wire [15:0] excess_rd_data1;
	wire [15:0] excess_rd_data2;
	wire [15:0] excess_rd_data3;
	wire [15:0] excess_rd_data4;
	
	excess_ram_32x16bit excess_ram_32x16bit_init(
		.clk(clk_clahe),
		.excess_addr(excess_addr),
		.excess_wr_data(excess_wr_data),
		.excess_wren(excess_wren),
		
		.excess_4block_rden(excess_4block_rden),
		.excess_addr_rd1(excess_addr_rd1),
		.excess_addr_rd2(excess_addr_rd2),
		.excess_addr_rd3(excess_addr_rd3),
		.excess_addr_rd4(excess_addr_rd4),
		.excess_rd_data1(excess_rd_data1),
		.excess_rd_data2(excess_rd_data2),
		.excess_rd_data3(excess_rd_data3),
		.excess_rd_data4(excess_rd_data4)
	);
	
	histogram histogram_init(
		.clk(clk_clahe),
		.rst_n(rst_n),
//		.in_data_en(buf_data_en),
		.in_data_en(data_en_1),
		.data_in(data_out_4364),//
		.area_flag(area_flag),
		.width(width),
		.height(height),
		.TVALID_in(TVALID_input_buf1),
		
		.hist_stat_rd_a(porta_data_out),
		.porta_addr(porta_addr),
		.portb_addr(portb_addr),
		.hist_stat_wr_b(portb_data_in),
		.portb_wr_block(portb_wr_block),
		.porta_rd_block(porta_rd_block)
		
	);
	
	wire [21:0] w1;
	wire [21:0] w2;
	wire [21:0] w3;
	wire [21:0] w4;
	
	wire inter_H_SYNC;
	wire inter_V_SYNC;
	wire inter_data_en;
	wire inter_complete;
	wire [7:0] inter_data_out;
	wire TVALID_inter;
	
	interpolation_cntl interpolation_cntl_init(
		.clk(clk_clahe),
		.rst_n(rst_n),
		.in_H_SYNC(buf_H_SYNC),
		.in_V_SYNC(buf_V_SYNC),
//		.in_data_en(buf_data_en_4363),
		.in_data_en(data_en_2),
		.data_in(data_out_4363),
		.area_flag(~area_flag),
		.width(width),
		.height(height),
		.TVALID_in(TVALID_input_buf2),
		
		.porta_rd_block1(porta_rd_block1),
		.porta_rd_block2(porta_rd_block2),
		.porta_rd_block3(porta_rd_block3),
		.porta_rd_block4(porta_rd_block4),
//		.portb_addr(portb_addr),
		
		.w1(w1),
		.w2(w2),
		.w3(w3),
		.w4(w4),
		
		.excess_addr_rd1(excess_addr_rd1),
		.excess_addr_rd2(excess_addr_rd2),
		.excess_addr_rd3(excess_addr_rd3),
		.excess_addr_rd4(excess_addr_rd4),
		.excess_rden(excess_4block_rden),
		
		.o_H_SYNC(inter_H_SYNC),
		.o_V_SYNC(inter_V_SYNC),
		.o_data_en(inter_data_en),
		.inter_data_out(inter_data_out),
		.inter_complete(inter_complete),
		.TVALID_inter(TVALID_inter)
	);
	
	wire equ_complete;
//	wire [7:0] data_out;
//	wire o_H_SYNC;
//    wire o_V_SYNC;
//    wire o_data_en;
	equalizer equalizer_init(
		.clk(clk_clahe),
		.rst_n(rst_n),
		.in_H_SYNC(inter_H_SYNC),
		.in_V_SYNC(inter_V_SYNC),
		.in_data_en(inter_data_en),
		.data_in(inter_data_out),
		.inter_complete(inter_complete),
		.block_size(block_size),
		.TVALID_in(TVALID_input_buf2),
		
		.porta_data_out_1(porta_data_out_1),
		.porta_data_out_2(porta_data_out_2),
		.porta_data_out_3(porta_data_out_3),
		.porta_data_out_4(porta_data_out_4),
		
		.excess_rd_data1(excess_rd_data1),
		.excess_rd_data2(excess_rd_data2),
		.excess_rd_data3(excess_rd_data3),
		.excess_rd_data4(excess_rd_data4),
		
		.w1(w1),
		.w2(w2),
		.w3(w3),
		.w4(w4),
		
		.o_H_SYNC(o_H_SYNC),
		.o_V_SYNC(o_V_SYNC),
//		.o_data_en(o_data_en),
		.data_out(data_out),
		.equ_complete(equ_complete)
	);
	assign equ_complete_o = equ_complete;
	wire clear_done;
	wire clip_done;
	
	histogram_clear histogram_clear_init(
		.clk(clk_clahe),
		.rst_n(rst_n),
		.clear_en(equ_complete),
		.area_flag(~area_flag),
		
		.portb_addr(portb_addr),
		.portb_clear_wren_bus(portb_clear_wren_bus),
		.portb_clear_flag(portb_clear_flag),
		.portb_clear_data(portb_data_in),
		.clear_done(clear_done)
	);
	
	clipper clipper_init(
		.clk(clk_clahe),
		.rst_n(rst_n),
		.clear_done(clear_done),
		.area_flag(area_flag),
		
		.hist_stat_rd_a(porta_data_out),
		.porta_addr(porta_addr),
		.porta_rd_block(porta_rd_block),
		.constract_th(constract_th),
		
		.portb_addr(portb_addr),
		.portb_wr_data(portb_data_in),
		.portb_wr_block(portb_wr_block),
		
		.excess_addr(excess_addr),
		.excess_wr_data(excess_wr_data),
		.excess_wren(excess_wren),
		
		.clip_done(clip_done),
		.cilp_start_r2_out(cilp_start_r2_out)//
	);
	
	initial_clear initial_clear_init(
		.clk(clk_clahe),
		.rst_n(rst_n),
		.in_data_en(in_data_en),
		.portb_addr(portb_addr),
		.portb_clear_flag_initial(portb_clear_flag_initial),
		.portb_clear_data_initial(portb_data_in),
		.portb_clear_wren_bus_initial(portb_clear_wren_bus)
	);
	
	assign hist_stat_rd_a_out = porta_data_out;//

	always@(posedge clip_done or negedge rst_n)
	begin
		if(~rst_n)
			area_flag <= 0;
		else
			area_flag <= ~area_flag;
	end
	
	//VGA2AXI
//	VGA2AXI VGA2AXI_init(
//        .ACLK(ACLK_out),
//        .ARESTN(ARESTN_out),
//        .TDATA(TDATA_out),
//        .TSTRB(TSTRB_out),
//        .TLAST(TLAST_out),
//        .TVALID(TVALID_out),
//        .TUSER(TUSER_out),
//        .TREADY(TREADY_in),
//        
//			.TUSER_in(TUSER_in),
//         .TVALID_in(TVALID_input_buf2),
//			.width(width),
//			.height(height),
//		
//        .clk(clk),
//        .rst_n(rst_n),
//        .H_SYNC(o_H_SYNC),
//        .V_SYNC(o_V_SYNC),
//        .DATA_EN(o_data_en),
//        .pixel(data_out)
//    );
	
	reg [19:0] cnt;
	always@(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            cnt <= 0;
			else if(buf_V_SYNC == 0)
				cnt <= 1;
         else
         begin
            if(TVALID_input_buf2 == 1)
                cnt <= cnt + 1;
            else if(cnt > height*width)
                cnt <= cnt + 1;
            else
                cnt <= cnt;
         end
    end
	assign o_data_en = buf_V_SYNC == 0 ? 0 :
	                   (cnt < 6 ? 0 : 
	                   (cnt < (height*width + 6) && cnt >= (height*width))? 1 : TVALID_input_buf2);//cnt < 17 ? 0 : 920,832
endmodule 