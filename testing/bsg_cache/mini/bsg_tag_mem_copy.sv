`include "bsg_defines.sv"

module bsg_tag_mem_copy #(
  parameter width_p=184
  ,parameter els_p=128
)(
  input clk_i
  ,input reset_i
  ,input [width_p-1:0] data_i
  ,input [width_p-1:0] data_o
  ,input v_i
  ,input w_i
  ,input [`BSG_SAFE_CLOG2(els_p)-1:0] addr_i
  ,output logic [width_p-1:0] tag_mem_copy_o [els_p-1:0]
);

  integer i;
  logic [width_p-1:0] tag_mem_copy [els_p-1:0];

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      for (i = 0; i < els_p; i++) tag_mem_copy[i] <= '0;
    end
    else if (v_i && w_i) begin
      tag_mem_copy[addr_i] <= data_i;
    end
  end

  assign tag_mem_copy_o = tag_mem_copy;

//   always_ff @(posedge clk_i) begin
//     if (v_i && !w_i) begin
//       $display("Read tag_mem[%0d] = %h", addr_i, data_o);
//     end
//   end

endmodule