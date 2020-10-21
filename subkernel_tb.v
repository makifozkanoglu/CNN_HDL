`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2020 09:04:52 PM
// Design Name: 
// Module Name: subkernel_tb
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



module subkernel_tb#(parameter INWIDTH = 8, parameter OUTWIDTH = 16, parameter KERNEL_WIDTH = 4, parameter KERNEL_HEIGHT = 3 , parameter KERNEL_SIZE_BIT = 5)();

    reg reset,clk,start;
    reg [KERNEL_WIDTH*KERNEL_HEIGHT*INWIDTH-1:0] KERNEL;
    reg [KERNEL_WIDTH*KERNEL_HEIGHT*INWIDTH-1:0] X;
    wire [OUTWIDTH-1:0] subkernel_out;
    wire done;

    subkernel dut(reset,clk,start,KERNEL,X,subkernel_out,done);

    initial begin
        reset = 1;
        start = 0;
        clk = 0;
        KERNEL <= 96'h010000000001000000000100;
        X <= 96'h010203040102030401020304;
        #20;
        reset = 0;
        start = 1;
    end
    
    always #10 clk = ~clk;

endmodule
