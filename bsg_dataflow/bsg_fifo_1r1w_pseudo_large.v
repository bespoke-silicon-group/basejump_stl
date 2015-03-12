//
// bsg_fifo_1r1w_pseudo_large
//
// MBT 3/11/15
//
// This fifo looks like a 1R1W fifo but actually is implemented
// with a 1RW FIFO for the bulk of its storage, and has a
// small 1R1W FIFO to help decouple reads and writes that may
// conflict. This FIFO is useful for cases where reads and writes
// are intermittant, for example, an element is written into the
// FIFO every other cycle, and an element is read from the FIFO
// every other cycle.
//
// _______________________________
//               \     __________ \__|\    ____________
//                \___/ 1RW FIFO \___| |__/ 1R1W FIFO  \______
//                    \___big____/   | |  \___little___/
//                                   |/
//
// Data is inserted directly into the little fifo until
// that fifo is full. Then it is stored in
// the 1 port ram. When data is not enqued into the big fifo,
// and there is sufficient gauranteed space in the little fifo
// then data is transferred from the big fifo to the little fifo.
//
// Although both bsg_fifo_1r1w_pseudo_large and bsg_fifo_1r1w_large
// use 1RW rams, the pseudo fifo will be more area efficient for
// smaller FIFO sizes, because 1) it does not read as much data at a time
// and thus does not require as many sense amps (see your RAM compiler)
// and 2) the little FIFO is smaller than the associated "little fifo"
// serial-to-parallel registers of the true 1r1w.
//
// Guarantees:
//
// In order to maintain the appearance of the 1R1W FIFO, this
// FIFO will always accept up to els_p data elements without saying
// that it is full. These elements can be sent back-to-back, but this
// may starve out the little FIFO since it will not be able to
// access the 1RW FIFO.
//
// Non-guarantees:
//
// The FIFO does not guarantee the availability of
// data on output with any certain timing. For example, if you have
// code that counts how many elements went into the FIFO, and then
// expects to deque that number of elements without checking the
// v_o bit, that code will fail.
//
//
// Parameters:
//
// The size of the little FIFO determines three factors:
//
// First, how many elements must be queued up before the FIFO starts
// using the large 1RW FIFO, which will likely consume a lot more power.
// Second, after how many elements the effective throughput of the FIFO drops to 1/2.
// Third, the maximum "conflict run" on writes that the FIFO can sustain before dropping below
// an average throughput of 1/2 because of structural hazards on the 1RW ram.
//

// early_yumi_p:  this parameter says whether the yumi signal comes in earlier
// which allows us to reduce latency between deque and the next element
// being transferred from the internal ram to the output. this ordinarily would take
// 2+n cycles (yumi->BF deq->LF enq) where n is the number BF enques. early yumi
// changes this to (yumi/BF deq -> LF enq) or 1+n cycles.
// this can be used if the yumi signal is known early, and reduces the
// required little fifo size by 1 element to 1+n.
//
// Assertion to be proved: the FIFO size required for a conflict run size of n is 2+n.
// (yumi->BF deq->LF enq)+conflicts. So, your basic small FIFO should be at least 3 elements for
// enque patterns that do every-other cycle with an unknown relationship to the output, which
// is also every other cycle. The early yumi flag changes this parameter to
// (yumi/BF deq -> LF enq) +conflicts = 1+n = 2 elements
//
// This allows the fifo to support 1/2 rate inputs and outputs with conflict runs of 1 and only a twofer.
//
// TODO: parameterize little FIFO size
//

// formerly two_port_large_bank
module bsg_fifo_1r1w_pseudo_large #(parameter width_p = -1
                                      , parameter els_p = -1
				      // Future extensions: it would be nice to be
				      // able to allow the little fifo to
				      // be parameterized with the value n, so that it could
				      // be adapted to deal with bursts,
				      // or if yumi is not early.
				      , parameter early_yumi_p = 0
				      , parameter verbose_p = 0
				      )
   (input   clk_i
    , input reset_i

    , input [width_p-1:0] data_i
    , input v_i
    , output ready_o

    , output v_o
    , output [width_p-1:0] data_o
    , input  yumi_i
    );

   wire big_full_lo, big_empty_lo;
   wire [width_p-1:0] big_data_lo;

   logic               big_enq, big_deq, big_deq_r;

   wire               little_ready_lo, little_will_have_space;

   logic 	      little_valid, big_valid;
   
   if (early_yumi_p)
     assign little_will_have_space = little_ready_lo | yumi_i;
   else
     assign little_will_have_space = little_ready_lo;

   // whether we dequed something on the last cycle

   always_ff @(posedge clk_i)
     if (reset_i)
       big_deq_r <= 1'b0;
     else
       big_deq_r <= big_deq;

   // if the big fifo is not full, then we can take more data
   wire ready_o_int = ~big_full_lo;
   assign ready_o   = ready_o_int;

   // for debugging; whether we are bypassing the big fifo
   // synopsys translate_off

   wire bypass_mode = v_i & ~ big_enq;

   // sum up all of the storage in this fifo
   wire [31:0] num_elements_debug = big1p.num_elements_debug + big_deq_r + little2p.num_elements_debug;


   // synopsys translate_on

   always_comb
     begin
        // if we fetch an element last cycle, we need to enque
        // it into the little fifo
        if (big_deq_r)
          begin
             // we dequed last cycle, so there must be room
             // in both big and little fifos
             little_valid = 1'b1;
             big_enq      = v_i;

             // if there is data in big fifo
             // and we are not enqueing to the big fifo
             // and the little fifo is empty
             // we can grab another word

	     // we do not test for the yumi signal here
	     // because an empty little fifo cannot have a yumi.
             big_deq      = (~big_empty_lo & ~big_enq & ~v_o);
          end
        else
          begin
             // clean through bypass mode; skip
             // big fifo and go to little fifo
             if (big_empty_lo)
               begin
                  little_valid = v_i  & little_will_have_space;
                  big_enq      = v_i  & ~little_will_have_space;
                  big_deq      = 1'b0; // big FIFO is empty, can't deque
               end
             else
               // there is data in the big fifo
               // but we did not fetch from it
               // last cycle.
               // we cannot enque anything into
               // the little fifo this cycle.
               begin
		  little_valid = 1'b0;
                  big_enq = v_i  & ~big_full_lo;
                  big_deq = ~big_enq & little_will_have_space;
               end
          end // else: !if(big_deq_r)

        big_valid    = big_enq | big_deq;
     end

   // if we dequed from the big queue last cycle
   // then we enque it into the little fifo

   wire [width_p-1:0] little_data = big_deq_r ? big_data_lo : data_i;

   bsg_fifo_1rw_large #(.width_p(width_p)
                        ,.els_p(els_p)
			,.verbose_p(verbose_p)
                        ) big1p
     (.clk_i         (clk_i       )
      ,.reset_i      (reset_i     )
      ,.data_i       (data_i      )

      ,.v_i          (big_valid)
      ,.enq_not_deq_i(big_enq)

      ,.full_o   (big_full_lo )
      ,.empty_o  (big_empty_lo)
      ,.data_o   (big_data_lo )
      );

   bsg_two_fifo #(.width_p(width_p)
		  ,. verbose_p(verbose_p)) little2p
     (.clk_i   (clk_i)
      ,.reset_i(reset_i)
      ,.ready_o(little_ready_lo)
      ,.data_i (little_data)
      ,.v_i    (little_valid)

      ,.v_o    (v_o)
      ,.data_o (data_o)
      ,.yumi_i (yumi_i)
      );

endmodule

