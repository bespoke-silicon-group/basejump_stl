

module top;
  localparam width_lp = 31;
  wire vo;
  wire [`BSG_SAFE_CLOG2(width_lp)-1:0] ao;
  logic [width_lp-1:0] in = 0;
  
  bsg_encode_one_hot #(.width_p(width_lp),.lo_to_hi_p(1),. debug_p(1)) foo
  (.i(in)
   ,.addr_o(ao)
   ,.v_o(vo)
  );
  
  initial 
    begin
	   in = 0;
      for (integer i = 0; i < width_lp+1; i=i+1)
        begin
          #10;
          in = (1 << i);
 
        end
    end
endmodule
