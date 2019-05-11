/****************************************************************************************
*
*    File Name:  tb.v
*      Version:  6.00
*        Model:  BUS Functional
*
* Dependencies:  mobile_ddr.v, mobile_ddr_parameters.vh, subtest.vh
*
*  Description:  Micron SDRAM DDR (Double Data Rate) test bench
*
*         Note: -Set simulator resolution to "ps" accuracy
*               -Set Debug = 0 to disable $display messages
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
*                Copyright 2003 Micron Technology, Inc. All rights reserved.
*
* Rev  Author Date        Changes
* ---  ------ ----------  ---------------------------------------
* 4.1  JMK    01/14/2001  -Grouped specify parameters by speed grade
*                         -Fixed mem_sizes parameter
* 2.1  SPH    03/19/2002  -Second Release
*                         -Fix tWR and several incompatability
*                            between different simulators
* 3.0  TFK    02/18/2003  -Added tDSS and tDSH timing checks.
*                         -Added tDQSH and tDQSL timing checks.
* 3.1  CAH    05/28/2003  -update all models to release version 3.1
*                            (no changes to this model)
* 3.2  JMK    06/16/2003  -updated all DDR400 models to support CAS Latency 3
* 3.3  JMK    09/11/2003  -Added initialization sequence checks.
* 4.0  JMK    12/01/2003  -Grouped parameters into "ddr_parameters.v"
*                         -Fixed tWTR check
* 4.2  JMK    03/19/2004  -Fixed pulse width checking on dqs
* 4.3  JMK    04/27/2004  -Changed bl wire size in tb module
*                         -Changed Dq_buf size to [15:0]
* 5.0  JMK    06/16/2004  -Added read to write checking.
*                         -Added read with precharge truncation to write checking.
*                         -Added associative memory array to reduce memory consumption.
*                         -Added checking for required DQS edges during write.
* 6.0  DMR    12/03/2004  -new density
* 6.01 BAAB   05/18/2006  -assimilating into Minneapolis site organization
* 3.11 BAS    10/18/2006  -added read_verify
* 3.35 bas    02/28/07    -mobile_ddr.v file  uses tAC correctly to calculate strobe/data launch
* 3.36 bas    03/05/07    -fixed error messages for different banks interrupting 
                             reads/writes w/autoprecharge
* 3.37 bas    03/21/07    -added T47M part for 512Mb in parameters file,
                             modified tXP check to measure in tCLK for T47M
* 3.60 clk    09/19/07    -fixed dm/dq verification fifo's
* 3.60 clk    09/19/07    -fixed dqrx module delay statement
* 3.80 clk    10/29/07    - Support for 1024Mb T48M
* 4.00 clk    12/30/07    - Fixed Read terminated by precharge testcase
* 4.70 clk    03/30/08    - Fixed typo in SRR code
* 4.80 clk    04/03/08    - Disable clk checking during initialization
* 4.90 clk    04/16/08    - Fixed tInit, added mpc support, updated t35m timing
* 5.00 clk    05/14/08    - Fixed back to back auto precharge commands          
* 5.20 clk    05/21/08    - Fixed read interrupt by pre (BL8), fixed 1024Mb parameter file
* 5.30 clk    05/22/08    - Fixed DM signal which cause false tWTR errors                    
              05/27/08    - Rewrote write and read pipelins, strobes
* 5.40 clk    05/28/08    - Fixed Addressing problem in Burst Order logic
* 5.50 clk    07/25/08    - Added T36N part type                                   
* 5.60 clk    09/05/08    - Fixed tXP in 256Mb part type                           
* 5.70 clk    09/17/08    - Fixed burst term check for write w/ all DM active       
* 5.80 clk    11/18/08    - Fixed internally latched dq & mask widths
* 5.90 clk    12/10/08    - Updated T36N parameters to latest datasheet
* 6.00 clk    03/05/09    - Fixed DQS problem w/ CL = 2
****************************************************************************************/

