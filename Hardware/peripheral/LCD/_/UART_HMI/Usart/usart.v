module usart # (
	parameter PORT_WID = 8
)
(
	input 	 	 	 	   	 	 		rst_n  	 	,
	input 	 	 	  				 	clk  	    ,
//	input	 		 		 	 	 	req_send    , 	 	//发送请求信号(上升沿脉冲)
//	input	  	 	 	 	 	 	 	data_high   ,
//	input	  	 	 	 	 	 	 	datain_en   ,         
//	input 		  	  	  	  	 	    RXD 	 	,
//	input	 	 [PORT_WID - 1 : 0] 	datain      , 	 	//并行数据输入
	output	 	   	 	 	 	  		TXD         , 	 	//串行输出接口
	output 	 	       	 	 	 	 	TI 	 	    , 	 	//一帧数据放完毕中断标志位
//	output	 	 	  	  				RI	 	    ,
	output 	 	  	 	  	 	 	 	send_inter  , 	 	//发送完成中断标志
	output 	 	 	  		 	 	 	req_flag   	 	   //数据输出，同时向串口发送模块发出请求脉冲	
);

wire	  		 	 	 bps_start_send;
wire	  		 	 	 bps_flag_send;
//wire	  		 	 	 bps_start_rec;
//wire	  		 	 	 bps_flag_rec;
wire [PORT_WID - 1 : 0]  data_rso;
wire 	 	 	   	  	 dout_high;
wire                     dout_en;
wire [PORT_WID - 1 : 0]  dout;

BAUD_Generator # (8, 5208, 2604) baud_send
(
	.rst_n 	 	 	  	  	  		 (rst_n),
	.clk 	 	 		 			 (clk),
	.bps_start 	 	 		 		 (bps_start_send),
	.bps_flag 	 	 		 		 (bps_flag_send)
);

USART_Send # (8, 4) 	 	 	    send_i1
(
	.rst_n 	 	 	  	  	  		 (rst_n),
	.clk 	 	 		 			 (clk),
	.tx_bps_start 	 	 		     (bps_start_send),
	.tx_bps_flag 	 	 		 	 (bps_flag_send),
 	.TI 	 	 		 	         (TI),
 	.TXD 	 	 		 	         (TXD),
 	.datain 	 	 		 	     (data_rso),
 	.req_send 	 	                 (req_flag)
);


// BAUD_Generator # (8, 5208, 2604) baud_rec
// (
// 	.rst_n 	 	 	  	  	  		 (rst_n),
// 	.clk 	 	 		 			 (clk),
// 	.bps_start 	 	 		 		 (bps_start_rec),
// 	.bps_flag 	 	 		 		 (bps_flag_rec)
// );

// USART_Rec # (4, 8) 	  	 		 rec_i1
// (
// 	.rst_n 	 	 	  	  	  		 (rst_n),
// 	.clk 	 	 		 			 (clk),
// 	.rx_bps_start 	 	 		     (bps_start_rec),
// 	.rx_bps_flag 	 	 		 	 (bps_flag_rec),
// 	.RI 	 	 		 	         (RI),
// 	.RXD 	 	 		 	         (RXD),
// 	.dataout	 	   	   	  	     (data_rs)
// );


USART_Ctrl # (8, 14, 4)    	 ctrl_i1
(
	.rst_n 	 	 	  	  	  		 (rst_n),
	.clk 	 	 		 			 (clk),
	.datain  		 				 (dout),
 	.data_high 	 	 		         (dout_high),
 	.datain_en 	 	 		 	     (dout_en),
	.dataout	 	   	   	  	     (data_rso),
	.send_inter	 	      	  	     (send_inter),
	.req_flag	 	   	 	  	     (req_flag)
);


endmodule

