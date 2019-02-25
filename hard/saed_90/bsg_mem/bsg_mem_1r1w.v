// DGS 3/2/2018
// 
// Async 1 read-port and 1 write port ram.
//

`define bsg_mem_1r1w_macro(bits,words) \
  if (els_p == words && width_p == bits)    \
    begin: macro                            \
       saed90_``bits``x``words``_2P_ASYNC mem     \
         (.CE1  (w_clk_i)                     \
         ,.OEB1 (1'b0)                      \
         ,.CSB1 (1'b0)                      \
         ,.A1   (r_addr_i)                  \
         ,.O1   (r_data_o)                  \
         ,.CE2  (w_clk_i)                     \
         ,.WEB2 (~w_v_i)                    \
         ,.CSB2 (1'b0)                      \
         ,.A2   (w_addr_i)                  \
         ,.I2   (w_data_i)                  \
         );                                 \
    end

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
    , input [width_p-1:0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [width_p-1:0] r_data_o
    );

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1r1w_macro    (64, 512) else

  begin: notmacro

   bsg_mem_1r1w_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ,.read_write_same_addr_p(read_write_same_addr_p)
       ,.harden_p(harden_p)
       ) synth
       (.*);

  end // block: notmacro


endmodule

