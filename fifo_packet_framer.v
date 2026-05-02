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
    input  wire        clk,
    input  wire        rst_n,

    // Tín hiệu từ Camera
    input  wire        i_vsync,
    input  wire        i_rowIsProcess,
    input  wire        i_outputIsValid,
    input  wire [7:0]  i_pixel_data,

    // Giao tiếp với CoreFIFO
    output reg         o_fifo_we,
    output reg  [7:0]  o_fifo_data,
    input  wire        i_fifo_full,

    // Giao tiếp với UART
    output reg         o_data_ready, // Cờ báo UART
    input  wire        i_fifo_empty
);

    // ==========================================
    // 1. DÒ SƯỜN TÍN HIỆU
    // ==========================================
    reg vsync_d;
    reg rowIsProcess_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vsync_d        <= 1'b1;
            rowIsProcess_d <= 1'b0;
        end else begin
            vsync_d        <= i_vsync;
            rowIsProcess_d <= i_rowIsProcess;
        end
    end

    wire vsync_fall = (vsync_d == 1'b1 && i_vsync == 1'b0);
    wire vsync_rise = (vsync_d == 1'b0 && i_vsync == 1'b1);
    wire row_fall   = (rowIsProcess_d == 1'b1 && i_rowIsProcess == 1'b0);

    // ==========================================
    // 2. MÁY TRẠNG THÁI (FSM)
    // ==========================================
    localparam ST_IDLE       = 3'd0;
    localparam ST_SEND_SOF   = 3'd1;
    localparam ST_PROCESS    = 3'd2;
    localparam ST_SEND_EOL   = 3'd3;
    localparam ST_WAIT_DRAIN = 3'd4; // Trạng thái dừng ghi chờ xả

    reg [2:0] state;
    reg [2:0] byte_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            byte_cnt      <= 3'd0;
            o_fifo_we     <= 1'b0;
            o_fifo_data   <= 8'h00;
            o_data_ready  <= 1'b0;
        end else begin
            // Mặc định ngắt lệnh ghi mỗi đầu chu kỳ
            o_fifo_we <= 1'b0;

            case (state)
                ST_IDLE: begin
                    o_data_ready <= 1'b0; // Đảm bảo cờ UART đã tắt
                    if (vsync_fall) begin
                        state    <= ST_SEND_SOF;
                        byte_cnt <= 3'd0;
                    end
                end

                ST_SEND_SOF: begin
                    if (!i_fifo_full) begin
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
                end

                ST_PROCESS: begin
                    // 1. Phát hiện sườn lên VSYNC -> Dừng ghi, chuyển trạng thái
                    if (vsync_rise) begin
                        state <= ST_WAIT_DRAIN;
                    end
                    // 2. Phát hiện sườn xuống Dòng -> Ghi EOL
                    else if (row_fall) begin
                        state    <= ST_SEND_EOL;
                        byte_cnt <= 3'd0;
                    end
                    // 3. Đang quét Dòng -> Mở cửa ghi Data
                    else if (i_outputIsValid && !i_fifo_full) begin
                        o_fifo_we   <= 1'b1;
                        o_fifo_data <= i_pixel_data;
                    end
                end

                ST_SEND_EOL: begin
                    if (!i_fifo_full) begin
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
                end

                ST_WAIT_DRAIN: begin
                    // Phát cờ báo cho UART
                    o_data_ready <= 1'b1;
                    
                    // Đợi đến khi FIFO trống thì quay lại chờ khung mới
                    if (i_fifo_empty == 1'b1) begin
                        o_data_ready <= 1'b0; // Hạ cờ
                        state        <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
