///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: ImageProcessing_APBwrapper.v
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

module ImageProcessing_APBwrapper( 
    // =========================================================
    // 1. NHÓM CHÂN CHU?N APB3 (S? n?i vào lõi CPU RISC-V)
    // =========================================================
    input  wire        PCLK,      // Xung nh?p h? th?ng c?a Bus APB
    input  wire        PRESETN,   // Reset h? th?ng t? CPU (M?c th?p)
    input  wire        PSEL,      // CPU ch?n giao ti?p v?i kh?i này
    input  wire        PENABLE,   // C? kích ho?t chu k? APB
    input  wire        PWRITE,    // 1 = CPU Ghi, 0 = CPU Ð?c
    input  wire [31:0] PADDR,     // Dây d?a ch? t? CPU
    input  wire [31:0] PWDATA,    // D? li?u CPU ghi 
    output reg  [31:0] PRDATA,    // D? li?u ta ném tr? v? cho CPU
    output wire        PREADY,    // Báo cho CPU: "S?n sàng"
    output wire        PSLVERR,   // C? báo l?i (Luôn là 0)

    // =========================================================
    // 2. NHÓM CHÂN NGO?I VI (N?i th?ng ra các chân Camera)
    // =========================================================
    input  wire        cam_pixelclock, 
    input  wire        cam_VSYNC,      
    input  wire        cam_HREF,       
    input  wire [7:0]  cam_data,       
    
    // =========================================================
    // 3. CHÂN NG?T (INTERRUPT)
    // =========================================================
    output wire        interrupt_out   
);

    // Các dây d?n n?i b? t? kh?i FPGA lõi
    wire [31:0] w_finalDensityCount;
    wire        w_frameIsFinish;

    // =========================================================
    // G?I KH?I Ð?M XE LÕI VÀO ÐÂY
    // =========================================================
    FpgaImageProcessing Core (
        .pixelClock        (cam_pixelclock),
        .VSYNC             (cam_VSYNC),
        .PRESETN           (PRESETN),          
        .HREF              (cam_HREF),
        .DATA              (cam_data),
        .threshold         (sync_threshold_2), // Dùng giá tr? Threshold dã qua d?ng b?
        .frameIsFinish     (w_frameIsFinish),
        .finalDensityCount (w_finalDensityCount)
    );

  
    // Thanh ghi thu?c mi?n PCLK (Do CPU qu?n lý)
    reg  [7:0]  reg_threshold;
    reg  [31:0] pclk_DensityCount;
    
    // Các thanh ghi ch?t d?ng b? (Synchronizers) d? gi?i quy?t CDC
    reg  [7:0]  sync_threshold_1, sync_threshold_2;
    reg         sync_frameFinish_1, sync_frameFinish_2, sync_frameFinish_3;

    // =========================================================
    // CDC 1: T? PCLK SANG PIXELCLOCK (CPU ghi -> FPGA Core nh?n)
    // CPU ghi giá tr? Threshold b?ng PCLK. Ta dùng 2 t?ng Flip-Flop
    // d? d?y an toàn giá tr? này sang mi?n cam_pixelclock.
    // =========================================================
    always @(posedge cam_pixelclock) begin
        sync_threshold_1 <= reg_threshold;
        sync_threshold_2 <= sync_threshold_1;
    end

    // =========================================================
    // CDC 2: T? PIXELCLOCK SANG PCLK (FPGA Core báo -> CPU d?c)
    // Ð?ng b? c? ng?t và ch?t d? li?u d? CPU d?c du?c an toàn.
    // =========================================================
    always @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            sync_frameFinish_1 <= 1'b0;
            sync_frameFinish_2 <= 1'b0;
            sync_frameFinish_3 <= 1'b0;
            pclk_DensityCount  <= 32'd0;
        end else begin
            // Ðua c? báo xong khung hình qua 2 t?ng D-FlipFlop vào mi?n PCLK
            sync_frameFinish_1 <= w_frameIsFinish;
            sync_frameFinish_2 <= sync_frameFinish_1;
            sync_frameFinish_3 <= sync_frameFinish_2; 
            
            // B?t su?n lên c?a c? ng?t. Khi x? lý xong 1 frame ?nh, 
            // ta l?p t?c chép d? li?u t? camera sang ch?t ? mi?n PCLK
            if (sync_frameFinish_2 && !sync_frameFinish_3) begin
                pclk_DensityCount <= w_finalDensityCount;
            end
        end
    end
    
    // Ð?y ng?t dã d?ng b? hóa lên cho CPU
    assign interrupt_out = sync_frameFinish_2;

    // =========================================================
    // LOGIC GHI BUS APB (Theo chu?n Actel AMBA 3)
    // =========================================================
    always @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            reg_threshold <= 8'd128; // Reset v? giá tr? ngu?ng m?c d?nh
        end else begin
            // Ch? ghi d? li?u khi CPU b?t PSEL, PWRITE và PENABLE
            if (PSEL && PWRITE && PENABLE) begin
                // Gi? s? c?p d?a ch? Offset 0x04 cho thanh ghi Threshold
                if (PADDR[7:0] == 8'h04) begin 
                    reg_threshold <= PWDATA[7:0];
                end
            end
        end
    end

    // =========================================================
    // LOGIC Ð?C BUS APB (Theo chu?n Actel AMBA 3)
    // =========================================================
    // Bu?c 1: Mux d? li?u t? h?p d?a trên d?a ch? PADDR
    reg [31:0] read_mux;
    always @(*) begin
        case (PADDR[7:0])
            8'h00: read_mux = pclk_DensityCount;        // Offset 0x00: Ð?c k?t qu? d?m
            8'h04: read_mux = {24'd0, reg_threshold};   // Offset 0x04: CPU d?c l?i Threshold
            default: read_mux = 32'd0;
        endcase
    end

    // Bu?c 2: B?t bu?c Register tín hi?u tr? v? b?ng xung PCLK
    always @(posedge PCLK or negedge PRESETN) begin
        if (!PRESETN) begin
            PRDATA <= 32'd0;
        end else begin
            // N?u có l?nh d?c (PWRITE = 0)
            if (PSEL && !PWRITE) begin
                PRDATA <= read_mux;
            end else begin
                PRDATA <= 32'd0;
            end
        end
    end

    // Lõi tinh luôn s?n sàng dáp ?ng
    assign PREADY  = 1'b1;  
    assign PSLVERR = 1'b0;  

endmodule
