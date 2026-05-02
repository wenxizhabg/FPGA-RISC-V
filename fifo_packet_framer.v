///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: fifo_packet_framer.v
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

module fifo_packet_framer (
    input  wire        pclk,             // Xung nhịp Camera
    input  wire        rst_n,            // Reset đồng bộ
    
    // Tín hiệu từ module Camera.v
    input  wire        i_vsync,
    input  wire        i_rowIsProcess,
    input  wire        i_outputIsValid,
    input  wire [7:0]  i_pixel_data,

    // Tín hiệu giao tiếp Write Port của CoreFIFO
    output reg         o_fifo_we,
    output reg  [7:0]  o_fifo_data
);

    // ==========================================
    // 1. KHỐI DÒ SƯỜN XUỐNG (FALLING EDGE DETECTOR)
    // ==========================================
    reg vsync_d;
    reg rowIsProcess_d;

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_d        <= 1'b1;
            rowIsProcess_d <= 1'b0;
        end else begin
            vsync_d        <= i_vsync;
            rowIsProcess_d <= i_rowIsProcess;
        end
    end

    // Tạo các xung kích hoạt chỉ tồn tại trong đúng 1 chu kỳ clock
    wire vsync_fall = (vsync_d == 1'b1 && i_vsync == 1'b0);
    wire row_fall   = (rowIsProcess_d == 1'b1 && i_rowIsProcess == 1'b0);

    // ==========================================
    // 2. ĐỊNH NGHĨA MAGIC WORDS
    // ==========================================
    // Start of Frame (SOF): DE AD BE EF
    // End of Line (EOL):    CA FE BA BE

    // ==========================================
    // 3. MÁY TRẠNG THÁI (FSM) ĐIỀU KHIỂN GHI
    // ==========================================
    localparam ST_IDLE       = 2'd0;
    localparam ST_SEND_SOF   = 2'd1;
    localparam ST_PROCESS    = 2'd2; // Trạng thái chính: Hứng data hoặc chờ sườn xuống
    localparam ST_SEND_EOL   = 2'd3;

    reg [1:0] state;
    reg [2:0] byte_cnt; // Bộ đếm để bơm 4 byte

    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= ST_IDLE;
            byte_cnt    <= 3'd0;
            o_fifo_we   <= 1'b0;
            o_fifo_data <= 8'h00;
        end else begin
            // Mặc định kéo WE xuống 0 để không ghi rác
            o_fifo_we <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (vsync_fall) begin
                        state    <= ST_SEND_SOF;
                        byte_cnt <= 3'd0;
                    end
                end

                ST_SEND_SOF: begin
                    o_fifo_we <= 1'b1;
                    case (byte_cnt)
                        3'd0: o_fifo_data <= 8'hDE;
                        3'd1: o_fifo_data <= 8'hAD;
                        3'd2: o_fifo_data <= 8'hBE;
                        3'd3: o_fifo_data <= 8'hEF;
                    endcase
                    
                    if (byte_cnt == 3'd3) begin
                        state <= ST_PROCESS;
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                    end
                end

                ST_PROCESS: begin
                    // Ưu tiên 1: Sự kiện rớt VSYNC (Khởi động lại toàn bộ)
                    if (vsync_fall) begin
                        state    <= ST_SEND_SOF;
                        byte_cnt <= 3'd0;
                    end 
                    // Ưu tiên 2: Sự kiện rớt Dòng (Hết dòng ngang)
                    else if (row_fall) begin
                        state    <= ST_SEND_EOL;
                        byte_cnt <= 3'd0;
                    end 
                    // Ưu tiên 3: Có dữ liệu hợp lệ từ Camera -> Mở cửa cho lọt qua
                    else if (i_outputIsValid) begin
                        o_fifo_we   <= 1'b1;
                        o_fifo_data <= i_pixel_data;
                    end
                end

                ST_SEND_EOL: begin
                    o_fifo_we <= 1'b1;
                    case (byte_cnt)
                        3'd0: o_fifo_data <= 8'hCA;
                        3'd1: o_fifo_data <= 8'hFE;
                        3'd2: o_fifo_data <= 8'hBA;
                        3'd3: o_fifo_data <= 8'hBE;
                    endcase
                    
                    if (byte_cnt == 3'd3) begin
                        state <= ST_PROCESS;
                    end else begin
                        byte_cnt <= byte_cnt + 1;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
