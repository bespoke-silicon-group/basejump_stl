`define DUT dut.fi32.m32
`define IN_WIDTH_P 32
`define PIPELINE_P 1

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

   localparam in_width_lp     = `IN_WIDTH_P;
   localparam num_inputs_lp   = 2;
   localparam output_width_lp = 64;
   localparam pipeline_lp = `PIPELINE_P;



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
   wire [output_width_lp-1:0] 		 test_output, expected_output;
   logic [output_width_lp-1:0] expected_output_r;

   wire [num_inputs_lp*in_width_lp-1:0]       tip1 = (test_inputs + 1'b1);

   wire signed [num_inputs_lp-1:0][in_width_lp-1:0] signed_inputs = test_inputs;

   // craziness of verilog signed numbers
   wire signed [output_width_lp-1:0] signed_output                  = $signed(signed_inputs[0]) * $signed(signed_inputs[1]);

   assign expected_output = signed_p ? signed_output
                                     : test_inputs[in_width_lp-1:0] * test_inputs[in_width_lp+:in_width_lp];

   // expected output must be delayed for pipelined version.
   if (pipeline_lp)
     begin: fi
        always @(posedge clk)
          begin
             expected_output_r <= expected_output;
          end
     end
   else
     begin: fi
        assign expected_output_r = expected_output;
     end

   always_ff @(posedge clk)
     begin
        // uncomment the below clause to dump out values even when things are correct -- useful for debugging.
        assert (reset || ((test_output == expected_output_r) /* && (test_inputs != 'h36000_0000) */ ) || (^test_inputs) === 'x) // || (^test_output === 'x))
          else
            begin
               $error("mismatch on input %x ==> (%x vs %x (expect) vs %x vs %x)",test_inputs,test_output,expected_output,signed_inputs,signed_output);

`ifdef mul16x16
               $display("%b %b ",  `DUT.gb.booth_dots[17], `DUT.brr1.rof[3].br.rof[5].b4b.dot_vals);
               $display("%b %b ",  `DUT.gb.booth_dots[16], `DUT.brr1.rof[3].br.rof[4].b4b.dot_vals);
               $display("%b %b ",  `DUT.gb.booth_dots[15], `DUT.brr1.rof[3].br.rof[3].b4b.dot_vals);
               $display("%b %b ",  `DUT.gb.booth_dots[14], `DUT.brr1.rof[3].br.rof[2].b4b.dot_vals);
               $display("%b %b ",  `DUT.gb.booth_dots[13], `DUT.brr1.rof[3].br.rof[1].b4b.dot_vals);
               $display("%b %b ",  `DUT.gb.booth_dots[12], `DUT.brr1.rof[3].br.rof[0].b4b.dot_vals);

               $display("%b %b ",  `DUT.gb.booth_dots[11], `DUT.brr1.rof[2].br.rof[5].b4b.dot_vals);
               $display("%b %b %b ", `DUT.gb.booth_dots[10], `DUT.brr1.rof[2].br.rof[4].b4b.dot_vals, `DUT.brr0.rof[3].br.rof[4].b4b.dot_vals);
               $display("%b %b %b ", `DUT.gb.booth_dots[ 9], `DUT.brr1.rof[2].br.rof[3].b4b.dot_vals, `DUT.brr0.rof[3].br.rof[3].b4b.dot_vals);
               $display("%b %b %b ", `DUT.gb.booth_dots[ 8], `DUT.brr1.rof[2].br.rof[2].b4b.dot_vals, `DUT.brr0.rof[3].br.rof[2].b4b.dot_vals);
               $display("%b %b %b ", `DUT.gb.booth_dots[ 7], `DUT.brr1.rof[2].br.rof[1].b4b.dot_vals, `DUT.brr0.rof[3].br.rof[1].b4b.dot_vals);
               $display("%b %b %b ", `DUT.gb.booth_dots[ 6], `DUT.brr1.rof[2].br.rof[0].b4b.dot_vals, `DUT.brr0.rof[3].br.rof[0].b4b.dot_vals);

               $display("%b %b %b ",  `DUT.gb.booth_dots[ 5], `DUT.brr1.rof[1].br.rof[5].b4b.dot_vals, `DUT.brr0.rof[2].br.rof[5].b4b.dot_vals);
               $display("%b %b %b ",  `DUT.gb.booth_dots[ 4], `DUT.brr1.rof[1].br.rof[4].b4b.dot_vals, `DUT.brr0.rof[2].br.rof[4].b4b.dot_vals);
               $display("%b %b %b ",  `DUT.gb.booth_dots[ 3], `DUT.brr1.rof[1].br.rof[3].b4b.dot_vals, `DUT.brr0.rof[2].br.rof[3].b4b.dot_vals);
               $display("%b %b %b ",  `DUT.gb.booth_dots[ 2], `DUT.brr1.rof[1].br.rof[2].b4b.dot_vals, `DUT.brr0.rof[2].br.rof[2].b4b.dot_vals);
               $display("%b %b %b ",  `DUT.gb.booth_dots[ 1], `DUT.brr1.rof[1].br.rof[1].b4b.dot_vals, `DUT.brr0.rof[2].br.rof[1].b4b.dot_vals);
               $display("%b %b %b ",  `DUT.gb.booth_dots[ 0], `DUT.brr1.rof[1].br.rof[0].b4b.dot_vals, `DUT.brr0.rof[2].br.rof[0].b4b.dot_vals);
               $display("  %b %b ", `DUT.brr1.rof[0].br.rof[7].b4b.dot_vals,`DUT.brr0.rof[1].br.rof[7].b4b.dot_vals);
               $display("  %b %b ", `DUT.brr1.rof[0].br.rof[6].b4b.dot_vals,`DUT.brr0.rof[1].br.rof[6].b4b.dot_vals);
               $display("  %b %b ", `DUT.brr1.rof[0].br.rof[5].b4b.dot_vals,`DUT.brr0.rof[1].br.rof[5].b4b.dot_vals);
               $display("  %b %b ", `DUT.brr1.rof[0].br.rof[4].b4b.dot_vals,`DUT.brr0.rof[1].br.rof[4].b4b.dot_vals);
               $display("  %b %b ", `DUT.brr1.rof[0].br.rof[3].b4b.dot_vals,`DUT.brr0.rof[1].br.rof[3].b4b.dot_vals);
               $display("  %b %b ", `DUT.brr1.rof[0].br.rof[2].b4b.dot_vals,`DUT.brr0.rof[1].br.rof[2].b4b.dot_vals);
               $display("  %b %b ", `DUT.brr1.rof[0].br.rof[1].b4b.dot_vals,`DUT.brr0.rof[1].br.rof[1].b4b.dot_vals);
               $display("  %b %b " ,`DUT.brr1.rof[0].br.rof[0].b4b.dot_vals, `DUT.brr0.rof[1].br.rof[0].b4b.dot_vals);
               $display("       %b ", `DUT.brr0.rof[0].br.rof[5].b4b.dot_vals);
               $display("       %b ", `DUT.brr0.rof[0].br.rof[4].b4b.dot_vals);
               $display("       %b ", `DUT.brr0.rof[0].br.rof[3].b4b.dot_vals);
               $display("       %b ", `DUT.brr0.rof[0].br.rof[2].b4b.dot_vals);
               $display("       %b ", `DUT.brr0.rof[0].br.rof[1].b4b.dot_vals);
               $display("       %b ", `DUT.brr0.rof[0].br.rof[0].b4b.dot_vals);

               $display("%b --> %b --> sdn:%b ", `DUT.sdn.x_i, `DUT.sdn.temp_x, `DUT.SDN);
               $display("sdn:%b y_i:%b", `DUT.brr0.rof[0].br.rof[0].b4b.SDN_i,
                        `DUT.brr0.rof[0].br.rof[0].b4b.y_i);
               $display("sdn:%b y_i:%b", `DUT.brr0.rof[0].br.rof[1].b4b.SDN_i,
                        `DUT.brr0.rof[0].br.rof[1].b4b.y_i);
               $display("sdn:%b y_i:%b", `DUT.brr0.rof[0].br.rof[4].b4b.SDN_i,
                        `DUT.brr0.rof[0].br.rof[4].b4b.y_i);
               $display("sdn:%b y_i:%b", `DUT.brr0.rof[0].br.rof[5].b4b.SDN_i,
                        `DUT.brr0.rof[0].br.rof[5].b4b.y_i);
               $display("carries:%b ", `DUT.brr0.carries);
               $display("y_pad  %b y_pad[0:-9] " ,`DUT.brr0.rof[0].br.y_pad,`DUT.brr0.rof[0].br.y_pad[0:-9]);
               $display("y_p  %b " ,`DUT.brr0.rof[0].br.y_p);
               $display("blocks  %b " ,`DUT.brr0.rof[0].br.blocks_p);

               $display("sdn:%b ", `DUT.b_10.rof[0].b4b.SDN_i);
               $display("gb_dots, sdn_i: %b %b", `DUT.gb.booth_dots, `DUT.gb.SDN_i);

               $error("c30   = %b, s30   = %b (c30<<1+s30=%x)",   `DUT.c30,   `DUT.s30,   (`DUT.c30<<1)   + { 1'b0, `DUT.s30 });
               $error("c74   = %x, s74   = %x (c74<<1+s74=%x)",   `DUT.c74,   `DUT.s74,   (`DUT.c74<<1)   + { 1'b0, `DUT.s74 });
               $error("c42s  = %x, s42s  = %x (c42c<<1+c42s=%x)", `DUT.c42_c, `DUT.c42_s, (`DUT.c42_c <<1)+ { 1'b0, `DUT.c42_s});

               $error("gb_c  = %x, gb_s  = %x", `DUT.gb_c, `DUT.gb_s);
               $error("sum_a = %x, sum_b = %x", `DUT.sum_a, `DUT.sum_b);
