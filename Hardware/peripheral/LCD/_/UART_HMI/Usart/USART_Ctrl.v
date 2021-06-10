module USART_Ctrl # (
	parameter CTRL_WID = 8,
	parameter NUM_CHAR = 13,
	parameter BIT_WID = 4
)
(
	input 	 	 	 	   	 	 		rst_n  	 	,
	input 	 	 	  				 	clk  	    ,
	input 	 [CTRL_WID - 1 : 0] 	 	datain 	 	,
	input  	 	 	 	 	 	 		data_high 	, 	 	//数据进入的高电平使能区间（接收区间）
	input	 	 	 	 	 	 	  	datain_en   ,	 	//每个数据请求脉冲（在上述高电平器期间）
	output reg [CTRL_WID - 1 : 0]	   	dataout 	, 	 	//8位并性数据输出
	output 	 	  	          	 	 	send_inter  , 	 	//发送完成中断标志
	output 	 	 	  	reg    	 	 	req_flag   	 	   //数据输出，同时向串口发送模块发出请求脉冲
);

/*******************整体功能***********************/
//实现2s，FPGA向串口屏发送字符串（在t0\t1\t2中要显示的内容，即电流、电角度、转速等参数）
//将t0.txt(or t1.txt存入到数组中)，然后当有输入进来时，和已在内存中的固定字符进行组合
/*******************END***********************/

//parameter TIME_1S = 27'd50_000_000; 	 	//1s = 1/(1/50M) = 50 * 10^6 = 5 * 10^7;
parameter TIME_10BITS = 62400; 	 	 	  	//发送数据的字符间隔，10bit数据间隔=104us*10=1040us，则1040*50=52000，取
														//TIME_10BITS >= 52000即可，但也不必太长
wire 	 	 	 	 	 	  	 	rec_finish;		   	 	 	//接收完成标志位（脉冲）
reg  [1 : 0] 	 	 	  	  	 	n_edge_reg; 	 					//下降沿存储寄存器
reg  [4 * BIT_WID - 1 : 0]      	time10_cnt; 	 	 		 	  	//每个字符的发送间隔  
reg  [CTRL_WID - 1 : 0] 	 	 	store  [NUM_CHAR - 1 : 0]; 	//中间的是位宽，后面的代表字符深度（个数） 
//reg  [7 * BIT_WID - 2 : 0]      	time_cnt; 	 	 	 	 	 	//2秒定时器计数变量（27位）
reg  [BIT_WID - 1 : 0] 	 	 	 	bit_cnt; 	 	 	   	 	 	//接收的字符个数计数变量
//reg 	 	 	 	    	 	 	datain_en_n; 	 	 			//数据请求脉冲打一个节拍
reg  [BIT_WID - 1 : 0] 	 		  	bit_sum; 	 	 	  	   	   //接收的字符总个数
reg	 	 	 	 	 	 	 	 	send_en; 	 	  	  	 		   //向外发送字符使能信号（发送区间）
reg  [BIT_WID - 1 : 0] 		  	  	send_bit_cnt; 	  	 	  	 	//发送字符个数计数器

/**************************字符接收***************************/
//发送区间定为2s,send_en发送使能时开始计数
//always @ (posedge clk, negedge rst_n)
//begin
//	if (!rst_n)
//		time_cnt <= {(7 * BIT_WID - 1){1'b0}};
//	else if (time_cnt == TIME_1S || !send_en)
//		time_cnt <= {(7 * BIT_WID - 1){1'b0}};
//	else if (send_en)
//		time_cnt <= time_cnt + 1'b1;
//end

//store初始化以及将接收到字符写入到非固定内存中
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
	begin
//		store[0] <= 8'h22;
		store[0] <= "t";
		store[1] <= "0";
		store[2] <= ".";
		store[3] <= "t";
		store[4] <= "x"; 
		store[5] <= "t"; 
		store[6] <= "=";
		store[7] <= 8'h22;
		store[8] <= "0";
		store[9] <= "0";
		store[10] <= "0";
		store[11] <= "0";
		store[12] <= "0";
	end
	else if (datain_en && data_high) 		 	//延迟1拍，注意要在data_high有效的时候判断datain_en，因为数据接收完毕时
		store[8 + bit_cnt] <= datain;
	else if (send_bit_cnt == NUM_CHAR + bit_sum)
	begin
		store[8] <= "0";	
		store[9] <= "0";
		store[10] <= "0";
		store[11] <= "0";
		store[12] <= "0"; 
	end
