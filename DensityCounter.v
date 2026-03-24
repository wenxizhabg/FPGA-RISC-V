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
    input wire PRESETN,                    // 1. Bổ sung chân Reset (Tích cực mức thấp)
    
    // Giao tiếp từ đuôi khối DilationFilter
    input wire newFrameIsPrepareNow,        
    input wire inputIsValid,
    input wire [7:0] valueOfInputPixel,
    
    // Thanh ghi ngõ ra để CPU RISC-V đọc
    output reg frameIsFinish,              // Cờ ngắt (Interrupt) báo xong frame
    output reg [31:0] finalDensityCount      
);

    reg [18:0] counter;
    reg newFrameIsPrepareLast;

    always @(posedge pixelClock or negedge PRESETN) begin
        if (!PRESETN) begin
            // Dọn sạch toàn bộ thanh ghi khi khởi động
            newFrameIsPrepareLast <= 1'b0;
            counter               <= 19'd0;
            finalDensityCount     <= 32'd0;
            frameIsFinish         <= 1'b0;
        end 
        else begin
            // 1. Cập nhật quá khứ để bắt sườn
            newFrameIsPrepareLast <= newFrameIsPrepareNow;
            
            // 2. Bắt sườn lên trực tiếp bên trong khối đồng bộ (Kết thúc Frame cũ)
            if (newFrameIsPrepareNow == 1'b1 && newFrameIsPrepareLast == 1'b0) begin
                // Đệm thêm 13 bit 0 vào biến đếm 19-bit để ép chuẩn thành 32-bit cho bus APB
                finalDensityCount <= {13'd0, counter}; 
                counter           <= 19'd0; // Reset bộ đếm cho frame mới
                frameIsFinish     <= 1'b1;  // Bật cờ ngắt lên 1 nhịp
            end 
            else begin
                frameIsFinish <= 1'b0;  // Hạ cờ ngắt xuống ngay lập tức
                
                // 3. Logic đếm điểm ảnh trắng (Chỉ đếm khi KHÔNG phải lúc reset)
                if (inputIsValid == 1'b1 && valueOfInputPixel == 8'd255) begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end

endmodule
