`include "bsg_defines.sv"


module testbench();

  // Clock gen and reset;
  bit clk, reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(10)
  ) cg0 (.o(clk)); 


  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(4)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );
  


  // Parameters;
  localparam width_p = 7;


  // Random number DPI;
  import "DPI-C" context function int get_random_binary();

  
  // DUT;
  logic [width_p-1:0][width_p-1:0] reqs_r, grants_lo;
  logic yumi_li;

  bsg_alloc_wavefront #(
    .width_p(width_p)
  ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.reqs_i(reqs_r)
    ,.grants_o(grants_lo)

    ,.yumi_i(yumi_li)
  );

  assign yumi_li = 1'b1;

  always_ff @ (posedge clk) begin
    if (reset) begin
      reqs_r <= '0;
    end
    else begin
      for (integer i = 0; i < width_p; i++) begin
        for (integer j = 0; j < width_p; j++) begin
          reqs_r[i][j] <= get_random_binary();
        end
      end
    end
  end

  
  // cycle counter;
  integer ctr_r;
  bsg_cycle_counter #(
    .width_p(32)
  ) cc0 (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.ctr_r_o(ctr_r)
  );

  initial begin
    wait(ctr_r == 100000);
    $finish();
  end


  // transpose grants_lo;
  logic [width_p-1:0][width_p-1:0] grants_lo_tp;
  bsg_transpose #(
    .width_p(width_p)
    ,.els_p(width_p)
  ) tp0 (
    .i(grants_lo)
    ,.o(grants_lo_tp)
  );
  

  // assertion;;
  always_ff @ (negedge clk) begin
    if (~reset) begin
      // Assert #1;
      for (integer i = 0; i < width_p; i++) begin
        for (integer j = 0; j < width_p; j++) begin
          if (grants_lo[i][j]) begin
            assert(reqs_r[i][j]) else $error("(%0d, %0d) grants=1, but req=0.", i, j);
          end
        end
      end

      // Assert #2;
      for (integer i = 0; i < width_p; i++) begin
        assert($countones(grants_lo[i]) < 2) else $error("Found more than one grant in row %d", i);
      end

      // Assert #3;
      for (integer i = 0; i < width_p; i++) begin
        assert($countones(grants_lo_tp[i]) < 2) else $error("Found more than one grant in column %d", i);
      end

    end
  end


endmodule
