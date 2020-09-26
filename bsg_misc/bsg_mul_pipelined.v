// bsg_mul_pipelined
//
//
// 5-24-15 MBT
//
//
// This implements a radix-4 booth-encoded multiplier with 4:2 tree,
// followed by a final carry propagate add.
//
// If you all you need is a simple multiply, you might be able
// to get away with the verilog operator "*". This version is
// for when you want something special that you can hack.

// In particular, this implementation breaks the multiplier down
// into "_hard" blocks that substitute in for structured portions
// of the multiplier in ASIC processes. We make use of the
// rp_groups infrastructure in IC compiler, but other
// infrastructures could also easily work.
//
// The algorithm is from West and Harris 4th edition Figs 11.82,
// Fig 11.83, Fig 11.89a, and 11.91, but we generalize to allow
// for an input to determine signed/unsigned.
//
// For now, multiplier implementations are hard-coded to commonly
// used sizes; e.g. 32-bit and 16-bit.
//
// To implement a new size, you reuse the building block routines:
//   bsg_mul_SDN: generates the booth encoded version of the input x_i
//   bsg_mul_B4B_rep_rep: handles 4 rows of the mult. partial products
//   bsg_mul_comp42_rep_rep: 4:2 compressor; combines output
//                           of bsg_mul_B4B_rep_rep at leaves
//                           and other bsg_mul_comp42_rep_rep
//                           as you go up the tree.
//   bsg_mul_green_block: handles last, odd row of the pp's
//                        necessary to support unsigned multiplies.
//                        (the term green block is nonstandard.)
//
//  It still requires some thought, and construction of a
//  "dot diagram", with 4:2 compressors in place is essential
//  for getting it right.

// See MBT's detailed notes in Computer Arithmetic Google Doc for more
//
// TODO: Nested modules are not supported in 2014 VCS, so we have to
// preface everything with bsg_mul. One day we can put this in a
// nested module or augmented package interface.
//

`include "bsg_defines.v"

`ifndef BSG_MUL_BOOTH_DOT_
`define BSG_MUL_BOOTH_DOT_
function automatic [0:0] bsg_mul_booth_dot([2:0] sdn, y0, ym1);
  return ((sdn[2] & y0) | (sdn[1] & ym1)) ^ sdn[0];
endfunction
`endif

// The parameter harden_p is whether you want to invoke
// the foundry_specific routines.

// pass in 0 for pipeline_ if you want unpipelined.

module bsg_mul_pipelined #(parameter width_p="inv"
                           , parameter pipeline_p=1
                           , parameter harden_p  =1
                           )
   (  input clk_i
    , input en_i
    , input   [width_p-1:0] x_i
    , input [width_p-1:0] y_i
    , input signed_i   // signed multiply
    , output [width_p*2-1:0] z_o
    );

   if (width_p == 32)
     begin: fi32
        bsg_mul_32_32 #(.harden_p(harden_p), .pipeline_p(pipeline_p)) m32 (.*);
     end
   else if (width_p == 16)
     begin: fi16
        bsg_mul_16_16 #(.harden_p(harden_p)) m16 (.*);
     end
   else initial assert ("width" == "unhandled") else $error("unhandled case for %m");

endmodule // bsg_mul

