module gio(
input wire PCLK,
input wire PRESETn,
input wire PSEL,
input wire[11:0] PADDR,
input wire PENABLE,
input wire PWRITE,
input wire[31:0] PWDATA,
output wire [31:0] PRDATA,
input wire [3:0] GPIOI,
output wire [2:0] GPIOO);

wire read_en,write_en;
wire [3:0] REG_00 ;
reg [2:0] REG_01;
assign read_en=PSEL & (~PWRITE);
assign write_en=PSEL & (~PENABLE)&PWRITE;
always@(posedge PCLK or negedge PRESETn)begin
if(~PRESETn)begin
    REG_01[2:0]<=3'b0;
    end else if(write_en)begin
        case(PADDR)[11:2])
        10'b1:REG_01[2:0]=PWDATA[2:0];
        default:;
        end case
    end
end
always@(*)begin
if(read_en)begin
    case(PADDR[11:2])
        10'b0:PRDATA[31:0]={28'b0,REG_00[3:0]};
        10'b1:PRDATA[31:0]={29'b0,REG_01[2:0]};
        default:PRDATA[31:0]=32'b0;
        endcase
    end else begin
        PRDATA=32'b0;
    end
end
assgin REG_00[3:0]=GPIOI[3:0];
assgin GPIOO[2:0]=REG_01[2:0];
endmodule
