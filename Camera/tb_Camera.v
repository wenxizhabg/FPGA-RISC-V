///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: tb_Camera.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
// Testbench cho module Camera OV7670 - Kiểm tra logic tách byte Y
// (Đã tinh chỉnh: Camera giả lập xuất dữ liệu tại sườn xuống của PCLK)
//
// Targeted device: <Family::PolarFireSoC> <Die::MPFS095T> <Package::FCSG325>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 

`timescale 1ns/100ps

module tb_Camera;

parameter SYSCLK_PERIOD = 40; // 25MHZ (Chu kỳ 40ns)

reg SYSCLK;
reg NSYSRESET;

// --- Thêm các biến giả lập tín hiệu từ Camera ---
reg VSYNC;
reg HREF;
reg [7:0] DATA;

// --- Thêm các dây (wire) để quan sát ngõ ra của module ---
wire newFrameIsPrepare;
wire rowIsProcess;
wire outputIsValid;
wire [7:0] valueOfOutputPixel;

initial
begin
    SYSCLK = 1'b0;
    NSYSRESET = 1'b0;
    
    // Khởi tạo trạng thái ban đầu cho Camera
    VSYNC = 1'b0;
    HREF = 1'b0;
    DATA = 8'h00;
end

//////////////////////////////////////////////////////////////////////
// Reset Pulse
//////////////////////////////////////////////////////////////////////
initial
begin
    #(SYSCLK_PERIOD * 10 )
        NSYSRESET = 1'b1; // Sau 10 chu kỳ (400ns), nhả Reset (kéo lên 1)
end


//////////////////////////////////////////////////////////////////////
// Clock Driver
//////////////////////////////////////////////////////////////////////
always @(SYSCLK)
    #(SYSCLK_PERIOD / 2.0) SYSCLK <= !SYSCLK;


//////////////////////////////////////////////////////////////////////
// Instantiate Unit Under Test:  Camera
//////////////////////////////////////////////////////////////////////
Camera Camera_0 (
    // Inputs
    .PCLK(SYSCLK),             // Dùng SYSCLK của tb làm nhịp PCLK cho camera
    .PRESETN(NSYSRESET),       // Dùng NSYSRESET làm tín hiệu Reset
    .VSYNC(VSYNC),
    .HREF(HREF),
    .DATA(DATA),

    // Outputs
    .newFrameIsPrepare(newFrameIsPrepare),
    .rowIsProcess(rowIsProcess),
    .outputIsValid(outputIsValid),
    .valueOfOutputPixel(valueOfOutputPixel)
);

//////////////////////////////////////////////////////////////////////
// Kịch bản mô phỏng dữ liệu (Stimulus) - CHUẨN SƯỜN XUỐNG
//////////////////////////////////////////////////////////////////////
initial
begin
    // 1. Đợi hệ thống nhả Reset hoàn toàn
    #(SYSCLK_PERIOD * 15);

    // 2. Giả lập Camera nháy VSYNC (Bắt đầu khung hình mới)
    @(negedge SYSCLK); // Chờ đến sườn xuống mới bắt đầu đổi mức
    VSYNC = 1'b1;
    #(SYSCLK_PERIOD * 3);
    
    @(negedge SYSCLK);
    VSYNC = 1'b0; 

    // Nghỉ một chút trước khi truyền dòng ngang đầu tiên
    #(SYSCLK_PERIOD * 5); 

    // ========================================================
    // BẮT ĐẦU DÒNG 1
    // ========================================================
    @(negedge SYSCLK);
    HREF = 1'b1;
    DATA = 8'hAA; // Nhịp 1: Truyền Byte U1 ở sườn xuống -> Module sẽ đọc ở sườn lên tiếp theo

    @(negedge SYSCLK);
    DATA = 8'h11; // Nhịp 2: Truyền Byte Y1 -> KỲ VỌNG: Mạch chốt được 11

    @(negedge SYSCLK);
    DATA = 8'hBB; // Nhịp 3: Truyền Byte V1

    @(negedge SYSCLK);
    DATA = 8'h22; // Nhịp 4: Truyền Byte Y2 -> KỲ VỌNG: Mạch chốt được 22

    // KẾT THÚC DÒNG 1
    @(negedge SYSCLK);
    HREF = 1'b0;
    DATA = 8'h00; // Trả data về 0

    // Nghỉ giữa các dòng (Horizontal Blanking)
    #(SYSCLK_PERIOD * 5); 

    // ========================================================
    // BẮT ĐẦU DÒNG 2
    // ========================================================
    @(negedge SYSCLK);
    HREF = 1'b1;
    DATA = 8'hCC; // Nhịp 1: Truyền Byte U3

    @(negedge SYSCLK);
    DATA = 8'h33; // Nhịp 2: Truyền Byte Y3 -> KỲ VỌNG: Mạch chốt được 33

    // KẾT THÚC DÒNG 2
    @(negedge SYSCLK);
    HREF = 1'b0;
    DATA = 8'h00;

    // Nghỉ ngơi trước khi kết thúc khung hình
    #(SYSCLK_PERIOD * 10);

    // 3. Giả lập Camera nháy VSYNC lần nữa (Kết thúc khung hình)
    @(negedge SYSCLK);
    VSYNC = 1'b1;
    #(SYSCLK_PERIOD * 3);
    
    @(negedge SYSCLK);
    VSYNC = 1'b0;

    // Dừng mô phỏng sau khi quan sát xong
    #(SYSCLK_PERIOD * 5);
    $stop;
end

endmodule
