`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/30/2023 09:57:58 AM
// Design Name: 
// Module Name: tb_axi_stream_insert_header
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_axi_stream_insert_header();

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



axi_stream_insert_header axi_stream_insert_header_u0
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

initial clk = 1;
always #10 clk=~clk;

integer number,i,j;


function [3:0] random_keep_insert;
	input [BYTE_CNT_WD-1:0] number_rk;
	case(number_rk)
		0: random_keep_insert = 4'b0001;
		1: random_keep_insert = 4'b0011;
		2: random_keep_insert = 4'b0111;
		3: random_keep_insert = 4'b1111;
	endcase
endfunction

function [3:0] random_last_keep_in;
	input integer number_rl;
	case(number_rl)
		0: random_last_keep_in = 4'b1000;
		1: random_last_keep_in = 4'b1100;
		2: random_last_keep_in = 4'b1110;
		3: random_last_keep_in = 4'b1111;
	endcase
endfunction

wire shakehand_clk = clk&valid_in&ready_in;


//验证基本功能
initial begin
	rst_n = 1'd0;
	valid_insert = 0;
	byte_insert_cnt = 0;
	keep_insert = 0;
	data_insert = 0;
	last_in=0;
	valid_in=0;
	data_in=0;
	keep_in=0;
	#40;
	rst_n = 1'd1;
    #60;
	for(j=0;j<10;j=j+1) begin
	#1;
		valid_insert = 1;
		byte_insert_cnt = $random()%4;
		keep_insert = random_keep_insert(byte_insert_cnt);
		data_insert = $random();
		last_in = 0;
	#19;
		number = {$random()}%8+10;
		keep_in = 4'b1111;
		valid_in = 1;
		for(i=0;i<number-1;i=i+1)begin
			data_in = $random();
			@(posedge shakehand_clk);
		end
		
		last_in = 1;
		valid_in = 1;
		data_in = $random();

		keep_in = random_last_keep_in($random()%4);
		@(posedge shakehand_clk);
	
		data_in = 0;
		valid_in = 0;
		valid_insert = 0;
		last_in = 0;
		keep_in = 0;
		#100;
	end
end

//验证逐级反压

	initial begin
		ready_out = 1'd1;
		#600;
		#1;
		ready_out = 1'd0;
		#19
		#100;
		ready_out = 1'd1;
		#300;
		#1
		ready_out = 1'd0;
		#19
		#50;
		ready_out = 1'd1;
	end

endmodule
