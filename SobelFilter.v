///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: SobelFilter.v
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

module SobelFilter(
    input wire pixelClock, 
    
    // --- Giao tiếp nhận ma trận 3x3 từ module Gauss ---
    input wire newFrameIsPrepareI,                    // Cờ báo chuẩn bị ảnh mới                          
    input wire rowIsProcessI,                         // Cờ báo đang xử lý hàng (từ module trước)
    input wire inputIsValid,                          // Cờ báo ma trận 3x3 ngõ vào là hợp lệ
    // 9 điểm ảnh đã được làm mịn của cửa sổ trượt 3x3
    input wire [7:0] p11, p12, p13, 
    input wire [7:0] p21, p22, p23, 
    input wire [7:0] p31, p32, p33,
    
    // --- Giao tiếp ngõ ra cường độ biên ---
    output reg newFrameIsPrepareO,
    output reg rowIsProcessO,                          // Đẩy cờ trạng thái hàng đi tiếp
    output reg outputIsValid,                         // Cờ báo điểm ảnh ngõ ra hợp lệ
    output reg [7:0] valueOfOutputPixel              // Điểm ảnh cường độ biên
    
);

    // 1. DATAPATH: Mạch tổ hợp tính toán có dấu (Combinational Logic)
    
    // Khai báo biến có dấu (signed) 11-bit để chứa các số âm
    // Tại sao 11-bit? Tổng max là (1+2+1)*255 = 1020 (Cần 10 bit data + 1 bit dấu)
    wire signed [10:0] Gx, Gy;
    wire [10:0] abs_Gx, abs_Gy;
    wire [11:0] G_sum; // Tổng độ lớn biên (cần 12 bit để tránh tràn)

    // Áp dụng ma trận hạt nhân Sobel X và Y tối ưu hóa cho FPGA:
    // Gx = [-1 0 1; -2 0 2; -1 0 1]
    // Gy = [ 1 2 1;  0 0 0; -1 -2 -1]
    
    // Dùng phép dịch bit (<< 1) để nhân với 2
    
    // Tính Gx (Đạo hàm theo hướng X - Cột phải trừ Cột trái)
    // Cột giữa (0, 0, 0) được bỏ qua
    assign Gx = (p13 + (p23 << 1) + p33) - (p11 + (p21 << 1) + p31);

    // Tính Gy (Đạo hàm theo hướng Y - Hàng trên trừ Hàng dưới)
    // Hàng giữa (0, 0, 0) được bỏ qua
    assign Gy = (p11 + (p12 << 1) + p13) - (p31 + (p32 << 1) + p33);

    // Lấy trị tuyệt đối bằng mạch MUX logic tối ưu:
    // Nếu bit dấu (bit cao nhất MSB) là 1 (số âm) -> Đảo bit cộng 1 (Bù 2) để thành số dương
    assign abs_Gx = (Gx[10]) ? (~Gx + 1'b1) : Gx;
    assign abs_Gy = (Gy[10]) ? (~Gy + 1'b1) : Gy;

    // Tính tổng cường độ biên Manhattan: G = |Gx| + |Gy|
    assign G_sum = abs_Gx + abs_Gy;

    // 2. CONTROL UNIT & OUTPUT REGISTER: Mạch tuần tự chốt dữ liệu
    always @(posedge pixelClock) begin
        newFrameIsPrepareO <= newFrameIsPrepareI;
        
        if (newFrameIsPrepareI == 1'b1) begin
            valueOfOutputPixel <= 8'b0;
            outputIsValid <= 1'b0;
            rowIsProcessO <= 1'b0;
        end else begin
            // Luôn truyền trạng thái Hàng đi tiếp sang khối sau
            rowIsProcessO <= rowIsProcessI;
            
            // Chỉ chốt kết quả tính toán khi ma trận ngõ vào là hợp lệ
            if (inputIsValid == 1'b1) begin
                // Tránh tràn số: Nếu tổng > 255 (Màu trắng max), thì kẹp nó về 255
                if (G_sum > 12'd255) begin
                    valueOfOutputPixel <= 8'd255;
                end else begin
                    valueOfOutputPixel <= G_sum[7:0]; // Chỉ lấy 8 bit thấp
                end
                outputIsValid <= 1'b1;         // Báo cho khối sau lấy data
            end else begin
                // Nếu ngõ vào là rác, hạ cờ Valid ngõ ra
                outputIsValid <= 1'b0;
            end
        end
    end

endmodule
