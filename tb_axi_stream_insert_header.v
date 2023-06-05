module tb_axi_stream_insert_header();

	parameter MAX_DATA_COUNT = 5;
	parameter MAX_DELAY = 5;


	parameter DATA_WD = 32;
	parameter DATA_BYTE_WD = DATA_WD / 8;
	parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

	reg 		clk;
	reg 		rst_n;
	reg 		valid_in;
	reg 		[DATA_WD-1 : 0] data_in;
	wire 		[DATA_BYTE_WD-1 : 0] keep_in;
	wire 		last_in;
     
	wire 		ready_in;
	wire 		valid_out;
	wire 		[DATA_WD-1 : 0] data_out;
	wire 		[DATA_BYTE_WD-1 : 0] keep_out;
	wire 		last_out;
	reg 		ready_out; 

	reg 		valid_insert;
	reg 		[DATA_WD-1 : 0] data_insert;
	wire 		[DATA_BYTE_WD-1 : 0] keep_insert;
	reg 		[BYTE_CNT_WD-1 : 0] byte_insert_cnt;

	wire 		ready_insert;



axi_stream_insert_header 
# (
	.DATA_WD(DATA_WD),
	.DATA_BYTE_WD(DATA_BYTE_WD),
	.BYTE_CNT_WD(BYTE_CNT_WD)
)
axi_stream_insert_header_u0
(
	.clk				(clk			),
	.rst_n				(rst_n			),
	.valid_in			(valid_in		),
	.data_in			(data_in		),
	.keep_in			(keep_in		),
	.last_in			(last_in		),
	.ready_in			(ready_in		),
	.valid_out			(valid_out		),
	.data_out			(data_out		),
	.keep_out			(keep_out		),
	.last_out			(last_out		),
	.ready_out			(ready_out		),
	.valid_insert		(valid_insert	),
	.data_insert		(data_insert	),
	.keep_insert		(keep_insert	),
	.byte_insert_cnt	(byte_insert_cnt),
	.ready_insert		(ready_insert	)
);


// 随机产生keep insert
function [DATA_WD-1 : 0] random_keep_insert; 
	input [BYTE_CNT_WD-1:0] number_rk;

	integer j_insert;
	begin
	random_keep_insert = 1;
        for(j_insert=0;j_insert<number_rk;j_insert=j_insert+1) begin
            random_keep_insert = random_keep_insert << 1;
            random_keep_insert = random_keep_insert | 1'b1;
        end
    end
endfunction

//随机产生last last in
function [DATA_WD-1 : 0] random_last_keep_in;
	input integer number_rl;

	integer j_last;
	begin
	j_last = 0;
	random_last_keep_in = 0;
        for(j_last=0;j_last<number_rl;j_last=j_last+1) begin
            random_last_keep_in = random_last_keep_in << 1;
            random_last_keep_in = random_last_keep_in | 1'b1;
        end
	random_last_keep_in = ~ random_last_keep_in;
    end
endfunction


//产生时钟
initial clk = 1;
always #10 clk <= ~clk;


initial begin
	rst_n = 0;
	#50;
	rst_n = 1;
end


// 随机产生数据通路数据
always@(posedge clk) begin
	if(!rst_n)
		valid_in <= 0;
	else if(!valid_in || ready_in)
		valid_in <= {$random} % 10 > 3 ? 1:0;
	else
		valid_in <= valid_in;
end	

integer data_count;
integer i;
always@(posedge clk) begin
	if(!rst_n) begin
		data_in <= $random;
		data_count = {$random} % MAX_DATA_COUNT;
		i=0;
	end
	else if(valid_in && ready_in) begin
		if(i < data_count) begin
			data_in <= $random;
			i = i+1;
		end
		else if(i >= data_count) begin
			data_in <= $random;
			i = 0;
			data_count = {$random} % MAX_DATA_COUNT;
		end
	end
end

assign last_in = (i==data_count);
assign keep_in = (i==data_count)? random_last_keep_in({$random() % DATA_BYTE_WD}) : 32'hFFFF_FFFF;

// 随机产生head通路数据
always@(posedge clk) begin
	if(!rst_n)
		valid_insert <= 0;
	else if(!valid_insert || ready_insert) 
		valid_insert <=  {$random % 10} > 8 ? 1:0;
	else
		valid_insert <= valid_insert;
end

always@(posedge clk) begin
	if(!rst_n) begin
		data_insert <= $random;
		byte_insert_cnt <= {$random} % DATA_BYTE_WD;
	end
	else if(valid_insert && ready_insert) begin
		data_insert <= $random;
		byte_insert_cnt <= {$random} % DATA_BYTE_WD;
	end
end

assign keep_insert = random_keep_insert(byte_insert_cnt);

// 随机产生ready out
always@(posedge clk) begin
	if(!rst_n)
		ready_out <= 1'd0;
	else
		ready_out <= ({$random} % 10) > 1 ? 1:0;
end

endmodule
