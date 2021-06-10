`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/15 15:37:17
// Design Name: 
// Module Name: sd_write
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


module sd_write(
    input               SD_clk,
    input               SD_dataout,
    input               init,
    
    input   [31:0]      sec,                //write SD sec address
    input               write_req,          //write SD request
    
    output  reg         SD_cs,
    output  reg         SD_datain,
    output  reg [3:0]   mystate,
    output  reg         rx_valid,
    output  reg         write_o

    );

wire    [3:0]   mystate_o;
reg     [7:0]   rx;
reg             en;
reg     [5:0]   aa;
reg     [21:0]  cnt;
reg     [7:0]   write_data;
reg     [47:0]  CMD24 = {8'h58, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};         //block 'write' command CMD24 byte array
reg     [7:0]   Sblock_token = 8'hfe;
reg     [7:0]   CMDX;
reg     [7:0]   CMDY = 8'hff;
reg     [2:0]   cnta;

parameter   idle = 4'd0;
parameter   write_cmd = 4'd1;
parameter   wait_8clk = 4'd2;
parameter   start_taken = 4'd3;
parameter   writea = 4'd4;
parameter   write_crc = 4'd5;
parameter   write_wait = 4'd6;
parameter   write_done = 4'd7;

always @(posedge SD_clk)
begin
    rx[0]<=SD_dataout;
    rx[7:1]<=rx[6:0];
end


//------------------------------------------------------------------------------------------
// receive SD card answer data
//------------------------------------------------------------------------------------------

always @(posedge SD_clk)
begin
    if(!SD_dataout && !en)
    begin
        rx_valid<=1'b0;
        aa<=1;
        en<=1'b1;
    end                             //wait for SD_dataout turning to Vol, and then receive data
    else if(en)
    begin
        if(aa<7)
        begin
            aa<=aa+1'b1;
            rx_valid<=1'b0;
        end
        else
        begin
            aa<=0;
            en<=1'b0;
            rx_valid<=1'b1;             //when received 8th bit data, valid signal valid
        end
    end
    else
    begin
        en<=1'b0;
        aa<=0;
        rx_valid<=1'b0;
    end
end

//---------------------------------------------------------------------------
// SD card WRITE application
//---------------------------------------------------------------------------

always@(negedge SD_clk)
if(!init)
    begin
        mystate<=idle;
        CMD24<={8'h58, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};
        write_o<=1'b0;
    end
else
begin
    case(mystate)
        idle:   begin
                SD_cs<=1'b1;
                SD_datain<=1'b1;
                cnt<=22'd0;
                if(write_req)           //if there is a write request
                begin
                    mystate<=write_cmd;
                    CMD24<={8'h58, sec[31:24], sec[23:16], sec[15:8], sec[7:0], 8'hff};
                    Sblock_token<=8'hfe;
                    write_o<=1'b0;
                end
                else
                    mystate<=idle;
        end
        write_cmd:  begin               //send CMD24 command(singal block write)
                    if(CMD24!=48'd0)
                    begin
                        SD_cs<=1'b0;
                        SD_datain<=CMD24[47];
                        CMD24<={CMD24[46:0], 1'b0};
                    end
                    else
                    begin
                        if(rx_valid)                    //wait for answer signal
                        begin
                            cnta<=7;
                            mystate<=wait_8clk;
                            SD_cs<=1'b1;
                            SD_datain<=1'b1;
                        end
                    end
        end
        wait_8clk:  begin                               //write data after waiting 8 clock
                    if(cnta>0)
                    begin
                        cnta<=cnta-1'b1;
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                    end
                    else
                    begin
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                        mystate<=start_taken;
                        cnta<=7;
                    end
        end
        start_taken:    begin                   //send start block taken
                        if(cnta>0)
                        begin
                            cnta<=cnta-1'b0;
                            SD_cs<=1'b0;
                            SD_datain<=Sblock_token[cnta];          //high-order will be send first
                        end
                        else
                        begin
                            SD_cs<=1'b0;
                            SD_datain<=Sblock_token[0];
                            mystate<=writea;
                            cnta<=7;
                            cnt<=0;
                        end
        end
        writea: begin                   //write 512 bytes to SD(0-255, 0-255)
                if(cnt<512)
                begin
                    if(cnta>0)
                    begin
                        SD_cs<=1'b0;
                        SD_datain<=cnt[cnta];
                        cnta<=cnta-1'b1;
                    end
                    else
                    begin
                        SD_cs<=1'b0;
                        SD_datain<=cnt[0];
                        cnta<=7;
                        cnt<=cnt+1'b1;
                    end
                end
                else                    //write last byte
                begin
                    if(cnta>0)
                    begin
                        SD_datain<=cnt[cnta];
                        cnta<=cnta-1'b1;
                    end
                    else
                    begin
                        SD_datain<=cnt[cnta];
                        cnta<=7;
                        cnt<=0;
                        mystate<=write_crc;
                    end
                end
        end
        write_crc:  begin                   //write crc: 0xff, 0xff
                    if(cnt<16)
                    begin
                        SD_cs<=1'b0;
                        SD_datain<=1'b1;
                        cnt<=cnt+1'b1;
                    end
                    else
                    begin
                        if(rx_valid)            //wait data response token
                            mystate<=write_wait;
                        else
                            mystate<=write_crc;
                    end
        end
        write_wait: begin                       //wait for data writing finished
                    if(rx==8'hff)
                        mystate<=write_done;
                    else
                        mystate<=write_wait;
        end
        write_done: begin
                    if(cnt<22'd15)              //wait 15 clocks
                    begin
                        SD_cs<=1'b1;
                        SD_datain<=1'b1;
                        cnt<=cnt+1'b1;
                    end
                    else
                    begin
                        mystate<=idle;
                        write_o<=1'b1;
                        cnt<=0;
                    end
        end
        default:    mystate<=idle;
    endcase
end
    
endmodule
