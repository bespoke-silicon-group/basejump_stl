`include "bsg_defines.v"

`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits,mux) \
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      gf14_1rw_d``words``_w``bits``_m``mux``_bit              \
        mem                                                   \
          ( .CLK   ( clk_i     )                              \
          , .A     ( addr_i    )                              \
          , .D     ( data_i    )                              \
          , .Q     ( data_o    )                              \
          , .CEN   ( ~v_i      )                              \
          , .GWEN  ( ~w_i      )                              \
          , .WEN   ( ~w_mask_i )                              \
          , .RET1N ( 1'b1      )                              \
          , .STOV  ( 1'b0      )                              \
          , .EMA   ( 3'b011    )                              \
          , .EMAW  ( 2'b01     )                              \
          , .EMAS  ( 1'b0      )                              \
          );                                                  \
    end: macro

`define bsg_mem_1rw_sync_mask_write_bit_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && width_p == bits) begin: macro \
    bsg_mem_1rw_sync_mask_write_bit_banked #(                     \
      .width_p(width_p)                                                     \
      ,.els_p(els_p)                                                        \
      ,.latch_last_read_p(latch_last_read_p)                                \
      ,.num_width_bank_p(wbank)                                             \
      ,.num_depth_bank_p(dbank)                                             \
    ) bmem (                                                                \
      .clk_i(clk_i)                                                         \
      ,.reset_i(reset_i)                                                    \
      ,.v_i(v_i)                                                            \
      ,.w_i(w_i)                                                            \
      ,.addr_i(addr_i)                                                      \
      ,.data_i(data_i)                                                      \
      ,.w_mask_i(w_mask_i)                                                  \
      ,.data_o(data_o)                                                      \
    );                                                                      \
  end: macro

module bsg_mem_1rw_sync_mask_write_bit #( parameter width_p = -1
                                        , parameter els_p = -1
                                        , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                        , parameter harden_p = 1
                                        , parameter latch_last_read_p = 1
                                        )
  ( input                       clk_i
  , input                       reset_i
  , input [width_p-1:0]         data_i
  , input [addr_width_lp-1:0]   addr_i
  , input                       v_i
  , input [width_p-1:0]         w_mask_i
  , input                       w_i
  , output logic [width_p-1:0]  data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,48,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,30,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,4,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,34,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(512,4,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(512,32,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(128,152,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,58,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(128,112,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,124,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,62,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(128,116,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(32,62,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,15,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,7,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(32,124,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(128,15,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,112,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,31,4) else

  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(64,116,2,1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(256,112,1,2) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(64,248,2,1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(64,496,8,1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(128,232,2,1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(32,496,4,1) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(256,448,1,4) else

    begin: notmacro
      bsg_mem_1rw_sync_mask_write_bit_synth #(.width_p(width_p), .els_p(els_p))
        synth
          (.*);
    end // block: notmacro

  // synopsys translate_off
  always_ff @(posedge clk_i)
    begin
      if (v_i)
        assert (addr_i < els_p)
          else $error("Invalid address %x to %m of size %x\n", addr_i, els_p);
    end

  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
    end
// synopsys translate_on

endmodule

