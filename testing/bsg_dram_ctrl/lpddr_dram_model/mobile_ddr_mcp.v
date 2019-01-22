/****************************************************************************************
*
*    File Name:  mobile_ddr_mcp.v
*
* Dependencies:  mobile_ddr.v, mobile_ddr_parameters.vh
*
*  Description:  Micron MOBILE DDR SDRAM multi-chip package model
*
*   Disclaimer   This software code and all associated documentation, comments or other 
*  of Warranty:  information (collectively "Software") is provided "AS IS" without 
*                warranty of any kind. MICRON TECHNOLOGY, INC. ("MTI") EXPRESSLY 
*                DISCLAIMS ALL WARRANTIES EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
*                TO, NONINFRINGEMENT OF THIRD PARTY RIGHTS, AND ANY IMPLIED WARRANTIES 
*                OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. MTI DOES NOT 
*                WARRANT THAT THE SOFTWARE WILL MEET YOUR REQUIREMENTS, OR THAT THE 
*                OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE. 
*                FURTHERMORE, MTI DOES NOT MAKE ANY REPRESENTATIONS REGARDING THE USE OR 
*                THE RESULTS OF THE USE OF THE SOFTWARE IN TERMS OF ITS CORRECTNESS, 
*                ACCURACY, RELIABILITY, OR OTHERWISE. THE ENTIRE RISK ARISING OUT OF USE 
*                OR PERFORMANCE OF THE SOFTWARE REMAINS WITH YOU. IN NO EVENT SHALL MTI, 
*                ITS AFFILIATED COMPANIES OR THEIR SUPPLIERS BE LIABLE FOR ANY DIRECT, 
*                INDIRECT, CONSEQUENTIAL, INCIDENTAL, OR SPECIAL DAMAGES (INCLUDING, 
*                WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, BUSINESS INTERRUPTION, 
*                OR LOSS OF INFORMATION) ARISING OUT OF YOUR USE OF OR INABILITY TO USE 
*                THE SOFTWARE, EVEN IF MTI HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
*                DAMAGES. Because some jurisdictions prohibit the exclusion or 
*                limitation of liability for consequential or incidental damages, the 
*                above limitation may not apply to you.
*
*                Copyright 2008 Micron Technology, Inc. All rights reserved.
*
****************************************************************************************/
`timescale 1ns / 1ps

module mobile_ddr_mcp (
    Clk   ,     
    Clk_n ,     
    Cke   ,     
    Cs_n  ,     
    Ras_n ,     
    Cas_n ,     
    We_n  ,     
    Addr  ,     
    Ba    ,     
    Dq    ,     
    Dqs   ,     
    Dm          
);

    `include "mobile_ddr_parameters.vh"

    // Declare Ports
    input                         Clk   ;
    input                         Clk_n ;
    input       [CS_BITS - 1 : 0] Cke   ;
    input       [CS_BITS - 1 : 0] Cs_n  ;
    input                         Ras_n ;
    input                         Cas_n ;
    input                         We_n  ;
    input     [ADDR_BITS - 1 : 0] Addr  ;
    input                 [1 : 0] Ba    ;
    inout       [DQ_BITS - 1 : 0] Dq    ;
    inout      [DQS_BITS - 1 : 0] Dqs   ;
    input       [DM_BITS - 1 : 0] Dm    ;

    wire [RANKS - 1 : 0] Cke_mcp = Cke   ;
    wire [RANKS - 1 : 0] Cs_n_mcp = Cs_n ;

    mobile_ddr rank [RANKS - 1:0] (
        .Clk   ( Clk       ) ,     
        .Clk_n ( Clk_n     ) ,     
        .Cke   ( Cke_mcp   ) ,     
        .Cs_n  ( Cs_n_mcp  ) ,     
        .Ras_n ( Ras_n     ) ,     
        .Cas_n ( Cas_n     ) ,     
        .We_n  ( We_n      ) ,     
        .Addr  ( Addr      ) ,     
        .Ba    ( Ba        ) ,     
        .Dq    ( Dq        ) ,     
        .Dqs   ( Dqs       ) ,     
        .Dm    ( Dm        )      
    );

endmodule
