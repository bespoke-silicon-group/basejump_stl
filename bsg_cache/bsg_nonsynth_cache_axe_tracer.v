/**
 *  bsg_nonsynth_cache_axe_tracer.v
 *
 *  use SystemVerilog 'bind' on bsg_cache.
 *
 *
 *  @author tommy
 *
 */


module bsg_nonsynth_cache_axe_tracer
  import bsg_cache_pkg::*;
  #(parameter data_width_p="inv"
    , parameter addr_width_p="inv"
    , parameter ways_p="inv"
    , parameter sbuf_entry_width_lp=`bsg_cache_sbuf_entry_width(addr_width_p,data_width_p,ways_p)
  )
  (
    input clk_i
    , input v_o
    , input yumi_i
    , input st_op_v_r
    , input ld_op_v_r
    , input [addr_width_p-1:0] addr_v_r
    , input [sbuf_entry_width_lp-1:0] sbuf_entry_li
    , input [data_width_p-1:0] data_o
  );

  `declare_bsg_cache_sbuf_entry_s(addr_width_p, data_width_p, ways_p);
  bsg_cache_sbuf_entry_s sbuf_entry;
  assign sbuf_entry = sbuf_entry_li;


  // synopsys translate_off
  always_ff @ (posedge clk_i) begin
    if (v_o & yumi_i) begin
      if (st_op_v_r) begin
        $display("time: %0t", $time);
        $display("#AXE 0: M[%0d] := %0d", addr_v_r>>2, sbuf_entry.data);
      end
  
      if (ld_op_v_r) begin
        $display("time: %0t", $time);
        $display("#AXE 0: M[%0d] == %0d", addr_v_r>>2, data_o);
      end
    end
  end
  // synopsys translate_on


endmodule
