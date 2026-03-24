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
    // Kích thước tối đa cấp phát cho Block RAM (độ rộng ảnh VGA là 640)
    parameter MAX_WIDTH = 640,  
    parameter DATA_WIDTH = 8    
)(
    input wire pixelClock,
    input wire PRESETN,                               // 1. Bổ sung chân Reset
    
    input wire newFrameIsPrepareI,                    // Cờ báo chuẩn bị ảnh mới                          
    input wire rowIsProcessI,                         // Cờ báo đang xử lý trong 1 hàng
    input wire inputIsValid,                          // Cờ báo có điểm ảnh mới hợp lệ truyền tới
    input wire [DATA_WIDTH-1:0] valueOfInputPixel,    // Điểm ảnh đầu vào
    
    output reg newFrameIsPrepareO,
    output reg rowIsProcessO,                         // Đẩy cờ trạng thái hàng đi tiếp
    output reg outputIsValid,                         // Cờ báo ma trận 3x3 đã sẵn sàng
    
    output reg [DATA_WIDTH-1:0] p11, p12, p13,        // Hàng trên cùng (Hàng n-2)
    output reg [DATA_WIDTH-1:0] p21, p22, p23,        // Hàng giữa (Hàng n-1)
    output reg [DATA_WIDTH-1:0] p31, p32, p33         // Hàng dưới cùng (Hàng n hiện tại)
);

    // Khai báo 2 bộ đệm hàng (Block RAM)
    reg [DATA_WIDTH-1:0] theSecondPreviousRow [0:MAX_WIDTH-1]; 
    reg [DATA_WIDTH-1:0] theFirstPreviousRow [0:MAX_WIDTH-1]; 
    
    // Con trỏ cột (Địa chỉ RAM) và Biến đếm hàng
    reg [10:0] col_ptr;
    reg [1:0]  row_count; // Chỉ cần đếm đến 2 là đủ biết đã sẵn sàng

    // QUY TRÌNH 1: Dịch dữ liệu và Quản lý con trỏ (Data Path)
    always @(posedge pixelClock or negedge PRESETN) begin
        if (!PRESETN) begin
            col_ptr <= 0;
            {p11, p12, p13} <= 24'b0;
            {p21, p22, p23} <= 24'b0;
            {p31, p32, p33} <= 24'b0;
        end
        else if (newFrameIsPrepareI == 1'b1) begin
            col_ptr <= 0;
            {p11, p12, p13} <= 24'b0;
            {p21, p22, p23} <= 24'b0;
            {p31, p32, p33} <= 24'b0;
        end 
        else if (rowIsProcessI == 1'b0) begin
            // Hạ cờ Hàng rớt xuống 0 -> Tự động đưa địa chỉ RAM về 0
            col_ptr <= 0;
        end 
        else if (inputIsValid == 1'b1) begin
            // Bước A: Hút dữ liệu từ RAM Hàng và Ngõ vào
            p13 <= theSecondPreviousRow[col_ptr];
            p23 <= theFirstPreviousRow[col_ptr];
            p33 <= valueOfInputPixel;

            // Bước B: Cập nhật RAM Hàng (Đùn hàng lên)
            theSecondPreviousRow[col_ptr] <= theFirstPreviousRow[col_ptr];
            theFirstPreviousRow[col_ptr]  <= valueOfInputPixel;

            // Bước C: Dịch cột tạo ma trận cửa sổ trượt 3x3
            p12 <= p13; p11 <= p12;
            p22 <= p23; p21 <= p22;
            p32 <= p33; p31 <= p32;

            // Bước D: Tăng địa chỉ RAM
            col_ptr <= col_ptr + 1;
        end
    end

    // QUY TRÌNH 2: Quản lý các cờ trạng thái (Control Path)
    always @(posedge pixelClock or negedge PRESETN) begin
        if (!PRESETN) begin
            newFrameIsPrepareO <= 1'b0;
            rowIsProcessO      <= 1'b0;
            outputIsValid      <= 1'b0;
            row_count          <= 2'b0;
        end
        else begin
            newFrameIsPrepareO <= newFrameIsPrepareI;

            if (newFrameIsPrepareI == 1'b1) begin
                outputIsValid <= 1'b0;
                rowIsProcessO <= 1'b0;
                row_count     <= 2'b0; // Reset bộ đếm hàng khi có frame mới
            end else begin
                // Luôn truyền trạng thái Hàng đi tiếp cho các khối tính toán
                rowIsProcessO <= rowIsProcessI;
                
                // Đếm số hàng đã nạp vào Buffer (chỉ tăng khi kết thúc 1 hàng)
                // Phát hiện sườn xuống của rowIsProcessI (hoặc dùng col_ptr == MAX_WIDTH)
                // Ở đây ta dùng cách an toàn: nếu đang nạp pixel cuối cùng của hàng
                if (rowIsProcessI == 1'b1 && inputIsValid == 1'b1 && col_ptr == (MAX_WIDTH - 1)) begin
                    if (row_count < 2'd2) begin
                        row_count <= row_count + 1'b1;
                    end
                end

                if (rowIsProcessI == 1'b1 && inputIsValid == 1'b1) begin
                    // ĐIỀU KIỆN KÉP: Đủ 3 cột (col_ptr >= 2) VÀ Đủ 3 hàng (row_count >= 2)
                    if (col_ptr >= 2 && row_count == 2'd2) begin
                        outputIsValid <= 1'b1; 
                    end else begin
                        outputIsValid <= 1'b0; 
                    end
                end else begin
                    outputIsValid <= 1'b0;
                end
            end
        end
    end

endmodule

