module Camera(
    // --- CÁC CHÂN NỐI TRỰC TIẾP RA CAMERA OV7670 ---
    input wire PCLK,        // Xung nhịp từ camera
    input wire PRESETN,     // Bổ sung chân Reset (Tích cực mức thấp)
    input wire VSYNC,       // Cờ báo khung hình (Mức Cao = Đang nghỉ/Chuyển Frame)
    input wire HREF,        // Cờ báo dòng ngang (Mức Cao = Đang truyền data dòng)
    input wire [7:0] DATA,  // Bus dữ liệu 8-bit từ camera

    // --- CÁC CHÂN NỐI VÀO KHỐI GAUSS/LINE BUFFER ---
    output reg newFrameIsPrepare,         // Cờ báo: 1 = đã kết thúc frame cũ, chuẩn bị cho frame mới.
    output reg rowIsProcess,              // Cờ báo: 1 = đang xuất dữ liệu của hàng = HREF
    output reg outputIsValid,             // Cờ báo: 1 = Có data Y hợp lệ
    output reg [7:0] valueOfOutputPixel   // Ảnh xám Y đã lọc
);

    // Cờ lật để bỏ qua 1 xung, lấy 1 xung
    reg byte_toggle;

    // Toàn bộ hệ thống đập theo nhịp PCLK của camera và Reset bất đồng bộ
    always @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            // Trạng thái khởi động: Dọn sạch rác trong các thanh ghi
            newFrameIsPrepare  <= 1'b0;
            rowIsProcess       <= 1'b0;
            outputIsValid      <= 1'b0;
            valueOfOutputPixel <= 8'b0;
            byte_toggle        <= 1'b0;
        end
        else begin
            newFrameIsPrepare <= VSYNC;
            
            // 1. Nếu VSYNC lên mức cao (Camera đang nghỉ giữa 2 khung hình)
            if (VSYNC == 1'b1) begin
                byte_toggle        <= 1'b0;
                outputIsValid      <= 1'b0;
                rowIsProcess       <= 1'b0;
                valueOfOutputPixel <= 8'b0;
            end 
            // 2. Nếu HREF ở mức cao (Camera đang nhả dữ liệu của 1 dòng)
            else if (HREF == 1'b1) begin
                byte_toggle <= ~byte_toggle; // Lật cờ: 0 -> 1 -> 0 -> 1...
                rowIsProcess <= 1'b1;        
                
                // Camera nhả chuỗi U-Y-V-Y. Lấy nhịp chẵn (Y), bỏ nhịp lẻ (U, V)
                if (byte_toggle == 1'b1) begin 
                    valueOfOutputPixel <= DATA;       // Chốt byte độ sáng Y
                    outputIsValid      <= 1'b1;       // Báo cho Line Buffer đứng sau hút data vào
                end else begin
                    outputIsValid      <= 1'b0;       // Bỏ qua màu U/V, hạ cờ báo để khối sau nghỉ
                end
            end
            // 3. Nếu HREF xuống mức thấp (Camera đang nghỉ giữa các dòng)
            else begin
                byte_toggle        <= 1'b0; // Đặt lại cờ để dòng mới luôn bắt đầu chuẩn nhịp
                outputIsValid      <= 1'b0;
                rowIsProcess       <= 1'b0;
            end
        end
    end

endmodule
