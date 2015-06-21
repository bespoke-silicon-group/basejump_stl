


module test_bsg;

//`include "test_bsg_clock_params.v"

   //parameter modulo_bits_p = 4;
   parameter modulo_bits_p = 0;
   localparam cycle_time_lp = 1000;

   wire clk;
   wire reset;
//    localparam in_width_lp     = 16;
//   localparam num_inputs_lp   = 2;
//   localparam output_width_lp = 32;

   localparam in_width_lp     = 32;
   localparam num_inputs_lp   = 2;
   localparam output_width_lp = 64;

   logic [output_width_lp-1:0] modulo_val_p;
   logic        signed_p;

   initial begin
      $value$plusargs("modulo_val_p=%d",modulo_val_p);
      $value$plusargs("signed_p=%d",signed_p);
   end

   bsg_nonsynth_clock_gen #(.cycle_time_p(cycle_time_lp)) clock_gen
   (.o(clk));

   bsg_nonsynth_reset_gen #(.reset_cycles_lo_p(5)
                           ,.reset_cycles_hi_p(5)
                           ) reset_gen
     (.clk_i(clk)
      ,.async_reset_o(reset)
      );

   logic [num_inputs_lp*in_width_lp-1:0] test_inputs_raw, test_inputs, test_inputs_r;
   wire [output_width_lp-1:0]     test_output, expected_output;

   wire [num_inputs_lp*in_width_lp-1:0]       tip1 = (test_inputs + 1'b1);

   wire signed [num_inputs_lp-1:0][in_width_lp-1:0] signed_inputs = test_inputs;

   // craziness of verilog signed numbers
   wire signed [output_width_lp-1:0] signed_output                  = $signed(signed_inputs[0]) * $signed(signed_inputs[1]);

   assign expected_output = signed_p ? signed_output
                                     : test_inputs[in_width_lp-1:0] * test_inputs[in_width_lp+:in_width_lp];

   always_ff @(posedge clk)
     begin
	// uncomment the below clause to dump out values even when things are correct -- useful for debugging.
        assert (reset || ((test_output == expected_output) /* && (test_inputs != 'h36000_0000) */ ) || (^test_inputs) === 'x) // || (^test_output === 'x))
          else
            begin
               $error("mismatch on input %x ==> (%x vs %x (expect) vs %x vs %x)",test_inputs,test_output,expected_output,signed_inputs,signed_output);

