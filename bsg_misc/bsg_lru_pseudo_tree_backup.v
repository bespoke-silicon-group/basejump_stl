/**
 *    bsg_lru_pseudo_tree_backup.v
 *
 *    tree pseudo LRU backup finder.
 *
 *    Given the LRU bits and the bit vector of disabled ways, it will tell
 *    you the backup LRU to replace.
 *      
 *    The algorithm to find backup_LRU is:
 *    start from the root of the LRU tree, and traverse down the tree in the
 *    direction of the LRU bits, if there is at least one unlocked way in that
 *    direction. If not, take the opposite direction.
 *   
 *
 *    ==== Example ==============================================
 *
 *    rank=0                    [0]
 *                               0
 *                         /            \
 *    rank=1            [1]             [2]
 *                       1               0
 *                    /     \         /     \
 *    rank=2        [3]     [4]     [5]     [6]
 *                   1       0       1       1
 *                 /   \   /   \   /  \    /   \
 *    way         w0  w1  w2  w3  w4  w5  w6   w7
 *
 *
 *    Let say LRU bits were 7'b110_1010 so that LRU way is w2.
 *    If the disabled ways are {w2}, then backup_LRU = w3.
 *    If the disabled are {w2,w3}, then backup_LRU = w1
 *    If the disabled are {w0,w1,w2,w3}, the backup_LRU = w5.
 *
 *    ============================================================
 *
 *    @author tommy
 *
 *
 */



module bsg_lru_pseudo_tree_backup
  #(parameter ways_p="inv"
    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
  )
  (
    input [ways_p-2:0] lru_bits_i
    , input [ways_p-1:0] disabled_ways_i
    , output logic [lg_ways_lp-1:0] lru_way_id_o
  );


  // localparam 
  //
  logic [ways_p-2:0] modify_data;
  logic [ways_p-2:0] modify_mask;
  logic [ways_p-2:0] modified_lru_bits;


  // backup LRU logic
  // i = rank
  for (genvar i = 0; i < lg_ways_lp; i++) begin

    logic [(2**(i+1))-1:0] and_reduce;
    
    // j = bucket
    for (genvar j = 0; j < (2**(i+1)); j++)
      assign and_reduce[j] = &disabled_ways_i[(ways_p/(2**(i+1)))*j+:(ways_p/(2**(i+1)))];
  
    // k = start index in LRU bits
    for (genvar k = 0; k < (2**(i+1))/2; k++) begin
      assign modify_data[(2**i)-1+k] = and_reduce[2*k];
      assign modify_mask[(2**i)-1+k] = |and_reduce[2*k+:2];
    end
  end

  bsg_mux_bitwise #(
    .width_p(ways_p-1)
  ) mux (
    .data0_i(lru_bits_i)
    ,.data1_i(modify_data)
    ,.sel_i(modify_mask)
    ,.data_o(modified_lru_bits)
  );


  // encoder
  //
  bsg_lru_pseudo_tree_encode #(
    .ways_p(ways_p)
  ) lru_encode (
    .lru_i(modified_lru_bits)
    ,.way_id_o(lru_way_id_o)
  );


endmodule
