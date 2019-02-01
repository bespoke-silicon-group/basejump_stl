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
          bsg_rp_tsmc_40_rf_w``words``_b``bits``_1r1w w``words``_b``bits \
            ( .clock_i(w_clk_i)                                         \
              ,.data_i(w_data_i)                                        \
              ,.write_sel_one_hot_i(wa_one_hot)                         \
              ,.read_sel_one_hot_i (ra_one_hot)                         \
              ,.data_o(r_data_o)                                        \
              );                                                        \
       end

module bsg_mem_1r1w
  #(parameter width_p="inv"
    , parameter els_p="inv"
    , parameter read_write_same_addr_p=0
    , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
		, parameter harden_p=1
    , parameter debug_p=0
  )
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

  wire unused = w_reset_i;

   `bsg_mem_1r1w_macro(32,16)
     else `bsg_mem_1r1w_macro(32,2)
     else `bsg_mem_1r1w_macro(32,8)
     else `bsg_mem_1r1w_macro(16,62)
     else `bsg_mem_1r1w_macro(4,32)
     else `bsg_mem_1r1w_macro(4,61)
     else `bsg_mem_1r1w_macro(4,62)
     else `bsg_mem_1r1w_macro(4,64)
     else `bsg_mem_1r1w_macro(4,66)
     else `bsg_mem_1r1w_macro(4,68)
     else `bsg_mem_1r1w_macro(4,70)
     else `bsg_mem_1r1w_macro(4,72)
     else `bsg_mem_1r1w_macro(4,74)
     else `bsg_mem_1r1w_macro(4,76)
     else `bsg_mem_1r1w_macro(4,80)
     else `bsg_mem_1r1w_macro(2,1)
     else `bsg_mem_1r1w_macro(2,2)
     else `bsg_mem_1r1w_macro(2,3)
     else `bsg_mem_1r1w_macro(2,4)
     else `bsg_mem_1r1w_macro(2,5)
     else `bsg_mem_1r1w_macro(2,6)
     else `bsg_mem_1r1w_macro(2,7)
     else `bsg_mem_1r1w_macro(2,8)
     else `bsg_mem_1r1w_macro(2,9)
     else `bsg_mem_1r1w_macro(2,10)
     else `bsg_mem_1r1w_macro(2,11)
     else `bsg_mem_1r1w_macro(2,12)
     else `bsg_mem_1r1w_macro(2,13)
     else `bsg_mem_1r1w_macro(2,14)
     else `bsg_mem_1r1w_macro(2,15)
     else `bsg_mem_1r1w_macro(2,16)
     else `bsg_mem_1r1w_macro(2,17)
     else `bsg_mem_1r1w_macro(2,18)
     else `bsg_mem_1r1w_macro(2,19)
     else `bsg_mem_1r1w_macro(2,20)
     else `bsg_mem_1r1w_macro(2,21)
     else `bsg_mem_1r1w_macro(2,22)
     else `bsg_mem_1r1w_macro(2,23)
     else `bsg_mem_1r1w_macro(2,24)
     else `bsg_mem_1r1w_macro(2,25)
     else `bsg_mem_1r1w_macro(2,26)
     else `bsg_mem_1r1w_macro(2,27)
     else `bsg_mem_1r1w_macro(2,28)
     else `bsg_mem_1r1w_macro(2,29)
     else `bsg_mem_1r1w_macro(2,30)
     else `bsg_mem_1r1w_macro(2,31)
     else `bsg_mem_1r1w_macro(2,32)
     else `bsg_mem_1r1w_macro(2,33)
     else `bsg_mem_1r1w_macro(2,34)
     else `bsg_mem_1r1w_macro(2,35)
     else `bsg_mem_1r1w_macro(2,36)
     else `bsg_mem_1r1w_macro(2,37)
     else `bsg_mem_1r1w_macro(2,38)
     else `bsg_mem_1r1w_macro(2,39)
     else `bsg_mem_1r1w_macro(2,40)
     else `bsg_mem_1r1w_macro(2,41)
     else `bsg_mem_1r1w_macro(2,42)
     else `bsg_mem_1r1w_macro(2,43)
     else `bsg_mem_1r1w_macro(2,44)
     else `bsg_mem_1r1w_macro(2,45)
     else `bsg_mem_1r1w_macro(2,46)
     else `bsg_mem_1r1w_macro(2,47)
     else `bsg_mem_1r1w_macro(2,48)
     else `bsg_mem_1r1w_macro(2,49)
     else `bsg_mem_1r1w_macro(2,50)
     else `bsg_mem_1r1w_macro(2,51)
     else `bsg_mem_1r1w_macro(2,52)
     else `bsg_mem_1r1w_macro(2,53)
     else `bsg_mem_1r1w_macro(2,54)
     else `bsg_mem_1r1w_macro(2,55)
     else `bsg_mem_1r1w_macro(2,56)
     else `bsg_mem_1r1w_macro(2,57)
     else `bsg_mem_1r1w_macro(2,58)
     else `bsg_mem_1r1w_macro(2,59)
     else `bsg_mem_1r1w_macro(2,60)
     else `bsg_mem_1r1w_macro(2,61)
     else `bsg_mem_1r1w_macro(2,62)
     else `bsg_mem_1r1w_macro(2,63)
     else `bsg_mem_1r1w_macro(2,64)
     else `bsg_mem_1r1w_macro(2,65)
     else `bsg_mem_1r1w_macro(2,66)
     else `bsg_mem_1r1w_macro(2,67)
     else `bsg_mem_1r1w_macro(2,68)
     else `bsg_mem_1r1w_macro(2,69)
     else `bsg_mem_1r1w_macro(2,70)
     else `bsg_mem_1r1w_macro(2,71)
     else `bsg_mem_1r1w_macro(2,72)
     else `bsg_mem_1r1w_macro(2,73)
     else `bsg_mem_1r1w_macro(2,74)
     else `bsg_mem_1r1w_macro(2,75)
     else `bsg_mem_1r1w_macro(2,76)
     else `bsg_mem_1r1w_macro(2,77)
     else `bsg_mem_1r1w_macro(2,78)
     else `bsg_mem_1r1w_macro(2,79)
     else `bsg_mem_1r1w_macro(2,80)
     else `bsg_mem_1r1w_macro(2,81)
     else `bsg_mem_1r1w_macro(2,82)
     else `bsg_mem_1r1w_macro(2,83)
     else `bsg_mem_1r1w_macro(2,84)
     else `bsg_mem_1r1w_macro(2,85)
     else `bsg_mem_1r1w_macro(2,86)
     else `bsg_mem_1r1w_macro(2,87)
     else `bsg_mem_1r1w_macro(2,88)
     else `bsg_mem_1r1w_macro(2,89)
     else `bsg_mem_1r1w_macro(8,8)
     else begin : notmacro

		bsg_mem_1r1w_synth
		  #(.width_p(width_p)
		    ,.els_p(els_p)
		    ,.read_write_same_addr_p(read_write_same_addr_p)
		    ,.harden_p(harden_p)
		    ) synth
		    (.*);
	     end

   // synopsys translate_off

   initial begin
     if (debug_p) begin
       if (width_p*els_p >= 64)
         $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d (%m), harden_p=%d"
            ,width_p,els_p,read_write_same_addr_p,harden_p);
     end
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
