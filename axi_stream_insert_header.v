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
	reg [DATA_BYTE_WD-1 : 0] r_keep_in;
	
	reg r_ready_insert;
	reg [DATA_WD-1 : 0] r_data_insert; 
	reg [DATA_WD-1 : 0] r_keep_insert; 
	reg [BYTE_CNT_WD-1 : 0] r_byte_insert_cnt; 
	reg r1_shakehand_insert,r2_shakehand_insert;
	reg r1_last_in,r2_last_in;


/***************************************************************/

/*****************************网表型****************************/
	
	wire shakehand_in;
	wire shakehand_insert;
	wire shakehand_out;

    
	wire [DATA_WD-1 : 0] d0_data_in;
	wire [DATA_WD-1 : 0] d0_data_insert;
	wire [DATA_WD-1 : 0] data_out_step,data_out_start;
	wire [DATA_BYTE_WD :0] d0_byte_cnt_shift;
	wire [DATA_WD :0] d0_byte_cnt_shift_8;
	wire [DATA_WD :0] d0_byte_cnt_8;

	// wire [DATA_BYTE_WD-1 : 0] invert_keep_insert;


/***************************************************************/


/*****************************组合逻辑****************************/
	
	assign ready_in = r_ready_in && (~valid_out || ready_out);
	assign shakehand_in = ready_in && valid_in;
	
	assign ready_insert = r_ready_insert && (~valid_out || ready_out);
	assign shakehand_insert = ready_insert && valid_insert;

    assign shakehand_out = valid_out && ready_out;

	assign d0_data_insert = r_data_insert & {{8{r_keep_insert[3]}},{8{r_keep_insert[2]}},{8{r_keep_insert[1]}},{8{r_keep_insert[0]}}};
	assign d0_byte_cnt_shift = 'd4-(r_byte_insert_cnt+1);
	assign d0_byte_cnt_shift_8 = d0_byte_cnt_shift << 3;	
	assign d0_byte_cnt_8 = (r_byte_insert_cnt+1) << 3;	
	assign d0_data_in = r1_data_in & {{8{r_keep_in[3]}},{8{r_keep_in[2]}},{8{r_keep_in[1]}},{8{r_keep_in[0]}}};

	assign last_out = (|(r_keep_insert & r_keep_in)) ? r2_last_in:r1_last_in;
	assign valid_out = (|r_keep_in) | last_out; 

	// assign invert_keep_insert = r_keep_insert[0:3];

	assign data_out_start 	= d0_data_insert << d0_byte_cnt_shift_8 | d0_data_in >> d0_byte_cnt_8;
	assign data_out_step 	= r2_data_in << d0_byte_cnt_shift_8 | d0_data_in >> d0_byte_cnt_8;
	// assign data_out 		= (r1_shakehand_in && !r2_shakehand_in) ? data_out_start:data_out_step;
	assign data_out 		= (r2_shakehand_insert) ? data_out_start:data_out_step;
	
	assign keep_out		= last_out ? 
						(r2_last_in ? (r_keep_in << d0_byte_cnt_shift) 
									: (r_keep_insert << d0_byte_cnt_shift|r_keep_in >> (r_byte_insert_cnt+1))): 
						((valid_out) ? 4'b1111 : 4'b0000);
/***************************************************************/

/******************************进程*****************************/

	always@(posedge clk) begin
		if(!rst_n) begin
			r1_shakehand_insert <= 1'd0;
			r2_shakehand_insert <= 1'd0;

		end
		else begin
			r1_shakehand_insert <= shakehand_insert;
			r2_shakehand_insert <= r1_shakehand_insert;
		end
	end



	always@(posedge clk) begin
		if(!rst_n) begin
			r1_last_in <= 1'd0;
			r2_last_in <= 1'd0;
		end
		else begin
			r1_last_in <= last_in;
			r2_last_in <= r1_last_in;
		end
	end

	always@(posedge clk) begin
		if(!rst_n || last_in)
			r_ready_in <= 1'd0;
		else if(shakehand_insert)
			r_ready_in <= 1'd1;
		else 
			r_ready_in <= r_ready_in;
	end

	always@(posedge clk) begin
		if(!rst_n || r1_last_in) begin
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
		if(!rst_n || last_out) 
			r2_data_in <= 'd0;
		else if(shakehand_out)
			r2_data_in <= d0_data_in;
	end

	always@(posedge clk) begin
		if(!rst_n || last_out)
			r_keep_in <= 'd0;
		else if(shakehand_in)
			r_keep_in <= keep_in;
		else 
			r_keep_in <= r_keep_in;
	end

	always@(posedge clk) begin
		if(!rst_n || last_out)
			r_ready_insert <= 1'd1;
		else if(shakehand_insert)
			r_ready_insert <= 1'd0;
		else
			r_ready_insert <= r_ready_insert;	
	end

	always@(posedge clk) begin
		if(!rst_n || last_out) begin
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
		if(!rst_n || last_out)
			r_byte_insert_cnt <= 'd0;
		else if(shakehand_insert)
			r_byte_insert_cnt <= byte_insert_cnt;
		else
			r_byte_insert_cnt <= r_byte_insert_cnt;	
	end

/***************************************************************/
endmodule
