// MBT 11/9/2014
//
// 1 read-port, 1 write-port ram
//
// reads are asynchronous; we allow reading and writing of same address
//


`define bsg_mem_1r1w_macro(words,bits)                                  \
     if (els_p == words && width_p == bits)                             \
       begin: macro                                                     \
          wire [els_p-1:0] wa_one_hot = (w_v_i << w_addr_i);            \
          wire [els_p-1:0] ra_one_hot = (r_v_i << r_addr_i);            \
                                                                        \
          bsg_rp_tsmc_250_rf_w``words``_b``bits``_1r1w w``words``_b``bits \
            ( .clock_i(w_clk_i)                                         \
              ,.data_i(w_data_i)                                        \
              ,.write_sel_one_hot_i(wa_one_hot)                         \
              ,.read_sel_one_hot_i (ra_one_hot)                         \
              ,.data_o(r_data_o)                                        \
              );                                                        \
       end

module bsg_mem_1r1w #(parameter width_p=-1
                      , parameter els_p=-1
                      , parameter read_write_same_addr_p=0
                      , parameter addr_width_lp=$clog2(els_p)
		      , parameter harden_p=1)
   (input   w_clk_i
    , input w_reset_i

    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [width_p-1:0] r_data_o
    );

   `bsg_mem_1r1w_macro(32,16)
     else `bsg_mem_1r1w_macro(32,2)
     else `bsg_mem_1r1w_macro(32,8)
     else `bsg_mem_1r1w_macro(16,62)
     else `bsg_mem_1r1w_macro(4,61)
     else `bsg_mem_1r1w_macro(4,62)
     else `bsg_mem_1r1w_macro(4,64)
     else `bsg_mem_1r1w_macro(4,66)
     else `bsg_mem_1r1w_macro(4,68)
     else `bsg_mem_1r1w_macro(2,62)
     else `bsg_mem_1r1w_macro(2,64)
     else `bsg_mem_1r1w_macro(2,66)
     else `bsg_mem_1r1w_macro(8,8)
     else `bsg_mem_1r1w_macro(2,8)
     else `bsg_mem_1r1w_macro(2,80)
     else `bsg_mem_1r1w_macro(4,32)
           else
             begin : notmacro

		bsg_mem_1r1w_synth
		  #(.width_p(width_p)
		    ,.els_p(els_p)
		    ,.read_write_same_addr_p(read_write_same_addr_p)
		    ,.harden_p(harden_p)
		    ) synth
		    (.*);
	     end

   // synopsys translate_off

   initial
     begin
        if (width_p*els_p >= 64)
        $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d (%m)"
                 ,width_p,els_p,read_write_same_addr_p);
     end

   always_ff @(posedge w_clk_i)
     if (w_v_i)
       begin
          assert (w_addr_i < els_p)
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert (~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p))
            else $error("%m: Attempt to read and write same address %x",w_addr_i);
       end
   
   // synopsys translate_on

endmodule
