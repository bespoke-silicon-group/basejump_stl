// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.

`define bsg_mem_1rw_sync_macro_bit(words,bits,lgEls,mux) \
if (els_p == words && width_p == bits)                   \
  begin: macro                                           \
    tsmc40_1rw_d``words``_w``bits``_m``mux``_bit mem     \
      (.A     ( addr_i    )                              \
      ,.D     ( data_i    )                              \
      ,.BWEB  ( ~w_mask_i )                              \
      ,.WEB   ( ~w_i      )                              \
      ,.CEB   ( ~v_i      )                              \
      ,.CLK   ( clk_i     )                              \
      ,.Q     ( data_o    )                              \
      ,.DELAY ( 2'b0      ));                            \
  end

`define bsg_mem_1rf_sync_macro_bit(words,bits,lgEls,mux) \
if (els_p == words && width_p == bits)                   \
  begin: macro                                           \
    tsmc40_1rf_d``words``_w``bits``_m``mux``_bit mem     \
      (.A     ( addr_i    )                              \
      ,.D     ( data_i    )                              \
      ,.BWEB  ( ~w_mask_i )                              \
      ,.WEB   ( ~w_i      )                              \
      ,.CEB   ( ~v_i      )                              \
      ,.CLK   ( clk_i     )                              \
      ,.Q     ( data_o    )                              \
      ,.DELAY ( 2'b0      ));                            \
  end

`define bsg_mem_1rw_sync_mask_write_bit_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && width_p == bits) begin: macro           \
    bsg_mem_1rw_sync_mask_write_bit_banked #(                               \
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


module bsg_mem_1rw_sync_mask_write_bit #(parameter width_p=-1
			               , parameter els_p=-1
                     , parameter latch_last_read_p=0
			               , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                     , parameter harden_p=1)
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [width_p-1:0] w_mask_i
    , input w_i
    , output [width_p-1:0]  data_o
    );
  
  wire unused = reset_i;

   // we use a 2 port RF because the 1 port RF
   // does not support bit-level masking for 80-bit width
   // alternatively we could instantiate 2 40-bit 1rw RF's 								
   `bsg_mem_1rf_sync_macro_bit(32,124,5,2) else
   `bsg_mem_1rf_sync_macro_bit(64,124,6,2) else
   `bsg_mem_1rf_sync_macro_bit(128,116,7,2) else

   `bsg_mem_1rw_sync_mask_write_bit_banked_macro(32,496,4,1) else
   `bsg_mem_1rw_sync_mask_write_bit_banked_macro(64,248,2,1) else
   `bsg_mem_1rw_sync_mask_write_bit_banked_macro(128,232,2,1) else

   begin : notmacro
     bsg_mem_1rw_sync_mask_write_bit_synth
       #(.width_p(width_p)
         ,.els_p(els_p)
         ) synth
         (.*);
   end

   // synopsys translate_off

   always_ff @(posedge clk_i)
     if (v_i)
       assert (addr_i < els_p)
         else $error("Invalid address %x to %m of size %x\n", addr_i, els_p);

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
     end

  // synopsys translate_on


endmodule
