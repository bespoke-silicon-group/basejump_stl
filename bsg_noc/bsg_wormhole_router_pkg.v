`include "bsg_defines.v"

package bsg_wormhole_router_pkg;
  localparam  bit [1:0][2:0][2:0] StrictX
                             = {   // EWP (input)
                                {  3'b011 // E
                                  ,3'b101 // W
                                  ,3'b111 // P (output)
                                }
                               ,   // EWP (output)
                                {  3'b011 // E
                                  ,3'b101 // W
                                  ,3'b111 // P (input)
                                }
                              };

  localparam  bit [1:0][2:0][2:0] X_AllowLoopBack  // for testing only; you should never build a machine like this 
                             = {   // EWP (input)    // it will deadlock
                                {  3'b100 // E
                                  ,3'b010 // W
                                  ,3'b000 // P (output)
                                }
                               ,   // EWP (output)
                                {  3'b111 // E
                                  ,3'b111 // W
                                  ,3'b111 // P (input)
                                }
                              };

  localparam bit [1:0][4:0][4:0] StrictXY
                            = {
                               {//  SNEWP (input)
                                 5'b01111  // S
                                ,5'b10111  // N
                                ,5'b00011  // E
                                ,5'b00101  // W
                                ,5'b11111  // P (output)
                                }
                               ,
                               {//  SNEWP (output)
                                 5'b01001  // S
                                ,5'b10001  // N
                                ,5'b11011  // E
                                ,5'b11101  // W
                                ,5'b11111  // P (input)
                                }
                               };

  localparam bit [1:0][4:0][4:0] StrictYX
                            = {
                               {//  SNEWP (input)
                                 5'b01001  // S
                                ,5'b10001  // N
                                ,5'b11011  // E
                                ,5'b11101  // W
                                ,5'b11111  // P (output)
                                }
                               ,
                               {//  SNEWP (output)
                                 5'b01111  // S
                                ,5'b10111  // N
                                ,5'b00011  // E
                                ,5'b00101  // W
                                ,5'b11111  // P (input)
                                }
                               };

  // These are "OR-in" matrices, that are intended to be layered upon StrictYX or Strict XY.
 localparam bit [1:0][4:0][4:0] XY_Allow_S
                            = {
                               {//  SNEWP (input)
                                 5'b00000  // S
                                ,5'b00000  // N
                                ,5'b10000  // E
                                ,5'b10000  // W
                                ,5'b00000  // P (output)
                                }
                               ,
                               {//  SNEWP (output)
                                 5'b00110  // S
                                ,5'b00000  // N
                                ,5'b00000  // E
                                ,5'b00000  // W
                                ,5'b00000  // P (input)
                                }
                               };

 localparam bit [1:0][4:0][4:0]  XY_Allow_N
                            = {
                               {//  SNEWP (input)
                                 5'b00000  // S
                                ,5'b00000  // N
                                ,5'b01000  // E
                                ,5'b01000  // W
                                ,5'b00000  // P (output)
                                }
                               ,
                               {//  SNEWP (output)
                                 5'b00000  // S
                                ,5'b00110  // N
                                ,5'b00000  // E
                                ,5'b00000  // W
                                ,5'b00000  // P (input)
                                }
                               };

 localparam bit
   [1:0][4:0][4:0] YX_Allow_W = {
                               {//  SNEWP (input)
                                 5'b00010  // S
                                ,5'b00010  // N
                                ,5'b00000  // E
                                ,5'b00000  // W
                                ,5'b00000  // P (output)
                                }
                               ,
                               {//  SNEWP (output)
                                 5'b00000  // S
                                ,5'b00000  // N
                                ,5'b00000  // E
                                ,5'b11000  // W
                                ,5'b00000  // P (input)
                                }
                               };

 localparam bit
   [1:0][4:0][4:0] YX_Allow_E = {
                               {//  SNEWP (input)
                                 5'b00100  // S
                                ,5'b00100  // N
                                ,5'b00000  // E
                                ,5'b00000  // W
                                ,5'b00000  // P (output)
                                }
                               ,
                               {//  SNEWP (output)
                                 5'b00000  // S
                                ,5'b00000  // N
                                ,5'b11000  // E
                                ,5'b00000  // W
                                ,5'b00000  // P (input)
                                }
                               };

endpackage
