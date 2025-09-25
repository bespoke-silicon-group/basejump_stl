/****************************************************************************************
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
*                Copyright 2005 - 2006 Micron Technology, Inc. All rights reserved.
*
*
*	Revisions:	 baaab - 06/20/06 - tMRD was set to 2.0 ns but should be 2 * tCK - fixed.
*									Added ROW_BITS & BA_BITS for compatibility w/our system.
*									Also changed Col bits from 10 to 9 per spec.
*									Removed x32 option and part size parameter.
*
****************************************************************************************/

    //            Parameters current with 128Mb datasheet rev J (11/05)
    // 04.17.08 - Parameters current with 128Mb Data sheet rev A (04/08)

    // Timing parameters based on Speed Grade

                                          // SYMBOL UNITS DESCRIPTION
                                          // ------ ----- -----------
`ifdef sg5                                //              Timing Parameters for -5 (CL = 3)
    parameter tAC3_max         =     5.0; // tAC    ns    Access window of DQ from CK/CK#
    parameter tAC2_max         =     6.5; // tAC    ns    Access window of DQ from CK/CK#
    parameter tCK              =     5.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK3_min         =     5.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK2_min         =    12.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tDQSQ            =    0.40; // tDQSQ  ns    DQS-DQ skew, DQS to last DQ valid, per group, per access
    parameter tHZ3_max         =     5.0; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tHZ2_max         =     6.5; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tRAS             =    40.0; // tRAS   ns    Active to Precharge command time
    parameter tRC              =    55.0; // tRC    ns    Active to Active/Auto Refresh command time
    parameter tRCD             =    15.0; // tRCD   ns    Active to Read/Write command time
    parameter tRP              =    15.0; // tRP    ns    Precharge command period
    parameter tRRD             =    10.0; // tRRD   ns    Active bank a to Active bank b command time
    parameter tWTR             =     2.0; // tWTR  tCK    Internal Write-to-Read command delay
    parameter tXP              =     5.0; // tXP    ns    Exit power-down to first valid cmd *note: In data sheet this is specified as one clk, but min tck fails before tXP on the actual part
`else `ifdef sg54                         //              Timing Parameters for -6 (CL = 3)
    parameter tAC3_max         =     5.0; // tAC    ns    Access window of DQ from CK/CK#
    parameter tAC2_max         =     6.5; // tAC    ns    Access window of DQ from CK/CK#
    parameter tCK              =     5.4; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK3_min         =     5.4; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK2_min         =    12.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tDQSQ            =    0.45; // tDQSQ  ns    DQS-DQ skew, DQS to last DQ valid, per group, per access
    parameter tHZ3_max         =     5.0; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tHZ2_max         =     6.5; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tRAS             =    42.0; // tRAS   ns    Active to Precharge command time
    parameter tRC              =    58.2; // tRC    ns    Active to Active/Auto Refresh command time
    parameter tRCD             =    16.2; // tRCD   ns    Active to Read/Write command time
    parameter tRP              =    16.2; // tRP    ns    Precharge command period
    parameter tRRD             =    10.8; // tRRD   ns    Active bank a to Active bank b command time
    parameter tWTR             =     2.0; // tWTR  tCK    Internal Write-to-Read command delay
    parameter tXP              =     5.4; // tXP    ns    Exit power-down to first valid cmd *note: In data sheet this is specified as one clk, but min tck fails before tXP on the actual part
`else `ifdef sg6                          //              Timing Parameters for -6 (CL = 3)
    parameter tAC3_max         =     5.5; // tAC    ns    Access window of DQ from CK/CK#
    parameter tAC2_max         =     6.5; // tAC    ns    Access window of DQ from CK/CK#
    parameter tCK              =     6.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK3_min         =     6.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK2_min         =    12.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tDQSQ            =    0.50; // tDQSQ  ns    DQS-DQ skew, DQS to last DQ valid, per group, per access
    parameter tHZ3_max         =     5.5; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tHZ2_max         =     6.5; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tRAS             =    42.0; // tRAS   ns    Active to Precharge command time
    parameter tRC              =    60.0; // tRC    ns    Active to Active/Auto Refresh command time
    parameter tRCD             =    18.0; // tRCD   ns    Active to Read/Write command time
    parameter tRP              =    18.0; // tRP    ns    Precharge command period
    parameter tRRD             =    12.0; // tRRD   ns    Active bank a to Active bank b command time
    parameter tWTR             =     2.0; // tWTR  tCK    Internal Write-to-Read command delay
    parameter tXP              =     6.0; // tXP    ns    Exit power-down to first valid cmd *note: In data sheet this is specified as one clk, but min tck fails before tXP on the actual part
`else `define sg75                        //              Timing Parameters for -75 (CL = 3)
    parameter tAC3_max         =     6.0; // tAC    ns    Access window of DQ from CK/CK#
    parameter tAC2_max         =     6.5; // tAC    ns    Access window of DQ from CK/CK#
    parameter tCK              =     7.5; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK3_min         =     7.5; // tCK    ns    Nominal Clock Cycle Time
    parameter tCK2_min         =    12.0; // tCK    ns    Nominal Clock Cycle Time
    parameter tDQSQ            =    0.60; // tDQSQ  ns    DQS-DQ skew, DQS to last DQ valid, per group, per access
    parameter tHZ3_max         =     6.0; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tHZ2_max         =     6.5; // tHZ    ns    Data-out high Z window from CK/CK#
    parameter tRAS             =    45.0; // tRAS   ns    Active to Precharge command time
    parameter tRC              =    75.0; // tRC    ns    Active to Active/Auto Refresh command time
    parameter tRCD             =    22.5; // tRCD   ns    Active to Read/Write command time
    parameter tRP              =    22.5; // tRP    ns    Precharge command period
    parameter tRRD             =    15.0; // tRRD   ns    Active bank a to Active bank b command time
    parameter tWTR             =     1.0; // tWTR  tCK    Internal Write-to-Read command delay
    parameter tXP              =     7.5; // tXP    ns    Exit power-down to first valid cmd *note: In data sheet this is specified as one clk, but min tck fails before tXP on the actual part
`endif `endif `endif

    parameter tAC2_min         =     2.0; // tAC    ns    Access window of DQ from CK/CK#
    parameter tAC3_min         =     2.0; // tAC    ns    Access window of DQ from CK/CK#
    parameter tLZ              =     1.0; // tLZ    ns    Data-out low Z window from CK/CK#
    parameter tMRD             =     2.0; // tMRD  tCK    Load Mode Register command cycle time
    parameter tRFC             =    80.0; // tRFC   ns    Refresh to Refresh Command interval time
    parameter tSRC             =     1.0; // tSRC  tCK    SRR READ command to first valid command (Not Applicable for 128Mb, 256Mb Parts)
    parameter tSRR             =     2.0; // tSRR  tCK    SRR command to SRR READ command         (Not Applicable for 128Mb, 256Mb Parts)
    parameter tWR              =    15.0; // tWR    ns    Write recovery time

    // Size Parameters based on Part Width
