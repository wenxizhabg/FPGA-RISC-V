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
    
    // Giao tiếp từ đuôi khối DilationFilter
    input wire newFrameIsPrepareNow,        
    input wire inputIsValid,
    input wire [7:0] valueOfInputPixel,
    
    // Thanh ghi ngõ ra để CPU RISC-V đọc
    output reg frameIsFinish,          // Vừa là tên sự kiện, vừa là cờ ngõ ra!
    output reg [31:0] finalDensityCount     
);

    reg [18:0] counter;
    reg newFrameIsPrepareLast;
    
    initial begin
        counter = 19'd0;
        newFrameIsPrepareLast = 1'b0;
        frameIsFinish = 1'b0;
        finalDensityCount = 32'd0;
    end

    always @(posedge pixelClock) begin
        // 1. Cập nhật quá khứ
        newFrameIsPrepareLast <= newFrameIsPrepareNow;
        
        // 2. Logic đếm điểm ảnh trắng
        if (inputIsValid == 1'b1 && valueOfInputPixel == 8'd255) begin
            counter <= counter + 1'b1;
        end
        
        // 3. Bắt sườn trực tiếp bên trong khối đồng bộ
        if (newFrameIsPrepareNow == 1'b1 && newFrameIsPrepareLast == 1'b0) begin
            finalDensityCount <= {13'b0, counter}; 
            counter <= 19'd0;
            frameIsFinish <= 1'b1; // Cờ nảy lên cùng nhịp đập với Data
        end else begin
            frameIsFinish <= 1'b0; 
        end
    end

endmodule
