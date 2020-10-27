// MBT 11/10/14
//
//
// bsg_fifo_1r1w_large
//
// This implementation is specifically
// intended for processes where 1RW rams
// are much cheaper than 1R1W rams, like
// most ASIC processes, or where 1R1W rams
// are not available.
//
// The idea is that a 1R1W ram is often 1.7X
// or more of the size of a 1RW, so we can
// save area.
//
// There are five+ possible implementations
// of a FIFO using 1RW rams:
//
// a. (bsg_fifo_1r1w_small) synthesize 1R1W RF from DFFs. Area per bit
//    of storage is often 10x larger than 1RW SRAM. But the SRAM
//    needs a sense-amp for every bit that is accessed per cycle, which is
//    about the size of 7 DFF-bits. So, for instance, if you need
//    to access 64 bits per cycle, then that incurs ~450 DFF bits of overhead,
//    so the DFF-RF will be cheaper up until to 512 bits. If you only need
//    to access 32 bits in parallel, then the breakeven would be closer to 256 bits.
//
// b. Use a true 1R1W ram; about 2X larger than 1RW SRAM. Maybe available for FPGA
//    but often not available, or not a good deal for ASIC.
//
// c. (not implemented) To get more ports, use two rams of half size, and then round
//    robin odd/even elements. We can favor the
//    writer, and then use a two-element fifo
//    with bypass after each 1RW, and select between
//    the two. Net cost is 4 words of DFF plus two 1RW SRAMs of size 1/2 but same width.
//    A draft of this code is at the end of this file, but it is incomplete/untested Caveat emptor.
//
// d. (bsg_fifo_1r1w_large) To get "more ports", use a single 1RW of double width
//    and read/write two elements at a time, as described in this module.
//    The cost is 7 DFF elements for staging plus 1 RW of double width and half words. So for
//    a 64-bit wide ram, the overhead is almost 3*450 = 1400 DFF bits; slightly more than
//    case c), but since there is only one RAM there are savings.
//
//    A single 1RW versus two 1RW's can be a win, but not always. The RAM
//    is larger, so there is potential for there is to be more amortization of
//    overhead. But on the other hand, # of sense amps is the same, so some of the
//    overheads are the same. One problem with this design for smaller RAMs is 
//    that it doubles the number of sense amps in a single ram, which can make
//    the aspect ratio undesirable or even impossible.
//
// e. (bsg_fifo_1r1w_pseudo_large) Use a pseudo 1RW fifo, where it looks like it is 1r1w, but actually
//    it is a 1RW that favors writes. Unlike "large", it has the same bandwidth, so we save space
//    on sense amps. This only applies when you know data is coming in at 1/2 rate or slower.
//
// Generally speaking, an SRAM's area is proportional to the number of bits, the number of
// sense amps, and the amount of decoder. If we take a wide ram and break it into two rams
// of half the width, but the same total bits, we have the same number of total bits and
// the same number of sense amps, but more decoder area, so there is a slight increase. 
//
// The 7 elements overhead coud potentially be significant,
// since they are implemented with ordinary flops, probably 4X per bit versus the
// So we have an equation,  area improvement = 1.7 W / (W + 4*7);
//
//       64 --> 20% (probably less than this)
//      128 --> 40%
//      256 --> 53%
//      512 --> 62%

//
// Rather than use two 1RW and alternate
// between them, we use one 1RW of double
// width. This saves area especially for
// medium size fifos (e.g. 64x64 = 4096 bits).
//
// Since data is bunched in pairs, we create
// a free slot from which we can fetch data from
// the big fifo every other cycle.

// When there is little data in the FIFO
// data is round robin dispatched to a pair of
// two element fifos (little fifos). If the
// little fifos fill up, then the data is bunched up into
// pairs and written into a double width single
// ported 1RW FIFO (big fifos). Priority is given to
// writing to the big fifos; except if the little fifo
// only has two elements left; then reads are given
// priority so that the data arrives in time.
//
// This policies allows us to guarantee the invariants of
// a FIFO: it will never say it's full if it has less than
// N elements in it; and it will never say it's empty
// if it has more than 0 elements in it. This is not
// that straightforward with this kind of fifo because
// the data could actually be in three different places:
// the buncher, the little FIFO, and the big FIFO.
//
// Note that the FIFO does not guarantee an upper bound
// on how many elements it will accept. This may actually
// be as high as N+4+3.
//
//
//                                |\   ___   _______
//                 _______________| |  |R|__/ 2 fifo\    ___
// /------------\_/               | |  |R|  \_______/ \ | N \
// |ser2parallel|_    ________    | |__|2|              | to |___
// \------------/ \  / big    \   | |  |t|    ______    | 1  |
//                 \/ 1RW FIFO \__| |  |2|__/ 2 fifo\_/ |___/
//                  \__________/  |/   |_|  \_______/
//
//

