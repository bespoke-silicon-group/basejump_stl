module bsg_adder_wallace_tree_3_2 #(
  parameter integer width_p = "inv"
  ,parameter integer capacity_p = "inv"
  ,parameter integer out_width_p = "inv"
)(
  input [capacity_p-1:0][width_p-1:0] ops_i
  ,output [out_width_p-1:0] resA_o
  ,output [out_width_p-1:0] resB_o
);
  if(capacity_p == 18) begin: CAPACITY_18
    wire [width_p+4:0] A_lo;
    wire [width_p+4:0] B_lo;
    bsg_adder_wallace_tree_18 #(
      .width_p(width_p)
    ) tree (
      .ops_i(ops_i)
      ,.resA_o(A_lo)
      ,.resB_o(B_lo)
    );
    assign resA_o = A_lo[out_width_p-1:0];
    assign resB_o = B_lo[out_width_p-1:0];
  end
  else if(capacity_p == 10) begin: CAPACITY_10
    wire [width_p+3:0] A_lo;
    wire [width_p+3:0] B_lo;
    bsg_adder_wallace_tree_10 #(
      .width_p(width_p)
    ) tree (
      .ops_i(ops_i)
      ,.resA_o(A_lo)
      ,.resB_o(B_lo)
    );
    assign resA_o = A_lo[out_width_p-1:0];
    assign resB_o = B_lo[out_width_p-1:0];
  end
  else if(capacity_p == 6) begin: CAPACITY_6
    wire [width_p+2:0] A_lo;
    wire [width_p+2:0] B_lo;
    bsg_adder_wallace_tree_6 #(
      .width_p(width_p)
    ) tree (
      .ops_i(ops_i)
      ,.resA_o(A_lo)
      ,.resB_o(B_lo)
    );
    assign resA_o = A_lo[out_width_p-1:0];
    assign resB_o = B_lo[out_width_p-1:0];
  end
  else if(capacity_p == 4) begin: CAPACITY_4
    wire [width_p-1:0] A_lo;
    wire [width_p-1:0] B_lo;
    bsg_adder_carry_save_4_2 #(
      .width_p(width_p)
    ) tree (
      .opA_i(ops_i[0])
      ,.opB_i(ops_i[1])
      ,.opC_i(ops_i[2])
      ,.opD_i(ops_i[3])

      ,.A_o(A_lo)
      ,.B_o(B_lo)
    );
    assign resA_o = A_lo[out_width_p-1:0];
    assign resB_o = B_lo[out_width_p-1:0];
  end
  else begin
    initial $error("There is no wallace tree for capacity = %d, but you can use bsg_adder_wallace_tree_generator.py to generate.",capacity_p);
  end
endmodule
