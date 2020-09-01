/**
 *      bsg_mesh_router_pkg.v
 *
 */



package bsg_mesh_router_pkg;


  
  //  ruche directions
  typedef enum logic [3:0] {
    RW = 4'd5
    ,RE = 4'd6
    ,RN = 4'd7
    ,RS = 4'd8
  } ruche_dirs_e;



  //                        //
  //    routing matrices    //
  //                        //


  // vanilla 2D mesh
 

 
  // dims_p = 2
  // XY_order_p = 1
  localparam bit [4:0][4:0] StrictXY = {
    //  SNEWP (input)
     5'b01111  // S
    ,5'b10111  // N
    ,5'b00011  // E
    ,5'b00101  // W
    ,5'b11111  // P (output)
  };

  // dims_p = 2
  // XY_order_p = 0
  localparam bit [4:0][4:0] StrictYX = {
    //  SNEWP (input)
     5'b01001  // S
    ,5'b10001  // N
    ,5'b11011  // E
    ,5'b11101  // W
    ,5'b11111  // P (output)
  };




  // Half Ruche (ruche network in X-direction)
  // depopulated router
  // YX retraces XY.


  // dims_p = 3
  // XY_order_p = 1
  localparam bit [6:0][6:0] HalfRucheX_StrictXY = {
    //  RE,RW,SNEWP (input)
     7'b0100001  // RE
    ,7'b1000001  // RW
    ,7'b0001111  // S
    ,7'b0010111  // N
    ,7'b0100011  // E
    ,7'b1000101  // W
    ,7'b0011111  // P (output)
   };


  // dims_p = 3
  // XY_order_p = 0
  localparam bit [6:0][6:0] HalfRucheX_StrictYX = {
    //  RE,RW,SNEWP (input)
     7'b0100010  // RE
    ,7'b1000100  // RW
    ,7'b0001001  // S
    ,7'b0010001  // N
    ,7'b0011011  // E
    ,7'b0011101  // W
    ,7'b1111111  // P (output)
  };




  // dims_p = 4
  // XY_order_p = 0
  localparam bit [8:0][8:0] FullRuche_StrictXY = {
    //  RS,RN,RE,RW,SNEWP (input)
     9'b010001000  // RS
    ,9'b100010000  // RN
    ,9'b000100001  // RE
    ,9'b001000001  // RW
    ,9'b000001111  // S
    ,9'b000010111  // N
    ,9'b000100011  // E
    ,9'b001000101  // W
    ,9'b110011111  // P (output)
   };




  // dims_p = 4
  // XY_order_p = 1
  localparam bit [8:0][8:0] FullRuche_StrictYX = {
    //  RS,RN,RE,RW,SNEWP (input)
     9'b010000001  // RS
    ,9'b100000001  // RN
    ,9'b000100010  // RE
    ,9'b001000100  // RW
    ,9'b010001001  // S
    ,9'b100010001  // N
    ,9'b000011011  // E
    ,9'b000011101  // W
    ,9'b001111111  // P (output)
   };



endpackage
