// STD 10-30-16
//
// Synchronous 1-port ram with byte masking
// Only one read or one write may be done per cycle.
//

`define bsg_mem_1rw_sync_mask_write_byte_macro(words,bits)  \
  if (els_p == words && data_width_p == bits)               \
    begin: macro                                            \
      logic [data_width_p-1:0] w_bmask_li;                  \
      logic [data_width_p-1:0] data_out;                    \
      always_comb                                           \
        begin                                               \
          for (integer k = 0; k < write_mask_width_lp; k++) \
            begin                                           \
              w_bmask_li[8*k+:8] = {8{write_mask_i[k]}};    \
            end                                             \
        end                                                 \
       free45_1rw_d``words``_w``bits`` mem                  \
         (.clk       ( clk_i       )                        \
         ,.ce_in     ( v_i         )                        \
         ,.we_in     ( w_i         )                        \
         ,.addr_in   ( addr_i      )                        \
         ,.wd_in     ( data_i      )                        \
         ,.w_mask_in ( w_bmask_li  )                        \
         ,.rd_out    ( data_out    )                        \
         );                                                 \
       if (latch_last_read_p == 1)                          \
        begin: llr                                          \
          logic read_en_r;                                  \
          bsg_dff #(.width_p(1))                            \
            read_en_dff                                     \
            (.clk_i  ( clk_i      )                         \
            ,.data_i ( v_i & ~w_i )                         \
            ,.data_o ( read_en_r  )                         \
            );                                              \
                                                            \
          bsg_dff_en_bypass #(.width_p(data_width_p))       \
            data_dff                                        \
            (.clk_i  ( clk_i     )                          \
            ,.en_i   ( read_en_r )                          \
            ,.data_i ( data_out  )                          \
            ,.data_o ( data_o    )                          \
            );                                              \
        end                                                 \
    end

`define bsg_mem_1rw_sync_mask_write_byte_banked_macro(words,bits,wbank,dbank)   \
  if (els_p == words && data_width_p == bits)                                   \
    begin: macro                                                                \
      bsg_mem_1rw_sync_mask_write_byte_banked                                   \
        #(.data_width_p(data_width_p)                                           \
         ,.els_p(els_p)                                                         \
         ,.latch_last_read_p(latch_last_read_p)                                 \
         ,.num_depth_bank_p(dbank)                                              \
         ,.num_width_bank_p(wbank)                                              \
         )                                                                      \
         bank                                                                   \
         (.clk_i(clk_i)                                                         \
         ,.reset_i(reset_i)                                                     \
         ,.v_i(v_i)                                                             \
         ,.w_i(w_i)                                                             \
         ,.addr_i(addr_i)                                                       \
         ,.data_i(data_i)                                                       \
         ,.write_mask_i(write_mask_i)                                           \
         ,.data_o(data_o)                                                       \
         );                                                                     \
    end

module bsg_mem_1rw_sync_mask_write_byte #(parameter els_p = -1
                                         ,parameter data_width_p = -1
                                         ,parameter latch_last_read_p = 0
                                         ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                         ,parameter write_mask_width_lp = data_width_p>>3
                                         ,parameter harden_p = 1
                                         )
  (input                           clk_i
  ,input                           reset_i
  ,input                           v_i
  ,input                           w_i
  ,input [addr_width_lp-1:0]       addr_i
  ,input [data_width_p-1:0]        data_i
  ,input [write_mask_width_lp-1:0] write_mask_i
  ,output [data_width_p-1:0]       data_o
  );

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1rw_sync_mask_write_byte_macro(512, 64) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(1024, 32) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(2048, 64) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(4096, 64) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(1024, 32) else
  
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(1024, 256, 8, 1) else
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(1024, 512, 8, 2) else
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(2048, 256, 4, 4) else
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(1024, 512, 8, 2) else
  
  // no hardened version found
    begin: notmacro

      // Instantiate a synthesizale 1rw sync mask write byte
      bsg_mem_1rw_sync_mask_write_byte_synth #(.els_p(els_p), .data_width_p(data_width_p), .latch_last_read_p(latch_last_read_p)) synth 
       (.*);

    end // block: notmacro

  // synopsys translate_off
  always_comb
    assert (data_width_p % 8 == 0)
      else $error("data width should be a multiple of 8 for byte masking");

  initial
    begin
      $display("## bsg_mem_1rw_sync_mask_write_byte: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
    end
  // synopsys translate_on
   
endmodule
