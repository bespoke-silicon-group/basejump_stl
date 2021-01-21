// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.

`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits)  \
  if (els_p == words && width_p == bits)                   \
    begin: macro                                           \
       logic [width_p-1:0] data_out;                       \
       free45_1rw_d``words``_w``bits`` mem                 \
         (.clk       ( clk_i     )                         \
         ,.ce_in     (  v_i      )                         \
         ,.we_in     (  w_i      )                         \
         ,.addr_in   ( addr_i    )                         \
         ,.wd_in     ( data_i    )                         \
         ,.rd_out    ( data_out  )                         \
         ,.w_mask_in ( w_mask_i  )                         \
         );                                                \
       if (latch_last_read_p == 1)                         \
         begin: llr                                        \
           logic read_en_r;                                \
           bsg_dff #(.width_p(1))                          \
             read_en_dff                                   \
             (.clk_i   ( clk_i      )                      \
             ,.data_i  ( v_i & ~w_i )                      \
             ,.data_o  ( read_en_r  )                      \
             );                                            \
                                                           \
           bsg_dff_en_bypass #(.width_p(width_p))          \
             data_dff                                      \
             (.clk_i   ( clk_i     )                       \
             ,.en_i    ( read_en_r )                       \
             ,.data_i  ( data_out  )                       \
             ,.data_o  ( data_o    )                       \
             );                                            \
         end                                               \
       else                                                \
         begin: no_llr                                     \
           assign data_o = data_out;                       \
         end                                               \
    end

`define bsg_mem_1rw_sync_mask_write_bit_banked_macro(words,bits,wbank,dbank)     \
  if (els_p == words && width_p == bits)                                         \
    begin: macro                                                                 \
      bsg_mem_1rw_sync_mask_write_bit_banked                                     \
        #(.width_p(width_p)                                                      \
         ,.els_p(els_p)                                                          \
         ,.latch_last_read_p(latch_last_read_p)                                  \
         ,.num_width_bank_p(wbank)                                               \
         ,.num_depth_bank_p(dbank)                                               \
        )                                                                        \
        bmem                                                                     \
        (.clk_i(clk_i)                                                           \
        ,.reset_i(reset_i)                                                       \
        ,.v_i(v_i)                                                               \
        ,.w_i(w_i)                                                               \
        ,.addr_i(addr_i)                                                         \
        ,.data_i(data_i)                                                         \
        ,.w_mask_i(w_mask_i)                                                     \
        ,.data_o(data_o)                                                         \
        );                                                                       \
    end

module bsg_mem_1rw_sync_mask_write_bit #(parameter width_p=-1
                           , parameter els_p=-1
                           , parameter latch_last_read_p=0
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           , parameter harden_p = 1
                           )
   (input   clk_i
    , input reset_i
    , input v_i
    , input w_i
    , input [addr_width_lp-1:0] addr_i
    , input [width_p-1:0] data_i
    , input [width_p-1:0] w_mask_i
    , output [width_p-1:0]  data_o
    );

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 50) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (32, 64) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (32, 66) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (256, 34) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (512, 64) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (128, 128) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 124) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 62) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 31) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (128, 116) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 15) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 7) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 3) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (64, 1) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (32, 124) else
  `bsg_mem_1rw_sync_mask_write_bit_macro (128, 15) else
  
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(64,248,2,1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(256, 128, 1, 2) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(128, 256, 2, 1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(1024, 512, 8, 2) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(128,232,2,1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(32,496,4,1) else

  // no hardened version found
    begin: notmacro

   bsg_mem_1rw_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ,.latch_last_read_p(latch_last_read_p)
       ) synth
       (.*);

    end // block: notmacro


   // synopsys translate_off

   always_ff @(posedge clk_i)
     if (v_i === 1)
       assert ((reset_i === 'X) || (reset_i === 1'b1) || (addr_i < els_p))
         else $error("Invalid address %x to %m of size %x (reset_i = %b, v_i = %b, clk_i=%b)\n", addr_i, els_p, reset_i, v_i, clk_i);

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
     end

  // synopsys translate_on

   
endmodule
