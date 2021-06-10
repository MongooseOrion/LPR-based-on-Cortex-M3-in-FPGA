`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/14 20:19:57
// Design Name: 
// Module Name: sd_initial
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
`define rx_vaild rx_valid           //valid used incorrect spell, `define instead

module sd_initial(
    input               rst_n,
    input               SD_clk,
    input               SD_dataout,
    
    output reg          SD_cs,
    output reg          SD_datain,
    
    output reg [47:0]   rx,
    output reg          init_o,
    output reg [3:0]    state
    
    );
    
reg  [47:0]  CMD0   = {8'h40, 8'h00, 8'h00, 8'h00, 8'h00, 8'h95};  //CMD0 command, CRC95 required
reg  [47:0]  CMD8   = {8'h48, 8'h00, 8'h00, 8'h01, 8'haa, 8'h87};  //CMD8 command, CRC87 required
reg  [47:0]  CMD55  = {8'h77, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};  //CMD55 command, CRC NOT required
reg  [47:0]  ACMD41 = {8'h69, 8'h40, 8'h00, 8'h00, 8'h00, 8'hff};  //CMD41 command, CRC NOT required

reg  [9:0]   counter= 10'd0;
reg          reset  = 1'b1;

parameter   idle = 4'b0000;         //state : idle
parameter   send_cmd0 = 4'b0001;    //state : send CMD0
parameter   wait_01 = 4'b0010;      //state : wait for CMD0 answering
parameter   waitb = 4'b0011;        //state : wait for a while
parameter   send_cmd8 = 4'b0100;     //state : send CMD8
parameter   waita = 4'b0101;        //state : wait for CMD8 answering
parameter   send_cmd55 = 4'b0110;   //state : send CMD55
parameter   send_acmd41 = 4'b0111;  //state : send ACMD41
parameter   init_done = 4'b1000;    //init end
parameter   init_fail = 4'b1001;    //init failed

reg  [9:0]   cnt;

reg  [5:0]   aa;
reg          rx_vaild;
reg          en;

//----------------------------------------------------------------------------
// receive data from SD
//----------------------------------------------------------------------------

always @(posedge SD_clk)
begin
    rx[0] <= SD_dataout;
    rx[47:1]<=rx[46:0];
end

//----------------------------------------------------------------------------
// receive command answer signal from SD
//----------------------------------------------------------------------------

always @(posedge SD_clk)
begin
    if(!SD_dataout && !en)      //wait for SD_dataout turning to Vol, and then receiving data
    begin
        rx_vaild<=1'b0;
        aa<=1;
        en<=1'b1;               //when en turns to Voh, receiving data
    end
    else if(en)
    begin
        if(aa<47) 
        begin
            aa<=aa+1'b1;
            rx_vaild<=1'b0;
        end
        else 
        begin
        aa<=0;
        en<=1'b0;
        rx_vaild<=1'b1;         //when 48th bit data received, rx_vaild signal begins to vaild
        end
    end
    else
    begin
        en<=1'b0;
        aa<=0;
        rx_vaild<=1'b0;
    end
end

//-------------------------------------------------------------------------------------------
// counting delaying after power on, release reset signal
//-------------------------------------------------------------------------------------------
        
always @(negedge SD_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        counter<=0;
        reset<=1'b1;
    end
    else
    begin
        if(counter<10'd1023)
        begin
            counter<=counter+1'b1;
            reset<=1'b1;
        end
        else
        begin
            reset<=1'b0;
        end
    end
end

//-----------------------------------------------------------------------------------
// SD card initialization
//-----------------------------------------------------------------------------------

always @(negedge SD_clk)
begin
    if(reset==1'b1)
    begin
        if(counter<512)
        begin
            SD_cs<=1'b0;            //when chip select CS signal turns to Vol, choose SD card
            SD_datain<=1'b1;
            init_o<=1'b0;
            state=idle;
        end
        else
        begin
            SD_cs<=1'b1;            //when CS signal turns to Voh, release SD card
            SD_datain<=1'b1;
            init_o<=1'b0;
            state<=idle;
        end
    end
    else
    begin
        case(state)
            idle:   begin
                    init_o<=1'b0;
                    CMD0<={8'h40, 8'h00, 8'h00, 8'h00, 8'h00, 8'h95};       //CMD0 command string
                    SD_cs<=1'b1;
                    SD_datain<=1'b1;
                    state<=send_cmd0;
                    cnt<=0;
            end
            send_cmd0:  begin                                               //send command CMD0 to SD card
                        if(CMD0!=48'd0)
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=CMD0[47];                            //shift output
                            CMD0<={CMD0[46:0], 1'b0};
                        end
                        else
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=1'b1;
                            state<=wait_01;
                        end
            end
            wait_01:    begin                               //wait SD card COMD0 command response 0x01
                        if(rx_vaild && rx[47:40] == 8'h01)
                        begin
                           SD_cs<=1'b1;
                           SD_datain<=1'b1;
                           state<=waitb;
                        end
                        else if(rx_vaild && rx[47:40] != 8'h01)
                        begin
                            SD_cs<=1'b1;
                            SD_datain<=1'b1;
                            state<=idle;
                        end
                        else
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=1'b1;
                            state<=wait_01;
                        end
            end
            waitb:  begin                           //wait for a while
                    if(cnt<10'd1023)
                    begin
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                        state<=waitb;
                        cnt<=cnt+1'b1;
                    end
                    else
                    begin
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                        CMD8<={8'h48, 8'h00, 8'h00, 8'h01, 8'haa, 8'h87};        //CMD8 command string
                        cnt<=0;
                        state<=send_cmd8;
                    end
            end
            send_cmd8:  begin                           //send CMD8 command to SD
                        if(CMD8!=48'd0)
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=CMD8[47];
                            CMD8<={CMD8[46:0], 1'b0};
                        end
                        else
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=1'b1;
                            state<=waita;
                        end
            end
            waita:  begin                                   //wait for CMD8 answer
                    SD_cs<=1'b0;
                    SD_datain<=1'b1;
                    if(rx_vaild && rx[19:16]==4'b0001)              //SD 2.0, support 2.7v-3.6v supply voltage
                    begin
                        state<=send_cmd55;
                        CMD55<={8'h77, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};      //CMD55 command string
                        ACMD41={8'h69, 8'h40, 8'h00, 8'h00, 8'h00, 8'hff};      //ACMD41 commmand string
                    end
                    else if(rx_vaild && rx[19:16]!=4'b0001)
                    begin
                        state<=init_fail;
                    end
            end
            send_cmd55: begin               //send CMD55
                        if(CMD55!=48'D0)
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=CMD55[47];
                            CMD55<={CMD55[46:0], 1'b0};
                        end
                        else
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=1'b1;
                            if(rx_vaild && rx[47:40]==8'h01)        //wait for CMD55 answer signal 01
                                state<=send_acmd41;
                            else
                            begin
                                if(cnt<10'd127)
                                    cnt<=cnt+1'b1;
                                else
                                begin
                                    cnt<=10'd0;
                                    state<=init_fail;
                                end
                            end
                        end
          end
          send_acmd41:  begin                   //send acmd41
                        if(ACMD41!=48'd0)
                        begin
                            SD_cs<=1'd0;
                            SD_datain<=ACMD41[47];
                            ACMD41<={ACMD41[46:0], 1'b0};
                        end
                        else
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=1'b1;
                            ACMD41<=48'd0;
                            if(rx_vaild && rx[47:40]==8'h00)        //wait for CMD55 answer signal 00
                                state<=init_done;
                            else
                            begin
                                if(cnt<10'd127)
                                    cnt<=cnt+1'b1;
                                else
                                begin
                                    cnt<=10'd0;
                                    state<=init_fail;
                                end
                            end
                        end
          end
          init_done:    begin                       //init done
                        init_o<=1'b1;
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                        cnt<=0;
          end
          init_fail:    begin
                        init_o<=1'b0;
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                        cnt<=0;
                        state<=waitb;
          end                                       //init failed, send CMD8, CMD55 and CMD41 again
          default:      begin
                        state<=idle;
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                        init_o<=1'b0;
          end
        endcase
    end
end 
endmodule