`ifdef mul16x16
               $display("%b %b ",  dut.gb.booth_dots[17], dut.brr1.rof[3].br.rof[5].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[16], dut.brr1.rof[3].br.rof[4].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[15], dut.brr1.rof[3].br.rof[3].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[14], dut.brr1.rof[3].br.rof[2].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[13], dut.brr1.rof[3].br.rof[1].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[12], dut.brr1.rof[3].br.rof[0].b4b.dot_vals);

               $display("%b %b ",  dut.gb.booth_dots[11], dut.brr1.rof[2].br.rof[5].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[10], dut.brr1.rof[2].br.rof[4].b4b.dot_vals, dut.brr0.rof[3].br.rof[4].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 9], dut.brr1.rof[2].br.rof[3].b4b.dot_vals, dut.brr0.rof[3].br.rof[3].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 8], dut.brr1.rof[2].br.rof[2].b4b.dot_vals, dut.brr0.rof[3].br.rof[2].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 7], dut.brr1.rof[2].br.rof[1].b4b.dot_vals, dut.brr0.rof[3].br.rof[1].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 6], dut.brr1.rof[2].br.rof[0].b4b.dot_vals, dut.brr0.rof[3].br.rof[0].b4b.dot_vals);

               $display("%b %b %b ",  dut.gb.booth_dots[ 5], dut.brr1.rof[1].br.rof[5].b4b.dot_vals, dut.brr0.rof[2].br.rof[5].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 4], dut.brr1.rof[1].br.rof[4].b4b.dot_vals, dut.brr0.rof[2].br.rof[4].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 3], dut.brr1.rof[1].br.rof[3].b4b.dot_vals, dut.brr0.rof[2].br.rof[3].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 2], dut.brr1.rof[1].br.rof[2].b4b.dot_vals, dut.brr0.rof[2].br.rof[2].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 1], dut.brr1.rof[1].br.rof[1].b4b.dot_vals, dut.brr0.rof[2].br.rof[1].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 0], dut.brr1.rof[1].br.rof[0].b4b.dot_vals, dut.brr0.rof[2].br.rof[0].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[7].b4b.dot_vals,dut.brr0.rof[1].br.rof[7].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[6].b4b.dot_vals,dut.brr0.rof[1].br.rof[6].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[5].b4b.dot_vals,dut.brr0.rof[1].br.rof[5].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[4].b4b.dot_vals,dut.brr0.rof[1].br.rof[4].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[3].b4b.dot_vals,dut.brr0.rof[1].br.rof[3].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[2].b4b.dot_vals,dut.brr0.rof[1].br.rof[2].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[1].b4b.dot_vals,dut.brr0.rof[1].br.rof[1].b4b.dot_vals);
               $display("  %b %b " ,dut.brr1.rof[0].br.rof[0].b4b.dot_vals, dut.brr0.rof[1].br.rof[0].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[5].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[4].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[3].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[2].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[1].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[0].b4b.dot_vals);

               $display("%b --> %b --> sdn:%b ", dut.sdn.x_i, dut.sdn.temp_x, dut.SDN);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[0].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[0].b4b.y_i);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[1].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[1].b4b.y_i);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[4].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[4].b4b.y_i);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[5].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[5].b4b.y_i);
               $display("carries:%b ", dut.brr0.carries);
               $display("y_pad  %b y_pad[0:-9] " ,dut.brr0.rof[0].br.y_pad,dut.brr0.rof[0].br.y_pad[0:-9]);
               $display("y_p  %b " ,dut.brr0.rof[0].br.y_p);
               $display("blocks  %b " ,dut.brr0.rof[0].br.blocks_p);

               $display("sdn:%b ", dut.b_10.rof[0].b4b.SDN_i);
               $display("gb_dots, sdn_i: %b %b", dut.gb.booth_dots, dut.gb.SDN_i);

               $error("c30   = %b, s30   = %b (c30<<1+s30=%x)",   dut.c30,   dut.s30,   (dut.c30<<1)   + { 1'b0, dut.s30 });
               $error("c74   = %x, s74   = %x (c74<<1+s74=%x)",   dut.c74,   dut.s74,   (dut.c74<<1)   + { 1'b0, dut.s74 });
               $error("c42s  = %x, s42s  = %x (c42c<<1+c42s=%x)", dut.c42_c, dut.c42_s, (dut.c42_c <<1)+ { 1'b0, dut.c42_s});

               $error("gb_c  = %x, gb_s  = %x", dut.gb_c, dut.gb_s);
               $error("sum_a = %x, sum_b = %x", dut.sum_a, dut.sum_b);
`else // !`ifdef mul16x16
	       // mul32x32
               $display("                       %b", dut.c30);
               $display("                        %b", dut.s30);
               $display("               %b", dut.c74);
               $display("                %b", dut.s74);
               $display("       %b", dut.cB8);
               $display("        %b", dut.sB8);
               $display("%b", dut.cFC);
               $display(" %b", dut.sFC);
	       $display(" check:                        %b", ({1'b0, dut.c30} << 1) + dut.s30);
	       $display(" check:                %b", ({1'b0, dut.c74} << 1) + dut.s74);
	       $display(" check:        %b", ({1'b0, dut.cB8} << 1) + dut.sB8);
	       $display(" check:  %b\n", (dut.cFC << 1) + dut.sFC);


               $display("%b%b", dut.c42_01c, {1'b0, dut.c30[4:0]});
               $display(" %b%b", dut.c42_01s, dut.s30[5:0]);

               $display("%b%b", dut.c42_23c, {1'b0, dut.cB8[4:0]});
               $display(" %b%b", dut.c42_23s, dut.sB8[5:0]);

               $display("%b%b%b", dut.c42_03c, {1'b0, dut.c42_01c[6:0]}, {1'b0, dut.c30[4:0]});
               $display(" %b%b%b", dut.c42_03s, dut.c42_01s[7:0], dut.s30[5:0]);

/*
               $display("%b %b ",  dut.gb.booth_dots[17], dut.brr1.rof[3].br.rof[5].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[16], dut.brr1.rof[3].br.rof[4].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[15], dut.brr1.rof[3].br.rof[3].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[14], dut.brr1.rof[3].br.rof[2].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[13], dut.brr1.rof[3].br.rof[1].b4b.dot_vals);
               $display("%b %b ",  dut.gb.booth_dots[12], dut.brr1.rof[3].br.rof[0].b4b.dot_vals);

               $display("%b %b ",  dut.gb.booth_dots[11], dut.brr1.rof[2].br.rof[5].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[10], dut.brr1.rof[2].br.rof[4].b4b.dot_vals, dut.brr0.rof[3].br.rof[4].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 9], dut.brr1.rof[2].br.rof[3].b4b.dot_vals, dut.brr0.rof[3].br.rof[3].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 8], dut.brr1.rof[2].br.rof[2].b4b.dot_vals, dut.brr0.rof[3].br.rof[2].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 7], dut.brr1.rof[2].br.rof[1].b4b.dot_vals, dut.brr0.rof[3].br.rof[1].b4b.dot_vals);
               $display("%b %b %b ", dut.gb.booth_dots[ 6], dut.brr1.rof[2].br.rof[0].b4b.dot_vals, dut.brr0.rof[3].br.rof[0].b4b.dot_vals);

               $display("%b %b %b ",  dut.gb.booth_dots[ 5], dut.brr1.rof[1].br.rof[5].b4b.dot_vals, dut.brr0.rof[2].br.rof[5].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 4], dut.brr1.rof[1].br.rof[4].b4b.dot_vals, dut.brr0.rof[2].br.rof[4].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 3], dut.brr1.rof[1].br.rof[3].b4b.dot_vals, dut.brr0.rof[2].br.rof[3].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 2], dut.brr1.rof[1].br.rof[2].b4b.dot_vals, dut.brr0.rof[2].br.rof[2].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 1], dut.brr1.rof[1].br.rof[1].b4b.dot_vals, dut.brr0.rof[2].br.rof[1].b4b.dot_vals);
               $display("%b %b %b ",  dut.gb.booth_dots[ 0], dut.brr1.rof[1].br.rof[0].b4b.dot_vals, dut.brr0.rof[2].br.rof[0].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[7].b4b.dot_vals,dut.brr0.rof[1].br.rof[7].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[6].b4b.dot_vals,dut.brr0.rof[1].br.rof[6].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[5].b4b.dot_vals,dut.brr0.rof[1].br.rof[5].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[4].b4b.dot_vals,dut.brr0.rof[1].br.rof[4].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[3].b4b.dot_vals,dut.brr0.rof[1].br.rof[3].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[2].b4b.dot_vals,dut.brr0.rof[1].br.rof[2].b4b.dot_vals);
               $display("  %b %b ", dut.brr1.rof[0].br.rof[1].b4b.dot_vals,dut.brr0.rof[1].br.rof[1].b4b.dot_vals);
               $display("  %b %b " ,dut.brr1.rof[0].br.rof[0].b4b.dot_vals, dut.brr0.rof[1].br.rof[0].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[5].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[4].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[3].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[2].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[1].b4b.dot_vals);
               $display("       %b ", dut.brr0.rof[0].br.rof[0].b4b.dot_vals);

//             $display("%b --> %b --> sdn:%b ", dut.sdn.x_i, dut.sdn.temp_x, dut.SDN);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[0].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[0].b4b.y_i);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[1].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[1].b4b.y_i);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[4].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[4].b4b.y_i);
               $display("sdn:%b y_i:%b", dut.brr0.rof[0].br.rof[5].b4b.SDN_i,
                        dut.brr0.rof[0].br.rof[5].b4b.y_i);
               $display("carries:%b ", dut.brr0.carries);
               $display("y_pad  %b y_pad[0:-9] " ,dut.brr0.rof[0].br.y_pad,dut.brr0.rof[0].br.y_pad[0:-9]);
               $display("y_p  %b " ,dut.brr0.rof[0].br.y_p);
               $display("blocks  %b " ,dut.brr0.rof[0].br.blocks_p);

               //$display("sdn:%b ", dut.b_10.rof[0].b4b.SDN_i);
               $display("gb_dots, sdn_i: %b %b", dut.gb.booth_dots, dut.gb.SDN_i);
*/
               $error("c30   = %b, s30   = %b (c30<<1+s30=%x)",   dut.c30,   dut.s30,   (dut.c30<<1)   + { 1'b0, dut.s30 });
               $error("c74   = %x, s74   = %x (c74<<1+s74=%x)",   dut.c74,   dut.s74,   (dut.c74<<1)   + { 1'b0, dut.s74 });
               //$error("c42s  = %x, s42s  = %x (c42c<<1+c42s=%x)", dut.c42_c, dut.c42_s, (dut.c42_c <<1)+ { 1'b0, dut.c42_s});

               $error("gb_c  = %x, gb_s  = %x", dut.gb_c, dut.gb_s);
               $error("sum_a = %x, sum_b = %x", dut.sum_a, dut.sum_b);

`endif
               $finish;
            end

        test_inputs_r <= test_inputs_raw;

        if ((test_inputs_raw & 20'hFFFF0) == 0)
            $display("%x->%x",test_inputs, test_output);

	// if (~(test_inputs_raw[in_width_lp*num_inputs_lp-1]) & (test_inputs_r[in_width_lp*num_inputs_lp-1]))
        //  $finish();
     end
/*
   bsg_cycle_counter #(.width_p(in_width_lp*num_inputs_lp-modulo_bits_p)) bcc
     (.clk(clk)
      ,.reset_i(reset)
      ,.ctr_r_o(test_inputs_raw[modulo_bits_p+:in_width_lp*num_inputs_lp-modulo_bits_p])
      );
*/
   bsg_lfsr #(.width_p(in_width_lp*num_inputs_lp-modulo_bits_p)) blfsr
     (.clk(clk)
      ,.reset_i(reset)
      ,.yumi_i(1'b1)
      ,.o(test_inputs_raw[modulo_bits_p+:in_width_lp*num_inputs_lp-modulo_bits_p])
      );

   if (modulo_bits_p != 0)
     begin: fi
        assign test_inputs_raw[0+:modulo_bits_p] = modulo_val_p[0+:modulo_bits_p];
     end

   assign test_inputs = test_inputs_raw;

   bsg_mul_32_32 #(.width_p(in_width_lp)
		   ,.harden_p(1'b1)) dut
     ( .x_i(test_inputs[0+:in_width_lp]          )
      ,.y_i(test_inputs[in_width_lp+:in_width_lp])
      ,.signed_i(signed_p)
      ,.z_o(test_output)
      );
/*
   bsg_nonsynth_ascii_writer
     #(.width_p(in_width_lp)
       ,.values_p(6)
       ,.filename_p("output.log")
       ,.fopen_param_p("w")
       ,.format_p("%x  ")
       ) ascii_writer
   (.clk     (clk)
    ,.reset_i(reset)
    ,.valid_i(1'b1)
    ,.data_i ({ test_output,
                expected_output,
                test_inputs
                }
              )
    );
*/
endmodule

