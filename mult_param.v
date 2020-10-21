`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2020 03:03:45 PM
// Design Name: 
// Module Name: mult_param
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


module mult_param #(parameter BIT_SIZE = 8)(
             input signed [BIT_SIZE-1:0] A,B,
             input clk,reset,enable,
             output reg done,
             output reg signed [2*BIT_SIZE-1:0] result
             );
             
     always@(posedge clk) begin
		if(reset) begin
			result = 0;
		    done = 0;
		end
		else begin
			if(enable) begin
				result = A*B;
				done = 1;
			end
			else begin
				result = 0;
				done = 0;
			end
		end
	 end
endmodule
