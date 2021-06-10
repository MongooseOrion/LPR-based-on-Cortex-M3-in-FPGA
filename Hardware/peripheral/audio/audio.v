`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/25 22:29:22
// Design Name: 
// Module Name: audio
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

//��ģ��Ϊ��������Ƶ���


module audio(
    input   clk,
    input   rst,
    input   sd_sw,
    output reg led,
    output reg AUD_SD,
    output reg AUD_PWM
    );

//����PWM������ֵ���˴���������Ƶ���������
reg [15:0] led_threshold;
//�ֽ׶����趨Ϊ0������������Ҫ����
always @(posedge clk or posedge rst) begin
    if(rst) begin
        led_threshold <= 16'h0;
    end
    else begin
        led_threshold <= 16'h0;
     end
   end
//�øո����ɵ�PWM��ֵ����PWM��������LED��
// Drive led based on MIC_DATA, by generating PWM wave
reg [15:0] led_count;
always @(posedge clk or posedge rst) begin
    if(rst) begin
        led_count <= 16'd0;
    end
    else if(led_count < 16'd512) begin
        led_count <= led_count + 16'd1;
    end
    else begin
        led_count <= 16'd0;
    end
end

always @(posedge clk or posedge rst) begin
    if(rst) begin
        led <= 1'b0;
    end
    else begin
        if(led_count<led_threshold) begin
            led <= 1'b1;
        end
        else begin
            led <= 1'b0;
        end
    end
end
//�����ɺõ�PWM��ֱ�����ӵ���Ƶ�����˳�������Ŵ���ʹ��
// Audio output drive, directly use the PWM above
always @(posedge clk or posedge rst) begin
    if(rst) begin
        AUD_SD <= 1'b0;
        AUD_PWM <= 1'b0;
    end
    else begin
        AUD_SD <= sd_sw;
        AUD_PWM <= led;
    end
end

endmodule
