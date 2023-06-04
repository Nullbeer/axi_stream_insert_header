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
	reg 		[DATA_BYTE_WD-1 : 0] keep_in;
	reg 		last_in;
     
	wire 		ready_in;
	wire 		valid_out;
	wire 		[DATA_WD-1 : 0] data_out;
	wire 		[DATA_BYTE_WD-1 : 0] keep_out;
	wire 		last_out;
	reg 		ready_out; 

	reg 		valid_insert;
	reg 		[DATA_WD-1 : 0] data_insert;
	reg 		[DATA_BYTE_WD-1 : 0] keep_insert;
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
integer delay_in;
initial begin
	valid_in = 0;
	#30;
	while(1) begin
		valid_in = {$random % 100} > 9 ? 1:0;
		delay_in = {$random} % MAX_DELAY;
		repeat(delay_in) begin 
			@(posedge clk);
		end
	   	#1;
	end
end

integer data_count;
integer i;
initial begin
	data_in = 0;
	keep_in = 0;
	last_in = 0;
	#30;
	while(1) begin
		data_count = {$random()} % MAX_DATA_COUNT + 2;
		for(i=0;i<data_count;i=i+1) begin
			keep_in = 32'hFFFF_FFFF;
			data_in = $random;
			@(posedge clk);
			while(!(valid_in && ready_in))begin
				@(posedge clk);
			end
			#1;
		end
		data_in = {$random()};
		keep_in = random_last_keep_in({$random() % DATA_BYTE_WD});
		last_in = 1'd1;
		@(posedge clk);
		while(!(valid_in && ready_in))begin
			@(posedge clk);
		end
		#1;
		last_in = 0;
		data_in = 32'd0;
		keep_in = 32'd0;
		@(posedge clk); #1;
	end
end

//随机产生head insert
integer delay_insert;
initial begin
	valid_insert = 0;
	#30
	while(1) begin
		valid_insert = {$random % 10} > 3 ? 1:0;
		delay_insert = {$random} % MAX_DATA_COUNT;
		repeat(delay_insert) begin 
			@(posedge clk);
		end
		#1;
	end
end

initial begin
	data_insert = 0;
	keep_insert = 0;
	byte_insert_cnt = 0;
	#30; 
	while(1) begin
		data_insert = $random();
		byte_insert_cnt = {$random()} % DATA_BYTE_WD;
		keep_insert = random_keep_insert(byte_insert_cnt);
		while(!(valid_insert && ready_insert))begin
			@(posedge clk);
		end
		#1;
	end
end

//随机产生ready_out,产生ready_out为1的可能性更大
integer delay_out;
initial begin
	ready_out = 0;
	#30;
	while(1) begin
		ready_out = ({$random()} % 10) > 3 ? 1:0;
		delay_out = {$random()} % MAX_DATA_COUNT;
		repeat(delay_out) begin
		   	@(posedge clk); 
		end
		#1;
	end
end


endmodule
