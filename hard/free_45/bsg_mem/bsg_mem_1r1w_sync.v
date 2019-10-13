// DGS 3/2/2018
//
// Synchronous 1 read-port and 1 write port ram.
//

`define bsg_mem_1r1w_sync_macro(words,bits) \
  if (els_p == words && width_p == bits)    \
    begin: macro                            \
      logic [els_p-1:0] v_r;                \
      always_ff @(posedge clk_i)            \
        if (reset_i)                        \
          v_r <= '0;                        \
        else if (w_v_i)                     \
          v_r[w_addr_i] <= ~v_r[w_addr_i];  \
                                            \
      wire [1:0] v_li    = {r_v_i | w_v_i, r_v_i | w_v_i};                                              \
      wire [1:0] w_li    = {w_v_i & ~v_r[w_addr_i], w_v_i & v_r[w_addr_i]};                             \
      wire [1:0][addr_width_lp-1:0]                                                                     \
                 addr_li = {v_r[r_addr_i] ? r_addr_i : w_addr_i, ~v_r[r_addr_i] ? r_addr_i : w_addr_i}; \
      logic [1:0][width_p-1:0] data_lo;                                                                 \
      assign r_data_o    = v_r[r_addr_i] ? data_lo[1] : data_lo[0];                                     \
                                            \
       free45_1rw_d``words``_w``bits`` mem0 \
         (.clk       ( clk_i      )         \
         ,.ce_in     ( v_li[0]    )         \
         ,.we_in     ( w_li[0]    )         \
         ,.addr_in   ( addr_li[0] )         \
         ,.wd_in     ( w_data_i   )         \
         ,.w_mask_in ( '1         )         \
         ,.rd_out    ( data_lo[1] )         \
         );                                 \
                                            \
       free45_1rw_d``words``_w``bits`` mem1 \
         (.clk       ( clk_i      )         \
         ,.ce_in     ( v_li[1]    )         \
         ,.we_in     ( w_li[1]    )         \
         ,.addr_in   ( addr_li[1] )         \
         ,.wd_in     ( w_data_i   )         \
         ,.w_mask_in ( '1         )         \
         ,.rd_out    ( data_lo[1] )         \
         );                                 \
    end

module bsg_mem_1r1w_sync #(parameter width_p=-1
                         ,parameter els_p=-1
                         ,parameter addr_width_lp=$clog2(els_p)
                         ,parameter harden_p = 1
                         )
  (input   clk_i
    , input reset_i
    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i
    , output logic [width_p-1:0] r_data_o
  );

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1r1w_sync_macro    (64, 512) else
  `bsg_mem_1r1w_sync_macro    (32, 64) else

      begin: notmacro

        // Instantiate a synthesizable 1rw sync ram
        bsg_mem_1r1w_sync_synth #(.width_p(width_p), .els_p(els_p)) synth
          (.*);

      end // block: notmacro

endmodule

