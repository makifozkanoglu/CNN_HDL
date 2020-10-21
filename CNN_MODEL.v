`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2020 04:08:47 PM
// Design Name: 
// Module Name: MNIST_CNN_MODEL
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
    

module MNIST_CNN_MODEL(
    clock,reset,conv_input_buffer,
    done,
    out0,out1, out2, out3, out4, out5, out6, out7, out8, out9
    );
    input clock,reset;
    output done;
   // output result;
    parameter FILTER_SIZE = 32;
    parameter FILTER_COUNTER_BIT_SIZE=5; //ceil of log2(FILTER_SIZE)
    parameter BIT_SIZE = 18;
    parameter INPUT_WIDTH=28;
    parameter INPUT_HEIGHT=28;
    parameter CHANNEL_SIZE=1;
    parameter SUBKERNEL_OUT_BIT = 45; //BIT_SIZE*2+ceil of log2(KERNEL_WIDTH*KERNEL_HEIGHT)
    parameter KERNEL_WIDTH = 21;
    parameter KERNEL_HEIGHT = 21; 
    parameter STRIDE = 7;
    parameter OUTPUT_WIDTH = (INPUT_WIDTH - KERNEL_WIDTH) / STRIDE + 1;
    parameter OUTPUT_HEIGHT = (INPUT_HEIGHT - KERNEL_HEIGHT) / STRIDE + 1;
    parameter CHANNEL_EXTENSION_BIT = 2; //ceil of log2(CHANNEL_SIZE)
    
    
        
    input [INPUT_WIDTH*INPUT_HEIGHT*CHANNEL_SIZE*BIT_SIZE-1:0] conv_input_buffer;
    wire [KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*FILTER_SIZE*BIT_SIZE-1:0] kernel_buffer;
    wire [FILTER_SIZE*BIT_SIZE-1:0] conv_bias_buffer;
    reg conv_enable;
    initial
        conv_enable=1;
    wire conv_done; assign done=conv_done;
    wire [FILTER_SIZE*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 :0] filter_result_buffer;
    
    filter#(
       .FILTER_SIZE(FILTER_SIZE),
       .FILTER_COUNTER_BIT_SIZE(FILTER_COUNTER_BIT_SIZE), //ceil of log2(FILTER_SIZE)
       .BIT_SIZE(BIT_SIZE),
       .INPUT_WIDTH(INPUT_WIDTH),
       .INPUT_HEIGHT(INPUT_HEIGHT),
       .CHANNEL_SIZE(CHANNEL_SIZE), 
       .SUBKERNEL_OUT_BIT(SUBKERNEL_OUT_BIT), //BIT_SIZE*2+ceil of log2(KERNEL_WIDTH*KERNEL_HEIGHT)
       .KERNEL_WIDTH(KERNEL_WIDTH), 
       .KERNEL_HEIGHT(KERNEL_HEIGHT), 
       .STRIDE (STRIDE),
       .OUTPUT_WIDTH (OUTPUT_WIDTH),
       .OUTPUT_HEIGHT (OUTPUT_HEIGHT ),
       .CHANNEL_EXTENSION_BIT (CHANNEL_EXTENSION_BIT) //ceil of log2(CHANNEL_SIZE)
       ) conv2d (
            .input_buffer(conv_input_buffer),
            .kernel_buffer_for_filters(kernel_buffer),
            .bias_buffer(conv_bias_buffer),
            .clock(clock),
            .reset(reset),
            .enable(conv_enable),
            .filter_result(filter_result_buffer),
            .done(conv_done)
        );
        
    genvar i,j,k,l;
    wire [(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 : 0] filter_result_array [FILTER_SIZE-1:0];
    for(i=0;i<FILTER_SIZE;i=i+1) begin
        assign filter_result_array[i] = 
                filter_result_buffer[(i+1)*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1:
                                         i*(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT];
    end
    
    wire [SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT - 1 : 0] pooling_result_array [FILTER_SIZE-1:0];
    reg max_pooling_enable;
    initial 
        max_pooling_enable = 1;

    generate
        for(i = 0; i < FILTER_SIZE; i = i + 1) begin
            max_pool_signed_prime pooling(
                       .ena_pool(max_pooling_enable),
                       .rst(reset),
                       .in_input_size(filter_result_array[i]),
                       .out_output_size(pooling_result_array[i])
                   );
        end
    endgenerate
    wire [(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*FILTER_SIZE - 1:0] result_buffer; 
    for (i = 0; i < FILTER_SIZE; i = i + 1) begin
        assign result_buffer [(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*(i+1) - 1:
                       (SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*i ] = pooling_result_array[i];
    end

//    reg signed [17:0] input_memory[0:783];
//    initial
//        $readmemb("/home/akif/Workspaces/GradProject/CNN_HDL/input_conv2.txt",input_memory);
    
    
    
//    //wire [BIT_SIZE-1:0] input_array [INPUT_WIDTH-1:0][INPUT_HEIGHT-1:0][CHANNEL_SIZE-1:0];
    
//    for (i=0;i<CHANNEL_SIZE;i=i+1) begin
//        for (j=0;j<INPUT_HEIGHT;j=j+1) begin
//            for (k=0;k<INPUT_WIDTH;k=k+1) begin
//                assign conv_input_buffer  [i*INPUT_WIDTH*INPUT_HEIGHT*BIT_SIZE+
//                                     j*INPUT_WIDTH*BIT_SIZE+
//                                     (k+1)*BIT_SIZE - 1:
//                                     i*INPUT_WIDTH*INPUT_HEIGHT*BIT_SIZE+
//                                     j*INPUT_WIDTH*BIT_SIZE+
//                                     k*BIT_SIZE] = input_memory[i*INPUT_WIDTH*INPUT_HEIGHT + j*INPUT_WIDTH + k];//input_array[k][j][i];
//            end
//        end
//    end
    
    reg signed [17:0] kernel_w_memory[0:14111];
    initial
        $readmemb("/home/akif/Workspaces/GradProject/CNN_HDL/kernel_w.txt",kernel_w_memory);
        
    //reg [BIT_SIZE-1:0] kernel_array_for_filters [KERNEL_WIDTH-1:0][KERNEL_HEIGHT-1:0][CHANNEL_SIZE-1:0][FILTER_SIZE-1:0];
    for (l=0;l<FILTER_SIZE;l=l+1) begin
        for (i=0;i<CHANNEL_SIZE;i=i+1) begin
            for (j=0;j<KERNEL_HEIGHT;j=j+1) begin
                for (k=0;k<KERNEL_WIDTH;k=k+1) begin
                    assign kernel_buffer [l*CHANNEL_SIZE*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      i*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      j*KERNEL_WIDTH*BIT_SIZE+
                                                      (k+1)*BIT_SIZE - 1:
                                                      l*CHANNEL_SIZE*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      i*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                      j*KERNEL_WIDTH*BIT_SIZE+
                                                      k*BIT_SIZE] = kernel_w_memory[l*CHANNEL_SIZE*KERNEL_WIDTH*KERNEL_HEIGHT + 
                                                                                    i*KERNEL_WIDTH*KERNEL_HEIGHT + 
                                                                                    j*KERNEL_WIDTH + k]; //kernel_array_for_filters[k][j][i][l];
                end
            end
        end
    end
    
    reg signed [17:0] kernel_b_memory[0:31];
    initial
        $readmemb("/home/akif/Workspaces/GradProject/CNN_HDL/kernel_b.txt",kernel_b_memory);
    for(i=0;i<FILTER_SIZE;i=i+1) begin
        assign conv_bias_buffer[(i+1)*BIT_SIZE - 1 : i*BIT_SIZE]= kernel_b_memory[i];
    end   
    
    /*
    module fullycon(
    
    input signed [46:0]  in1,  in2,  in3,  in4,  in5,  in6,  in7,  in8,  in9,  in10,
                    in11, in12, in13, in14, in15, in16, in17, in18, in19, in20,
                    in21, in22, in23, in24, in25, in26, in27, in28, in29, in30, in31, in32, 

    output signed [34:0] out1, out2, out3, out4, out5, out6, out7, out8, out9, out10
    );
    */
    output signed [34:0] out0,out1, out2, out3, out4, out5, out6, out7, out8, out9;
    fullycon dense
             (pooling_result_array[0],pooling_result_array[1],pooling_result_array[2],
              pooling_result_array[3],pooling_result_array[4],pooling_result_array[5],
              pooling_result_array[6],pooling_result_array[7],pooling_result_array[8],
              pooling_result_array[9],pooling_result_array[10],pooling_result_array[11],
              pooling_result_array[12],pooling_result_array[13],pooling_result_array[14],
              pooling_result_array[15],pooling_result_array[16],pooling_result_array[17],
              pooling_result_array[18],pooling_result_array[19],pooling_result_array[20],
              pooling_result_array[21],pooling_result_array[22],pooling_result_array[23],
              pooling_result_array[24],pooling_result_array[25],pooling_result_array[26],
              pooling_result_array[27],pooling_result_array[28],pooling_result_array[29],
              pooling_result_array[30],pooling_result_array[31],
              out0, out1, out2, out3, out4, out5, out6, out7, out8, out9);
              
    //assign result= |(out1|out2|out3|out4|out5|out6|out7|out8|out9|out0);
          
endmodule
