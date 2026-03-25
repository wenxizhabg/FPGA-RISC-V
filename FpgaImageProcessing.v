//////////////////////////////////////////////////////////////////////
// Created by SmartDesign Wed Mar 25 23:55:38 2026
// Version: 2025.1 2025.1.0.14
//////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

// FpgaImageProcessing
module FpgaImageProcessing(
    // Inputs
    DATA,
    HREF,
    PRESETN,
    VSYNC,
    pixelClock,
    sampleRate,
    threshold,
    // Outputs
    finalDensityCount,
    frameIsFinish
);

//--------------------------------------------------------------------
// Input
//--------------------------------------------------------------------
input  [7:0]  DATA;
input         HREF;
input         PRESETN;
input         VSYNC;
input         pixelClock;
input  [15:0] sampleRate;
input  [7:0]  threshold;
//--------------------------------------------------------------------
// Output
//--------------------------------------------------------------------
output [31:0] finalDensityCount;
output        frameIsFinish;
//--------------------------------------------------------------------
// Nets
//--------------------------------------------------------------------
wire          Camera_0_newFrameIsPrepare;
wire          Camera_0_outputIsValid;
wire          Camera_0_rowIsProcess;
wire   [7:0]  Camera_0_valueOfOutputPixel;
wire   [7:0]  DATA;
wire          DilationFilter_0_newFrameIsPrepareO;
wire          DilationFilter_0_outputIsValid;
wire   [7:0]  DilationFilter_0_valueOfOutputPixel;
wire   [31:0] finalDensityCount_net_0;
wire          frameIsFinish_net_0;
wire          GaussianFilter_0_newFrameIsPrepareO;
wire          GaussianFilter_0_outputIsValid;
wire          GaussianFilter_0_rowIsProcessO;
wire   [7:0]  GaussianFilter_0_valueOfOutputPixel;
wire          HREF;
wire          pixelClock;
wire          PRESETN;
wire          RowBuffer_0_newFrameIsPrepareO;
wire          RowBuffer_0_outputIsValid;
wire   [7:0]  RowBuffer_0_p11;
wire   [7:0]  RowBuffer_0_p12;
wire   [7:0]  RowBuffer_0_p13;
wire   [7:0]  RowBuffer_0_p21;
wire   [7:0]  RowBuffer_0_p22;
wire   [7:0]  RowBuffer_0_p23;
wire   [7:0]  RowBuffer_0_p31;
wire   [7:0]  RowBuffer_0_p32;
wire   [7:0]  RowBuffer_0_p33;
wire          RowBuffer_0_rowIsProcessO;
wire          RowBuffer_1_0_newFrameIsPrepareO;
wire          RowBuffer_1_0_outputIsValid;
wire   [7:0]  RowBuffer_1_0_p11;
wire   [7:0]  RowBuffer_1_0_p12;
wire   [7:0]  RowBuffer_1_0_p13;
wire   [7:0]  RowBuffer_1_0_p21;
wire   [7:0]  RowBuffer_1_0_p22;
wire   [7:0]  RowBuffer_1_0_p23;
wire   [7:0]  RowBuffer_1_0_p31;
wire   [7:0]  RowBuffer_1_0_p32;
wire   [7:0]  RowBuffer_1_0_p33;
wire          RowBuffer_1_0_rowIsProcessO;
wire          RowBuffer_1_newFrameIsPrepareO;
wire          RowBuffer_1_outputIsValid;
wire   [7:0]  RowBuffer_1_p11;
wire   [7:0]  RowBuffer_1_p12;
wire   [7:0]  RowBuffer_1_p13;
wire   [7:0]  RowBuffer_1_p21;
wire   [7:0]  RowBuffer_1_p22;
wire   [7:0]  RowBuffer_1_p23;
wire   [7:0]  RowBuffer_1_p31;
wire   [7:0]  RowBuffer_1_p32;
wire   [7:0]  RowBuffer_1_p33;
wire          RowBuffer_1_rowIsProcessO;
wire   [15:0] sampleRate;
wire          SobelFilter_0_newFrameIsPrepareO;
wire          SobelFilter_0_outputIsValid;
wire          SobelFilter_0_rowIsProcessO;
wire   [7:0]  SobelFilter_0_valueOfOutputPixel;
wire   [7:0]  threshold;
wire          VSYNC;
wire          frameIsFinish_net_1;
wire   [31:0] finalDensityCount_net_1;
//--------------------------------------------------------------------
// Top level output port assignments
//--------------------------------------------------------------------
assign frameIsFinish_net_1     = frameIsFinish_net_0;
assign frameIsFinish           = frameIsFinish_net_1;
assign finalDensityCount_net_1 = finalDensityCount_net_0;
assign finalDensityCount[31:0] = finalDensityCount_net_1;
//--------------------------------------------------------------------
// Component instances
//--------------------------------------------------------------------
//--------Camera
Camera Camera_0(
        // Inputs
        .PCLK               ( pixelClock ),
        .PRESETN            ( PRESETN ),
        .VSYNC              ( VSYNC ),
        .HREF               ( HREF ),
        .DATA               ( DATA ),
        // Outputs
        .newFrameIsPrepare  ( Camera_0_newFrameIsPrepare ),
        .rowIsProcess       ( Camera_0_rowIsProcess ),
        .outputIsValid      ( Camera_0_outputIsValid ),
        .valueOfOutputPixel ( Camera_0_valueOfOutputPixel ) 
        );

