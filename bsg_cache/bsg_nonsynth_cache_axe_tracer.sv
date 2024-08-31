/**
 *  bsg_nonsynth_cache_axe_tracer.sv
 *
 *  use SystemVerilog 'bind' on bsg_cache.
 *
 *
 *  @author tommy
 *
 */


`include "bsg_defines.sv"
`include "bsg_cache.svh"

module bsg_nonsynth_cache_axe_tracer
  import bsg_cache_pkg::*;
  #(parameter `BSG_INV_PARAM(data_width_p)
    , parameter `BSG_INV_PARAM(addr_width_p)
    , parameter `BSG_INV_PARAM(ways_p)
    , parameter sbuf_entry_width_lp=`bsg_cache_sbuf_entry_width(addr_width_p,data_width_p,ways_p)
  )
  (
    input clk_i
    , input v_o
    , input yumi_i
    , input bsg_cache_decode_s decode_v_r
    , input [addr_width_p-1:0] addr_v_r
    , input [sbuf_entry_width_lp-1:0] sbuf_entry_li
    , input [data_width_p-1:0] data_o
  );

  `declare_bsg_cache_sbuf_entry_s(addr_width_p, data_width_p, ways_p);
  bsg_cache_sbuf_entry_s sbuf_entry;
  assign sbuf_entry = sbuf_entry_li;


`ifndef BSG_HIDE_FROM_SYNTHESIS
  
  localparam logfile_lp = "bsg_cache.axe";

  integer fd;
  string header;

  initial forever begin
    @(negedge clk_i) begin
      if (v_o & yumi_i) begin
        if (decode_v_r.st_op) begin
          fd = $fopen(logfile_lp, "a");
          $fwrite(fd, "0: M[%0d] := %0d\n", addr_v_r>>2, sbuf_entry.data);
          $fclose(fd);
        end
  
        if (decode_v_r.ld_op) begin
          fd = $fopen(logfile_lp, "a");
          $fwrite(fd, "0: M[%0d] == %0d\n", addr_v_r>>2, data_o);
          $fclose(fd);
        end
      end
    end 
  end   
`endif


endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_cache_axe_tracer)
