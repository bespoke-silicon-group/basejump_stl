module bsg_tag_mem_copy #(
  parameter width_p,
  parameter els_p
)(
  input logic clk_i,
  input logic reset_i,
  input logic [width_p-1:0] data_i,
  input logic [width_p-1:0] data_o,
  input logic v_i,
  input logic w_i,
  input logic [$clog2(els_p)-1:0] addr_i
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

//   always_ff @(posedge clk_i) begin
//     if (v_i && !w_i) begin
//       $display("Read tag_mem[%0d] = %h", addr_i, data_o);
//     end
//   end

endmodule