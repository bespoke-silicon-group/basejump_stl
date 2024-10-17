package bsg_torus_router_pkg;
  localparam bit [8:0][8:0] TorusXY = {
    // s1,s0,n1,n0,e1,e0,w1,w0,p (output)
    9'b00_10_00_00_1,       // s1 
    9'b00_11_00_00_1,       // s0
    9'b10_00_00_00_1,       // n1 
    9'b11_00_00_00_1,       // n0 
    9'b11_11_00_10_1,       // e1 
    9'b11_11_00_11_1,       // e0 
    9'b11_11_10_00_1,       // w1 
    9'b11_11_11_00_1,       // w0 
    9'b11_11_11_11_1        // p      (input)
  };
endpackage
