`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/28/2020 03:21:41 PM
// Design Name: 
// Module Name: kernel
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



module kernel#(parameter BIT_SIZE = 9,
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
    input [KERNEL_WIDTH*KERNEL_HEIGHT*CHANNEL_SIZE*BIT_SIZE-1:0] kernel_buffer,
    input signed [BIT_SIZE-1:0] bias,
    input clock,reset,enable,
    output  [(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*OUTPUT_WIDTH*OUTPUT_HEIGHT - 1 :0] conv_result,
    output reg done
    );
    
    reg signed [SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT - 1:0] result; //?????????????????????? +2 ==> ceil of log2(CHANNEL_SIZE)
    reg result_flag;
    
    genvar i,j,k;
    reg signed [SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT - 1:0] conv_result_array [OUTPUT_WIDTH-1:0][OUTPUT_HEIGHT-1:0]; //SUBKERNEL_OUT_BIT + 2 ==> ceil of log2(CHANNEL_SIZE)
    for (i=0;i<OUTPUT_HEIGHT;i=i+1) begin
        for (j=0;j<OUTPUT_WIDTH;j=j+1) begin
            assign conv_result[(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*(i*OUTPUT_WIDTH+j+1) - 1:(SUBKERNEL_OUT_BIT + CHANNEL_EXTENSION_BIT)*(i*OUTPUT_WIDTH+j)]=conv_result_array[j][i];
        end
    end
    
    
    wire signed [BIT_SIZE-1:0] input_array [INPUT_WIDTH-1:0][INPUT_HEIGHT-1:0][CHANNEL_SIZE-1:0];
    for (i=0;i<CHANNEL_SIZE;i=i+1) begin
        for (j=0;j<INPUT_HEIGHT;j=j+1) begin
            for (k=0;k<INPUT_WIDTH;k=k+1) begin
                assign input_array[k][j][i]=input_buffer[i*INPUT_WIDTH*INPUT_HEIGHT*BIT_SIZE+
                                                         j*INPUT_WIDTH*BIT_SIZE+
                                                         (k+1)*BIT_SIZE - 1:
                                                         i*INPUT_WIDTH*INPUT_HEIGHT*BIT_SIZE+
                                                         j*INPUT_WIDTH*BIT_SIZE+
                                                         k*BIT_SIZE];
            end
        end
    end
    
    
    wire signed [BIT_SIZE-1:0] kernel_array [KERNEL_WIDTH-1:0][KERNEL_HEIGHT-1:0][CHANNEL_SIZE-1:0];
    for (i=0;i<CHANNEL_SIZE;i=i+1) begin
        for (j=0;j<KERNEL_HEIGHT;j=j+1) begin
            for (k=0;k<KERNEL_WIDTH;k=k+1) begin
                assign kernel_array[k][j][i]=kernel_buffer[i*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                          j*KERNEL_WIDTH*BIT_SIZE+
                                                          (k+1)*BIT_SIZE - 1:
                                                          i*KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE+
                                                          j*KERNEL_WIDTH*BIT_SIZE+
                                                          k*BIT_SIZE];
            end
        end
    end
    
    reg subkernel_start, subkernel_reset;
    wire [KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE-1:0] subkernel_w[CHANNEL_SIZE-1:0];
    wire [KERNEL_WIDTH*KERNEL_HEIGHT*BIT_SIZE-1:0] subkernel_x[CHANNEL_SIZE-1:0];
    wire signed [SUBKERNEL_OUT_BIT-1:0] subkernel_out [CHANNEL_SIZE-1:0];
    wire [CHANNEL_SIZE-1:0] subkernel_done;
    
    for (i=0;i<CHANNEL_SIZE;i=i+1) begin
        subkernel #(
                  .IN_BIT_SIZE(BIT_SIZE), 
                  .OUT_BIT_SIZE(SUBKERNEL_OUT_BIT), 
                  .KERNEL_WIDTH(KERNEL_WIDTH), 
                  .KERNEL_HEIGHT(KERNEL_HEIGHT) 
                  ) subkernel (
                 .reset(subkernel_reset), 
                 .clk(clock), 
                 .start(subkernel_start),
                 .KERNEL(subkernel_w[i]), 	
                 .X(subkernel_x[i]), 
                 .result(subkernel_out[i]),
                 .done(subkernel_done[i])
                 );
    end
    
    //reg [BIT_SIZE-1:0] subkernel_w_array [KERNEL_WIDTH-1:0][KERNEL_HEIGHT-1:0][CHANNEL_SIZE-1:0];
    reg [BIT_SIZE-1:0] subkernel_x_array [KERNEL_WIDTH-1:0][KERNEL_HEIGHT-1:0][CHANNEL_SIZE-1:0];
    
    genvar l,m,n;
    for(l=0;l<CHANNEL_SIZE;l=l+1) begin
        for(m=0;m<KERNEL_HEIGHT;m=m+1) begin
            for(n=0;n<KERNEL_WIDTH;n=n+1) begin
                assign subkernel_x[l][m*KERNEL_WIDTH*BIT_SIZE + (n+1)*BIT_SIZE - 1:m*KERNEL_WIDTH*BIT_SIZE + n*BIT_SIZE] = subkernel_x_array[n][m][l];
                assign subkernel_w[l][m*KERNEL_WIDTH*BIT_SIZE + (n+1)*BIT_SIZE - 1:m*KERNEL_WIDTH*BIT_SIZE + n*BIT_SIZE] = kernel_array[n][m][l];
            end
        end
    end
    
    reg [5:0] w_counter,h_counter;
    reg stride_enable;
    always@(posedge clock) begin
        if (reset) begin
            w_counter=0;
            h_counter=0;
            done=0;
        end
        else if (stride_enable & ~done) begin
            w_counter=w_counter+STRIDE;
            if (w_counter>INPUT_WIDTH - KERNEL_WIDTH) begin//büyük eşittir>= olabilir
                h_counter=h_counter+STRIDE;
                w_counter=0;
            end
            if(h_counter>INPUT_HEIGHT-KERNEL_HEIGHT) begin//büyük eşittir>= olabilir
                h_counter=0;
                done=1;
            end
        end
    end
    
    integer a,b,c;
    
    reg [2:0] state,NextState;
    always@(posedge clock)
    begin
        if (reset==1) begin
            state <= 0;
            NextState<=0;
        end
        else
            state <= NextState;
    end
    
    
    
    always@(posedge clock) begin
        if (reset) begin
            subkernel_start=0;
            subkernel_reset=1;
            result=0;
            stride_enable=0;
            result_flag=0;
            //state=0;
            for (a=0;a<OUTPUT_HEIGHT;a=a+1) begin
                for (b=0;b<OUTPUT_WIDTH;b=b+1) begin
                    conv_result_array[b][a]=0;
                end
            end
        end
        else if (enable & ~done) begin
        //kernel_array [KERNEL_WIDTH-1:0][KERNEL_HEIGHT-1:0][CHANNEL_SIZE-1:0];
            case(state) 
            3'd0:
                begin
                    subkernel_start=1;
                    subkernel_reset=0;
                    stride_enable=0;
                    
                    for(a=0;a<CHANNEL_SIZE;a=a+1) begin
                        for(b=0;b<KERNEL_HEIGHT;b=b+1) begin
                            for(c=0;c<KERNEL_WIDTH;c=c+1) begin
                                subkernel_x_array[c][b][a]=input_array[w_counter+c][h_counter+b][a];
                            end
                        end
                    end
                    
                    NextState=1;
                end
            3'd1:
                begin
                    //subkernel_x_array[0][0][0]=input_array[0][0][0];
                    //subkernel_start=1;
                    if (subkernel_done=={CHANNEL_SIZE{1'B1}}) begin
                        for(a=0;a<CHANNEL_SIZE;a=a+1) begin
                            result = result + subkernel_out[a]; 
                        end
                        result = result + bias;
                        //NextState=2;
                        result_flag=1;
                        conv_result_array[w_counter/STRIDE][h_counter/STRIDE]=result;
                        //conv_result[(SUBKERNEL_OUT_BIT + 1)*conv_counter - 1:(SUBKERNEL_OUT_BIT + 1)*(conv_counter-1)]=result;
                    end
                    NextState=2;
                end
            3'd2:
                begin
                    //done=1;
                    subkernel_start=0;
                    subkernel_reset=1;
                    result=0;
                    result_flag=0;
                    //stride_enable=1;
                    stride_enable=~stride_enable;
                    NextState=0;//3;
                end
            endcase
        end
    end
endmodule
