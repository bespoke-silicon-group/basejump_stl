// MBT BSG 11/13/2014
//
// Single-Enque, Multi-Deque FIFO
//
// A FIFO that takes in one word per cycle
// and allows more than one word per cycle to be removed.
// The number of words removed is determined by downstream consumer
// on a cycle-by-cycle basis.
//
// This module is likely to be much more expensive than other
// bsg_serial_in_parallel_out_* modules, and probably should be renamed.
//
// els_p and out_els_p can be set differently in order
// to increase the amount of buffering internal to the module
//
// this data structure supports bypassing, so can
// have zero latency (but possibly a larger cycle time.)
//
// this is a shifting-based fifo; so this is probably
// not ideal from power perspective
//
// 

`include "bsg_defines.sv"

module bsg_serial_in_parallel_out #(parameter `BSG_INV_PARAM(width_p)
                                    , parameter `BSG_INV_PARAM(els_p)
                                    , parameter out_els_p = els_p)
   (input                 clk_i
    , input               reset_i
    , input               valid_i
    , input [width_p-1:0] data_i
    , output              ready_and_o

    , output logic [out_els_p-1:0]                valid_o
    , output logic [out_els_p-1:0][width_p-1:0]   data_o

    , input  [$clog2(out_els_p+1)-1:0]            yumi_cnt_i
    );

   localparam double_els_lp = els_p * 2;

   logic [els_p-1:0][width_p-1:0] data_r, data_nn;
   logic [2*els_p-1:0  ][width_p-1:0] data_n;
   logic [els_p-1:0] 		  valid_r, valid_nn;
   logic [double_els_lp-1:0] 	  valid_n;

   logic [$clog2(els_p+1)-1:0]    num_els_r, num_els_n;

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          begin
             num_els_r <= 0;
             valid_r   <= 0;
          end
        else
          begin
             num_els_r <= num_els_n;
             valid_r   <= valid_nn;
          end
     end

  always_ff @(posedge clk_i) begin
     data_r <= data_nn;
  end


  // we are ready if we have at least
  // one spot that is not full

  assign ready_and_o = ~valid_r[els_p-1];

  // update element count
  assign num_els_n = (num_els_r + (valid_i & ready_and_o)) - yumi_cnt_i;

  always_comb begin
    data_n  = data_r;
    valid_n = (double_els_lp) ' (valid_r);

	  data_n[els_p+:els_p] = 0;

    // bypass in values
    data_n [num_els_r] = data_i;
    valid_n[num_els_r] = valid_i & ready_and_o;

    // this temporary value is
    // the output of this function
    valid_o = valid_n[out_els_p-1:0];
    data_o  = data_n [out_els_p-1:0];

	  // now we calculate the update
	  for (integer i = 0; i < els_p; i++) begin
	    data_nn[i] = data_n[yumi_cnt_i+i];
    end
	  valid_nn = valid_n[yumi_cnt_i+:els_p];
  end

endmodule


`BSG_ABSTRACT_MODULE(bsg_serial_in_parallel_out)
