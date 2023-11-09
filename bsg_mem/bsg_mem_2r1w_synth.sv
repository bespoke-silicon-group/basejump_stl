// MBT 4/1/2014
//
// 2 read-port, 1 write-port ram
//
// reads are asynchronous
//
// this file should not be directly instantiated by end programmers
// use bsg_mem_2r1w instead
//

`include "bsg_defines.sv"

module bsg_mem_2r1w_synth #(parameter `BSG_INV_PARAM(width_p)
			    , parameter `BSG_INV_PARAM(els_p)
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

   if (width_p == 0 || els_p == 0)
    begin: z
      wire unused0 = &{w_clk_i, w_v_i, w_addr_i, w_data_i, r0_v_i, r0_addr_i, r1_v_i, r1_addr_i};
      assign r0_data_o = '0;
      assign r1_data_o = '0;
    end
   else
    begin: nz

   logic [width_p-1:0]    mem [els_p-1:0];

   // this implementation ignores the r_v_i
   wire [addr_width_lp-1:0]  r0_addr_li = (els_p>1) ? r0_addr_i:'0;
   wire [addr_width_lp-1:0]  r1_addr_li = (els_p>1) ? r1_addr_i:'0;

   assign r1_data_o = mem[r1_addr_li];
   assign r0_data_o = mem[r0_addr_li];
   
   wire [addr_width_lp-1:0]  w_addr_li = (els_p>1) ? w_addr_i:'0;

   always_ff @(posedge w_clk_i)
     if (w_v_i)
       begin
          mem[w_addr_li] <= w_data_i;
       end
   end
endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_2r1w_synth)
