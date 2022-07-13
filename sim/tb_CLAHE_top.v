`timescale 1ns / 1ns
module tb_CLAHE_top();

	 reg ACLK_in;
    reg ARESTN_in;
    reg [7:0] TDATA_in;
    reg TSTRB_in;
    reg TLAST_in;
    reg TVALID_in;
    reg TUSER_in;
    wire TREADY_out;
    
   wire ACLK_out;     
   wire ARESTN_out;    
   wire [7:0] TDATA_out; 
   wire TSTRB_out;      
   wire TLAST_out;       
   wire TVALID_out;      
   wire TUSER_out;  

   wire [15:0] hist_stat_rd_a_out;
   wire cilp_start_r2_out;

   reg TREADY_in;       
  reg CLAHE_EN;
  reg [10:0] width_in;
  reg [10:0] height_in;
  reg [15:0] constract_th_in;
  
  //test port
  wire data_en_1_o,data_en_2_o;
  wire data_out_4363_o,data_out_4364_o;
  wire equ_complete;
    
    reg [7:0] temp8b;
    integer fd1;
    integer stop_flag;
    integer pixel_cnt;
    integer V_cnt;
    integer H_cnt;
    integer V_next;
    integer start_num, pause_num;

    parameter period = 500;
    parameter data_depth = 8;


    CLAHE_AXI CLAHE_AXI_init(
    .ACLK_in(ACLK_in),
    .ARESTN_in(ARESTN_in),
    .TDATA_in(TDATA_in),
    .TSTRB_in(TSTRB_in),
    .TLAST_in(TLAST_in),
    .TVALID_in(TVALID_in),
    .TUSER_in(TUSER_in),
    .TREADY_out(TREADY_out),
    
    .CLAHE_EN(CLAHE_EN),  
    .width_in(width_in),
    .height_in(height_in),
    .constract_th_in(constract_th_in),
    
    .ACLK_out(ACLK_out),      
    .ARESTN_out(ARESTN_out),   
    .TDATA_out(TDATA_out),
    .TSTRB_out(TSTRB_out),   
    .TLAST_out(TLAST_out),   
    .TVALID_out(TVALID_out),   
    .TUSER_out(TUSER_out),   
    .TREADY_in(TREADY_in),
	 
	 //test port
//	 .data_en_1_o(data_en_1),
//	 .data_en_2_o(data_en_2),
//	 .data_out_4363_o(data_out_4363_o),
//	 .data_out_4364_o(data_out_4364_o)
    .equ_complete(equ_complete),
    .hist_stat_rd_a_out(hist_stat_rd_a_out),
    .cilp_start_r2_out(cilp_start_r2_out)
    );

    initial
    begin
    CLAHE_EN = 1;
    height_in = 720;
    width_in = 1280;
    constract_th_in = 576;
    ARESTN_in = 0;
    TVALID_in = 0;
    TREADY_in = 1;
    #(period);
    ARESTN_in = 1;
    #(period);
	 
//	 while(stop_flag == 0 && TVALID_in == 1)
//	 begin
		 while(pixel_cnt < 32'd921600)
		 begin
		 start_num = {$random}%721 + 2;
		 pause_num = {$random}%11 + 2;
		 while(start_num > 1)
		 begin
		 start_num = start_num - 1;
		 #(period);
		 end
		 while(pause_num > 1)
		 begin
		 pause_num = pause_num - 1;
		 TVALID_in = 0;
		 #(period);
		 end
		 TVALID_in = 1;
		 end
		 
//	end
	TVALID_in = 0;
	#(period*(5000));
	
		 while(pixel_cnt < 32'd921600)
		 begin
		 start_num = {$random}%1281 + 2;
		 pause_num = {$random}%11 + 2;
		 while(start_num > 1)
		 begin
		 start_num = start_num - 1;
		 #(period);
		 end
		 while(pause_num > 1)
		 begin
		 pause_num = pause_num - 1;
		 TVALID_in = 0;
		 #(period);
		 end
		 TVALID_in = 1;
		 end
   end
integer repeat_time;
    //读
    initial
    begin
    repeat_time = 2;
	 #(period*2);
    repeat(2)
		begin
            stop_flag = 0;
            pixel_cnt = 0;
            V_next = 0;
            V_cnt = 1;
            H_cnt = 1;
				
            fd1 = $fopen("E:/my_verilog/prev_y.bin", "rb");
            #(3*period);
				TVALID_in = 1;
            while(pixel_cnt < 32'd921600)
            begin
					if(TREADY_out == 1'b1 && TVALID_in == 1'b1)
					begin
					$fread(temp8b, fd1, , 1);
					TDATA_in = temp8b;
					pixel_cnt = pixel_cnt + 1;
	
					if(V_cnt == 1 && V_next == 0)
					begin
					TUSER_in = 1;
					V_next = 1;
					end
					else if(H_cnt == 1280)
					TLAST_in = 1;
					else;
	
					if(V_cnt < 720)
					V_cnt = V_cnt + 1;
					else
					V_cnt = 1;
	
					if(H_cnt < 1280)
					H_cnt = H_cnt + 1;
					else
					H_cnt = 1;
	
					#(period/2);
					TUSER_in = 0;
					TLAST_in = 0;
					#(period/2);
            end
            else
            begin
					pixel_cnt = pixel_cnt;
					H_cnt = H_cnt;
					V_cnt = V_cnt;
					#(period);
            end
            if(pixel_cnt == 32'd921600)
					V_next = 0;
            end
            $fclose(fd1);
            if(repeat_time == 1)
					stop_flag = 1;
				else
					stop_flag = 0;
            pixel_cnt = pixel_cnt + 1;
            TVALID_in = 0;
				TDATA_in = 8'hzz;
            #(period*(6000));
			repeat_time = repeat_time - 1;
    //		$stop;
        end
    end
	
	//д
	integer fd2;
	initial
	begin
//		if(repeat_time == 1)
//		begin
			fd2 = $fopen("E:/my_verilog/AXI/CLAHE/CLAHE/CLAHE/CLAHE.bin", "wb");
			
			while(1)
			begin
				if(TVALID_out == 1)
				begin	
					$fwrite(fd2,"%02x",TDATA_out);						
				end
				else if(equ_complete == 1 && stop_flag == 1)
					begin
						$fclose(fd2);
						$stop;
					end
				#(period);
			end
//		end
	end
	
//	integer fd3;
//	initial
//	begin
//		fd3 = $fopen("E:/my_verilog/AXI/CLAHE/CLAHE/CLAHE/histogram.bin", "wb");
		
//		while(1)
//		begin
//			if(cilp_start_r2_out == 1)
//			begin
//				$fwrite(fd3,"%04x",hist_stat_rd_a_out);	
//			end
//			else if(o_data_en == 0 && stop_flag == 1)
//			begin
//				$fclose(fd3);
//				$stop;
//			end
//			#(period);
//		end
//	end
	integer fd3;
	initial
	begin
		fd3 = $fopen("E:/my_verilog/AXI/CLAHE/CLAHE/CLAHE/histogram.bin", "wb");
		
		while(1)
		begin
			if(cilp_start_r2_out == 1)
			begin
				$fwrite(fd3,"%04x",hist_stat_rd_a_out);	
			end
			else if(TVALID_out == 0 && stop_flag == 1)
			begin
				$fclose(fd3);
				$stop;
			end
			#(period);
		end
	end
	initial
    begin
    ACLK_in = 0;
    forever #(period/2) ACLK_in = ~ACLK_in;
    end

endmodule 