`timescale 1ns / 1ps

module tb;

`ifdef den128Mb
    `include "128Mb_mobile_ddr_parameters.vh"
`elsif den256Mb
    `include "256Mb_mobile_ddr_parameters.vh"
`elsif den512Mb
    `include "512Mb_mobile_ddr_parameters.vh"
`elsif den1024Mb
    `include "1024Mb_mobile_ddr_parameters.vh"
`elsif den2048Mb
    `include "2048Mb_mobile_ddr_parameters.vh"
`else
    // NOTE: Intentionally cause a compile fail here to force the users
    //       to select the correct component density before continuing
    ERROR: You must specify component density with +define+den____Mb.
`endif

    reg                         ck_tb       ;
    reg                         ck_enable = 1'b1 ;
    // ports
    wire                        ck;
    wire                        ck_n = ~ck;
    reg                         cke = 1'b0;
    reg                         cs_n;
    reg                         ras_n;
    reg                         cas_n;
    reg                         we_n;
    reg           [BA_BITS-1:0] ba;
    reg         [ADDR_BITS-1:0] a;
    wire          [DM_BITS-1:0] dm;
    wire          [DQ_BITS-1:0] dq;
    wire         [DQS_BITS-1:0] dqs;

    // mode registers
    reg         [ADDR_BITS-1:0] mode_reg0;                                 //Mode Register
    reg         [ADDR_BITS-1:0] mode_reg1;                                 //Extended Mode Register
    wire                  [2:0] cl       = mode_reg0[6:4];                 //CAS Latency
    wire                        bo       = mode_reg0[3];                   //Burst Order
    wire                  [7:0] bl       = (1<<mode_reg0[2:0]);            //Burst Length
    wire                        wl       = 1;                              //Write Latency

    // dq transmit
    reg                         dq_en;
    reg           [DM_BITS-1:0] dm_out;
    reg           [DQ_BITS-1:0] dq_out;
    reg                         dqs_en;
    reg          [DQS_BITS-1:0] dqs_out;
    assign                      dm       = dq_en ? dm_out : {DM_BITS{1'b0}};
    assign                      dq       = dq_en ? dq_out : {DQ_BITS{1'bz}};
    assign                      dqs      = dqs_en ? dqs_out : {DQS_BITS{1'bz}};

    // dq receive
    reg           [DM_BITS-1:0] dm_fifo [2*CL_MAX+16:0];
    reg           [DQ_BITS-1:0] dq_fifo [2*CL_MAX+16:0];
    wire          [DQ_BITS-1:0] q0, q1, q2, q3;
    reg                         ptr_rst_n;
    reg                   [1:0] burst_cntr;

    // timing definition in tCK units
    real                        tck;
    wire                 [11:0] trc   = tRC;
    wire                 [11:0] trrd  = ceil(tRRD/tck);
    wire                 [11:0] trcd  = ceil(tRCD/tck);
    wire                 [11:0] tras  = ceil(tRAS/tck);
    wire                 [11:0] twr   = ceil(tWR/tck);
    wire                 [11:0] trp   = ceil(tRP/tck);
    wire                 [11:0] tmrd  = tMRD;
    wire                 [11:0] trfc  = ceil(tRFC/tck);
    wire                 [11:0] tsrr  = ceil(tSRR);
    wire                 [11:0] tsrc  = ceil(tSRC);
    wire                 [11:0] tdqsq = tDQSQ;
    wire                 [11:0] twtr  = tWTR;

    initial begin
        $timeformat (-9, 1, " ns", 1);
`ifdef period
        tck <= `period; 
`else
        tck <= tCK;
