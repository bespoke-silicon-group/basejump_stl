
module testbench();

localparam ways_p     = 8;   
localparam lg_ways_lp =`BSG_SAFE_CLOG2(ways_p);

logic                  clk, reset;
logic [ways_p-2:0]     lru;
logic [lg_ways_lp-1:0] way_id;

always_ff @(posedge clk) begin
  if(reset) begin
    lru <= '0;
  end
  else begin
    lru <= lru + 'b1;
	$display("lru_i: %b | way_id_o: %b", lru, way_id);
  end
  
  if(lru == '1) begin
    $finish;
  end
  
end

bsg_nonsynth_clock_gen #(.cycle_time_p(10)
                         )
              clock_gen (.o(clk)
                         );

bsg_nonsynth_reset_gen #(.num_clocks_p(1)
                         ,.reset_cycles_lo_p(1)
                         ,.reset_cycles_hi_p(4)
                         )
               reset_gen(.clk_i(clk)
                         ,.async_reset_o(reset)
                         );

bsg_ptlru_encode
  #(.ways_p(ways_p)
  )
  ptw
  (.lru_i(lru)
   ,.way_id_o(way_id)
  );

endmodule
