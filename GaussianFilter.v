///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: GaussianFilter.v
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
module GaussianFilter(
    input wire pixelClock, 
    
    // --- Giao tiếp nhận ma trận 3x3 từ RowBuffering ---
    input wire newFrameIsPrepareI,                    // Cờ báo chuẩn bị ảnh mới                          
    input wire rowIsProcessI,                         // Cờ báo đang xử lý hàng (từ module trước)
    input wire inputIsValid,                          // Cờ báo ma trận 3x3 ngõ vào là hợp lệ
    // 9 điểm ảnh của cửa sổ trượt 3x3
    input wire [7:0] p11, p12, p13, 
    input wire [7:0] p21, p22, p23, 
    input wire [7:0] p31, p32, p33,
    
    // --- Giao tiếp ngõ ra đã làm mịn ---
    output reg newFrameIsPrepareO,
    output reg rowIsProcessO,                        // Đẩy cờ trạng thái hàng đi tiếp
    output reg outputIsValid,                         // Cờ báo điểm ảnh ngõ ra hợp lệ
    output reg [7:0] valueOfOutputPixel              // Điểm ảnh đã lọc Gauss
);

    // 1. DATAPATH: Mạch tổ hợp tính toán nặng (Combinational Logic)
    // Dùng wire 12-bit để chứa tổng, tránh bị tràn số khi cộng 9 con số 8-bit
    // Tối đa: 16 * 255 = 4080 (Vừa đủ trong 12-bit: max 4095)
    wire [11:0] sum; 

    // Áp dụng hệ số ma trận Gauss tối ưu hóa cho FPGA:
    // [1 2 1]
    // [2 4 2] / 16
    // [1 2 1]
    // Dùng phép dịch bit (<<) thay cho bộ nhân để tiết kiệm tài nguyên
    assign sum = p11 + (p12 << 1) + p13 + 
                 (p21 << 1) + (p22 << 2) + (p23 << 1) + 
                 p31 + (p32 << 1) + p33;

    // 2. CONTROL UNIT & OUTPUT REGISTER: Mạch tuần tự chốt dữ liệu an toàn
    always @(posedge pixelClock) begin
        newFrameIsPrepareO <= newFrameIsPrepareI;
        
        if (newFrameIsPrepareI == 1'b1) begin
            valueOfOutputPixel <= 8'b0;
            outputIsValid <= 1'b0;
            rowIsProcessO <= 1'b0;
        end else begin
            // Luôn truyền trạng thái Hàng đi tiếp sang khối sau (Sobel)
            rowIsProcessO <= rowIsProcessI;
            
            // Chỉ chốt kết quả tính toán khi ma trận ngõ vào là hợp lệ
            if (inputIsValid == 1'b1) begin
                // Chia 16 bằng phép dịch phải 4 bit (sum >> 4)
                // Phép gán này chốt dữ liệu vào thanh ghi, tăng độ ổn định timing
                valueOfOutputPixel <= sum >> 4; 
                outputIsValid <= 1'b1;         // Báo cho khối sau lấy data
            end else begin
                // Nếu ngõ vào là rác, hạ cờ Valid ngõ ra
                outputIsValid <= 1'b0;
            end
        end
    end

endmodule