`include "bsg_defines.v"

module bsg_fifo_1r1w_large #(parameter width_p           = -1
                             , parameter els_p           = -1
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

   wire [width_p*2-1:0] data_sipo;
   wire [1:0]          valid_sipo;

   wire [1:0]          yumi_cnt_sipo;

   // we had to bump els_p to 3 because of the case
   // where the little fifos have 3 elements (blocking
   // us from restoring from the 1RW FIFO), and where
   // the sipo has only one element (blocking us from
   // spooling to the 1RW fifo.) If we simultaneously
   // have enque and deque requests, then the sipo will
   // need to spool at the same time that we need to
   // access the 1RW fifo to prevent empty. the solution
   // is to add one extra element to the sipo so that it
   // can hold off one more cycle before spooling. then
   // we can restore 2 words from the fifo, and spool
   // on the next cycle.

   bsg_serial_in_parallel_out #(.width_p(width_p)
                                ,.els_p(3)
                                ,.out_els_p(2)
                                ) sipo
   (.clk_i      (clk_i)
    ,.reset_i   (reset_i)
    ,.valid_i   (v_i)
    ,.data_i    (data_i)
    ,.ready_o   (ready_o)
    ,.valid_o   (valid_sipo)
    ,.data_o    (data_sipo)

    ,.yumi_cnt_i(yumi_cnt_sipo)
    );

   wire [2*width_p-1:0] big_data_lo;
   wire                 big_valid, big_full_lo, big_empty_lo;
   logic                big_enq, big_deq,   big_deq_r;

   always_ff @(posedge clk_i)
     big_deq_r <= big_deq;

   bsg_fifo_1rw_large #(.width_p(width_p*2)
                        ,.els_p (els_p >> 1)
                        ) big1p
     (.clk_i         (clk_i       )
      ,.reset_i      (reset_i     )

      // low bits are older element
      ,.data_i       (data_sipo )

      ,.v_i          (big_valid)
      ,.enq_not_deq_i(big_enq)

      ,.full_o   (big_full_lo )
      ,.empty_o  (big_empty_lo)
      ,.data_o   (big_data_lo )
      );

   wire [2*width_p-1:0] little_data_rot;
   wire [1:0]           little_valid, little_ready;
   wire [1:0]           little_ready_rot, little_valid_rot;
   wire [1:0]           valid_int;

   // we are in bypass mode if we can directly bypass
   // to the small fifos.
   // - we cannot have on the previous cycle loaded
   // data from the big fifo; the small fifo we would like
   // to use cannot be full, and the big fifo must be empty.

   wire bypass_mode    = ~big_deq_r & little_ready[0] & big_empty_lo;

   wire can_spill     = ~big_full_lo & ~bypass_mode;

   // we have an emergency if both little fifos can receive data
   // (i.e. <= 2 elements) and we did not just fetch from the big fifo
   // and we have data in the big fifo. if we don't transfer now, we
   // will have a bubble.

   wire emergency     = (&little_ready_rot) & ~big_empty_lo & ~big_deq_r;

   // we will spill if we are in spill mode; and we have two elements
   // to spill, and the big fifo is not full.

   wire will_spill    = can_spill & (&valid_sipo) & ~emergency;

   // we deque if we are not spilling, big fifo has data available
   // and the small fifos has two elements free with an enque pending
   // or one element free with no enque pending

   assign big_deq     = ~will_spill & ~big_empty_lo
                        & (big_deq_r
                           ? (~|valid_int)         // small fifos are empty
                           : (&little_ready_rot)); // both fifos > 1 el free, no enq pending

   assign big_valid = will_spill | big_deq;
   assign big_enq   = will_spill;

   wire [2*width_p-1:0] little_data  = big_deq_r ? big_data_lo : data_sipo;
   wire [1:0] bypass_vector = valid_sipo & { bypass_mode, bypass_mode };
   assign               little_valid = big_deq_r ? 2'b11       : bypass_vector;

   wire [1:0]           cnt;

   bsg_thermometer_count #(.width_p(2)) thermo(.i(little_ready & bypass_vector)
                                               ,.o(cnt));

   assign yumi_cnt_sipo = will_spill
                          ? 2'b10
                          : cnt;

   bsg_round_robin_2_to_2 #(.width_p(width_p))
     rr222
       (.clk_i(clk_i)
        ,.reset_i(reset_i)

        ,.data_i(little_data)
        ,.v_i    (little_valid)
        ,.ready_o(little_ready)

        ,.data_o(little_data_rot)
        ,.v_o   (little_valid_rot)
        ,.ready_i(little_ready_rot)
        );


   wire [1:0][width_p-1:0] data_int;
   wire [1:0]           yumi_int;

   genvar               i;

   for (i = 0; i < 2; i++)
     begin : twofer
        bsg_two_fifo #(.width_p(width_p)) little
            (.clk_i   (clk_i)
             ,.reset_i(reset_i)

             ,.ready_o(little_ready_rot[i]                 )
             ,.data_i (little_data_rot [i*width_p+:width_p])
             ,.v_i    (little_valid_rot[i]                 )

             ,.v_o    (valid_int [i])
             ,.data_o (data_int  [i])
             ,.yumi_i (yumi_int  [i])
             );
     end

  bsg_round_robin_n_to_1 #(.width_p(width_p)
                            ,.num_in_p(2)
			    ,.strict_p(1)
                            ) round_robin_n_to_1
     (.clk_i   (clk_i     )
      ,.reset_i(reset_i   )

      ,.data_i (data_int )
      ,.v_i(valid_int)
      ,.yumi_o (yumi_int )

      ,.data_o (data_o    )
      ,.v_o(v_o       )
      ,.tag_o  ()
      ,.yumi_i (yumi_i    )
      );

   // synopsys translate_off

   // this sums up all of the storage in this fifo
   wire [31:0] num_elements_debug
               = 2*big1p.num_elements_debug
               + valid_int[0] + valid_int[1]
               + sipo.valid_r[0] + sipo.valid_r[1]
               + !little_ready_rot[0] + !little_ready_rot[1];

   // synopsys translate_on


endmodule