`else // !`ifdef mul16x16
	       if (pipeline_lp)
		 $display("Warning: pipelining is enabled, and these will be one cycle too late.");

               // mul32x32
               $display("                       %b", `DUT.c30);
               $display("                        %b", `DUT.s30);
               $display("               %b", `DUT.c74);
               $display("                %b", `DUT.s74);
               $display("       %b", `DUT.cB8);
               $display("        %b", `DUT.sB8);
               $display("%b", `DUT.cFC);
               $display(" %b", `DUT.sFC);
               $display(" check:                        %b", ({1'b0, `DUT.c30} << 1) + `DUT.s30);
               $display(" check:                %b", ({1'b0, `DUT.c74} << 1) + `DUT.s74);
               $display(" check:        %b", ({1'b0, `DUT.cB8} << 1) + `DUT.sB8);
               $display(" check:  %b\n", (`DUT.cFC << 1) + `DUT.sFC);


               $display("%b%b", `DUT.c42_01c, {1'b0, `DUT.c30[4:0]});
               $display(" %b%b", `DUT.c42_01s, `DUT.s30[5:0]);

               $display("%b%b", `DUT.c42_23c, {1'b0, `DUT.cB8[4:0]});
               $display(" %b%b", `DUT.c42_23s, `DUT.sB8[5:0]);

               $display("%b%b%b", `DUT.c42_03c, {1'b0, `DUT.c42_01c[6:0]}, {1'b0, `DUT.c30[4:0]});
               $display(" %b%b%b", `DUT.c42_03s, `DUT.c42_01s[7:0], `DUT.s30[5:0]);


               $display("gb_dots: %b", `DUT.gb_dot);

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
               $error("c30   = %b, s30   = %b (c30<<1+s30=%x)",   `DUT.c30,   `DUT.s30,   (`DUT.c30<<1)   + { 1'b0, `DUT.s30 });
               $error("c74   = %x, s74   = %x (c74<<1+s74=%x)",   `DUT.c74,   `DUT.s74,   (`DUT.c74<<1)   + { 1'b0, `DUT.s74 });
               //$error("c42s  = %x, s42s  = %x (c42c<<1+c42s=%x)", `DUT.c42_c, `DUT.c42_s, (`DUT.c42_c <<1)+ { 1'b0, `DUT.c42_s});

               $error("gb_c  = %x, gb_s  = %x", `DUT.gb_c, `DUT.gb_s);
               $error("sum_a = %x, sum_b = %x", `DUT.sum_a, `DUT.sum_b);

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
     (.clk_i(clk)
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
     begin: fi2
        assign test_inputs_raw[0+:modulo_bits_p] = modulo_val_p[0+:modulo_bits_p];
     end

   assign test_inputs = test_inputs_raw;

   bsg_mul_pipelined #(.width_p(in_width_lp)
                       ,.harden_p(1'b1)
                       ,.pipeline_p(pipeline_lp)
                       ) dut
     ( .clock_i(clk)
       ,.en_i(1'b1)
       ,.x_i(test_inputs[          0+:in_width_lp])
       ,.y_i(test_inputs[in_width_lp+:in_width_lp])
       ,.signed_i(signed_p)
       ,.z_o     (test_output)
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
