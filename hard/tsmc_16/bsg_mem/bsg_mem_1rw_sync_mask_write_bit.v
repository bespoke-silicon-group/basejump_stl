// ctorng 2-23-17
//
// Synchronous 1-port ram with bit masking
// Only one read or one write may be done per cycle.
//
// Ports for tsmc16_1rw and tsmc16_1rf
//
//   CLK   // in
//   Q     // out
//   CEN   // lo true
//   WEN   // lo true
//   GWEN  // lo true
//   A     // in
//   D     // in
//   STOV  // Self-timing Override - disabled
//   EMA   // Extra Margin Adjustment - default value
//   EMAW  // Extra Margin Adjustment Write - default value
//   EMAS  // Extra Margin Adjustment Sense Amp. - default value
//   RET1N // Retention Mode (active low) - disabled

`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits,lgEls)     \
if (els_p == words && width_p == bits)               \
  begin: macro                                       \
      tsmc16_1rw_lg``lgEls``_w``bits``_bit mem       \
        (.CLK   (clk_i )                             \
        ,.Q     (data_o)                             \
        ,.CEN   (~v_i  )                             \
        ,.WEN   (~w_mask_i)                          \
        ,.GWEN  (~w_i  )                             \
        ,.A     (addr_i)                             \
        ,.D     (data_i)                             \
        ,.STOV  (1'd0  )                             \
        ,.EMA   (3'd3  )                             \
        ,.EMAW  (2'd1  )                             \
        ,.EMAS  (1'd0  )                             \
        ,.RET1N (1'b1  )                             \
        );                                           \
  end // block: macro

`define bsg_mem_1rw_sync_mask_write_bit_macro_rf(words,bits,lgEls)  \
if (els_p == words && width_p == bits)               \
  begin: macro                                       \
      tsmc16_1rf_lg``lgEls``_w``bits``_bit mem       \
        (.Q     (data_o)                             \
        ,.CLK   (clk_i )                             \
        ,.CEN   (~v_i  )                             \
        ,.WEN   (~w_mask_i)                          \
        ,.GWEN  (~w_i  )                             \
        ,.A     (addr_i)                             \
        ,.D     (data_i)                             \
        ,.STOV  (1'd0  )                             \
        ,.EMA   (3'd3  )                             \
        ,.EMAW  (2'd1  )                             \
        ,.EMAS  (1'd0  )                             \
        ,.RET1N (1'b1  )                             \
        );                                           \
  end // block: macro

module bsg_mem_1rw_sync_mask_write_bit #(parameter width_p=-1
                                       , parameter els_p=-1
                                       , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p))
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [width_p-1:0] w_mask_i
    , input w_i
    , output [width_p-1:0]  data_o
    );

   `bsg_mem_1rw_sync_mask_write_bit_macro_rf(64,80,6) else
   bsg_mem_1rw_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ) synth
       (.*);

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

