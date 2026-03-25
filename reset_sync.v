///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: reset_sync.v
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

module reset_sync (
    input  wire clk,
    input  wire async_reset_n, // Reset b?t d?ng b? d?u vào (t? nút nh?n/h? th?ng)
    output wire sync_reset_n   // Reset dã du?c d?ng b? v?i clk này
);
    reg r1, r2;

    always @(posedge clk or negedge async_reset_n) begin
        if (!async_reset_n) begin
            r1 <= 1'b0;
            r2 <= 1'b0;
        end else begin
            r1 <= 1'b1;
            r2 <= r1; // D?ch m?c 1 qua 2 t?ng FF d? kh? nhi?u timing
        end
    end

    assign sync_reset_n = r2;
endmodule
