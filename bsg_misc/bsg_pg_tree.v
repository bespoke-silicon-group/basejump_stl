// bsg_pg_tree
//
// this code builds a PG (propagate generate) tree
// (although actually it is not a tree, it is a dag)
//
// The structure of the tree is given by the input parameters:
//
// input_width_p: # of input {p,g} pairs
// nodes_p:       # of nodes in the tree.
//
// l_edge_p[i]:      # of {p,g} pair to connect the "left" (lsb) input edge of the node i
// r_edge_p[i]:      # of {p,g} pair to connect the "right" (msb) input edge of the node i
// o_edge_p[i]:      # of {p,g} pair to connect the output of the node i
// node_type_p[i]:   the type of node (0: black, 1: grey, 2: black_buffer, 3: grey_buffer)
// row_p[i]:         what row the node lives on. can be used for datapath layout or complementary logic
//
// These components reflect the structure of Harris & Weste 4th edition p 438
//
// it is typically used for constructing adders, multipliers, carry predictors, etc.
//

`include "bsg_defines.v"

module bsg_pg_tree
#(parameter input_width_p="inv"
  ,parameter output_width_p="inv"
  , parameter nodes_p=1         
  , parameter edges_lp=nodes_p*3
  , parameter int l_edge_p [nodes_p-1:0]    = ' {0}
  , parameter int r_edge_p [nodes_p-1:0]    = ' {0}
  , parameter int o_edge_p [nodes_p-1:0]    = ' {0}
  , parameter int node_type_p [nodes_p-1:0] = ' {0}
  // for physical placement or doing even/odd complementary logic per Fig 11.16b
  // currently unimplemented
  , parameter int row_p    [nodes_p-1:0]     = ' {0}
  )	

  (input  [input_width_p-1:0] p_i
   ,input [input_width_p-1:0] g_i
   ,output [output_width_p-1:0] p_o
   ,output [output_width_p-1:0] g_o
  );
  
  wire [edges_lp-1:0] p;
  wire [edges_lp-1:0] g;

  // the input wires are placed at the start of the p and g arrays
  assign p[input_width_p-1:0] = p_i; 
  assign g[input_width_p-1:0] = g_i;

  // the output wires are at the end of the p and g arrays
  assign p_o = p[edges_lp-1-:output_width_p];
  assign g_o = g[edges_lp-1-:output_width_p];
  
  genvar i;
  
  for (i=0; i < nodes_p; i=i+1)
	begin: rof
    if (node_type_p[i] == 0) // so called "black cell" from Weste & Harris 4th ed
      begin: blk             // g[l_edge_p] should be assigned to faster input of AND gate
      	assign p[o_edge_p[i]] = p[l_edge_p[i]] | p[r_edge_p[i]];
      	assign g[o_edge_p[i]] = g[r_edge_p[i]] | (g[l_edge_p[i]] & p[r_edge_p[i]]);      
      end
    else if (node_type_p[i] == 1) // "grey cell"
      begin: gry                  // g[l_edge_p] should be assigned to faster input of AND gate
        assign p[o_edge_p[i]] = `BSG_UNDEFINED_IN_SIM(0);
    	  assign g[o_edge_p[i]] = g[r_edge_p[i]] | (g[l_edge_p[i]] & p[r_edge_p[i]]);       
      end
    else if (node_type_p[i] == 2) // "black_buffer"
    	begin: bbuf                 // note: only takes left side!
        assign p[o_edge_p[i]] = p[l_edge_p[i]];
        assign g[o_edge_p[i]] = g[l_edge_p[i]];            
      end
    else if (node_type_p[i] == 3) // "grey_buffer"
    	begin: gbuf                 // note: only takes left side!
        assign p[o_edge_p[i]] = `BSG_UNDEFINED_IN_SIM(0);
        assign g[o_edge_p[i]] = g[l_edge_p[i]];            
      end
	  else
      begin
      	initial $error("unknown node_type: ",node_type_p[i]);
      end
  end
  
endmodule
