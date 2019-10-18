/**
 *    bsg_lru_pseudo_tree_encode.v
 *
 *    Pseudo-Tree-LRU encode unit.
 *    Given the LRU bits, traverses the pseudo-LRU tree and returns the
 *    LRU way_id.
 *    Only power of 2 ways.
 *
 *    @author tommy
 *
 */

module bsg_lru_pseudo_tree_encode
  #(parameter ways_p = "inv"
    , parameter lg_ways_lp = `BSG_SAFE_CLOG2(ways_p)
  )
  (
    input [ways_p-2:0] lru_i
    , output logic [lg_ways_lp-1:0] way_id_o
  );


  for (genvar i = 0; i < lg_ways_lp; i++) begin: rank

    if (i == 0) begin: z

      assign way_id_o[lg_ways_lp-1] = lru_i[0];  // root

    end
    else begin: nz

      bsg_mux #(
        .width_p(1)
        ,.els_p(2**i)
      ) mux (
        .data_i(lru_i[((2**i)-1)+:(2**i)])
        ,.sel_i(way_id_o[lg_ways_lp-1-:i])
        ,.data_o(way_id_o[lg_ways_lp-1-i])
      );

    end
  end


endmodule

