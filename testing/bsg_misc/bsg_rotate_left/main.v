module main;
  
genvar i;
localparam width_p = 32;
  
  for (i = 0; i < width_p; i=i+1)
    begin
      wire [width_p-1:0] val;
      
      bsg_rotate_left  #(.width_p(width_p)) brl
        (.data_i( 32'hFEDC0123)
         ,.rot_i ( `BSG_SAFE_CLOG2(width_p) ' (i))
         ,.o(val)
        );
      initial begin
        #200;
      $display("%d = %x\n",i,val);
      end
      
    end
  
endmodule
