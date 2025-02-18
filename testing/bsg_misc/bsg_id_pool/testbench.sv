module testbench();

  parameter els_p = 32;
  parameter lg_els_lp = `BSG_SAFE_CLOG2(els_p);

  bit clk;
  bit reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) cg0 (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(8)
  ) rg0 (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

   logic pool_v_lo;
   logic [lg_els_lp-1:0] pool_id_lo;

   logic 		 pool_yumi_li;
   logic 		 pool_dealloc_v_li;
   logic [lg_els_lp-1:0] pool_dealloc_id_li;
   
   bsg_id_pool #(.els_p(els_p)
		) pool
     (.clk_i(clk)
      ,.reset_i(reset)
      
      ,.alloc_id_o  (pool_id_lo)
      ,.alloc_v_o   (pool_v_lo)
      ,.alloc_yumi_i(pool_yumi_li)
      ,.dealloc_v_i(pool_dealloc_v_li)
      ,.dealloc_id_i(pool_dealloc_id_li)
      );

   integer 		 i;

   always @(negedge clk)
     $display("v=%b id=%b",pool_v_lo, pool_id_lo);

   always @(posedge clk)
     $display("yumi_li=%b dealloc_v=%b pool_dealloc_id_li=%b",pool_yumi_li, pool_dealloc_v_li, pool_dealloc_id_li);     
   
   initial
     begin
	pool_dealloc_v_li = 1'b0;
	pool_yumi_li = 1'b0;
	@(negedge reset);
	@(negedge clk);
	for (i = 0; i < els_p; i++)
	  begin
	     @(negedge clk);
	     pool_yumi_li = 1'b1;
	  end

	@(negedge clk);
	pool_yumi_li = 1'b0;
	$display("done allocating");

	
	for (i = els_p-1; i >= 0; i--)
	  begin
	     @(negedge clk);
	     pool_dealloc_id_li = i;
	     pool_dealloc_v_li = 1'b1;
	  end

	@(negedge clk);
	pool_dealloc_v_li = 1'b0;

	$display("done deallocating");
	
	for (i = 0; i < els_p; i++)
	  begin
	     @(negedge clk);
	     pool_yumi_li = 1'b1;
	  end
	@(negedge clk);
	
	pool_yumi_li = 1'b0;
	@(negedge clk);
	
	$finish;
     end
endmodule  
