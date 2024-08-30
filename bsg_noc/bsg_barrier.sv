// bsg_barrier
//
// Light-weight configurable wire/logic efficient barrier.
//
// This barrier works with any nearest-neighbor connected topology (e.g., chain, torus, mesh, ruche)
// with bidirectional links.
//
// This allows all of the node hardware to be identical, but configured according into a number
// of subgraphs each capable of doing an independent barrier.
//
// Each node will have a local node input (Pi) and output (Po), and then a bunch of 
// connections to neighbor links. In the normal state, Pi and Po match. To enter the barrier,
// a node will flip the Pi bit (i.e. via XOR).  Each node has a bitmask of incoming links that 
// must all match the new barrier value before the output link outputs the barrier value.
// The barrier value propagates through the network until you get to the root node. The root node
// completes the barrier, usually pulling in links from every direction, going into a special flop
// which is the barrier root. Then the barrier root is broadcast across the reverse links specified
// by the incoming link list, eventually setting all of the Po links. As soon as a node receives the
// broadcast, it flips its "sense bit" which says whether a 1 or 0 is the new barrier target value.
//
// In a RISC-V based system, the approach would be
//
// <setup>:
//
// mtcsr BARCFG,  8'b <this node's output id selector> 24'b <this node's input bitmask>
//
// <execution>:
//
// memory fence   # if needed, stall until all memory operations done
// barsend        # flip Pi bit (bit 1) of BAR csr (note: Po bit is mapped to bit 2 of the register)
// barreceive     # stall in decode until Pi==Po
//
// Here is an example barrier for a Ruche factor 3 topology (you would configure the letters on the left of 
// the -> as the input mask and the letter on the right as the output direction). Note R is the "Root".
//
//   0.    1.     2.     3.     4.     5.      6.     7.       8.       9.     10.    11.     12.   13.    14.   15.
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  PWwE->S   PWEe->S    PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  0
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  NPWwE->S  NPWEe->S   PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  1
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  NPWwE->S  NPWEe->S   PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  2
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  NPWwE->e  NPWEwe->S  PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  3
//
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  SPWeE->e  NSPWEwe->R PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  4
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  SPWwE->N  SPWEe->N   PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  5
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  SPWwE->N  SPWEe->N   PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  6
// P->E  P->E   P->E  PW->E   PW->E PW->E   PW->e  PWwE->N    PWEe->N   PW->w  PE->W   PE->W  PE->W  P->W  P->W  P->W  7
//
//
// Context switching. The barrier is context switchable. To context switch the barrier, you interrupt all of the relevant tiles
// and wait long enough for any successful barrier to fully propagate. At this point, using BAR CSR, you can determine if you are either barrier-completed
// (Pi = Po) for all tiles or barrier in progress (Pi != Po for some subset of nodes.) For barrier in progress, we can record all of the nodes
// that have barrier in progress, and then reset the corresponding Pi bit to clear the in progress barrier.
//
// https://docs.google.com/presentation/d/1LkmpxLuo4vvxT_m_Ww6FkqnFa1y8ePmZIGdC5xIN26w/edit#slide=id.p

`include "bsg_defines.sv"

module bsg_barrier 
  #(`BSG_INV_PARAM(dirs_p),lg_dirs_lp=`BSG_SAFE_CLOG2(dirs_p+1))
  (
    input clk_i
    ,input reset_i
    
    // to remote nodes
    
    ,input  [dirs_p-1:0] data_i // late
    ,output [dirs_p-1:0] data_o // early-ish
    
    //
    // control of the barrier:
    //
    // which inputs we will gather from
    // and which outputs we send the gather output to
    // and for the broadcast phase, the opposite.
    //
    // usually comes from a CSR (or bsg_tag)
    //
    
    ,input  [dirs_p-1:0]     src_r_i 
    ,input  [lg_dirs_lp-1:0] dest_r_i
  );
  
  wire [dirs_p:0]        data_r;
  wire activate_n;
  
  wire data_broadcast_in  = data_r[dest_r_i];
    
  wire sense_n, sense_r;

  wire gather_and = & (~src_r_i | data_r[dirs_p-1:0]); // true if all selected bits are set to 1
  wire gather_or  = | (src_r_i & data_r[dirs_p-1:0]);  // false if all selected bits are set to 0

  // the barrier should go forward, based on the sense bit, if we are either all 0 or all 1.
  wire gather_out = sense_r ? gather_or : gather_and;
  
  //
  // flip sense bit if we are receiving the incoming broadcast
  // we are relying on the P bit still being high at the leaves
  // sense_r  broadcast_in sense_n
  // 0        0            0 
  // 0        1            1
  // 1        1            1
  // 1        0            0
  
  // if we see a transition on data_broadcast_in, then we have completed the barrier  
  assign sense_n = data_broadcast_in;
  
  bsg_dff_reset #(.width_p(dirs_p+2)) dff
  (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.data_i({activate_n,     data_i[dirs_p-1:0], sense_n})
   ,.data_o({data_r[dirs_p], data_r[dirs_p-1:0], sense_r})
  );
  
  // this is simply a matter of propagating the value in question

  wire [dirs_p-1:0] data_broadcast_out = { dirs_p { data_broadcast_in } } & src_r_i;
 
  // here we propagate the gather_out value, either to network outputs, or to the local activate reg (at the root of the broadcast)

  wire [dirs_p:0] dest_decode     = 1 << (dest_r_i);  
  
  wire [dirs_p:0] data_gather_out = dest_decode & { (dirs_p+1) { gather_out } };
  
  assign data_o = data_broadcast_out | data_gather_out[dirs_p-1:0];
  
  assign activate_n = data_gather_out[dirs_p];

  // synopsys translate_off
  
  localparam debug_p = 0;

  if (debug_p)
  always @(negedge clk_i)
    $display("%d: %m %b %b %b %b %b %b", $time, gather_and, gather_or, gather_out, sense_n, data_i, data_o);

  // synopsys translate_on
  
endmodule

`BSG_ABSTRACT_MODULE(bsg_barrier)
