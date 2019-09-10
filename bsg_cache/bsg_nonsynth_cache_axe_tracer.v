/**
 *  bsg_nonsynth_cache_axe_tracer.v
 *
 */


module bsg_nonsynth_cache_axe_tracer
  #(parameter data_width_p="inv"
    , parameter addr_width_p="inv"
  )
  (
    input clk_i
    , input v_o
    , input yumi_i
    , input st_op_v_r
    , input ld_op_v_r
    , input [addr_width_p-1:0] addr_v_r
    , input [data_width_p-1:0] sbuf_data_li
    , input [data_width_p-1:0] data_o
  );


  // synopsys translate_off
  always_ff @ (posedge clk_i) begin
    if (v_o & yumi_i) begin
      if (st_op_v_r) begin
        $display("time: %0t", $time);
        $display("#AXE 0: M[%0d] := %0d", addr_v_r>>2, sbuf_data_li);
      end
  
      if (ld_op_v_r) begin
        $display("time: %0t", $time);
        $display("#AXE 0: M[%0d] == %0d", addr_v_r>>2, data_o);
      end
    end
  end
  // synopsys translate_on


endmodule
