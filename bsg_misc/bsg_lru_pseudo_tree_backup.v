/**
 *    bsg_lru_pseudo_tree_backup.v
 *
 *    tree pseudo LRU backup finder.
 *
 *    Given the bit vector of disabled ways, it will tell
 *    you bit-mask and data to modify the original LRU bits to obtain
 *    the backup LRU.
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



`include "bsg_defines.v"

module bsg_lru_pseudo_tree_backup
  #(parameter ways_p="inv"
    , parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
  )
  (
    input [ways_p-1:0] disabled_ways_i
    , output logic [`BSG_SAFE_MINUS(ways_p, 2):0] modify_mask_o
    , output logic [`BSG_SAFE_MINUS(ways_p, 2):0] modify_data_o
  );

  // If direct-mapped there is no meaning to backup LRU
  if (ways_p == 1) begin: no_lru
    assign modify_mask_o = 1'b1;
    assign modify_data_o = 1'b0;
  end
  else begin: lru
  // backup LRU logic
  // i = rank
  for (genvar i = 0; i < lg_ways_lp; i++) begin

    logic [(2**(i+1))-1:0] and_reduce;
    
    // j = bucket
    for (genvar j = 0; j < (2**(i+1)); j++)
      assign and_reduce[j] = &disabled_ways_i[(ways_p/(2**(i+1)))*j+:(ways_p/(2**(i+1)))];
  
    // k = start index in LRU bits
    for (genvar k = 0; k < (2**(i+1))/2; k++) begin
      assign modify_data_o[(2**i)-1+k] = and_reduce[2*k];
      assign modify_mask_o[(2**i)-1+k] = |and_reduce[2*k+:2];
    end
  end
  end

endmodule
