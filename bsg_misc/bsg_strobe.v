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
// FIXME (bug found by Yichao Wu): does not handle case of width_p=1
//

`include "bsg_defines.v"

module bsg_strobe #(width_p="inv"
                    ,harden_p=0)
   (input clk_i
    , input                reset_r_i
    , input  [width_p-1:0] init_val_r_i
    , output logic strobe_r_o
    );

   localparam debug_lp = 0;

   logic strobe_n, strobe_n_buf;

   logic [width_p-1:0  ] S_r, S_n, S_n_n,C_n_prereset;
   logic [width_p-1-1:0] C_r, C_n;

   wire new_val = reset_r_i | strobe_n;

   bsg_dff #(.width_p(width_p-1)
             ,.harden_p(harden_p)
             ,.strength_p(2)
             ) C_reg
     (.clk_i (clk_i)
      ,.data_i (C_n  )
      ,.data_o (C_r  )
      );

   // complement of new sum bit
   //   assign  S_n = ~ (S_r ^ {C_r, 1'b1} );

   bsg_xnor #(.width_p(width_p),.harden_p(1)) xnor_S_n
     (.a_i(S_r),.b_i({C_r,1'b1}),.o(S_n));

   // A B S0 Y
   bsg_muxi2_gatestack #(.width_p(width_p),.harden_p(1)) muxi2_S_n
     (.i0(S_n)              //i2 == 0 (complement of sum bit)
      , .i1(init_val_r_i)   //i2 == 1   // note: implicitly, this is getting inverted
                                        // which is what we want -- we want to take the complement of init_val_r_i
      , .i2( {width_p {new_val} })
      ,.o(S_n_n)            // final sum bit, after reset
      );

   // when we receive a new value; we load sum bits with the init value
   bsg_dff #(.width_p(width_p)
             ,.harden_p(harden_p)
             ,.strength_p(4) // need some additional power on this one
             ) S_reg
     (.clk_i(clk_i)
      ,.data_i(S_n_n)
      ,.data_o(S_r)
      );

   // increment-by-one in carry-save representation (i.e. a counter)
   // the "1" is add by one.
   // implementable with an array of half-adders

   bsg_nand #(.width_p(width_p),.harden_p(1)) nand_C_n
     (.a_i(S_r)
      ,.b_i({C_r,1'b1})
      ,.o(C_n_prereset) // lo true
      );

   // this implements reset. if any of the three conditions
   // are true, then the carry is zerod:
   // 1. strobe is asserted
   // 2. reset is asserted
   // 3. C_nprereset (lo true) is asserted

   bsg_nor3 #(.width_p(width_p-1),.harden_p(1)) nor3_C_n
     (.a_i ({ (width_p-1)  {strobe_n_buf} })
      ,.b_i(C_n_prereset[0+:width_p-1])
      ,.c_i({ (width_p-1)  {reset_r_i}})
      ,.o  (C_n)
      );


   // we strobe when our CS value reaches -1. In CS representation, -1 iff every bit in C and S are different.
   // Moreover, in our counter representation, we further can show -1 is represented by all S bits being set.

   bsg_reduce #(.and_p(1)
                ,.harden_p(1)
                ,.width_p(width_p)
                ) andr
     (.i(S_r)
      ,.o(strobe_n)
      );

   // DC/ICC botches the buffering of this signal so we give it some help
   bsg_buf #(.width_p(1)) strobe_buf_gate
   (.i(strobe_n)
    ,.o(strobe_n_buf)
    );

   always_ff @(posedge clk_i)
     strobe_r_o <= strobe_n_buf;

   // synopsys translate_off
   if (debug_lp)
     begin : debug
        always @(negedge clk_i)
//          if (strobe_n)
            $display("%t (C=%b,S=%b) reset_r_i=%d new_val=%b init_val=%d val(C,S)=%b C^S=%b",$time
                     ,  C_r,S_r, reset_r_i, new_val, init_val_r_i, (C_r << 1)+S_r, strobe_n);
     end
   // synopsys translate_on


   // synopsys translate_off
   always @(negedge clk_i)
     assert((strobe_n === 'X) || strobe_n == & ((C_r << 1) ^ S_r))
       else $error("## faulty assumption about strobe signal in %m (C_r=%b, S_r=%b, strobe_n=%b)", C_r,S_r, strobe_n);
   // synopsys translate_on

endmodule
