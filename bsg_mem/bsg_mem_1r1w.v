// MBT 11/9/2014
//
// 1 read-port, 1 write-port ram
//
// reads are asynchronous
//

`include "bsg_defines.v"

module bsg_mem_1r1w #(parameter width_p=-1
                      , parameter els_p=-1
                      , parameter read_write_same_addr_p=0
                      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                      , parameter harden_p=0
                      )
   (input   w_clk_i
    , input w_reset_i

    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [`BSG_SAFE_MINUS(width_p, 1):0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [`BSG_SAFE_MINUS(width_p, 1):0] r_data_o
    );

   bsg_mem_1r1w_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ,.read_write_same_addr_p(read_write_same_addr_p)
       ,.harden_p(harden_p)
       ) synth
       (.*);

   //synopsys translate_off

   initial
     begin
	if (read_write_same_addr_p || (width_p*els_p >= 64))
          $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d, harden_p=%d (%m)"
                   ,width_p,els_p,read_write_same_addr_p,harden_p);
     end

   always_ff @(negedge w_clk_i)
     if (w_v_i===1'b1)
       begin
          assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || (w_addr_i < els_p))
            else $error("Invalid address %x to %m of size %x (w_reset_i=%b, w_v_i=%b)\n", w_addr_i, els_p, w_reset_i, w_v_i);

          assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || !(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p))
            else $error("%m: Attempt to read and write same address %x (w_v_i = %b, w_reset_i = %b)",w_addr_i,w_v_i,w_reset_i);
       end

   //synopsys translate_on

endmodule