//--------DensityCounter
DensityCounter DensityCounter_0(
        // Inputs
        .pixelClock           ( pixelClock ),
        .PRESETN              ( PRESETN ),
        .newFrameIsPrepareNow ( DilationFilter_0_newFrameIsPrepareO ),
        .inputIsValid         ( DilationFilter_0_outputIsValid ),
        .valueOfInputPixel    ( DilationFilter_0_valueOfOutputPixel ),
        .sampleRate           ( sampleRate ),
        // Outputs
        .frameIsFinish        ( frameIsFinish_net_0 ),
        .finalDensityCount    ( finalDensityCount_net_0 ) 
        );

//--------RowBuffer
RowBuffer DilationBuffer(
        // Inputs
        .pixelClock         ( pixelClock ),
        .PRESETN            ( PRESETN ),
        .newFrameIsPrepareI ( SobelFilter_0_newFrameIsPrepareO ),
        .rowIsProcessI      ( SobelFilter_0_rowIsProcessO ),
        .inputIsValid       ( SobelFilter_0_outputIsValid ),
        .valueOfInputPixel  ( SobelFilter_0_valueOfOutputPixel ),
        // Outputs
        .newFrameIsPrepareO ( RowBuffer_1_0_newFrameIsPrepareO ),
        .rowIsProcessO      ( RowBuffer_1_0_rowIsProcessO ),
        .outputIsValid      ( RowBuffer_1_0_outputIsValid ),
        .p11                ( RowBuffer_1_0_p11 ),
        .p12                ( RowBuffer_1_0_p12 ),
        .p13                ( RowBuffer_1_0_p13 ),
        .p21                ( RowBuffer_1_0_p21 ),
        .p22                ( RowBuffer_1_0_p22 ),
        .p23                ( RowBuffer_1_0_p23 ),
        .p31                ( RowBuffer_1_0_p31 ),
        .p32                ( RowBuffer_1_0_p32 ),
        .p33                ( RowBuffer_1_0_p33 ) 
        );

//--------DilationFilter
DilationFilter DilationFilter_0(
        // Inputs
        .pixelClock         ( pixelClock ),
        .PRESETN            ( PRESETN ),
        .newFrameIsPrepareI ( RowBuffer_1_0_newFrameIsPrepareO ),
        .rowIsProcessI      ( RowBuffer_1_0_rowIsProcessO ),
        .inputIsValid       ( RowBuffer_1_0_outputIsValid ),
        .threshold          ( threshold ),
        .p11                ( RowBuffer_1_0_p11 ),
        .p12                ( RowBuffer_1_0_p12 ),
        .p13                ( RowBuffer_1_0_p13 ),
        .p21                ( RowBuffer_1_0_p21 ),
        .p22                ( RowBuffer_1_0_p22 ),
        .p23                ( RowBuffer_1_0_p23 ),
        .p31                ( RowBuffer_1_0_p31 ),
        .p32                ( RowBuffer_1_0_p32 ),
        .p33                ( RowBuffer_1_0_p33 ),
        // Outputs
        .newFrameIsPrepareO ( DilationFilter_0_newFrameIsPrepareO ),
        .rowIsProcessO      (  ),
        .outputIsValid      ( DilationFilter_0_outputIsValid ),
        .valueOfOutputPixel ( DilationFilter_0_valueOfOutputPixel ) 
        );

