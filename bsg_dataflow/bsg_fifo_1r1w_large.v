// MBT 11/10/14
//
//
// bsg_fifo_1r1w_large
//
// This implementation is specifically
// intended for processes where 1RW rams
// are much cheaper than 1R1W rams, like
// most ASIC processes.
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
                            ) round_robin_n_to_1
     (.clk_i   (clk_i     )
      ,.reset_i(reset_i   )

      ,.data_i (data_int )
      ,.valid_i(valid_int)
      ,.yumi_o (yumi_int )

      ,.data_o (data_o    )
      ,.valid_o(v_o       )
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


`ifdef _SKIP_THIS_CODE

// bsg_fifo_two_port_large_banked
//
//  1R1W large fifo implementation
//
// This implementation is specifically
// intended for processes where 1RW rams
// are much cheaper than 1R1W rams, like
// most ASIC processes.
//
// The FIFO is implemented by instantiating
// two banks. Each bank has a large 1-port
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

// bsg_fifo_two_port_bank
//
// this module is responsible for handling one bank
// of the FIFO.
//
// it is made of a big 1p fifo and a little 2p fifo
//
// the assumption is that the system will never try
// to enque two elements in a row.
//

module bsg_fifo_two_port_large_bank #(parameter width_p = -1
                                    , parameter els_p = -1)
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
   wire [width_p-1:0] big_data_lo, little_data;

   wire               big_enq, big_deq, big_deq_r;

   wire               little_ready_lo;

   // whether we dequed something on the last cycle

   always_ff @(posedge clk)
     big_deq_r <= big_deq;

   // if the big fifo is not full, then we can take more data
   wire ready_o_int = ~big_full_lo;
   assign ready_o   = ready_o_int;

   always_comb
     begin
        little_valid = 1'b0;

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
             big_deq      = (~big_empty_lo & ~big_enq & ~v_o);
          end
        else
          begin
             // clean through bypass mode; skip
             // big fifo and go to little fifo
             if (big_empty_lo)
               begin
                  little_valid = v_i  & little_ready_lo;
                  big_enq      = v_i  & ~little_ready_lo;
                  big_deq      = ~v_i & little_ready_lo;
               end
             else
               // there is data in the big fifo
               // but we did not fetch from it
               // last cycle.
               // we cannot enque anything into
               // the little fifo this cycle.
               begin
                  big_enq = v_i  & ~big_full_lo;
                  big_deq = ~big_enq & little_ready_lo;
               end
          end // else: !if(big_deq_r)

        big_valid    = big_enq | big_deq;
     end

   // if we dequed from the big queue last cycle
   // then we enque it into the little fifo

   wire [width_p-1:0] little_data = big_deq_r ? big_data_lo : data_i;

   bsg_fifo_one_port #(.width_p(width_p)
                       ,.els_p(els_p)
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

   bsg_two_fifo #(.width_p(width_p)) little2p
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



module bsg_fifo_two_port_banked #(parameter width_p         = -1
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

   genvar i;

   wire [1:0]               v_i_demux, ready_o_mux;

   bsg_round_robin_1_to_n #(.width_p(width_p)
                            ,.num_out_p(2)
                            )
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
        bsg_fifo_two_port_bank #(.width(width_p)
                                   ,.els_p(els_p >> 1)
                                   ) bank
            (.clk_i   (clk_i)
             ,.reset_i(reset_i)

             ,.valid_i(v_i_demux  [i])
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


endmodule // bsg_fifo_two_port_banked

`endif // _SKIP_THIS_CODE
