
module testbench;


`include "test_bsg_clock_params.v"

   localparam cycle_time_lp = 20;

   wire clk;
   wire reset;
   localparam width_lp = 16;

   localparam els_lp = 4;

   bsg_nonsynth_clock_gen #(.cycle_time_p(cycle_time_lp)) clock_gen
   (.o(clk));

   bsg_nonsynth_reset_gen #(.reset_cycles_lo_p(5)
                           ,.reset_cycles_hi_p(5)
                           ) reset_gen
     (.clk_i(clk)
      ,.async_reset_o(reset)
      );

   logic [width_lp-1:0] test_data_in, test_data_out, test_data_check;
   wire test_valid_in, test_valid_out, test_ready_out, test_ready_in;

   logic [31:0] ctr;

   bsg_cycle_counter counter (.clk_i(clk)
                              ,.reset_i(reset)
                              ,.ctr_r_o(ctr)
                              );

   // *******************************************************
   // ** generate pattern of valids

   localparam pattern_width_lp = 20;
   wire [$clog2(pattern_width_lp)-1:0] pattern_bit;
   logic [pattern_width_lp-1:0]                test_pattern, test_pattern_r;

   bsg_circular_ptr #(.slots_p(1 << pattern_width_lp)
                      ,.max_add_p(1)
                      ) seq
     (.clk(clk)
      ,.reset_i(reset)
      ,.add_i  (pattern_bit == (pattern_width_lp-1))
      ,.o      (test_pattern)
      );

   // cycles through each bit of the battern
   bsg_circular_ptr #(.slots_p(pattern_width_lp)
                      ,.max_add_p(1)
                      ) sequ
     (.clk(clk)
      ,.reset_i(reset)
      ,.add_i  (1'b1)
      ,.o      (pattern_bit)
      );

   assign test_valid_in = test_pattern[pattern_bit];

   // our readies will be reflected and inverted
   assign test_ready_in = ~test_pattern[pattern_width_lp-pattern_bit-1];

   // end generate pattern of valids
   // *******************************************************


   // *******************************************************
   // generate data
   bsg_circular_ptr #(.slots_p(1 << width_lp)
                      ,.max_add_p(1)
                      ) gen
   (.clk(clk)
    ,.reset_i(reset)
    ,.add_i  (test_valid_in & test_ready_out)
    ,.o      (test_data_in)
    );


   // end generate data
   // *******************************************************
   localparam verbose_lp=0;

   always @(posedge clk)
     begin
        if (test_valid_in & test_ready_out & verbose_lp)
          $display("### %x sent     %x   bypass_mode=%x",ctr, test_data_in,fifo.bypass_mode);
     end

   wire test_yumi_in = test_ready_in & test_valid_out;

   bsg_fifo_1r1w_large #(.width_p(width_lp)
                         ,.els_p(els_lp)
                         ) fifo
     (.clk_i(clk)
      ,.reset_i(reset      )

      ,.data_i (test_data_in)
      ,.v_i    (test_valid_in)
      ,.ready_o(test_ready_out)

      ,.v_o    (test_valid_out)
      ,.data_o (test_data_out)
      ,.yumi_i (test_yumi_in) // recycle
      );

   bsg_circular_ptr #(.slots_p   (1 << width_lp)
                      ,.max_add_p(1)
                      ) check
   (.clk(clk)
    ,.reset_i(reset)
    ,.add_i  (test_yumi_in)
    ,.o      (test_data_check)
    );

   always_ff @(posedge clk)
     begin
        test_pattern_r <= test_pattern;

        if (test_yumi_in & ~(|test_pattern) & (&test_pattern_r))
          $finish();
     end

   always @(posedge clk)
     begin
        assert (reset | ((test_yumi_in !== 1'b1) | (test_data_check == test_data_out)))
          else
            begin
               $error("### mismatched value v=%x y=%x ch=%x da=%x reset=%x",test_valid_out, test_yumi_in, test_data_check, test_data_out, reset);
               $finish;
            end
        if (~reset & test_yumi_in === 1'b1)
          if (verbose_lp | ((test_data_out & 16'hffff) == 0))
            $display("### %x received %x (1rw r=%x w=%x f=%x e=%x) pattern=%b storage=%d"
                     , ctr, test_data_out, fifo.big1p.rd_ptr, fifo.big1p.wr_ptr
                     , fifo.big1p.fifo_full, fifo.big1p.fifo_empty, test_pattern, fifo.num_elements_debug);

        if (verbose_lp | 1)
          if (fifo.num_elements_debug > els_lp+6)
            $display("### storing %d els!\n", fifo.num_elements_debug);

        // IMPORTANT TEST: test that the fifo will never register full with less than els_lp
        // elements actually stored.

        if (~test_ready_out & test_valid_in)
	  // mbt: seems like this should be "<" -- so this fifo actually stores N+1 elements?
          if (fifo.num_elements_debug <= els_lp)
            begin
               $display("### %x FAIL BAD FULL %x (1rw r=%x w=%x f=%x e=%x) pattern=%b storage=%d"
                        , ctr, test_data_out, fifo.big1p.rd_ptr, fifo.big1p.wr_ptr
                        , fifo.big1p.fifo_full, fifo.big1p.fifo_empty, test_pattern, fifo.num_elements_debug);
               $finish;
            end

        // IMPORTANT TEST: test that the fifo will never register empty if there are actually
        // elements stored.
        //
        if (~test_valid_out & (fifo.num_elements_debug != 0))
          begin
             $display("### %x FAIL BAD empty %x (1rw r=%x w=%x f=%x e=%x) pattern=%b storage=%d"
                      , ctr, test_data_out, fifo.big1p.rd_ptr, fifo.big1p.wr_ptr
                      , fifo.big1p.fifo_full, fifo.big1p.fifo_empty, test_pattern, fifo.num_elements_debug);
             $finish;
          end
     end

endmodule

