module test_bsg;

reg [31:0][31:0] ops_li;
logic [37:0] sum_o;
logic [37:0] res_o;
bsg_adder_wallace_tree_32 #(
  .width_p(32)    
)wt(
  .ops_i(ops_li)
  ,.resA_o(sum_o)
  ,.resB_o(res_o)
);

wire [38:0] res_wl = sum_o + res_o;

wire [31:0][37:0] partial_sum;
assign partial_sum[0] = ops_li[0];
for(genvar i = 0; i < 31; ++i)
  assign partial_sum[i+1] = partial_sum[i] + ops_li[i+1];


initial begin
  ops_li = {32{$random}};
  #10
  $display("res_wl:%b",res_wl);
  $display("partial_sum:%b",partial_sum[31]);
  $display("Difference:%b",res_wl - partial_sum[31]);
end

         
endmodule

