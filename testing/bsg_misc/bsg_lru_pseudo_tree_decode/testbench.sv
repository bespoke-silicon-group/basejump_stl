
module testbench();

localparam ways_p     = 8;   
localparam lg_ways_lp =`BSG_SAFE_CLOG2(ways_p);

logic                  clk, reset;
logic [lg_ways_lp-1:0] way_id;
logic [ways_p-2:0]     data, mask;

always_ff @(posedge clk) begin
  if(reset) begin
    way_id <= '0;
  end
  else begin
    way_id <= way_id +  'b1;
	$display("way_id_i: %b | data_o: %b | mask_o: %b", way_id, data, mask);
  end
  
  if(way_id == '1) begin
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

bsg_lru_pseudo_tree_decode
  #(.ways_p(ways_p)
  )
  ptw
  (.way_id_i(way_id)
   ,.data_o(data)
   ,.mask_o(mask)
  );

endmodule