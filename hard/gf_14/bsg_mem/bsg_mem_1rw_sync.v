
`include "bsg_mem_1rw_sync_macros.vh"

module bsg_mem_1rw_sync #( parameter width_p = -1
                         , parameter els_p = -1
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         // whether to substitute a 1r1w
                         , parameter substitute_1r1w_p = 1
                         , parameter harden_p = 1
                         , parameter latch_last_read_p = 1
                         )
  ( input                     clk_i
  , input                     reset_i

  , input [width_p-1:0]       data_i
  , input [addr_width_lp-1:0] addr_i
  , input                     v_i
  , input                     w_i

  , output logic [width_p-1:0]  data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1rw_sync_macro(512,64,4) else
  `bsg_mem_1rw_sync_macro(256,96,2) else
  `bsg_mem_1rw_sync_macro(1024,46,4) else
  `bsg_mem_1rw_sync_macro(16,32,2) else
  `bsg_mem_1rw_sync_macro(64,49,4) else

  // no hardened version found
    begin : z
      // we substitute a 1r1w macro
      // fixme: theoretically there may be
      // a more efficient way to generate a 1rw synthesized ram
      if (substitute_1r1w_p)
        begin: s1r1w
          logic [width_p-1:0] data_lo;
        
          bsg_mem_1r1w #( .width_p(width_p)
                        , .els_p(els_p)
                        , .read_write_same_addr_p(0)
                        )
            mem
              (.w_clk_i   (clk_i)
              ,.w_reset_i(reset_i)
              ,.w_v_i    (v_i & w_i)
              ,.w_addr_i (addr_i)
              ,.w_data_i (data_i)
              ,.r_addr_i (addr_i)
              ,.r_v_i    (v_i & ~w_i)
              ,.r_data_o (data_lo)
              );
          
          // register output data to convert sync to async
          always_ff @(posedge clk_i) begin
            data_o <= data_lo;
          end
        end // block: s1r1w
      else
        begin: notmacro
          bsg_mem_1rw_sync_synth # (.width_p(width_p), .els_p(els_p), .latch_last_read_p(latch_last_read_p))
            synth
              (.*);
        end // block: notmacro
      end // block: z


  // synopsys translate_off
  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d, substitute_1r1w_p=%d (%m)",width_p,els_p,substitute_1r1w_p);
    end
  // synopsys translate_on

endmodule
