
//
// Maintains the replacement policy for an array of elements
// The scheme is synchronously updated when v_i goes high, and asynchronously
//   outputs the selected way for replacement based on internal and emptiness
//
module bsg_cam_1r1w_replacement
 #(parameter els_p      = 2
   // Which replacement scheme to use
   // Currently supported:
   //   - LRU
   , parameter scheme_p = "lru"
   )
  (input                       clk_i
   , input                     reset_i

   // Synchronous update
   , input                     v_i
   , input [els_p-1:0]         way_one_hot_i

   // May use combination of internal state and empty vector
   //   to determine replacement
   , input [els_p-1:0]         empty_i
   , output [els_p-1:0]        way_one_hot_o
   );

  // Standard tree-based pseudo-lru
  if (scheme_p == "lru")
    begin : lru
      localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p);

      // LRU storage
      logic [els_p-2:0] lru_n, lru_r;
      bsg_dff_reset_en
       #(.width_p(els_p-1))
       lru_reg
        (.clk_i(clk_i)
         ,.reset_i(reset_i)
         ,.en_i(v_i)

         ,.data_i(lru_n)
         ,.data_o(lru_r)
         );

      // Encode the one-hot way select based on LRU
      logic [lg_els_lp-1:0] lru_way_lo;
      bsg_lru_pseudo_tree_encode
       #(.ways_p(els_p))
       lru_encoder
        (.lru_i(lru_r)
         ,.way_id_o(lru_way_lo)
         );

      // Find an empty way if one exists
      logic [lg_els_lp-1:0] empty_way_lo;
      logic empty_way_v_lo;
      bsg_priority_encode
       #(.width_p(els_p), .lo_to_hi_p(1))
       empty_encoder
        (.i(empty_i)
         ,.addr_o(empty_way_lo)
         ,.v_o(empty_way_v_lo)
         );

      // Select the empty way if one exists; else, use LRU
      wire [lg_els_lp-1:0] way_lo = empty_way_v_lo ? empty_way_lo : lru_way_lo;

      // Output the one-hot way selected
      bsg_decode
       #(.num_out_p(els_p))
       way_decoder
        (.i(way_lo)
         ,.o(way_one_hot_o)
         );

      // Encode the one-hot way input to this module
      logic [lg_els_lp-1:0] way_li;
      bsg_encode_one_hot
       #(.width_p(els_p))
       way_encoder
        (.i(way_one_hot_i)
         ,.addr_o(way_li)
         ,.v_o()
         );

      // Decides which way to update based on MRU
      logic [els_p-2:0] update_data_lo, update_mask_lo;
      bsg_lru_pseudo_tree_decode
       #(.ways_p(els_p))
       decoder
        (.way_id_i(way_li)
         ,.data_o(update_data_lo)
         ,.mask_o(update_mask_lo)
         );
       
      // Muxes in the update data to compute the next LRU state
      // This doesn't get latched in unless there's an active use
      bsg_mux_bitwise
       #(.width_p(els_p-1))
       update_mux
        (.data0_i(lru_r)
         ,.data1_i(update_data_lo)
         ,.sel_i(update_mask_lo)
         ,.data_o(lru_n)
         );
    end

  initial
    begin
      assert (scheme_p == "lru") else $error("Only LRU scheme is currently supported");
    end
  
endmodule

