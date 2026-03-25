///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: DensityCounter.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::PolarFireSoC> <Die::MPFS095T> <Package::FCSG325>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

//`timescale <time_units> / <precision>

module DensityCounter (
    input wire pixelClock,
    input wire PRESETN,         
    
    // Giao ti?p t? duôi kh?i DilationFilter
    input wire newFrameIsPrepareNow,        
    input wire inputIsValid,
    input wire [7:0] valueOfInputPixel,
    
    // C?u hình t? CPU (N?i t? Wrapper xu?ng)
    // N?u xe ít, CPU g?i s? l?n (VD: 500). N?u xe dông, g?i s? nh? (VD: 1)
    input wire [15:0] sampleRate, 

    // Thanh ghi ngõ ra t?i FIFO_DENSITY
    output reg frameIsFinish,              // Ch? b?t khi d? s? khung hình c?n l?y m?u
    output reg [31:0] finalDensityCount      
);

    reg [18:0] pixelCounter;
    reg [15:0] finishFrameCounter; // B? tích luy s? khung hình
    reg newFrameIsPrepareLast;

    always @(posedge pixelClock or negedge PRESETN) begin
        if (!PRESETN) begin
            newFrameIsPrepareLast <= 1'b0;
            pixelCounter               <= 19'd0;
            finishFrameCounter              <= 16'd0;
            finalDensityCount     <= 32'd0;
            frameIsFinish         <= 1'b0;
        end 
        else begin
            newFrameIsPrepareLast <= newFrameIsPrepareNow;
            
            // Phát hi?n k?t thúc 1 khung hình (C?nh lên c?a PrepareNow)
            if (newFrameIsPrepareNow == 1'b1 && newFrameIsPrepareLast == 1'b0) begin
                
                if (finishFrameCounter >= sampleRate) begin
                    // Ðã d? chu k? l?y m?u -> Xu?t d? li?u và báo ng?t
                    finalDensityCount <= {13'd0, pixelCounter}; 
                    frameIsFinish     <= 1'b1;  
                    finishFrameCounter          <= 16'd0; // Reset b? d?m khung hình
                end 
                else begin
                    finishFrameCounter          <= finishFrameCounter + 1'b1;
                    frameIsFinish     <= 1'b0;
                end
                
                pixelCounter <= 19'd0; // Luôn reset b? d?m pixel sau m?i khung hình
            end 
            else begin
                frameIsFinish <= 1'b0; 
                
                // Ð?m di?m ?nh tr?ng trong khung hình hi?n t?i
                if (inputIsValid == 1'b1 && valueOfInputPixel == 8'd255) begin
                    pixelCounter <= pixelCounter + 1'b1;
                end
            end
        end
    end

endmodule
