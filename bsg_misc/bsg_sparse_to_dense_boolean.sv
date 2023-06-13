`include "bsg_defines.sv"

//
// bsg_sparse_to_dense_boolean
//
//
// takes a sparsely represented bit vector, encoded as two arrays;
// a sequence of indices and bit vector, and then transforms
// them into a single densely-represented bit vector.
//
// if a index is duplicated, then the corresponding data
// is OR'd together.
//
//
// example:
//
//  1 0  1 1 1 1 1 (values)
//  0 4  3 2 7 9 4 (indices)
//
//  --->
//
//  1 0 1 1 1 0 0 1 0 1
//
//
// from this perspective, bsg_decode_with_v is sparse_to_dense
// for sparse vectors with a single element.
//
// the sparse vector does not need to be ordered in any way
//

module bsg_sparse_to_dense_boolean #(`BSG_INV_PARAM (els_p)
                                    ,`BSG_INV_PARAM(width_p)
                                    )
  (input clk_i
   , input  reset_i
   , input  [els_p-1:0] val_i
   , input  [els_p-1:0][`BSG_SAFE_CLOG2(width_p)-1:0] index_i
   , output [width_p-1:0] o
  );
  
  genvar j;
  
  wire [els_p-1:0][width_p-1:0] matrix;

  for (j = 0; j < els_p; j++)
    begin: rof
      bsg_decode_with_v 
      #(.num_out_p(width_p))
      dec
      (
        .v_i(  val_i[j])
       ,.i  (index_i[j])
       ,.o  (matrix [j])
      );
    end	

  bsg_transpose_reduce #(.els_p(els_p)
                        ,.width_p(width_p)
                        ,.or_p(1)
                       ) tred
  (.i(matrix)
   ,.o(o)
  );

endmodule

`BSG_ABSTRACT_MODULE(bsg_sparse_to_dense_boolean)
