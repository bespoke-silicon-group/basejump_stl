// MBT 4/1/2014
//
// 2 read-port, 1 write-port ram
//
// reads are asynchronous
//
// this file should not be directly instantiated by end programmers
// use bsg_mem_2r1w instead
//

`include "bsg_defines.v"

module bsg_mem_2r1w_synth #(parameter width_p=-1
			    , parameter els_p=-1
			    , parameter read_write_same_addr_p=0
			    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
			    )
   (input   w_clk_i
    , input w_reset_i

    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0]       w_data_i

    , input                      r0_v_i
    , input [addr_width_lp-1:0]  r0_addr_i
    , output logic [`BSG_SAFE_MINUS(width_p, 1):0] r0_data_o

    , input                      r1_v_i
    , input [addr_width_lp-1:0]  r1_addr_i
    , output logic [`BSG_SAFE_MINUS(width_p, 1):0] r1_data_o

    );

   wire                   unused = w_reset_i;

   if (width_p == 0)
    begin: zero_width
      wire unused0 = w_clk_i;
      wire unused1 = w_v_i;
      wire [addr_width_lp-1:0] unused2 = w_addr_i;
      wire unused3 = w_data_i;
      wire unused4 = r0_v_i;
      wire [addr_width_lp-1:0] unused5 = r0_addr_i;
      wire unused6 = r1_v_i;
      wire [addr_width_lp-1:0] unused7 = r1_addr_i;

      assign r0_data_o = '0;
      assign r1_data_o = '0;
    end
   else
    begin: non_zero_width

   logic [width_p-1:0]    mem [els_p-1:0];

   // this implementation ignores the r_v_i
   assign r1_data_o = mem[r1_addr_i];
   assign r0_data_o = mem[r0_addr_i];

   always_ff @(posedge w_clk_i)
     if (w_v_i)
       begin
          mem[w_addr_i] <= w_data_i;
       end
   end
endmodule
