//****************************************Copyright (c)***********************************//
// File name:           asyn_rst_syn
// Last Version:        V1.1
// Descriptions:        异步复位，同步释放，并转换成高电平有效
//****************************************************************************************//

module asyn_rst_syn(
    input clk,          //目的时钟域
    input reset_n,      //异步复位，低有效
    
    output syn_reset    //高有效
    );
    
//reg define
reg reset_1;
reg reset_2;
    
//*****************************************************
//**                    main code
//***************************************************** 
assign syn_reset  = reset_2;
    
//对异步复位信号进行同步释放，并转换成高有效
always @ (posedge clk or negedge reset_n) begin
    if(!reset_n) begin
        reset_1 <= 1'b1;
        reset_2 <= 1'b1;
    end
    else begin
        reset_1 <= 1'b0;
        reset_2 <= reset_1;
    end
end
    
endmodule