end

//保存接收最后一个字符后的总接收字符个数
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		bit_sum <= {BIT_WID{1'b0}}; 
	else if (send_bit_cnt == NUM_CHAR + bit_sum)
		bit_sum <= {BIT_WID{1'b0}};
	else if (datain_en && data_high)
	 	bit_sum <= bit_cnt + 1'b1; 	 		//保存bit的最后值，记录送入了几个字符
end

//接收的字符个数累加
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		bit_cnt <= {BIT_WID{1'b0}};
	else if (datain_en && data_high)	
		bit_cnt <= bit_cnt + 1'b1;
	else if (bit_cnt == 4'd5) 	 	 	 	   //用户字符为最多5个
		bit_cnt <= {BIT_WID{1'b0}};
	else if (!data_high)
		bit_cnt <= {BIT_WID{1'b0}};
end

////datain_en打一节拍（经过程序优化后，该段程序可以删去）
//always @ (posedge clk, negedge rst_n)
//begin
//	if (!rst_n)
//		datain_en_n <= 1'b0;
//	else if (datain_en)
//		datain_en_n <= 1'b1;
//	else
//		datain_en_n <= 1'b0;
//end

//data_high的下降沿检测
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		n_edge_reg <= 2'b00;
	else
		n_edge_reg <= {n_edge_reg[0], data_high};
end

assign rec_finish = (n_edge_reg == 2'b10) ? 1'b1 : 1'b0; 	 	//下降沿到来

/**************************字符移位输出***************************/
//数据的移位送出
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		send_en <= 1'b0;
	else if (rec_finish) 	 	  		 	 		 		     	 	 //接收完毕，开启发送区间使能信号
		send_en <= 1'b1;
	else if (send_bit_cnt == NUM_CHAR + bit_sum) 		  	 	 //发送完最后一个字符拉低发送区间状态标志（包含FF）
		send_en <=1'b0;
end

always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		send_bit_cnt <= {BIT_WID{1'b0}};
	else if (send_en && req_flag)
		send_bit_cnt <= send_bit_cnt + 1'b1;
	else if (send_bit_cnt == NUM_CHAR + bit_sum)
		send_bit_cnt <= {BIT_WID{1'b0}}; 
end

//需要再发送3个0XFF,表征指令生效
/*本节解释：
在send_en && time10_cnt == TIME_10BITS条件满足时，置位req_flag并移出一个字符，
在4'd8 + bit_sum范围内，移位输出写入Memory中的数据（0-8是固定的，bit_sum表示接收到的字符的个数），
故在send_bit_cnt >= 4'd9 + bit_sum且send_bit_cnt <= 4'd10 + bit_sum之间（在发送完用户数据之后），
就发送两个双引号，此后，再发送三个0XFF作为数据指令的结束标志（HMI指令要求）。 
*/
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		dataout <= {CTRL_WID{1'b1}};
	else if (send_en && time10_cnt == TIME_10BITS) 
	begin
		if (send_bit_cnt <= 4'd7 + bit_sum)
			dataout <= store[send_bit_cnt];
		else if (send_bit_cnt >= 4'd8 + bit_sum)
			begin
				if (send_bit_cnt == 4'd8 + bit_sum)
					dataout <= 8'h22;
				else if (send_bit_cnt <= 4'd11 + bit_sum)
					dataout <= 8'hFF;
				else
					dataout <= 8'hFF;
			end	
	end
end

//发送完成中断标志位
assign send_inter = (send_bit_cnt == NUM_CHAR + bit_sum) ? 1'b1 : 1'b0;

//发送数据时将发送请求置位
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		req_flag <= 1'b0;
	else if (send_en && time10_cnt == TIME_10BITS)
		req_flag <= 1'b1;
	else 
		req_flag <= 1'b0;
end

//10bits延时计数器（防止向串口发送模块发送数据过快）
always @ (posedge clk, negedge rst_n)
begin
	if (!rst_n)
		time10_cnt <= {(4 * BIT_WID){1'b0}};
	else if (time10_cnt == TIME_10BITS)
		time10_cnt <= {(4 * BIT_WID){1'b0}};
	else if (send_en)
		time10_cnt <= time10_cnt + 1'b1;
end
/**************************END***************************/

endmodule

