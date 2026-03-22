///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: DilationFilter.v
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

module DilationFilter #(
    // Ngưỡng cường độ sáng để xác định viền (Có thể điều chỉnh khi test thực tế)
    // Tổng Sobel max là 255, bạn có thể để ngưỡng tầm 50-100 để lọc nhiễu nhẹ
    parameter THRESHOLD = 8'd50 
)(
    input wire pixelClock, 
    
    // --- Giao tiếp nhận ma trận 3x3 từ RowBuffering (chứa dữ liệu của Sobel) ---
    input wire newFrameIsPrepareI,                    // Cờ báo chuẩn bị ảnh mới                          
    input wire rowIsProcessI,                         
    input wire inputIsValid,                          
    input wire [7:0] p11, p12, p13, 
    input wire [7:0] p21, p22, p23, 
    input wire [7:0] p31, p32, p33,
    
    // --- Giao tiếp ngõ ra dạng ảnh (Image Output) để truyền lên PC ---
    output reg newFrameIsPrepareO,                    
    output reg rowIsProcessO,
    output reg outputIsValid,                         
    output reg [7:0] valueOfOutputPixel              // Điểm ảnh đầu ra (0 hoặc 255)

);

    // 1. DATAPATH: Mạch tổ hợp phân ngưỡng và Giãn nở
    
    // Bước A: Phân ngưỡng 9 điểm ảnh thành 9 bit nhị phân (1 = Sáng/Có viền, 0 = Tối/Nền)
    wire b11, b12, b13, b21, b22, b23, b31, b32, b33;
    
    assign b11 = (p11 > THRESHOLD);
    assign b12 = (p12 > THRESHOLD);
    assign b13 = (p13 > THRESHOLD);
    assign b21 = (p21 > THRESHOLD);
    assign b22 = (p22 > THRESHOLD);
    assign b23 = (p23 > THRESHOLD);
    assign b31 = (p31 > THRESHOLD);
    assign b32 = (p32 > THRESHOLD);
    assign b33 = (p33 > THRESHOLD);

    // Bước B: Dilation (Giãn nở) bằng cổng OR logic
    // Chỉ cần 1 trong 9 pixel xung quanh có viền, tâm cửa sổ sẽ biến thành viền
    wire dilated_bit;
    assign dilated_bit = b11 | b12 | b13 | 
                         b21 | b22 | b23 | 
                         b31 | b32 | b33;

    // 2. CONTROL UNIT & OUTPUT REGISTER
    always @(posedge pixelClock) begin
        newFrameIsPrepareO <= newFrameIsPrepareI;
        if (newFrameIsPrepareI == 1'b1) begin
            valueOfOutputPixel <= 8'd0;
            outputIsValid <= 1'b0;
            rowIsProcessO <= 1'b0;
        end else begin
            // Truyền cờ trạng thái hàng đi tiếp
            rowIsProcessO <= rowIsProcessI;
            
            if (inputIsValid == 1'b1) begin
                // Ép thành ảnh 8-bit để gửi qua UART/VGA cho máy tính dễ debug
                if (dilated_bit == 1'b1) begin
                    valueOfOutputPixel <= 8'd255; // Màu Trắng toát (Viền xe đã được làm dày)
                end else begin
                    valueOfOutputPixel <= 8'd0;   // Màu Đen (Mặt đường)
                end
                
                outputIsValid <= 1'b1;
            end else begin
                outputIsValid <= 1'b0;
            end
        end
    end

endmodule
