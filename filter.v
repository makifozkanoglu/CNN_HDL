`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2020 05:02:56 PM
// Design Name: 
// Module Name: filter
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


module filter#(
           parameter FILTER_SIZE = 15,
           parameter FILTER_COUNTER_BIT_SIZE=4, //ceil of log2(FILTER_SIZE)
           parameter BIT_SIZE = 9,
           parameter INPUT_WIDTH=32,
           parameter INPUT_HEIGHT=32,
           parameter CHANNEL_SIZE=3, 
           parameter SUBKERNEL_OUT_BIT = 24, //BIT_SIZE*2+ceil of log2(KERNEL_WIDTH*KERNEL_HEIGHT)
           parameter KERNEL_WIDTH = 6, 
           parameter KERNEL_HEIGHT = 6, 
           parameter STRIDE = 1,
           parameter OUTPUT_WIDTH = (INPUT_WIDTH - KERNEL_WIDTH) / STRIDE + 1,
           parameter OUTPUT_HEIGHT = (INPUT_HEIGHT - KERNEL_HEIGHT) / STRIDE + 1,
           parameter CHANNEL_EXTENSION_BIT = 2 //ceil of log2(CHANNEL_SIZE)
           )(
            input [INPUT_WIDTH*INPUT_HEIGHT*CHANNEL_SIZE*BIT_SIZE-1:0] input_buffer,
            input [KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*FILTER_SIZE*BIT_SIZE-1:0] kernel_buffer_for_filters,//
            input [FILTER_SIZE*BIT_SIZE-1:0] bias_buffer,//
            input clock,reset,enable,
            output [FILTER_SIZE*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 :0] filter_result,
            output reg done
            );
            
    genvar i;
    
    
    wire [KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*BIT_SIZE-1:0] kernel_array_for_filters [FILTER_SIZE-1:0];
    for(i=0;i<FILTER_SIZE;i=i+1) begin
        assign kernel_array_for_filters[i] = kernel_buffer_for_filters[(i+1)*KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*BIT_SIZE - 1:
                                                                          i*KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*BIT_SIZE];
    end
    
    
    wire signed [BIT_SIZE-1:0] bias_array_for_filters [FILTER_SIZE-1:0];
    for(i=0;i<FILTER_SIZE;i=i+1) begin
        assign bias_array_for_filters[i] = bias_buffer[(i+1)*BIT_SIZE - 1 : i*BIT_SIZE];
    end
    
    
    reg [(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 : 0] filter_result_array [FILTER_SIZE-1:0];
    for(i=0;i<FILTER_SIZE;i=i+1) begin
        assign filter_result[(i+1)*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1:
                                 i*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT]=filter_result_array[i];
    end
    
    
    wire  [(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 :0] conv_result;
    wire kernel_done;
    
    reg [KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*BIT_SIZE-1:0] kernel_buffer;
    reg signed [BIT_SIZE-1:0] bias;
    
    reg kernel_start,kernel_reset;
   
    kernel #(BIT_SIZE,
             INPUT_WIDTH,
             INPUT_HEIGHT,
             CHANNEL_SIZE, 
             SUBKERNEL_OUT_BIT, 
             KERNEL_WIDTH, 
             KERNEL_HEIGHT, 
             STRIDE,
             OUTPUT_WIDTH,
             OUTPUT_HEIGHT,
             CHANNEL_EXTENSION_BIT)
             kernel_uut(input_buffer, 
                        kernel_buffer,
                        bias,
                        clock,
                        kernel_reset,
                        kernel_start,
                        conv_result,
                        kernel_done);
    
            
    reg [1:0] state,NextState;
    always@(posedge clock)
    begin
        if (reset==1) begin
            state <= 0;
            NextState<=0;
        end
        else
            state <= NextState;
    end
    
    
    reg [FILTER_COUNTER_BIT_SIZE-1:0] filter_counter;
    always@(posedge clock) begin
        if (reset) begin
            kernel_start=0;
            kernel_reset=1;
            done=0;
            filter_counter=0;
        end
        else if (enable & ~done) begin
            case(state) 
            3'd0:
                begin
                    bias=bias_array_for_filters[filter_counter];
                    kernel_buffer=kernel_array_for_filters[filter_counter];
                    kernel_start=1;
                    kernel_reset=0;
                    if(kernel_done) begin
                        filter_result_array[filter_counter]=conv_result;
                        NextState=1;
                    end
                end
            3'd1:
                begin
                    if (NextState==1)
                        filter_counter=filter_counter+1;
                    NextState=2;
                end
            3'd2:
                begin
                    //done=1;
                    kernel_start=0;
                    if (filter_counter==FILTER_SIZE || filter_counter==0) begin
                        done=1;
                        NextState=3;
                    end
                    else begin
                        kernel_reset=1;
                        NextState=0;
                    end
                end
            endcase
        end
    end
            
endmodule
