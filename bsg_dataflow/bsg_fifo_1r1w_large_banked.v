// bsg_fifo_1r1w_large_banked
//
// MB 7/6/2016
//
// Not tested.
//
// 1R1W large fifo implementation using two banks
//
// This implementation is specifically
// intended for processes where 1RW rams
// are cheaper than 1R1W rams, like
// most ASIC processes. Versus 1r1w_large
// which employs a double width ram, this
// module implies two rams. For certain
// configurations, it will use less area.
//
// The FIFO is implemented by instantiating
// two banks. 

// Each bank has a large 1-port
// fifo and a small 2-element fifo.
//
// Data is inserted directly into the 2-element fifo until
// that fifo is full. Then it is stored in
// the 1 port ram. When data is not enqued into the big fifo,
// and there is sufficient space in the small fifo
// then data is transferred from the big fifo to the small fifo.
//
// Banks are read and written in round robin fashion.
// This means that every other cycle, there is a slot
// to transfer from the big fifo to the little fifo
// if there is sufficient space in the little fifo.

//
//                     __________
//                 ___/ 1RW FIFO \___|\    _______
//                /   \__________/ __| |__/ 2 fifo\   ___
//  /---------\ _/________________/  |/   \_______/ \| N \
// |  1-to-N   |__________________                   | to |___
//  \---------/  \     __________ \__|\    _______   | 1  |
//                \___/ 1RW FIFO \___| |__/ 2 fifo\_/|___/
//                    \__________/   | |  \_______/
//                                   |/
//
// We can prove that one element small
// fifo is insufficient.
//
// suppose that the small fifo #0,#1 is full.
//        and that big fifo #0 is non-empty
// cycle one: no deque from small fifo
//
// cycle two: data is dequed from small fifo #0
//            big fifo is deq because small fifo deq is too late

// cycle three:  data is enqued into big fifo #0
//               no deq from big fifo #0 is possible
//               small fifo #0 is empty
//               data deque from small fifo #1
//
// cycle four:  no data avail in small fifo #0
//


// mbt: note bsg_fifo_two_port_bank code moved to bsg_fifo_1r1w_pseudo_large

`include "bsg_defines.v"

module bsg_fifo_1r1w_large_banked #(parameter width_p         = -1
				    , parameter els_p         = -1
                                    )
   (input                  clk_i
    , input                reset_i
    , input [width_p-1:0]  data_i
    , input                v_i
    , output               ready_o

    , output               v_o
    , output [width_p-1:0] data_o
    , input                yumi_i
    );

   initial assert ((els_p & 1) == 0) else
     $error("odd number of elements for two port fifo not handled.");

   genvar i;

   wire [1:0]               v_i_demux, ready_o_mux;

   bsg_round_robin_1_to_n #(.width_p(width_p)
                            ,.num_out_p(2)
			   )  rr1n
   (.clk_i   (clk_i      )
    ,.reset_i(reset_i    )

    ,.valid_i(v_i        )
    ,.ready_o(ready_o    )

    ,.valid_o(v_i_demux  )
    ,.ready_i(ready_o_mux)
    );

   wire [1:0]               v_int, yumi_int;
   wire [width_p-1:0] [1:0] data_int;

   for (i = 0; i < 2; i++)
     begin

	//
	// this module is responsible for handling one bank
	// of the 1R1W FIFO.
	//
	// we exploit the property of the bsg_fifo_1r1w_pseudo_large fifo
	// that it will never read-stall on us if we have a conflict run 
	// of 1 element and write data every other cycle.
	//
	
        bsg_fifo_1r1w_pseudo_large #(.width(width_p)
                                     ,.els_p(els_p >> 1)
				     ,.early_yumi_p(1)
				     // ,.max_conflict_run_p (1)
                                     ) bank
            (.clk_i   (clk_i)
             ,.reset_i(reset_i)

             ,.v_i(v_i_demux  [i])
             ,.data_i (data_i        )
             ,.ready_o(ready_o_mux[i])

             ,.v_o    (v_int   [i])
             ,.data_o (data_int[i])
             ,.yumi_i (yumi_int[i])
             );
     end

   bsg_round_robin_n_to_1 #(.width(width_p)
                            ,.num_in_p(2)
                            ) round_robin_n_to_1
     (.clk_i   (clk_i     )
      ,.reset_i(reset_i   )

      ,.data_i (data_int )
      ,.valid_i(valid_int)
      ,.yumi_o (yumi_int )

      ,.data_o (data_o    )
      ,.valid_o(valid_o   )
      ,.yumi_i (yumi_i    )
      );


endmodule // bsg_fifo_1r1w_large_banked

