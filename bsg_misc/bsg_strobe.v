// bsg_strobe
//
//                       N
// Outputs sequence ( 1 0  )* for 0 <= N=init_val_i <= (1<<width_p)-1
//
// init_val_i = # of cycles to count between asserting 1
//              (e.g 0 means assert 1 continuously)
//
// One usage is clock downsampling.
//
// The paper "The Power of Carry-Save Addition" by Lutz and Jayasimha
// is a good introduction to the use of carry-save addition. However
// the version in this code is significantly evolved versus the
// one in the paper; many of the gates were unnecessary.
//
// This should run well above a GHZ in 250 nm; it is a little more than one XOR delay
// on top of the flop.
//
// init_val_i can be changed on the fly; new values are captured on the same clk edge that the
// output strobe appears so the switch from one strobe delay to another is atomic and no
// unspecifed delays appear.
//
// Both reset_r and init_val_r are recommended to be driven out of registers to reduce
// cycle time.
//
//  MBT 8/31/16
//
//

module bsg_strobe #(width_p="inv")
   (input clk_i
    , input                reset_r_i
    , input  [width_p-1:0] init_val_r_i
    , output logic strobe_r_o
    );

   localparam debug_lp = 0;

   logic strobe_n;

   logic [width_p-1:0  ] S;
   logic [width_p-1-1:0] C;

   // fast inner loop
   always_ff @(posedge clk_i)
     if (reset_r_i | strobe_n)
       begin
          S <= ~init_val_r_i;  // e.g., 0 --> 111111  (= -1, strobe immediately)
          C <= 0;              //       1 --> 111110  (= -2, strobe next cycle )
       end
     else
       begin
          // this is increment-by-one in carry save representation; i.e. a counter.
          // the "1" is the add by one
          // could be replaced with an array of half adders
          S <= S ^ {C, 1'b1};
          C <= S & {C, 1'b1};
       end

   //
   // we strobe when our CS value reaches -1. In CS representation, -1 iff every bit in C and S are different.
   // Moreover, in our counter representation, we further can show -1 is represented by all S bits being set.
   //

   assign strobe_n = &S;

   always_ff @(posedge clk_i)
     strobe_r_o <= strobe_n;

   if (debug_lp)
     begin : debug
        always @(negedge clk_i)
          if (strobe_n)
            $display("%t (C=%b,S=%b) init_val=%d val(C,S)=%b C^S=%b",$time, C,S,  init_val_r_i, (C << 1)+S, strobe_n);
     end

   always @(negedge clk_i)
     assert((strobe_n === 'X) || strobe_n == & ((C << 1) ^ S))
       else $error("## faulty assumption about strobe signal in %m", C,S, strobe_n);

endmodule
