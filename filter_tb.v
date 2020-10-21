`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/19/2020 06:53:39 PM
// Design Name: 
// Module Name: filter_tb
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


module filter_tb #(parameter FILTER_SIZE = 15,
                   parameter FILTER_COUNTER_BIT_SIZE=4,
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
                   );
    
    wire [INPUT_WIDTH*INPUT_HEIGHT*CHANNEL_SIZE*BIT_SIZE-1:0] input_buffer;
    wire [KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*FILTER_SIZE*BIT_SIZE-1:0] kernel_buffer_for_filters;//
    wire [FILTER_SIZE*BIT_SIZE-1:0] bias_buffer; assign bias_buffer=0;
    reg clock,reset,enable;
    wire [FILTER_SIZE*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 :0] filter_result;
    
    genvar i,j,k,l;
    
    wire [(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 : 0] filter_result_array [FILTER_SIZE-1:0];//burada genişlik ve uzunluk değerleri tek bit satırı halinde
    for(i=0;i<FILTER_SIZE;i=i+1) begin
        assign filter_result_array[i]=filter_result[(i+1)*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1:
                                                        i*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT];
    end
    
    wire [SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT - 1:0] filter_result_array_for_tb [OUTPUT_WIDTH-1:0][OUTPUT_HEIGHT-1:0][FILTER_SIZE-1:0]; //SUBKERNEL_OUT_BIT + 1 ==> ceil of log2(CHANNEL_SIZE)
    for (k=0;k<FILTER_SIZE;k=k+1) begin
        for (i=0;i<OUTPUT_HEIGHT;i=i+1) begin
            for (j=0;j<OUTPUT_WIDTH;j=j+1) begin
                assign filter_result_array_for_tb[j][i][k]=filter_result_array[k][(SUBKERNEL_OUT_BIT + 1)*(i*OUTPUT_WIDTH+j+1) - 1:(SUBKERNEL_OUT_BIT + 1)*(i*OUTPUT_WIDTH+j)];
            end
        end
    end
    
    wire done;
    filter #(FILTER_SIZE,
             FILTER_COUNTER_BIT_SIZE,
             BIT_SIZE,
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
           uut(input_buffer, 
               kernel_buffer_for_filters,
               bias_buffer,
               clock,
               reset,
               enable,
               filter_result,
               done);
   
   
    reg [BIT_SIZE-1:0] input_array [INPUT_WIDTH-1:0][INPUT_HEIGHT-1:0][CHANNEL_SIZE-1:0];
    for (i=0;i<CHANNEL_SIZE;i=i+1) begin
        for (j=0;j<INPUT_HEIGHT;j=j+1) begin
            for (k=0;k<INPUT_WIDTH;k=k+1) begin
                assign input_buffer  [i*INPUT_WIDTH*INPUT_HEIGHT*BIT_SIZE+
                                     j*INPUT_WIDTH*BIT_SIZE+
                                     (k+1)*BIT_SIZE - 1:
                                     i*INPUT_WIDTH*INPUT_HEIGHT*BIT_SIZE+
                                     j*INPUT_WIDTH*BIT_SIZE+
                                     k*BIT_SIZE]=input_array[k][j][i];
            end
        end
    end
    
    
    reg [BIT_SIZE-1:0] kernel_array_for_filters [KERNEL_WIDTH-1:0][KERNEL_HEIGHT-1:0][CHANNEL_SIZE-1:0][FILTER_SIZE-1:0];
    for (l=0;l<FILTER_SIZE;l=l+1) begin
        for (i=0;i<CHANNEL_SIZE;i=i+1) begin
            for (j=0;j<KERNEL_HEIGHT;j=j+1) begin
                for (k=0;k<KERNEL_WIDTH;k=k+1) begin
                    assign kernel_buffer_for_filters [l*CHANNEL_SIZE*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      i*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      j*KERNEL_WIDTH*BIT_SIZE+
                                                      (k+1)*BIT_SIZE - 1:
                                                      l*CHANNEL_SIZE*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      i*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      j*KERNEL_WIDTH*BIT_SIZE+
                                                      k*BIT_SIZE] = kernel_array_for_filters[k][j][i][l];
                end
            end
        end
    end
    integer a,b,c,d;
    reg [7:0] x;
    reg s;
    initial
    begin
        s=1;
        x=1;
        reset=1;
        clock=0;
        enable=0;
        #50;
        
        for (d=0;d<FILTER_SIZE;d=d+1) begin
            for (a=0;a<CHANNEL_SIZE;a=a+1) begin
                for (b=0;b<KERNEL_HEIGHT;b=b+1) begin
                    for (c=0;c<KERNEL_WIDTH;c=c+1) begin
                        if(s)
                            kernel_array_for_filters[c][b][a][d]=0;//1;//8'd1;//x;//8'd1;
                        else
                            kernel_array_for_filters[c][b][a][d]=1;//-1;
                        s=~s;
                        //x=x+1;
                    end
                end
            end
        end
        
        for (a=0;a<CHANNEL_SIZE;a=a+1) begin
            for (b=0;b<INPUT_HEIGHT;b=b+1) begin
                for (c=0;c<INPUT_WIDTH;c=c+1) begin
                    input_array[c][b][a]=1;//x;//8'd1;
                    //x=x+1;
                end
            end
        end
        
        #20;
        reset=0;
        enable=1;
        
    end
   
    always #10 clock=~clock;
endmodule
