module bsg_nonsynth_axe_tracer
  #(parameter data_width_p="inv"
    , parameter addr_width_p="inv"
  )
  (
    input clk_i
    , input v_i
    , input store_op_i
    , input load_op_i
    , input [addr_width_p-1:0] addr_i
    , input [data_width_p-1:0] store_data_i
    , input [data_width_p-1:0] load_data_i
  );


  // synopsys translate_off
  always_ff @ (posedge clk_i) begin
    if (v_i) begin
      if (store_op_i) begin
        $display("time: %0t", $time);
        $display("#AXE 0: M[%0d] := %0d", addr_i>>2, store_data_i);
      end
  
      if (load_op_i) begin
        $display("time: %0t", $time);
        $display("#AXE 0: M[%0d] == %0d", addr_i>>2, load_data_i);
      end
    end
  end
  // synopsys translate_on


endmodule
