///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: apb_fifo_wrapper.v
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

module apb_fifo_wrapper (
    // APB Bus Interface
    input  wire        PCLK,    // 150MHz
    input  wire        PRESETN, 
    input  wire [31:0] PADDR,   
    input  wire        PSEL,    
    input  wire        PENABLE, 
    input  wire        PWRITE,  
    input  wire [31:0] PWDATA,  
    output reg  [31:0] PRDATA,  
    output wire        PREADY,  
    output wire        PSLVERR,

    // Interface t?i FIFO Ghi (APB -> Threshold)
    output wire        fifo_wr_we,
    output wire [23:0]  fifo_wr_data,

    // Interface t?i FIFO Ð?c (Density -> APB)
    output wire        fifo_rd_re,
    input  wire [31:0] fifo_rd_data,
    input  wire        fifo_rd_empty
);

    // APB3 yêu c?u PREADY luôn b?ng 1 n?u không có wait-state [cite: 1418, 1538]
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0; // Không báo l?i bus

    // 1. Logic Ghi Threshold (Ð?a ch? 0x00)
    // Ði?u ki?n ghi: PSEL & PENABLE & PWRITE & Ð?a ch? == 0
    assign fifo_wr_we   = (PSEL && PENABLE && PWRITE && (PADDR[7:0] == 8'h00));
    assign fifo_wr_data = PWDATA[23:0];

    // 2. Logic Ð?c Density Count (Ð?a ch? 0x04)
    // Ði?u ki?n d?c: PSEL & PENABLE & !PWRITE & Ð?a ch? == 0x04
    assign fifo_rd_re   = (PSEL && PENABLE && !PWRITE && (PADDR[7:0] == 8'h04) && !fifo_rd_empty);

    // 3. Logic tr? d? li?u v? Bus PRDATA
    always @(*) begin
        if (PSEL && !PWRITE) begin
            case (PADDR[7:0])
                8'h04:   PRDATA = fifo_rd_data; // Tr? v? density count t? FIFO
                default: PRDATA = 32'h0;
            endcase
        end else begin
            PRDATA = 32'h0;
        end
    end

endmodule
