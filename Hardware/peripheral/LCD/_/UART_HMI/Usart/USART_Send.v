module USART_Send # (
	parameter PORT_WID = 8,
	parameter DATA_WID = 4
)
(
	input 	 	 	 	   	 	 		rst_n  	 	,
	input 	 	 	  				 	clk  	    ,
	input 	 	 		  	 	  	  	tx_bps_flag , 	 	//采样中点信号输入
	input	 		 		 	 	 	req_send    , 	 	//发送请求信号(上升沿脉冲)
	input	 	 [PORT_WID - 1 : 0] 	datain      , 	 	//并行数据输入
	output	 	   	 	 	 	  		TXD         , 	 	//串行输出接口
	output 	 	       	 	 	 	 	TI 	 	    , 	 	//一帧数据放完毕中断标志位
	output 	 	reg 	 	  	 		tx_bps_start 	 	//波特率发生器启动标志位输出
);

reg      	 	 	  		 	   	 	ti_buf          ;
reg      	 	 	  		 	   	 	tx_buf          ;
reg  	 	 [DATA_WID - 1 : 0] 	 	bit_cnt 	 	;
reg 	 	 [PORT_WID + 1 : 0]	 	 	datain_buf1 	;
reg 	 	 [PORT_WID + 1 : 0]	 	 	datain_buf2 	;

/*************请求信号到来写入数据****************/
//请求信号到来，写入数据big置位波特率启动位
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		tx_bps_start <= 1'b0;
	else if (req_send) 	 	 		  	  	 	    	  	 	 //请求信号有效，将输入写入到datain_buf1中
		tx_bps_start <= 1'b1;                      	 	 //波特率启动标志，直到停止位变为0
	else if (bit_cnt == 4'd10)
		tx_bps_start <= 1'b0;
end

always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		datain_buf1 <= {(PORT_WID + 1){1'b0}};
	else if (req_send)
		datain_buf1 <= {1'b1, datain[7 : 0], 1'b0}; 	 	 //10位数据帧格式，0位起始位，9位停止位;
end

reg 	 	 	 	 	 	 	 dat_flag;
/*************数据移位操作****************/
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
	begin
		datain_buf2 <= {(PORT_WID + 1){1'b0}};
		dat_flag <= 1'b0;
	end
	else if (tx_bps_flag)
	begin
		datain_buf2 <= datain_buf1 >> bit_cnt;
		dat_flag <= 1'b1; 	 	 	 	  	 	 	 	  	 	
	end
	else
		dat_flag <= 1'b0;
end

assign TXD = tx_buf; 
 
assign TI = ti_buf;
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		ti_buf <= 1'b0;
	else if (bit_cnt == 4'd10)
		ti_buf <= 1'b1;
	else
		ti_buf <= 1'b0;
end

always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		tx_buf <= 1'b1;
	else if (dat_flag) 	  	   	 	 	 		 	 //不是tx_bps_flag一到就赋值给tx_buf，顺延一个周期
		tx_buf <= datain_buf2[0]; 	 		 	 	    //为了避免datain_buf2初始赋值的影响
	else if (!tx_bps_start)
		tx_buf <= 1'b1;
end

/*************数据位数计数****************/
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		bit_cnt <= {DATA_WID{1'b0}};
	else if (tx_bps_flag)
		bit_cnt <= bit_cnt + 1'b1;
	else if (bit_cnt >= 4'd10)
		bit_cnt <= {DATA_WID{1'b0}};
end

endmodule