`endif
        ck_tb <= 1'b1;
        dq_en  <= 1'b0;
        dqs_en <= 1'b0;
    end

    // component instantiation
    mobile_ddr mobile_ddr (
        .Clk                ( ck    ) ,           
        .Clk_n              ( ck_n  ) ,           
        .Cke                ( cke   ) ,           
        .Cs_n               ( cs_n  ) ,           
        .Ras_n              ( ras_n ) ,           
        .Cas_n              ( cas_n ) ,           
        .We_n               ( we_n  ) ,           
        .Addr               ( a     ) ,           
        .Ba                 ( ba    ) ,           
        .Dq                 ( dq    ) ,           
        .Dqs                ( dqs   ) ,           
        .Dm                 ( dm    )  
    );

    // clock generator
    assign ck = ck_enable & ck_tb ;
    always @(posedge ck_tb) begin
      ck_tb <= #(tck/2) 1'b0;
      ck_tb <= #(tck) 1'b1;
    end

    function integer ceil;
        input number;
        real number;
        if (number > $rtoi(number))
            ceil = $rtoi(number) + 1;
        else
            ceil = number;
    endfunction

    function integer max;
        input arg1;
        input arg2;
        integer arg1;
        integer arg2;
        if (arg1 > arg2)
            max = arg1;
        else
            max = arg2;
    endfunction

    function [8*DQ_BITS-1:0] burst_order;
        input [8-1:0] col;
        input [8*DQ_BITS-1:0] dq; 
        reg [3:0] i;
        reg [2:0] j;
        integer k;
        begin
            burst_order = dq;
            for (i=0; i<bl; i=i+1) begin
                j = ((col%bl) ^ i);
                if (!bo)
                    j[1:0] = (col + i);
                for (k=0; k<DQ_BITS; k=k+1) begin
                    burst_order[i*DQ_BITS + k] = dq[j*DQ_BITS + k];
                end
            end
        end
    endfunction

    task power_up;
        begin
            cke   <= 1'b0;
            cs_n  <= 1'b1;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            ba    <= {BA_BITS{1'b0}};
            a     <= {ADDR_BITS{1'b0}}; 
            repeat(10) @(negedge ck_tb);
            @ (negedge ck_tb) cke <= 1'b1;
            $display ("%m at time %t TB:  A 200 us delay is required after cke is brought high.", $time);
        end
    endtask

    task stop_clock_enter ;
    begin
        @ (negedge ck_tb);
        ck_enable = 1'b0 ;
    end
    endtask

    task stop_clock_exit ;
    begin
        @ (negedge ck_tb);
        ck_enable = 1'b1 ;
    end
    endtask

    task load_mode;
        input   [BA_BITS-1:0] bank;
        input  [ROW_BITS-1:0] row;
        begin
            case (bank)
                0: mode_reg0 = row;
                1: mode_reg1 = row;
            endcase
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n  <= 1'b0;
            ba    <= bank;
            a     <= row;
            @(negedge ck_tb);
        end
    endtask

    task refresh;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n  <= 1'b1;
            @(negedge ck_tb);
        end
    endtask
     
    task precharge;
        input [BA_BITS-1:0] bank;
        input               ap; //precharge all
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b1;
            we_n  <= 1'b0;
            ba    <= bank;
            a     <= (ap<<10);
            @(negedge ck_tb);
        end
    endtask
     
    task activate;
        input   [BA_BITS-1:0] bank;
        input  [ROW_BITS-1:0] row;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            ba    <= bank;
            a     <= row;
            @(negedge ck_tb);
        end
    endtask

    //write task supports burst lengths <= 8
    task write;
        input   [BA_BITS-1:0] bank;
        input  [COL_BITS-1:0] col;
        input                 ap; //Auto Precharge
        input [16*DM_BITS-1:0] dm;
        input [16*DQ_BITS-1:0] dq;
        reg   [ADDR_BITS-1:0] atemp [1:0];
        integer i;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b0;
            we_n  <= 1'b0;
            ba    <= bank;
            atemp[0] = col & 10'h3ff;   //addr[ 9: 0] = COL[ 9: 0]
            atemp[1] = (col>>10)<<11;   //addr[ N:11] = COL[ N:10]
            a     <= atemp[0] | atemp[1] | (ap<<10);
            for (i=0; i<=bl; i=i+1) begin
                dqs_en <= #(wl*tck + i*tck/2) 1'b1;
                if (i%2 == 0) begin
                    dqs_out <= #(wl*tck + i*tck/2) {DQS_BITS{1'b0}};
                end else begin
                    dqs_out <= #(wl*tck + i*tck/2) {DQS_BITS{1'b1}};
                end

                dq_en  <= #(wl*tck + i*tck/2 + tck/4) 1'b1;
                dm_out <= #(wl*tck + i*tck/2 + tck/4) dm>>i*DM_BITS;
                dq_out <= #(wl*tck + i*tck/2 + tck/4) dq>>i*DQ_BITS;
            end
            dqs_en <= #(wl*tck + bl*tck/2 + tck/2) 1'b0;
            dq_en  <= #(wl*tck + bl*tck/2 + tck/4) 1'b0;
            @(negedge ck_tb);  
        end
    endtask

    // read without data verification
    task read;
        input    [BA_BITS-1:0] bank;
        input   [COL_BITS-1:0] col;
        input                  ap; //Auto Precharge
        reg    [ADDR_BITS-1:0] atemp [1:0];
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b0;
            we_n  <= 1'b1;
            ba    <= bank;
            atemp[0] = col & 10'h3ff;   //addr[ 9: 0] = COL[ 9: 0]
            atemp[1] = (col>>10)<<11;   //addr[ N:11] = COL[ N:10]
            a     <= atemp[0] | atemp[1] | (ap<<10);
            @(negedge ck_tb);
        end
    endtask

    task burst_term;
        integer i;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b0;
            @(negedge ck_tb);
            for (i=0; i<bl; i=i+1) begin
                dm_fifo[2*cl + i] <= {DM_BITS{1'bx}};
                dq_fifo[2*cl + i] <= {DQ_BITS{1'bx}};
            end
        end
    endtask

    task nop;
        input [31:0] count;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            repeat(count) @(negedge ck_tb);
        end
    endtask

    task deselect;
        input [31:0] count;
        begin
            cke   <= 1'b1;
            cs_n  <= 1'b1;
//            ras_n <= 1'b1;
//            cas_n <= 1'b1;
//            we_n  <= 1'b1;
            repeat(count) @(negedge ck_tb);
        end
    endtask

    task power_down;
        input [31:0] count;
        begin
            cke   <= 1'b0;
            cs_n  <= 1'b1;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b1;
            repeat(count) @(negedge ck_tb);
        end
    endtask

    task deep_power_down;
        input [31:0] count;
        begin
            cke   <= 1'b0;
            cs_n  <= 1'b0;
            ras_n <= 1'b1;
            cas_n <= 1'b1;
            we_n  <= 1'b0;
            repeat(count) @(negedge ck_tb);
        end
    endtask

    task self_refresh;
        input [31:0] count;
        begin
            cke   <= 1'b0;
            cs_n  <= 1'b0;
            ras_n <= 1'b0;
            cas_n <= 1'b0;
            we_n  <= 1'b1;
            repeat(count) @(negedge ck_tb);
        end
    endtask

    // read with data verification
    task read_verify;
        input   [BA_BITS-1:0] bank;
        input  [COL_BITS-1:0] col;
        input                 ap; //Auto Precharge
        input [16*DM_BITS-1:0] dm; //Expected Data Mask
        input [16*DQ_BITS-1:0] dq; //Expected Data
        integer i;
        begin
            read (bank, col, ap);
            for (i=0; i<bl; i=i+1) begin
                dm_fifo[2*cl + i] <= dm>>(i*DM_BITS);
                dq_fifo[2*cl + i] <= dq>>(i*DQ_BITS);
            end
        end
    endtask

    // receiver(s) for data_verify process
    dqrx dqrx[DQS_BITS-1:0] (ptr_rst_n, dqs, dq, q0, q1, q2, q3);

    // perform data verification as a result of read_verify task call
    reg [DQ_BITS-1:0] bit_mask;
    reg [DM_BITS-1:0] dm_temp;
    reg [DQ_BITS-1:0] dq_temp;
    always @(ck) begin:data_verify
        integer i;
        integer j;
        
        for (i=!ck; (i<2/(2.0 - !ck)); i=i+1) begin
            if (dm_fifo[i] === {DM_BITS{1'bx}}) begin
                burst_cntr = 0;
            end else begin

                dm_temp = dm_fifo[i];
                for (j=0; j<DQ_BITS; j=j+1) begin
                    bit_mask[j] = !dm_temp[j/(DQ_BITS/DM_BITS)];
                end

                case (burst_cntr)
                    0: dq_temp =  q0;
                    1: dq_temp =  q1;
                    2: dq_temp =  q2;
                    3: dq_temp =  q3;
                endcase
                //if ( ((dq_temp & bit_mask) === (dq_fifo[i] & bit_mask)))
                //    $display ("%m at time %t: INFO: Successful read data compare.  Expected = %h, Actual = %h, Mask = %h, i = %d", $time, dq_fifo[i], dq_temp, bit_mask, burst_cntr);
                if ((dq_temp & bit_mask) !== (dq_fifo[i] & bit_mask))
                    $display ("%m at time %t: ERROR: Read data miscompare.  Expected = %h, Actual = %h, Mask = %h, i = %d", $time, dq_fifo[i], dq_temp, bit_mask, burst_cntr);

                burst_cntr = burst_cntr + 1;
            end
        end

        if (ck_tb) begin
            ptr_rst_n <= (dm_fifo[4] !== {DM_BITS{1'bx}});
        end else begin
            //ptr_rst_n <= ptr_rst_n & (dm_fifo[6] !== {DM_BITS{1'bx}});
            for (i=0; i<=2*CL_MAX+16; i=i+1) begin
                dm_fifo[i] = dm_fifo[i+2];
                dq_fifo[i] = dq_fifo[i+2];
            end
        end
    end

    // End-of-test triggered in 'subtest.vh'
    task test_done;
        begin
            $display ("%m at time %t: INFO: Simulation is Complete", $time);
            $stop(0);
        end
    endtask

    // Test included from external file
    `include "subtest.vh"

