module axi_stream_insert_header # (
	parameter DATA_WD = 32,
	parameter DATA_BYTE_WD = DATA_WD / 8,
	parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
)(
	input clk,
	input rst_n,
	// AXI Stream input original data
	input valid_in,
	input [DATA_WD-1 : 0] data_in,
	input [DATA_BYTE_WD-1 : 0] keep_in,
	input last_in,
	output ready_in,
	// AXI Stream output with header inserted
	output valid_out,
	output [DATA_WD-1 : 0] data_out,
	output [DATA_BYTE_WD-1 : 0] keep_out,
	output last_out,
	input ready_out,
	// The header to be inserted to AXI Stream input
	input valid_insert,
	input [DATA_WD-1 : 0] data_insert,
	input [DATA_BYTE_WD-1 : 0] keep_insert,
	input [BYTE_CNT_WD-1 : 0] byte_insert_cnt,
	output ready_insert
);

/*****************************寄存器****************************/

reg r_ready_in;
reg [DATA_WD-1 : 0] r1_data_in,r2_data_in;
reg [DATA_BYTE_WD-1 : 0] r1_keep_in,r2_keep_in;
	
reg r_ready_insert;
reg [DATA_WD-1 : 0] r_data_insert; 
reg [DATA_WD-1 : 0] r_keep_insert; 
reg [BYTE_CNT_WD-1 : 0] r_byte_insert_cnt; 
reg r_last_in;
reg start_flag;

/***************************************************************/

/*****************************网表型****************************/


wire shakehand_in;
wire shakehand_insert;
wire shakehand_out;
    
wire [DATA_WD-1 : 0] data_out_temp;
wire [DATA_BYTE_WD :0] d0_byte_cnt_shift;
wire [DATA_WD :0] d0_byte_cnt_shift_8;
wire [DATA_WD :0] d0_byte_cnt_8;
wire [DATA_WD :0] d0_byte_cnt;

wire [DATA_WD-1 : 0] keep_out_temp;

wire stop_out_flag;
wire stop_in_flag;

/***************************************************************/

/*****************************组合逻辑****************************/

assign ready_in 			= r_ready_in && (~valid_out || ready_out);
assign shakehand_in 		= ready_in && valid_in;
	
assign ready_insert 		= r_ready_insert && (~valid_out || ready_out);
assign shakehand_insert 	= ready_insert && valid_insert;

assign shakehand_out		= ready_out && valid_out;

//传输最后一拍标志
assign stop_out_flag		= last_out && shakehand_out;
assign stop_in_flag			= r_last_in && shakehand_out;	


//数据移动字节计算
assign d0_byte_cnt			= r_byte_insert_cnt+1;
assign d0_byte_cnt_8 		= d0_byte_cnt << 3;	
assign d0_byte_cnt_shift 	= 'd4-d0_byte_cnt;
assign d0_byte_cnt_shift_8 	= d0_byte_cnt_shift << 3;	

//data,keep暂存计算
assign data_out_temp 		= (r2_data_in << d0_byte_cnt_shift_8) | (r1_data_in >> d0_byte_cnt_8);
assign keep_out_temp		= (r2_keep_in << d0_byte_cnt_shift) | (r1_keep_in >> d0_byte_cnt); 

//数据输出
assign keep_out		 		= keep_out_temp; 	
assign data_out				= data_out_temp;
assign valid_out 			= |r2_keep_in;
	// (|r1_keep_in) | last_out; 
assign last_out 			= (|r1_keep_in) ?
					  			(|(r_keep_insert & r1_keep_in) ? 1'd0 : 1'd1) :
					  			(|r2_keep_in)	? 1'd1 : 1'd0;


/***************************************************************/

/******************************进程*****************************/

always@(posedge clk) begin
	if(!rst_n) 
		start_flag <= 1'd0;
	else if(shakehand_insert)
		start_flag <= 1'd1;
	else if(shakehand_in)
	    start_flag <= 1'd0;
	else
	    start_flag <= start_flag;
end

always@(posedge clk) begin
	if(!rst_n || stop_out_flag)
		r_ready_insert <= 1'd1;
	else if(shakehand_insert)
		r_ready_insert <= 1'd0;
	else
		r_ready_insert <= r_ready_insert;	
end

always@(posedge clk) begin
	if(!rst_n || stop_out_flag) begin
		r_data_insert <= 'd0;
		r_keep_insert <= 'd0;
	end
	else if(shakehand_insert) begin
		r_data_insert <= data_insert;
		r_keep_insert <= keep_insert;
	end
	else begin
		r_data_insert <= r_data_insert;	
		r_keep_insert <= r_keep_insert;
	end
end

always@(posedge clk) begin
	if(!rst_n || stop_out_flag)
		r_byte_insert_cnt <= 'd0;
	else if(shakehand_insert)
		r_byte_insert_cnt <= byte_insert_cnt;
	else
		r_byte_insert_cnt <= r_byte_insert_cnt;	
end

always@(posedge clk) begin
	if(!rst_n || stop_out_flag)
		r_last_in <= 1'd0;
	else if(shakehand_in)
		r_last_in <= last_in;
	else
		r_last_in <= r_last_in;
end

always@(posedge clk) begin
	if(!rst_n || (last_in && shakehand_in))
		r_ready_in <= 1'd0;
	else if(shakehand_insert)
		r_ready_in <= 1'd1;
	else 
		r_ready_in <= r_ready_in;
end

always@(posedge clk) begin
	if(!rst_n || stop_in_flag) begin
		r1_data_in <= 'd0;
	end
	else if(shakehand_in) begin
		r1_data_in <= data_in;
	end
	else begin
		r1_data_in <= r1_data_in;	
	end
end

always@(posedge clk) begin
	if(!rst_n || stop_out_flag) 
		r2_data_in <= 'd0;
	else if(shakehand_in && start_flag) begin
		r2_data_in <= r_data_insert;
	end
	else if(shakehand_in || stop_in_flag)
		r2_data_in <= r1_data_in;
	else
		r2_data_in <= r2_data_in;
end

always@(posedge clk) begin
	if(!rst_n || stop_in_flag)
		r1_keep_in <= 'd0;
	else if(shakehand_in) 
		r1_keep_in <= keep_in;
	else 
		r1_keep_in <= r1_keep_in;
end

always@(posedge clk) begin
	if(!rst_n || stop_out_flag)
		r2_keep_in <= 'd0;
	else if(shakehand_in && start_flag) begin
		r2_keep_in <= r_keep_insert;
	end
	else if(shakehand_in || stop_in_flag)
		r2_keep_in <= r1_keep_in;
end

/***************************************************************/

endmodule
