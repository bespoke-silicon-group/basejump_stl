//====================================================================
// test_bsg.v
// 11/15/2016, shawnless.xie@gmail.com
//====================================================================
//
`define RANDOM_TEST 1

`ifdef RANDOM_TEST
    `define NUM     100000
`else
    `define NUM     4
`endif

`define WIDTH   32
`define SIGN
`define UNSIGN

module test_bsg;
   reg reset;
   reg clk;

   integer i,j;

   logic v_i, ready_o, v_o;
   logic gets_high_part;
   logic signed_opA,signed_opB;

   logic [`WIDTH-1:0]  result_o;

   logic [`WIDTH-1:0]           opA_i,     opB_i;
   logic [`WIDTH-1:0]           expect_result;
   logic signed [`WIDTH-1:0]  s_expect_result;

   logic signed [`WIDTH*2-1:0]  s_full_result;
   logic        [`WIDTH*2-1:0]  full_result;

`ifndef  RANDOM_TEST
   logic [`WIDTH-1:0]  opA [0:`NUM-1] = {32'h0000_0000, 32'h0000_0001, 32'h8000_8000, 32'hFFFF_FFFF};
   logic [`WIDTH-1:0]  opB [0:`NUM-1] = {32'h8000_0000, 32'h0000_0011, 32'h0000_0011, 32'hFFFF_FFFF};
`endif

   bsg_imul_iterative #(.width_p( `WIDTH )) dut (
     .clk_i  ( clk)
    ,.reset_i    ( reset  )

    ,.v_i      ( v_i  )//there is a request
    ,.ready_o  ( ready_o)//idiv is idle

    ,.opA_i    ( opA_i )
    ,.opB_i    ( opB_i )
    ,.signed_opA_i( signed_opA )
    ,.signed_opB_i( signed_opB )
    ,.gets_high_part_i( gets_high_part )

    ,.v_o      ( v_o   )//result is valid
    ,.result_o ( result_o )
    ,.yumi_i  ( v_o   )
    );

   initial clk = 0;
   initial reset = 1;
   initial #15 reset = 0;
   always  #10 clk = ~clk;

   initial #25 begin
   for(j=0; j< 2; j++) begin
      //get_hight parts or low parts
      if(j==0) gets_high_part = 1'b0;
      else     gets_high_part = 1'b1;

      for (i=0; i<`NUM; i=i+1) begin
             // do the signed case
             `ifdef SIGN
             wait (ready_o == 1);
                `ifdef RANDOM_TEST
                    opA_i  = $random;
                    opB_i  = $random;
                `else
                    opA_i  = opA[i];
                    opB_i  = opB[i];
                `endif
             signed_opA = 1'b1;
             signed_opB = 1'b1;

             v_i    = 1;
             wait (ready_o == 0);
             v_i    = 0;
             wait (v_o     == 1);

             s_full_result   = $signed(opA_i) * $signed(opB_i);
             if( gets_high_part) s_expect_result = s_full_result[`WIDTH+:`WIDTH];
             else                s_expect_result = s_full_result[0+:     `WIDTH];

             if ( result_o  !=  s_expect_result ) begin
                $display("----------- ERROR in signed mul -----------");
                if(gets_high_part) $display("      High part test     ");
                else               $display("      Low  part test     ");
                $display("opA:     0x%x  (%d)",  opA_i, $signed(opA_i));
                $display("opB:     0x%x  (%d)",  opB_i, $signed(opB_i) );
                $display("result:  0x%x  (%d),expect 0x%x", result_o, result_o, s_expect_result);
             end

            `endif

             // do the unsigned case
            `ifdef UNSIGN
             wait (ready_o == 1);
                `ifdef RANDOM_TEST
                    opA_i  = $random;
                    opB_i  = $random;
                `else
                    opA_i  = opA[i];
                    opB_i  = opB[i];
                `endif
             signed_opA = 1'b0;
             signed_opB = 1'b0;

             v_i    = 1;
             wait (ready_o == 0);
             v_i    = 0;
             wait (v_o     == 1);

             full_result   = opA_i  *  opB_i;
             if( gets_high_part) expect_result = full_result[`WIDTH+:`WIDTH];
             else                expect_result = full_result[0+:     `WIDTH];

             if ( result_o  !=  expect_result ) begin
                $display("----------- ERROR in unsigned mul -----------");
                if(gets_high_part) $display("      High part test     ");
                else               $display("      Low  part test     ");
                $display("opA:     0x%x  (%d)",   opA_i, opA_i);
                $display("opB:     0x%x  (%d)",  opB_i, opB_i );
                $display("result:  0x%x  (%d),expect 0x%x", result_o, result_o, expect_result);
             end
            `endif

        end //end for( i=0 )
    end // end for( j=0 )
      #80 $finish;
  end //end initial

endmodule