module bsg_mul_32_32 #(parameter harden_p=0, pipeline_p=0)
   (  input clk_i
    , input en_i
    , input   [31:0] x_i
    , input [31:0] y_i
    , input signed_i   // signed multiply
    , output [63:0] z_o
    );

   localparam width_lp = 32;

   localparam pp_lp = width_lp/2+1;

   wire [pp_lp-1:0][2:0] SDN;

   // booth encoding
   bsg_mul_SDN #(.width_p(width_lp)) sdn (.x_i, .signed_i, .SDN_o(SDN));

   // all of results of groups of 4 rows of the multiplier
   // the numbers for the bit widths indicate the size of each
   // block. we partion the array into a bunch of equal sized
   // blocks that allow for alignment in rp_groups.

   wire [      6+5+8+8+8+6-1:0]  c30, s30;    // 40:0
   wire [  1+8+6+5+8+8+8  -1:0]  c42_01c, c42_01s; //42:0->43:0 +1 is for dealing greendots
   wire [    8+6+5+8+8+8  -1:0]  c74, s74;    // 42:0
   wire [7+8+8+6+5+8+8    -1:0]  c42_03c, c42_03s;   // 57:0
   wire [  8+8+6+5+8+8    -1:0]  cB8, sB8;    // 42:0
   wire [7+8+8+6+5+8      -1:0]  c42_23c, c42_23s; //49:0
   wire [7+8+8+6+5+8      -1:0]  cFC, sFC;    // 41:0

   wire [3:0][3:0] cl;

   wire [2:0] 	   verify_zero;

   always @(verify_zero)
     assert (|verify_zero != 1'b1) else $error("unexpected carry in bsg_mul_32_32 %b", verify_zero);

   // hint: you read these strings right off of the "dot diagram"
   // the infrastructure (plus tweaking the 4:2 tree) does the rest!

   // handle first four rows of partial products

   bsg_mul_B4B_rep_rep
     #(.blocks_p      (6)
       ,.width_p      (41)   // is this correct?
       //  6    5    8    8  8   6
       // 41 35   30   22  14  6  0
       ,.group_vec_p  (56'h29_23_1e_16_0e_06_00)
       ,.y_p          (0)
       ,.y_size_p     (32)
       ,.S_above_vec_p(164'b0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_1000_0000_0100_0000_0010)
       ,.dot_bar_vec_p(164'b0000_1000_0000_0100_0000____0011_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000)
       ,.B_vec_p      (164'b0111_0111_0011_0011_0001____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____1000_0000_1100_1000_1110_1100)
       ,.one_vec_p    (164'b1000_0000_0100_0000_0010____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000)
       ,.harden_p(harden_p)
       ) brr0
       (.SDN_i({SDN[3:0],3'b000}), .y_i, .cr_i(1'b0), .cl_o(verify_zero[0]), .c_o(c30 [40 :0]), .s_o(s30[40:0]), .signed_i);


   wire [7+8+8+11-1:0] gb_c, gb_s, gb_dot; // 34 bits

   // a little bit out of order with respect to the diagram;
   bsg_mul_green_booth_dots #(.width_p(32)
                              ,.blocks_p(5)
                              //   7   8    8   6   5
                              //34  27   19  11   5   0
                              //22  1B   13  0B  05  00
                              ,.group_vec_p(48'h22_1B_13_0B_05_00)
                              ,.harden_p(harden_p)
                              ) gbd
     (.SDN_i (SDN[16:15])
      ,.y_i  (y_i       )
      ,.dot_o(gb_dot    )
      );


   wire 	       crr01_cl_o_tmp;

   // 43, 35, 29, 24, 16, 8, 0
   bsg_mul_comp42_rep_rep #(.blocks_p(6), .group_vec_p(56'h2b_23_1D_18_10_08_00),. width_p(43)) crr01
     (.i({   {c74[41:0], 1'b0} // note: gotta track c74[42]
           ,  s74[42:0]
           , {7'b0, c30[40:5]}
//           , {8'b0, s30[40:6]} -- incorporate gb early to reduce # of pipeline registers
           , {gb_dot[18:11], s30[40:6]}
           }
         )
      ,.cr_i(1'b0          )
      ,.cl_o(crr01_cl_o_tmp)
      ,.c_o(c42_01c[42:0]  )
      ,.s_o(c42_01s[42:0]  )
      );

   // merge in greendot and carry left with half adder.
   assign c42_01c[43] = gb_dot[19] & crr01_cl_o_tmp;
   assign c42_01s[43] = gb_dot[19] ^ crr01_cl_o_tmp;

// handle second four rows of partial products

   bsg_mul_B4B_rep_rep
     #(.blocks_p      (6)
       ,.width_p      (43)   // is this correct?
       //   8 6 5  8   8  8
       // 43 35 29  24 16   8  0
       // 2B 23 1D  18 10   8  0
       ,.group_vec_p  (56'h2b_23_1D_18_10_08_00)
       ,.y_p          (-2)
       ,.y_size_p     (32)
       ,.S_above_vec_p(172'b0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000__0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_1000_0000_0100_0000_0010_0000_0001)
       ,.dot_bar_vec_p(172'b0000_1000_0000_0100_0000_0010_0000_0001____0000_0000_0000_0000_0000_0000__0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.B_vec_p      (172'b0111_0111_0011_0011_0001_0001_0000_0000____0000_0000_0000_0000_0000_0000__0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____1000_0000_1100_1000_1110_1100_1111_1110)
       ,.one_vec_p    (172'b1000_0000_0100_0000_0010_0000_0001_0000____0000_0000_0000_0000_0000_0000__0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.harden_p(harden_p)
       ) brr1
       (.SDN_i(SDN[7:3]), .y_i, .cr_i(1'b0), .cl_o(verify_zero[1]), .c_o(c74 [42 :0]), .s_o(s74[42:0]), .signed_i);

   // this is the big one
   // block sizes:     7,  8,  8,  11,  8,  8
   // block sizes:     7,  8,  8,  6   5,  8,  8
   //              50,   43, 35, 27, 21  16,  8,  0
   //               32, 2b, 23,  1b, 15  10,  8,  0
   //
   bsg_mul_comp42_rep_rep #(.blocks_p(7), .group_vec_p(64'h32_2b_23_1b_15_10_08_00),. width_p(50)) crr03
     (.i({   {c42_23c   [40:0], 1'b0, cB8[6:0], 1'b0}
             , {c42_23s[41:0],    sB8[7:0]      }
             , {13'b0, c42_01c[43:7]}
//             , {15'b0, c42_01s[42:8]}
// we add gb_dot in here because there is space
// and when we pipeline we will need fewer registers this way

             , {gb_dot[33:20], c42_01s[43:8]}
             }
         )
      ,.cr_i(1'b0)
      ,.cl_o() // a carry out here is okay, it just falls off the end.
      ,.c_o(c42_03c[49:0])
      ,.s_o(c42_03s[49:0])
      );

   logic [49:0]                c42_03c_r, c42_03s_r;

   if (pipeline_p)
     begin : pipe
        logic [49:0][1:0] c42_03_trans, c42_03_trans_r;

        // we transpose the bits (basically zippering them)
        // so that carry bits and sum bits are stored near each other
        // in a vertical column that pitch-matches the 4:2 compressor stack
        bsg_transpose #(.width_p(50),.els_p(2)) bt (.i({c42_03c, c42_03s}), .o(c42_03_trans) );

        bsg_dff_en_rep_rep #(.blocks_p(7)
                             ,.width_p(50*2)
                             // mirrors crr03 comp42_rep_rep above
                             // everything is twice as wide because of the zippering

                             ,.group_vec_p((64'h32_2b_23_1b_15_10_08_00 << 1))
                             ,.harden_p(harden_p)
                     )
        dffe_c42_03_r (.clk_i
                       ,.en_i
                       ,.data_i(c42_03_trans)
                       ,.data_o(c42_03_trans_r)
                       );

        bsg_transpose #(.width_p(2),.els_p(50))
	bt2 (  .i(c42_03_trans_r ) ,.o({c42_03c_r      , c42_03s_r}) );

     end
   else
     begin: unpipe
        assign c42_03c_r = c42_03c;
        assign c42_03s_r = c42_03s;
     end

   // handle third four rows of partial products; this is mostly the same as the second row, but with two sub blocks flipped

   bsg_mul_B4B_rep_rep
     #(.blocks_p      (6)
       ,.width_p      (43)   // is this correct?
       //   8  8  6  5   8  8
       // 43 35 27 21  16   8  0
       // 2B 23 1B 15  10   8  0
       ,.group_vec_p  (56'h2b_23_1B_15_10_08_00)
       ,.y_p          (-2)
       ,.y_size_p     (32)
       ,.S_above_vec_p(172'b0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_1000_0000_0100_0000_0010_0000_0001)
       ,.dot_bar_vec_p(172'b0000_1000_0000_0100_0000_0010_0000_0001____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.B_vec_p      (172'b0111_0111_0011_0011_0001_0001_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____1000_0000_1100_1000_1110_1100_1111_1110)
       ,.one_vec_p    (172'b1000_0000_0100_0000_0010_0000_0001_0000____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.harden_p(harden_p)
       ) brr2
       (.SDN_i(SDN[11:7]), .y_i, .cr_i(1'b0), .cl_o(verify_zero[2]), .c_o(cB8 [42 :0]), .s_o(sB8[42:0]), .signed_i);



   // 42, 35, 27, 19, 8, 0
   // 42, 35, 27, 19, 13, 8, 0
   bsg_mul_comp42_rep_rep #(.blocks_p(6), .group_vec_p(56'h2a_23_1b_13_0d_08_00),. width_p(42)) crr23
     (.i({   {cFC[40:0], 1'b0}
           ,  sFC[41:0]
           , {6'b0, cB8[42:7]}
           , {7'b0, sB8[42:8]}
           }
         )
      ,.cr_i(1'b0)
      ,.cl_o() // carry here is okay, just falls off the end
      ,.c_o(c42_23c[41:0])
      ,.s_o(c42_23s[41:0])
      );

   // handle fourth four rows of partial products; this is mostly the same as the third row, but with two sub blocks flipped, and the last
   // subblock is shortened because it does not need a final "1".

   bsg_mul_B4B_rep_rep
     #(.blocks_p      (6)
       ,.width_p      (42)   // is this correct?
       //     7 8  8  6    5   8
       // 42 35  27  19 13   8  0
       // 2A 23  1B  13 0d    8  0
       ,.group_vec_p  (56'h2a_23_1B_13_0D_08_00)
       ,.y_p          (-2)
       ,.y_size_p     (32)
       ,.S_above_vec_p(168'b0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____0000_1000_0000_0100_0000_0010_0000_0001)
       ,.dot_bar_vec_p(168'b1000_0000_0100_0000_0010_0000_0001____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.B_vec_p      (168'b0111_0011_0011_0001_0001_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____1000_0000_1100_1000_1110_1100_1111_1110)
       ,.one_vec_p    (168'b0000_0100_0000_0010_0000_0001_0000____0000_0000_0000_0000_0000_0000_0000_0000___0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.harden_p(harden_p)
       ) brr3
       (.SDN_i(SDN[15:11]), .y_i, .cr_i(1'b0)
	, .cl_o()   // carry here is okay, just falls off the end.
	, .c_o(cFC [41 :0]), .s_o(sFC[41:0]), .signed_i);


   wire [10:0] gb_dot_r;
   wire [7:0]  c42_01s_r;
   wire [6:0]  c42_01c_r;
   wire [5:0]  s30_r;
   wire [4:0]  c30_r;

   if (pipeline_p)
     begin: pipe0
        bsg_dff_en #(.width_p(11)
                     ,.harden_p(harden_p)
                     )
        dffe_gb_dot_r (.clk_i
                       ,.en_i
                       ,.data_i(gb_dot[10:0])
                       ,.data_o(gb_dot_r)
                       );

        bsg_dff_en #(.width_p(8)
                     ,.harden_p(harden_p)
                     )
        dffe_c42_01s_r (.clk_i
                        ,.en_i
                        ,.data_i(c42_01s[7:0])
                        ,.data_o(c42_01s_r)
                        );

        bsg_dff_en #(.width_p(7)
                     ,.harden_p(harden_p)
                     )
        dffe_c42_01c_r (.clk_i
                        ,.en_i
                        ,.data_i(c42_01c[6:0])
                        ,.data_o(c42_01c_r)
                        );

        bsg_dff_en #(.width_p(6)
                     ,.harden_p(harden_p)
                     )
        dffe_s30_r (.clk_i
                    ,.en_i
                    ,.data_i(s30[5:0])
                    ,.data_o(s30_r)
                    );

        bsg_dff_en #(.width_p(5)
                     ,.harden_p(harden_p)
                     )
        dffe_c30_r (.clk_i
                    ,.en_i
                    ,.data_i(c30[4:0])
                    ,.data_o(c30_r)
                    );
     end
   else
     begin: unpipe0
        assign gb_dot_r = gb_dot[10:0];
        assign c42_01s_r = c42_01s[7:0];
        assign c42_01c_r = c42_01c[6:0];
        assign s30_r = s30[5:0];
        assign c30_r = c30[4:0];
     end

   bsg_mul_csa_rep #(.width_p(34)
                     ,.blocks_p(5)
                     //   7   8    8   6   5
                     //34  27   19  11   5   0
                     //22  1B   13  0B  05  00
                     ,.group_vec_p(48'h22_1B_13_0B_05_00)
                     ,.harden_p(harden_p)
                     ) gb
     (
//      .a_i (gb_dot)  -- fold in earlier so that
//                     -- we don't have to register these vals
//        .a_i({15'b0, gb_dot[18:0]})
        .a_i({23'b0, gb_dot_r[10:0]})
        ,.b_i (c42_03s_r[49:16])
        ,.c_i( c42_03c_r[48:15])
        ,.c_o (gb_c)
        ,.s_o (gb_s)
      );

   wire [63:0]        sum_a = {      gb_s[33:0],       c42_03s_r[15:0],       c42_01s_r[7:0],       s30_r[5:0]};
   wire [63:0]        sum_b = {gb_c[32:0], 1'b0, c42_03c_r[14:0], 1'b0, c42_01c_r[6:0], 1'b0, c30_r[4:0], 1'b0};

   // complete adder with propagation
   assign z_o = sum_a + sum_b;

endmodule


module bsg_mul_SDN #(parameter width_p=16,
                     parameter rows_lp=width_p/2+1)
   (input    [width_p-1:0]       x_i
    , input                     signed_i
    , output [rows_lp-1:0][2:0] SDN_o
    );

   // we do not need to signed-extend temp_x on a
   // signed multiply -- it just works out that way.

   wire [width_p+3-1:0] temp_x = { 2'b0, x_i, 1'b0 };

   genvar      i;

   for (i = 0; i < rows_lp; i=i+1)
     begin: rof
        wire [2:0] trip;

        if (i != rows_lp-1)
          begin:fi
             assign trip = temp_x[2*i+2:2*i];
          end
        else
          begin:fi
             // cancel out last row of computation for signed values
             // by setting N, S and D to 0.
             assign trip = temp_x[2*i+2:2*i] & ~{ 3 { signed_i } };
          end

        assign SDN_o[i][0] = trip[2];
        assign SDN_o[i][1] = ((& trip[1:0]) & ~trip[2])
                             | (~(| trip[1:0]) & trip[2])
                             ;
        assign SDN_o[i][2] =  trip[0] ^ trip[1];
     end

endmodule // SDN

// a 16x16 multiplier was not our direct goal
// we used this to debug the content in the Weste 4th ed book
// this size can be exhaustively tested.
// fixme: has not been updated to the same degree as mul_32_32

module bsg_mul_16_16 #(parameter harden_p=0)
   (input   [15:0] x_i
    , input [15:0] y_i
    , input signed_i   // signed multiply
    , output [31:0] z_o
    );

   wire [8:0][2:0] SDN;

   // booth encoding
   bsg_mul_SDN #(.width_p(16)) sdn (.x_i, .signed_i, .SDN_o(SDN));

   wire [24:0]     c30, s30;
   wire [25:0]     c74, s74;

   wire [1:0][3:0] cl;

   wire [2:0] 	   verify_zero;


   // handle first four rows of partial products

   bsg_mul_B4B_rep_rep
     #(.blocks_p      (4)
       ,.width_p      (25)
       // 5 6 8 6
       // 25 20  14 6 0
       // 19 14  e  6 0
       ,.group_vec_p  (40'h19_14_0e_06_00)
       ,.y_p          (0)
       ,.y_size_p     (16)
       ,.S_above_vec_p(100'b0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_1000_0000_0100_0000_0010)
       ,.dot_bar_vec_p(100'b0000_1000_0000_0100_0000____0011_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000)
       ,.B_vec_p      (100'b0111_0111_0011_0011_0001____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____1000_0000_1100_1000_1110_1100)
       ,.one_vec_p    (100'b1000_0000_0100_0000_0010____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000)
       ,.harden_p(harden_p)
       ) brr0
       (.SDN_i({SDN[3:0],3'b000}), .y_i, .cr_i(1'b0), .cl_o(verify_zero[0]), .c_o(c30 [24 :0]), .s_o(s30[24:0]), .signed_i);


   // handle second four rows of partial products


   bsg_mul_B4B_rep_rep
     #(.blocks_p      (4)
       ,.width_p      (26)
       // 6 6 6 8
       // 26 20  14 8 0
       // 1a 14  e  8 0
       ,.group_vec_p  (40'h1a_14_0e_08_00)
       ,.y_p          (-2)
       ,.y_size_p     (16)
       ,.S_above_vec_p(104'b0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000____0000_1000_0000_0100_0000_0010_0000_0001)
       ,.dot_bar_vec_p(104'b1000_0000_0100_0000_0010_0000____0001_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.B_vec_p      (104'b0111_0011_0011_0001_0001_0000____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000____1000_0000_1100_1000_1110_1100_1111_1110)
       ,.one_vec_p    (104'b0000_0100_0000_0010_0000_0001____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000____0000_0000_0000_0000_0000_0000_0000_0000)
       ,.harden_p(harden_p)
       ) brr1
       (.SDN_i({SDN[7:3]}), .y_i, .cr_i(1'b0), .cl_o(verify_zero[1]), .c_o(c74 [25 :0]), .s_o(s74[25:0]), .signed_i);

   // now we merge the two rows of partial products with a single row of 4:2 compressors

   wire [3:0]      ci_local;
   wire [25:0]     c42_c, c42_s;

   // group vec shows where we should segment the CSA's to allow for rp groups 26, 20, 14, 8, 0
   bsg_mul_comp42_rep_rep #(.blocks_p(4), .group_vec_p(40'h1a_14_0e_08_00),. width_p(26)) crr
     (.i({   {c74[24:0], 1'b0}
             ,  s74[25:0]
             , {6'b0, c30[24:5]}
             , {7'b0, s30[24:6]}
             }
         )
      ,.cr_i(1'b0)
      ,.cl_o(verify_zero[2])
      ,.c_o(c42_c[25:0])
      ,.s_o(c42_s[25:0])
      );

   wire [17:0]        gb_c, gb_s;

   bsg_mul_green_block #(.width_p(16)
                         ,.harden_p(harden_p)
                         ) gb
     (
      .SDN_i(SDN[8:7])
      ,.y_i (y_i)
      ,.s_i (c42_s[25:8])
      ,.s2_i(c42_c[24:7])
      ,.c_o (gb_c)
      ,.s_o (gb_s)
      );

   wire [31:0]        sum_a = {      gb_s[17:0],  c42_s[7:0],       s30[5:0]};
   wire [31:0]        sum_b = {gb_c[16:0], 1'b0, c42_c[6:0], 1'b0, c30[4:0], 1'b0};

   // complete adder with propagation
   assign z_o = sum_a + sum_b;

endmodule // muls_16_16

module bsg_mul_csa
     (input x_i
      ,input y_i
      ,input z_i
      ,output c_o
      ,output s_o
      );

     assign {c_o,s_o} = x_i + y_i + z_i;

endmodule


module bsg_dff_en_rep_rep #(parameter blocks_p=0
                            , width_p=0
                            , group_vec_p=0
                            , harden_p=1
                            )
   (input clk_i
    , input en_i
    , input  [width_p-1:0] data_i
    , output [width_p-1:0] data_o
    );

   genvar j;

  for (j = 0; j < blocks_p;j=j+1)
     begin: rof
        localparam group_end_lp   = (group_vec_p >> ((j+1) << 3 )) & 8'hFF;
        localparam group_start_lp = (group_vec_p >> ((j  ) << 3 )) & 8'hFF;
        localparam [31:0] blocks_lp  = group_end_lp-group_start_lp;

        bsg_dff_en #(.width_p(blocks_lp), .harden_p(harden_p)) bde
        (.clk_i
         ,.en_i
         ,.data_i(data_i[group_end_lp-1:group_start_lp])
         ,.data_o(data_o[group_end_lp-1:group_start_lp])
         );
     end

endmodule

//
// this generates blocks of 4:2 compressors, groups
// according to the group vector, which is a set of bytes
//

// i[0] is the fastest input, i[1] next fastest, i[2] next fastest, i[3] slowest.
// so arrange the inputs so that the slowest arriving signal is first, etc.

module bsg_mul_comp42_rep_rep #(parameter blocks_p=0
                                , width_p=0
                                , group_vec_p=0
                                , harden_p=1
                                )

   // we do this so that it is easy to combine vectors of results from blocks
   (input [3:0][width_p-1:0] i
    ,input cr_i
    ,output cl_o
    ,output [width_p-1:0] c_o
    ,output [width_p-1:0] s_o
    );

   genvar j;

   wire [blocks_p:0] carries;

   for (j = 0; j < blocks_p;j=j+1)
     begin: rof
        localparam group_end_lp   = (group_vec_p >> ((j+1) << 3 )) & 8'hFF;
        localparam group_start_lp = (group_vec_p >> ((j  ) << 3 )) & 8'hFF;

        wire [3:0][group_end_lp-group_start_lp-1:0] t;

        assign t[0] = i[0][group_end_lp-1:group_start_lp];
        assign t[1] = i[1][group_end_lp-1:group_start_lp];
        assign t[2] = i[2][group_end_lp-1:group_start_lp];
        assign t[3] = i[3][group_end_lp-1:group_start_lp];

        bsg_mul_comp42_rep #(.blocks_p(group_end_lp-group_start_lp)) cr
          (.i(t)
           ,.cr_i(carries[j]  )
           ,.cl_o(carries[j+1])
           ,.c_o(c_o[group_end_lp-1:group_start_lp])
           ,.s_o(s_o[group_end_lp-1:group_start_lp])
           );
     end

   assign cl_o = carries[blocks_p];
   assign carries[0] = cr_i;

endmodule


module bsg_mul_B4B_rep_rep
  #(parameter blocks_p      =  1
    , parameter width_p     =  0
    , parameter group_vec_p =  0
    , parameter y_p         = "inv"
    , parameter y_size_p    = 16
    , parameter S_above_vec_p = 0
    , parameter dot_bar_vec_p = 0
    , parameter B_vec_p     = 0
    , parameter one_vec_p   = 0
    , parameter harden_p    = 1'b0
    )
   ( input [4:0][2:0] SDN_i
     , input cr_i
     , input [y_size_p-1:0] y_i
     , input signed_i
     , output cl_o
     , output [width_p-1:0] c_o
     , output [width_p-1:0] s_o
     );

   genvar j;

   wire [blocks_p:0] carries;

   for (j = 0; j < blocks_p; j=j+1)
     begin: rof
        localparam group_end_lp      = (group_vec_p >> ((j+1) << 3 )) & 8'hFF;
        localparam group_start_lp    = (group_vec_p >> ((j  ) << 3 )) & 8'hFF;
        localparam [31:0] blocks_lp  = group_end_lp-group_start_lp;


        bsg_mul_B4B_rep
          #(.blocks_p(blocks_lp)
            ,.y_p          (y_p+group_start_lp   )
            ,.y_size_p     (y_size_p             )
            ,.S_above_vec_p(S_above_vec_p[4*group_end_lp-1:4*group_start_lp])
            ,.dot_bar_vec_p(dot_bar_vec_p[4*group_end_lp-1:4*group_start_lp])
            ,.B_vec_p      (B_vec_p      [4*group_end_lp-1:4*group_start_lp])
            ,.one_vec_p    (one_vec_p    [4*group_end_lp-1:4*group_start_lp])
            ,.harden_p (harden_p)
            ) br
          (.SDN_i
           ,.cr_i(carries[j])
           ,.y_i
           ,.signed_i
           ,.cl_o(carries[j+1])
           ,.c_o(c_o[group_end_lp-1:group_start_lp])
           ,.s_o(s_o[group_end_lp-1:group_start_lp])
           );
     end

   assign carries[0] = cr_i;
   assign cl_o = carries[blocks_p];

endmodule

module bsg_mul_B4B_rep #(parameter [31:0] blocks_p=1
                         ,parameter y_p      = "inv"
                         // size is required so VCS does not freak out
                         ,parameter [31:0] y_size_p = 16
                         ,parameter S_above_vec_p=0
                         ,parameter dot_bar_vec_p=0
                         ,parameter B_vec_p=0
                         ,parameter one_vec_p=0
                         ,parameter harden_p=0)
   ( input [4:0][2:0] SDN_i
     , input                 cr_i
     , input [y_size_p-1:0]  y_i
     , input                 signed_i
     , output                cl_o
     , output [blocks_p-1:0] c_o
     , output [blocks_p-1:0] s_o
     );

   genvar i;

   initial assert (y_p != -1) else $error("invalid input for y_p");

   localparam y_shift_p = 2+7;

   // sign extend if signed value
   // wire [16+8:-2-7] y_pad = { 8'b0, y_i, 9'b0 };
   wire [y_size_p+8+y_shift_p:0] y_pad = { { 8 { y_i[y_size_p-1] & signed_i }}, y_i, 9'b0 };

   wire [blocks_p-1:0][3:0][1:0]   y_in;

   for (i = 0; i < blocks_p; i=i+1)
     begin: wiring
        // the localparams are required to overcome some absurdity in VCS
        // where it is using >> 32 bit values to represent the constants
        // and then they are not correctly interpreted as small signed numbers

        localparam [31:0] x7 = y_shift_p+y_p+i-6;
        localparam [31:0] x6 = y_shift_p+y_p+i-6-1;
        localparam [31:0] x5 = y_shift_p+y_p+i-4;
        localparam [31:0] x4 = y_shift_p+y_p+i-4-1;
        localparam [31:0] x3 = y_shift_p+y_p+i-2;
        localparam [31:0] x2 = y_shift_p+y_p+i-2-1;
        localparam [31:0] x1 = y_shift_p+y_p+i;
        localparam [31:0] x0 = y_shift_p+y_p+i-1;
/*
        wire [3:0][1:0]   y_in = {
                                  {y_pad[x7],y_pad[x6]}
                                  , {y_pad[x5],y_pad[x4]}
                                  , {y_pad[x3],y_pad[x2]}
                                  , {y_pad[x1 ],y_pad[x0]}
                                  };
*/


        assign y_in[i][0] = {y_pad[x1], y_pad[x0]};

        assign y_in[i][1] = {y_pad[x3], y_pad[x2]};

        assign y_in[i][2] = {y_pad[x5], y_pad[x4]};

        assign y_in[i][3] = {y_pad[x7], y_pad[x6]};
     end // block: rof

   // this little nugget is what we replace using rp groups

   bsg_mul_booth_4_block_rep #(.blocks_p      (blocks_p)
                               ,.S_above_vec_p(S_above_vec_p)
                               ,.dot_bar_vec_p(dot_bar_vec_p)
                               ,.B_vec_p      (B_vec_p)
                               ,.one_vec_p    (one_vec_p)
                               ) bb4bh
     (.SDN_i
      ,.cr_i
      ,.y_vec_i(y_in)
      ,.cl_o
      ,.c_o
      ,.s_o
      );

endmodule // bsg_mul_B4B_rep


module bsg_mul_csa_rep #(parameter width_p="inv"
                         , blocks_p="inv"
                         , group_vec_p="inv"
                         , harden_p=0)
   ( input  [width_p-1  :0] a_i
     , input  [width_p-1:0] b_i
     , input  [width_p-1:0] c_i
     , output [width_p-1:0] c_o
     , output [width_p-1:0] s_o
     );

   genvar i,j;

   for (j = 0; j < blocks_p; j=j+1)
     begin: rof
        localparam group_end_lp      = (group_vec_p >> ((j+1) << 3 )) & 8'hFF;
        localparam group_start_lp    = (group_vec_p >> ((j  ) << 3 )) & 8'hFF;
        localparam [31:0] blocks_lp  = group_end_lp-group_start_lp;

        for (i = 0; i < blocks_lp; i++)
          begin: rof
             bsg_mul_csa csa (.x_i(a_i[group_start_lp+i]), .y_i(b_i[group_start_lp+i]), .z_i(c_i[group_start_lp+i]), .c_o(c_o[group_start_lp+i]), .s_o(s_o[group_start_lp+i]));
          end
     end

endmodule // bsg_mul_green_block

module bsg_mul_green_booth_dots #(parameter width_p="inv"
                                  , harden_p=0
                                  , blocks_p="inv"
                                  , group_vec_p="inv"
                                 )
   ( input    [1:0][2:0]      SDN_i
     , input  [width_p-1:0]   y_i
     , output [width_p+2-1:0] dot_o
     );

   wire [width_p+2-1:0] y_pad = { y_i, 2'b00 };

   genvar               i,j;

   for (j = 0; j < blocks_p; j=j+1)
     begin: blk
        localparam group_end_lp      = (group_vec_p >> ((j+1) << 3 )) & 8'hFF;
        localparam group_start_lp    = (group_vec_p >> ((j  ) << 3 )) & 8'hFF;
        localparam [31:0] blocks_lp  = group_end_lp-group_start_lp;

        // y_i does not need to be signed extended
        // this is the last row, after all
        // which should not exist for signed version.

        if (j != 0 && harden_p)
          begin: macro
             bsg_and #(.width_p(blocks_lp)
                       ,.harden_p(harden_p)
                       ) ba
             (.a_i  ({blocks_lp { SDN_i[1][2] } }    )
              ,.b_i (y_pad[group_start_lp+:blocks_lp])
              ,.o   (dot_o[group_start_lp+:blocks_lp])
              );
          end
        else
          begin: notmacro
             for (i = 0; i < blocks_lp; i++)
               begin: b

                  if (j == 0 && i == 0)
                    begin :fi
                       assign dot_o[0] = SDN_i[0][0];
                    end
                  else
                    if (j == 0 && i == 1)
                      begin : fi
                         assign dot_o[1] = 1'b0;
                      end
                    else
                      begin: fi
                         // assign dot_o[i] = bsg_booth_dot(SDN_i[1], y_pad[i-1], y_pad[i-2]);
                         // note: we do not need a dot here; as only S value may be set; an AND is sufficient.
                         // fixme: update the diagram.
                         assign dot_o[group_start_lp+i] = SDN_i[1][2] & y_pad[group_start_lp+i];
                      end
               end // block: rof
          end // block: notmacro
     end // block: rof
endmodule