//--------RowBuffer
RowBuffer GaussianBuffer(
        // Inputs
        .pixelClock         ( pixelClock ),
        .PRESETN            ( PRESETN ),
        .newFrameIsPrepareI ( Camera_0_newFrameIsPrepare ),
        .rowIsProcessI      ( Camera_0_rowIsProcess ),
        .inputIsValid       ( Camera_0_outputIsValid ),
        .valueOfInputPixel  ( Camera_0_valueOfOutputPixel ),
        // Outputs
        .newFrameIsPrepareO ( RowBuffer_0_newFrameIsPrepareO ),
        .rowIsProcessO      ( RowBuffer_0_rowIsProcessO ),
        .outputIsValid      ( RowBuffer_0_outputIsValid ),
        .p11                ( RowBuffer_0_p11 ),
        .p12                ( RowBuffer_0_p12 ),
        .p13                ( RowBuffer_0_p13 ),
        .p21                ( RowBuffer_0_p21 ),
        .p22                ( RowBuffer_0_p22 ),
        .p23                ( RowBuffer_0_p23 ),
        .p31                ( RowBuffer_0_p31 ),
        .p32                ( RowBuffer_0_p32 ),
        .p33                ( RowBuffer_0_p33 ) 
        );

//--------GaussianFilter
GaussianFilter GaussianFilter_0(
        // Inputs
        .pixelClock         ( pixelClock ),
        .PRESETN            ( PRESETN ),
        .newFrameIsPrepareI ( RowBuffer_0_newFrameIsPrepareO ),
        .rowIsProcessI      ( RowBuffer_0_rowIsProcessO ),
        .inputIsValid       ( RowBuffer_0_outputIsValid ),
        .p11                ( RowBuffer_0_p11 ),
        .p12                ( RowBuffer_0_p12 ),
        .p13                ( RowBuffer_0_p13 ),
        .p21                ( RowBuffer_0_p21 ),
        .p22                ( RowBuffer_0_p22 ),
        .p23                ( RowBuffer_0_p23 ),
        .p31                ( RowBuffer_0_p31 ),
        .p32                ( RowBuffer_0_p32 ),
        .p33                ( RowBuffer_0_p33 ),
        // Outputs
        .newFrameIsPrepareO ( GaussianFilter_0_newFrameIsPrepareO ),
        .rowIsProcessO      ( GaussianFilter_0_rowIsProcessO ),
        .outputIsValid      ( GaussianFilter_0_outputIsValid ),
        .valueOfOutputPixel ( GaussianFilter_0_valueOfOutputPixel ) 
        );

//--------RowBuffer
RowBuffer SobelBuffer(
        // Inputs
        .pixelClock         ( pixelClock ),
        .PRESETN            ( PRESETN ),
        .newFrameIsPrepareI ( GaussianFilter_0_newFrameIsPrepareO ),
        .rowIsProcessI      ( GaussianFilter_0_rowIsProcessO ),
        .inputIsValid       ( GaussianFilter_0_outputIsValid ),
        .valueOfInputPixel  ( GaussianFilter_0_valueOfOutputPixel ),
        // Outputs
        .newFrameIsPrepareO ( RowBuffer_1_newFrameIsPrepareO ),
        .rowIsProcessO      ( RowBuffer_1_rowIsProcessO ),
        .outputIsValid      ( RowBuffer_1_outputIsValid ),
        .p11                ( RowBuffer_1_p11 ),
        .p12                ( RowBuffer_1_p12 ),
        .p13                ( RowBuffer_1_p13 ),
        .p21                ( RowBuffer_1_p21 ),
        .p22                ( RowBuffer_1_p22 ),
        .p23                ( RowBuffer_1_p23 ),
        .p31                ( RowBuffer_1_p31 ),
        .p32                ( RowBuffer_1_p32 ),
        .p33                ( RowBuffer_1_p33 ) 
        );

//--------SobelFilter
SobelFilter SobelFilter_0(
        // Inputs
        .pixelClock         ( pixelClock ),
        .PRESETN            ( PRESETN ),
        .newFrameIsPrepareI ( RowBuffer_1_newFrameIsPrepareO ),
        .rowIsProcessI      ( RowBuffer_1_rowIsProcessO ),
        .inputIsValid       ( RowBuffer_1_outputIsValid ),
        .p11                ( RowBuffer_1_p11 ),
        .p12                ( RowBuffer_1_p12 ),
        .p13                ( RowBuffer_1_p13 ),
        .p21                ( RowBuffer_1_p21 ),
        .p22                ( RowBuffer_1_p22 ),
        .p23                ( RowBuffer_1_p23 ),
        .p31                ( RowBuffer_1_p31 ),
        .p32                ( RowBuffer_1_p32 ),
        .p33                ( RowBuffer_1_p33 ),
        // Outputs
        .newFrameIsPrepareO ( SobelFilter_0_newFrameIsPrepareO ),
        .rowIsProcessO      ( SobelFilter_0_rowIsProcessO ),
        .outputIsValid      ( SobelFilter_0_outputIsValid ),
        .valueOfOutputPixel ( SobelFilter_0_valueOfOutputPixel ) 
        );


endmodule
