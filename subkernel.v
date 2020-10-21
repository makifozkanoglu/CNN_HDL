`timescale 1ns / 1ps

module subkernel #(parameter IN_BIT_SIZE = 8, 
                   parameter OUT_BIT_SIZE = 20, 
                   parameter KERNEL_WIDTH = 4, 
                   parameter KERNEL_HEIGHT = 3 ) (
    input reset, clk, start,

	input [KERNEL_WIDTH*KERNEL_HEIGHT*IN_BIT_SIZE-1:0] KERNEL, 	
	            			
	input [KERNEL_WIDTH*KERNEL_HEIGHT*IN_BIT_SIZE-1:0] X, 
	            
	output reg signed [OUT_BIT_SIZE-1:0] result,
	
	output reg done       
    );
    
    wire [KERNEL_WIDTH*KERNEL_HEIGHT-1:0] mult_done;
    
    wire signed [IN_BIT_SIZE-1:0] kernel [KERNEL_WIDTH*KERNEL_HEIGHT-1:0];
    wire signed [IN_BIT_SIZE-1:0] x [KERNEL_WIDTH*KERNEL_HEIGHT-1:0];
    wire signed [2*IN_BIT_SIZE-1:0] multiplier_result [KERNEL_WIDTH*KERNEL_HEIGHT-1:0];
    wire [KERNEL_WIDTH*KERNEL_HEIGHT-1:0] COMPARE = {KERNEL_WIDTH*KERNEL_HEIGHT{1'b1}};

    genvar i;
    integer j;
    
    
    for(i = 0; i < KERNEL_WIDTH*KERNEL_HEIGHT; i = i + 1) begin
        assign kernel[i] = KERNEL[(i+1)*IN_BIT_SIZE-1:i*IN_BIT_SIZE];
    end
    
    for(i = 0; i < KERNEL_WIDTH*KERNEL_HEIGHT; i = i + 1) begin
        assign x[i] = X[(i+1)*IN_BIT_SIZE-1:i*IN_BIT_SIZE];
    end

    generate
        for(i = 0; i < KERNEL_WIDTH*KERNEL_HEIGHT; i = i + 1) begin
            mult_param 
                   #(.BIT_SIZE(IN_BIT_SIZE))
                       mult(.A(x[i]),
                            .B(kernel[i]),
                            .result(multiplier_result[i]),
                            .clk(clk),
                            .reset(reset),
                            .enable(start),
                            .done(mult_done[i]));
        end
    endgenerate
	
	
    always@(posedge clk) begin
      
		if(reset) begin
			result = 0;
		    done = 0;		   
		end
		else begin
			if(start) begin 
                  if(mult_done==COMPARE & ~done) 
                  begin
                     for(j=0;j < KERNEL_WIDTH*KERNEL_HEIGHT;j=j+1) begin
                        result = result + multiplier_result[j];                        
                     end
                     done=1;
                  end
			end
	   end
	end
	
endmodule