`ifdef x16
    parameter ADDR_BITS        =      12; // Set this parameter to control how many Address bits are used
    parameter ROW_BITS         =      12; // Set this parameter to control how many Row bits are used
    parameter DQ_BITS          =      16; // Set this parameter to control how many Data bits are used
    parameter DQS_BITS         =       2; // Set this parameter to control how many DQS bits are used
    parameter DM_BITS          =       2; // Set this parameter to control how many DM bits are used
    parameter COL_BITS         =       9; // Set this parameter to control how many Column bits are used
    parameter BA_BITS          =       2; // Bank bits
`else `define x32
    parameter ADDR_BITS        =      12; // Set this parameter to control how many Address bits are used
    parameter ROW_BITS         =      12; // Set this parameter to control how many Row bits are used
    parameter DQ_BITS          =      32; // Set this parameter to control how many Data bits are used
    parameter DQS_BITS         =       4; // Set this parameter to control how many DQS bits are used
    parameter DM_BITS          =       4; // Set this parameter to control how many DM bits are used
    parameter COL_BITS         =       8; // Set this parameter to control how many Column bits are used
    parameter BA_BITS          =       2; // Bank bits
`endif

    // For use with the Multi Chip Package
`ifdef DUAL_RANK
    parameter CS_BITS          =       2; // Set this parameter to control how many Chip Select bits are used
    parameter RANKS            =       2; // Set this parameter to control how many Ranks on the mcp are used
`else 
    parameter CS_BITS          =       2; // Set this parameter to control how many Chip Select bits are used
    parameter RANKS            =       1; // Set this parameter to control how many Ranks on the mcp are used
`endif

    parameter full_mem_bits    = BA_BITS+ADDR_BITS+COL_BITS; // Set this parameter to control how many unique addresses are used
    parameter part_mem_bits    = 10;                   // Set this parameter to control how many unique addresses are used
    parameter part_size        = 128;                  // Set this parameter to indicate part size(512Mb, 256Mb, 128Mb)
    parameter tCH_MAX          = 0.55;                 // Clk high level width
    parameter tCH_MIN          = 0.45;                 // Clk high level width
    parameter tCL_MAX          = 0.55;                 // Clk low level width
    parameter tCL_MIN          = 0.45;                 // Clk low level width
    parameter tCKE             = 2.0;                  // Minimum tCKE High/Low time (in tCK's)
    parameter CL_MAX           = 3;                    // Maximum CAS Latency
    parameter BL_MAX           =    16  ;
