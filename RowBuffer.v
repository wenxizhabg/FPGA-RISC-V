///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: RowBuffer.v
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

module RowBuffer #(
    // Kích thước tối đa cấp phát cho Block RAM (Ảnh VGA là 640 nên 1024 là quá dư dả)
    parameter MAX_WIDTH = 1024,  
    parameter DATA_WIDTH = 8    
)(
    input wire pixelClock,
    input wire reset,                                 // Reset đồng bộ (Tích cực mức cao)
    
    input wire rowIsProcessI,                         // Cờ báo đang xử lý trong 1 hàng
    input wire inputIsValid,                          // Cờ báo có điểm ảnh mới hợp lệ truyền tới
    input wire [DATA_WIDTH-1:0] valueOfInputPixel,    // Điểm ảnh đầu vào
    
    output reg [DATA_WIDTH-1:0] p11, p12, p13,        // Hàng trên cùng (Hàng n-2)
    output reg [DATA_WIDTH-1:0] p21, p22, p23,        // Hàng giữa (Hàng n-1)
    output reg [DATA_WIDTH-1:0] p31, p32, p33,        // Hàng dưới cùng (Hàng n hiện tại)
    
    output reg outputIsValid,                         // Cờ báo ma trận 3x3 đã sẵn sàng
    output reg rowIsProcessO                          // Đẩy cờ trạng thái hàng đi tiếp
);

    // 1. Khai báo 2 bộ đệm hàng (Trình biên dịch sẽ tự động map vào Block RAM)
    reg [DATA_WIDTH-1:0] theSecondPreviousRow [0:MAX_WIDTH-1]; 
    reg [DATA_WIDTH-1:0] theFirstPreviousRow [0:MAX_WIDTH-1]; 
    
    // Con trỏ cột (Đóng vai trò là Địa chỉ RAM)
    reg [10:0] col_ptr;

    // QUY TRÌNH 1: Dịch dữ liệu và Quản lý con trỏ (Data Path)
    always @(posedge pixelClock) begin
        if (reset == 1'b1) begin
            col_ptr <= 0;
            {p11, p12, p13} <= 24'b0;
            {p21, p22, p23} <= 24'b0;
            {p31, p32, p33} <= 24'b0;
        end 
        else if (rowIsProcessI == 1'b0) begin
            // Hễ cờ Hàng rớt xuống 0 -> Tự động đưa địa chỉ RAM về 0
            // Giúp hệ thống tự thích ứng với mọi chiều rộng ảnh mà không bị xô lệch
            col_ptr <= 0;
        end 
        else if (inputIsValid == 1'b1) begin
            // Bước A: Hút dữ liệu từ RAM Hàng và Ngõ vào
            p13 <= theSecondPreviousRow[col_ptr];
            p23 <= theFirstPreviousRow[col_ptr];
            p33 <= valueOfInputPixel;

            // Bước B: Cập nhật RAM Hàng (Đùn hàng lên)
            theSecondPreviousRow[col_ptr] <= theFirstPreviousRow[col_ptr];
            theFirstPreviousRow[col_ptr] <= valueOfInputPixel;

            // Bước C: Dịch cột tạo ma trận cửa sổ trượt 3x3
            p12 <= p13; p11 <= p12;
            p22 <= p23; p21 <= p22;
            p32 <= p33; p31 <= p32;

            // Bước D: Tăng địa chỉ RAM
            col_ptr <= col_ptr + 1;
        end
    end

    // QUY TRÌNH 2: Quản lý các cờ trạng thái (Control Path)
    always @(posedge pixelClock) begin
        if (reset == 1'b1) begin
            outputIsValid <= 1'b0;
            rowIsProcessO <= 1'b0;
        end else begin
            // Luôn truyền trạng thái Hàng đi tiếp cho các khối tính toán (Gauss/Sobel)
            rowIsProcessO <= rowIsProcessI;
            
            if (rowIsProcessI == 1'b1 && inputIsValid == 1'b1) begin
                // Bỏ qua 2 pixel đầu tiên của mỗi hàng (rác do cuộn vòng từ mép phải sang mép trái)
                // Chỉ vẩy cờ Hợp lệ từ pixel thứ 3 trở đi
                if (col_ptr >= 2) begin
                    outputIsValid <= 1'b1; 
                end else begin
                    outputIsValid <= 1'b0; 
                end
            end else begin
                outputIsValid <= 1'b0;
            end
        end
    end

endmodule
