module SobelFilter(
    input wire pixelClock, 
    input wire PRESETN,                               // 1. Bổ sung chân Reset (Tích cực mức thấp)
    
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
    output reg rowIsProcessO,                         // Đẩy cờ trạng thái hàng đi tiếp
    output reg outputIsValid,                         // Cờ báo điểm ảnh ngõ ra hợp lệ
    output reg [7:0] valueOfOutputPixel               // Điểm ảnh cường độ biên
);

    // 1. DATAPATH: Mạch tổ hợp tính toán có dấu (Combinational Logic)
    
    // Khai báo các mảng tổng thành phần (Unsigned 11-bit là dư dả cho tổng max 1020)
    wire [10:0] sum_x_pos, sum_x_neg;
    wire [10:0] sum_y_pos, sum_y_neg;
    
    // Khai báo biến có dấu (signed) 12-bit để chứa kết quả trừ an toàn tuyệt đối
    wire signed [11:0] Gx, Gy;
    wire [11:0] abs_Gx, abs_Gy;
    wire [12:0] G_sum; // Tổng |Gx| + |Gy| (cần 13 bit để tránh tràn hoàn toàn)

    // Tính các cụm tổng thành phần (chưa trừ)
    assign sum_x_pos = p13 + (p23 << 1) + p33;
    assign sum_x_neg = p11 + (p21 << 1) + p31;
    
    assign sum_y_pos = p11 + (p12 << 1) + p13;
    assign sum_y_neg = p31 + (p32 << 1) + p33;

    // ÉP KIỂU SANG CÓ DẤU (Signed): 
    // Nối thêm 1 bit '0' ở đầu để Verilog hiểu đây là số dương, sau đó mới trừ
    assign Gx = $signed({1'b0, sum_x_pos}) - $signed({1'b0, sum_x_neg});
    assign Gy = $signed({1'b0, sum_y_pos}) - $signed({1'b0, sum_y_neg});

    // Lấy trị tuyệt đối bằng mạch MUX (Bit 11 là MSB - bit dấu)
    assign abs_Gx = (Gx[11]) ? (~Gx + 1'b1) : Gx;
    assign abs_Gy = (Gy[11]) ? (~Gy + 1'b1) : Gy;

    // Tính tổng cường độ biên Manhattan: G = |Gx| + |Gy|
    assign G_sum = abs_Gx + abs_Gy;

    // 2. CONTROL UNIT & OUTPUT REGISTER: Mạch tuần tự chốt dữ liệu
    always @(posedge pixelClock or negedge PRESETN) begin
        if (!PRESETN) begin
            // Trạng thái khởi động: Dọn sạch thanh ghi
            newFrameIsPrepareO <= 1'b0;
            rowIsProcessO      <= 1'b0;
            outputIsValid      <= 1'b0;
            valueOfOutputPixel <= 8'b0;
        end 
        else begin
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
                    if (G_sum > 13'd255) begin
                        valueOfOutputPixel <= 8'd255;
                    end else begin
                        valueOfOutputPixel <= G_sum[7:0]; // Chỉ lấy 8 bit thấp
                    end
                    outputIsValid <= 1'b1;         // Báo cho khối sau lấy data
                end else begin
                    outputIsValid <= 1'b0;
                end
            end
        end
    end

endmodule