endmodule

module dqrx (
    ptr_rst_n, dqs, dq, q0, q1, q2, q3
);

`ifdef den128Mb
    `include "128Mb_mobile_ddr_parameters.vh"
`elsif den256Mb
    `include "256Mb_mobile_ddr_parameters.vh"
`elsif den512Mb
    `include "512Mb_mobile_ddr_parameters.vh"
`elsif den1024Mb
    `include "1024Mb_mobile_ddr_parameters.vh"
`elsif den2048Mb
    `include "2048Mb_mobile_ddr_parameters.vh"
`else
    // NOTE: Intentionally cause a compile fail here to force the users
    //       to select the correct component density before continuing
    ERROR: You must specify component density with +define+den____Mb.
`endif

    input  ptr_rst_n;
    input  dqs;
    input  [DQ_BITS/DQS_BITS-1:0] dq;
    output [DQ_BITS/DQS_BITS-1:0] q0;
    output [DQ_BITS/DQS_BITS-1:0] q1;
    output [DQ_BITS/DQS_BITS-1:0] q2;
    output [DQ_BITS/DQS_BITS-1:0] q3;

    reg [1:0] ptr;
    reg [DQ_BITS/DQS_BITS-1:0] q [3:0];

    reg ptr_rst_dly_n;
    always @(posedge ptr_rst_n) ptr_rst_dly_n <= #(tAC2_min + tDQSQ) ptr_rst_n;
    always @(negedge ptr_rst_n) ptr_rst_dly_n <= #(tAC2_max + tDQSQ + 0.002) ptr_rst_n;

    reg dqs_dly;
    always @(dqs) dqs_dly <= #(tDQSQ + 0.001) dqs;

    always @(negedge ptr_rst_dly_n or posedge dqs_dly or negedge dqs_dly) begin
        if (!ptr_rst_dly_n) begin
            ptr <= 0;
        end else if (dqs_dly || ptr) begin
            q[ptr] <= dq;
            ptr <= ptr + 1;
        end
    end

    assign q0  = q[0];
    assign q1  = q[1];
    assign q2  = q[2];
    assign q3  = q[3];
endmodule
