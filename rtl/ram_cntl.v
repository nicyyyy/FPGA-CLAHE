module ram_cntl(
	input clk,
	//port a
	input [7:0] porta_addr,//
	input [4:0] porta_wr_block,//
	input [4:0] porta_rd_block,//
	input [15:0] porta_data_in,//
	output [15:0] porta_data_out,//
	
	input [4:0] porta_rd_block1,
	input [4:0] porta_rd_block2,
	input [4:0] porta_rd_block3,
	input [4:0] porta_rd_block4,
	output [15:0] porta_data_out_1,
	output [15:0] porta_data_out_2,
	output [15:0] porta_data_out_3,
	output [15:0] porta_data_out_4,

	//	port b,用于计算插值和均衡化
	input [7:0] portb_addr,//因为是同一个灰度值，所以片内地址都是一样的
	
	input [4:0] portb_wr_block,//译码产生写信号，地址同gray,或写入累计直方图统计值
	input [15:0] portb_data_in,
	
	input portb_clear_flag,//清零信号来时，同时选中16片ram
	input [31:0] portb_clear_wren_bus,
	
	input portb_clear_flag_inital,//初始化清零
	input [31:0] portb_clear_wren_bus_inital
);
	//与插值模块的连接 	
	wire [31:0] decode_wren_b;
	Decoder_5_32 Decoder_5_32_b_wren(
		.data_in(portb_wr_block),
		.data_out(decode_wren_b)
	);
	wire [31:0] portb_wren;
	assign portb_wren = portb_clear_flag == 1 ? portb_clear_wren_bus : decode_wren_b;
	
	wire [15:0] portb_data_bus[31:0];//a口输出数据总线
	
	
	//	与直方图计算模块的连接
	wire [31:0] decode_wren_a;
	Decoder_5_32 Decoder_5_32_a_wren(
		.data_in(porta_wr_block),
		.data_out(decode_wren_a)
	);
	
	
	wire [15:0] porta_data_bus[31:0];//b口输出数据总线
	assign porta_data_out = porta_data_bus[porta_rd_block];
	assign porta_data_out_1 = porta_data_bus[porta_rd_block1];
	assign porta_data_out_2 = porta_data_bus[porta_rd_block2];
	assign porta_data_out_3 = porta_data_bus[porta_rd_block3];
	assign porta_data_out_4 = porta_data_bus[porta_rd_block4];
	
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank1 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka ( clk ),
		.clkb ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena  ( 1'b1 ),
		.enb  ( 1'b1 ),
		.wea  ( decode_wren_a[0] ),
		.web  ( portb_wren[0] ),
		.douta ( porta_data_bus[0] ),
		.doutb ( portb_data_bus[0] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank2 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[1] ),
		.web  ( portb_wren[1] ),
		.douta( porta_data_bus[1] ),
		.doutb( portb_data_bus[1] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank3 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[2] ),
		.web  ( portb_wren[2] ),
		.douta( porta_data_bus[2] ),
		.doutb( portb_data_bus[2] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank4 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[3] ),
		.web  ( portb_wren[3] ),
		.douta( porta_data_bus[3] ),
		.doutb( portb_data_bus[3] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank5 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[4] ),
		.web  ( portb_wren[4] ),
		.douta( porta_data_bus[4] ),
		.doutb( portb_data_bus[4] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank6 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[5] ),
		.web  ( portb_wren[5] ),
		.douta( porta_data_bus[5] ),
		.doutb( portb_data_bus[5] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank7 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[6] ),
		.web  ( portb_wren[6] ),
		.douta( porta_data_bus[6] ),
		.doutb( portb_data_bus[6] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank8 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[7] ),
		.web  ( portb_wren[7] ),
		.douta( porta_data_bus[7] ),
		.doutb( portb_data_bus[7] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank9 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[8] ),
		.web  ( portb_wren[8] ),
		.douta( porta_data_bus[8] ),
		.doutb( portb_data_bus[8] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank10 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[9] ),
		.web  ( portb_wren[9] ),
		.douta( porta_data_bus[9] ),
		.doutb( portb_data_bus[9] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank11 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[10] ),
		.web  ( portb_wren[10] ),
		.douta( porta_data_bus[10] ),
		.doutb( portb_data_bus[10] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank12 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[11] ),
		.web  ( portb_wren[11] ),
		.douta( porta_data_bus[11] ),
		.doutb( portb_data_bus[11] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank13 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[12] ),
		.web  ( portb_wren[12] ),
		.douta( porta_data_bus[12] ),
		.doutb( portb_data_bus[12] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank14 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[13] ),
		.web  ( portb_wren[13] ),
		.douta( porta_data_bus[13] ),
		.doutb( portb_data_bus[13] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank15 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[14] ),
		.web  ( portb_wren[14] ),
		.douta( porta_data_bus[14] ),
		.doutb( portb_data_bus[14] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank16 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[15] ),
		.web  ( portb_wren[15] ),
		.douta( porta_data_bus[15] ),
		.doutb( portb_data_bus[15] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank17 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[16] ),
		.web  ( portb_wren[16] ),
		.douta( porta_data_bus[16] ),
		.doutb( portb_data_bus[16] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank18 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[17] ),
		.web  ( portb_wren[17] ),
		.douta( porta_data_bus[17] ),
		.doutb( portb_data_bus[17] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank19 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[18] ),
		.web  ( portb_wren[18] ),
		.douta( porta_data_bus[18] ),
		.doutb( portb_data_bus[18] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank20 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[19] ),
		.web  ( portb_wren[19] ),
		.douta( porta_data_bus[19] ),
		.doutb( portb_data_bus[19] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank21 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[20] ),
		.web  ( portb_wren[20] ),
		.douta( porta_data_bus[20] ),
		.doutb( portb_data_bus[20] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank22 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[21] ),
		.web  ( portb_wren[21] ),
		.douta( porta_data_bus[21] ),
		.doutb( portb_data_bus[21] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank23 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[22] ),
		.web  ( portb_wren[22] ),
		.douta( porta_data_bus[22] ),
		.doutb( portb_data_bus[22] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank24 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[23] ),
		.web  ( portb_wren[23] ),
		.douta( porta_data_bus[23] ),
		.doutb( portb_data_bus[23] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank25 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[24] ),
		.web  ( portb_wren[24] ),
		.douta( porta_data_bus[24] ),
		.doutb( portb_data_bus[24] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank26 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[25] ),
		.web  ( portb_wren[25] ),
		.douta( porta_data_bus[25] ),
		.doutb( portb_data_bus[25] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank27 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[26] ),
		.web  ( portb_wren[26] ),
		.douta( porta_data_bus[26] ),
		.doutb( portb_data_bus[26] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank28 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[27] ),
		.web  ( portb_wren[27] ),
		.douta( porta_data_bus[27] ),
		.doutb( portb_data_bus[27] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank29 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[28] ),
		.web  ( portb_wren[28] ),
		.douta( porta_data_bus[28] ),
		.doutb( portb_data_bus[28] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank30 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[29] ),
		.web  ( portb_wren[29] ),
		.douta( porta_data_bus[29] ),
		.doutb( portb_data_bus[29] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank31 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[30] ),
		.web  ( portb_wren[30] ),
		.douta( porta_data_bus[30] ),
		.doutb( portb_data_bus[30] )
		);
	histogram_ram_256x16bit	histogram_ram_256x16bit_bank32 (
		.addra ( porta_addr ),
		.addrb ( portb_addr ),
		.clka  ( clk ),
		.clkb  ( clk ),
		.dina ( porta_data_in ),
		.dinb ( portb_data_in ),
		.ena   ( 1'b1 ),
		.enb   ( 1'b1 ),
		.wea  ( decode_wren_a[31] ),
		.web  ( portb_wren[31] ),
		.douta( porta_data_bus[31] ),
		.doutb( portb_data_bus[31] )
		);
endmodule 