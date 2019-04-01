
`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits) \
  if (els_p == words && width_p == bits)                  \
    begin: macro                                          \
      hard_mem_1rw_bit_mask_d``words``_w``bits``_wrapper  \
        mem                                               \
          (.clk_i   (clk_i)                               \
          ,.reset_i (reset_i)                             \
          ,.data_i  (data_i)                              \
          ,.addr_i  (addr_i)                              \
          ,.v_i     (v_i)                                 \
          ,.w_mask_i(w_mask_i)                            \
          ,.w_i     (w_i)                                 \
          ,.data_o  (data_o)                              \
          );                                              \
    end: macro

`define bsg_mem_1rw_sync_mask_write_bit_macro_banks(words,bits) \
  if (els_p == words && width_p == 2*``bits``)                  \
    begin: macro                                                \
      hard_mem_1rw_bit_mask_d``words``_w``bits``_wrapper        \
        mem0                                                    \
          (.clk_i   (clk_i)                                     \
          ,.reset_i (reset_i)                                   \
          ,.data_i  (data_i[width_p/2-1:0])                     \
          ,.addr_i  (addr_i)                                    \
          ,.v_i     (v_i)                                       \
          ,.w_mask_i(w_mask_i[width_p/2-1:0])                   \
          ,.w_i     (w_i)                                       \
          ,.data_o  (data_o[width_p/2-1:0])                     \
          );                                                    \
      hard_mem_1rw_bit_mask_d``words``_w``bits``_wrapper        \
        mem1                                                    \
          (.clk_i   (clk_i)                                     \
          ,.reset_i (reset_i)                                   \
          ,.data_i  (data_i[width_p-1:width_p/2])               \
          ,.addr_i  (addr_i)                                    \
          ,.v_i     (v_i)                                       \
          ,.w_mask_i(w_mask_i[width_p-1:width_p/2])             \
          ,.w_i     (w_i)                                       \
          ,.data_o  (data_o[width_p-1:width_p/2])               \
          );                                                    \
    end: macro

module bsg_mem_1rw_sync_mask_write_bit #( parameter width_p = -1
                                        , parameter els_p = -1
                                        , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
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
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,15)        else
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,7)         else
  `bsg_mem_1rw_sync_mask_write_bit_macro(64,96)        else
  `bsg_mem_1rw_sync_mask_write_bit_macro_banks(64,96)  else

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

