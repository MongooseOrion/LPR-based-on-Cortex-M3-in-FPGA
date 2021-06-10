module BAUD_Generator # (
	parameter BAUD_WID = 8,
	parameter BAUD_rate_cnt = 434, 	 	//115200 bits/s,5208代表9600bps
	parameter BAUD_rate_mid_cnt = 434	
)
(
	input 	 		 	 	 	rst_n     	,
	input 	 	 	  		 	clk      	,
	input 	 	  		 	   	bps_start 	, 	 	//波特率发生器启动信号
	output 	 	reg 	     	bps_flag  	 		//采样中点标志
	
);

reg 	 	[2 * BAUD_WID - 1 : 0] 	 	bps_cnt;
reg 	 	[2 * BAUD_WID - 1 : 0] 	 	bps_cnt_n;

/*************BAUD_Generator计数值***************/
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		bps_cnt <= {2 * BAUD_WID{1'b0}};
	else
		bps_cnt <= bps_cnt_n;
end

//bps_cnt_n在BAUD_rate_cnt和!bps_start（波特率发生器关闭）时清零
always @ (*)
begin
	if (bps_cnt == BAUD_rate_cnt)
		bps_cnt_n = {2 * BAUD_WID{1'b0}};
	else if (bps_start)
		bps_cnt_n = bps_cnt + 1'b1;
	else if (!bps_start)
		bps_cnt_n = {2 * BAUD_WID{1'b0}};
	else
		bps_cnt_n = bps_cnt;
end

/*************中点采样信号置位****************/
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		bps_flag <= 1'b0;
	else if (bps_cnt == BAUD_rate_mid_cnt)
		bps_flag <= 1'b1;
	else
		bps_flag <= 1'b0;
end
endmodule
