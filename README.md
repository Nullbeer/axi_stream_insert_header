# axi_stream_insert_header

## 对题目的理解：
每次传输data时，都需要在第一拍数据上，将另一路上的data_insert添加上再进行传输。

举例：
data_insert = 32'h00112233
keep_insert = 4'b0011

输入三组数据
data_in[0] = 32'h8899AABB
data_in[1] = 32'hCCDDEEFF
data_in[2] = 32'h55556666
 
keep_last_in = 4'b1110

那么输出的数据为
将data_insert的低两个字节直接添加到data_in的头部
data_out[0] = 32'b22338899
data_out[1] = 32'bAABBCCDD
data_out[2] = 32'bEEFF5555
data_out[3] = 32'b66000000
并且
keep_last_out = 4'b1000
