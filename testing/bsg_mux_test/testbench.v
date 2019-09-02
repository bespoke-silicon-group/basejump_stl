module testbench();

localparam width_p = 8;
localparam els_p = 1;

logic [width_p-1:0] data_li, data_lo;
logic sel_li;

bsg_mux #(
  .width_p(width_p)
  ,.els_p(els_p)
) mux (
  .data_i(data_li)
  ,.sel_i(sel_li)
  ,.data_o(data_lo)
);


initial begin
  #1;
  data_li = 8'b1010_1111;
  sel_li = 1'b0;
  #100;
  sel_li = 1'b1;
  #100;
  $finish;
  

end

endmodule
