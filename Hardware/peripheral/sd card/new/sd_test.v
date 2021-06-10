`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/15 21:48:21
// Design Name: 
// Module Name: sd_test
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


module sd_test(
        input   clk,                //50MHz input clock
        input   rst_n,
        input   SD_dataout,         //SD SPI data output
        
        output  SD_clk,             //SD SPI clock 25MHz
        output  SD_cs,              //SD SPI chip select
        output  SD_datain           //SD SPI data input
        
    );
    
wire        SD_datain_i;
wire        SD_datain_w;
wire        SD_datain_r;

wire        SD_cs_i;
wire        SD_cs_w;
wire        SD_cs_r;

wire [7:0]  mydata_o;               //synthesis keep
wire        myvalid_o;              //synthesis keep
wire        init_o;                 //synthesis keep               //SD card initialize finished flag
wire        write_o;                //SD Block write finished flag
wire        read_o;

wire [3:0]  initial_state;
wire [3:0]  write_state;
wire [3:0]  read_state;
wire        rx_valid;

reg         SD_datain_o;
reg         SD_cs_o;

reg [31:0]  read_sec;
reg         read_req;
reg [31:0]  write_sec;
reg         write_req;
reg [3:0]   sd_state;

parameter   STATUS_INITIAL = 4'd0;          //SD initialize state
parameter   STATUS_WRITE = 4'd1;            //sd write data state
parameter   STATUS_READ = 4'd2;             //sd read data state
parameter   STATUS_IDLE = 4'd3;             //sd idle state

assign  SD_cs = SD_cs_o;
assign  SD_datain = SD_datain_o;

//-----------------------------------------------------------------------------------------
// SD card initialization, block write, block read
//-----------------------------------------------------------------------------------------

always @(posedge SD_clk or negedge rst_n)
    if(!rst_n)
    begin
        sd_state<=STATUS_INITIAL;
        read_req<=1'b0;
        read_sec<=32'd0;
        write_req<=1'b0;
        write_sec<=32'd0;
    end
    else
        case(sd_state)
        
        STATUS_INITIAL:                     //wait for sd card initialize end
            if(init_o)
            begin
                sd_state<=STATUS_WRITE;
                write_sec<=32'd0;
                write_req<=1'b1;
            end
            else
                sd_state<=STATUS_INITIAL;
        STATUS_WRITE:                       //wait for SD card block write end, begins to write 512 data from section 0
            if(write_o)
            begin
                sd_state<=STATUS_READ;
                read_sec<=32'd0;
                read_req<=1'b1;
            end
            else
            begin
                write_req<=1'b0;
                sd_state<=STATUS_WRITE;
            end
            
        STATUS_READ:                        //wait for sd block read end, begins to read 512 data from section 0
            if(read_o)
                sd_state<=STATUS_IDLE;
            else
                begin
                read_req<=1'b0;
                sd_state<=STATUS_READ;
            end
                
        STATUS_IDLE:                        //free state
            sd_state<=STATUS_IDLE;
        endcase
        
//---------------------------------------------------------------------------------------
// SD initialize program
//---------------------------------------------------------------------------------------

sd_initial sd_initial_inst(
    .rst_n                  (rst_n),
    .SD_clk                 (SD_clk),
    .SD_cs                  (SD_cs_i),
    .SD_datain              (SD_datain_i),
    .SD_dataout             (SD_dataout),
    .rx(),
    .init_o                 (init_o),           //when init_o is Voh, sd card initialization finished 
    .state                  (initial_state)
);

//----------------------------------------------------------------------------------------
// sd card bock read program,write 512 data:0-255, 0-255
//----------------------------------------------------------------------------------------

sd_write sd_write_inst(
    .SD_clk                 (SD_clk),
    .SD_cs                  (SD_cs_w),
    .SD_datain              (SD_datain_w),
    .SD_dataout             (SD_dataout),
    
    .init                   (init_o),
    .sec                    (write_sec),            //sd card write section address
    .write_req              (write_req),            //sd write request signal
    .mystate                (write_state),
    .rx_valid               (rx_valid),
    .write_o                (write_o)               //when write_o is Voh, sd card data write finished
    
);

//----------------------------------------------------------------------------------------
// sd card block read program, read 512 data
//----------------------------------------------------------------------------------------

sd_read sd_read_inst(
    .SD_clk                 (SD_clk),
    .SD_cs                  (SD_cs_r),
    .SD_datain              (SD_datain_r),
    .SD_dataout             (SD_dataout),
    .init                   (init_o),
    .sec                    (read_sec),             //sd card section of read address
    .read_req               (read_req),             //sd card read request signal
    
    .mydata_o               (mydata_o),             //sd card data of already read
    .myvalid_o              (myvalid_o),            //when myvalid_o is Voh, means data is availiable
    
    .data_come              (data_come),
    .mystate                (read_state),
    
    .read_o                 (read_o)
);

//---------------------------------------------------------------------------------------
// sd card SPI signal choose
//----------------------------------------------------------------------------------------

always @(*)
begin
    case(sd_state)
        STATUS_INITIAL:
        begin
            SD_cs_o<=SD_cs_i;
            SD_datain_o<=SD_datain_i;
        end
        STATUS_WRITE:
        begin
            SD_cs_o<=SD_cs_w;
            SD_datain_o<=SD_datain_w;
        end
        STATUS_READ:
        begin
            SD_cs_o<=SD_cs_r;
            SD_datain_o<=SD_datain_r;
        end
        default:
        begin
            SD_cs_o<=1'b1;
            SD_datain_o<=1'b1;
        end
    endcase
end

//-----------------------------------------------------------------------------------------
// clock wiz PLL generate 25MHz SD card SPI clock
//-----------------------------------------------------------------------------------------

/*clk_wiz_0 pll_inst(
    .reset                     (~rst_n),
    .clk_in1                   (clk),
    .clk_out1                  (SD_clk),               //25MHz sd card SPI clock
    //.locked                    ()
);*/

endmodule
