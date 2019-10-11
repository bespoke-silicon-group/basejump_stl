// MBT 8-18-2014
//
// Takes num_in_p channels and then
// blocking round robin transmits the words across num_out_p channels.
//
//
// Interface: valid/yumi on input; and ready/valid on output.
//
// Example: 10 byte-wide channels in, and 4 byte-wide channels out.
//          4 byte-wide channels in, and 10 byte-wide channels out.
//
//

// bsg_rr_f2f_input
//
// this takes a number of input channel data and valid signals
// rotates them so that highest priority channel is at position 0
// the next highest at 1, etc. this is the so called "intermediate"
// representation; where channels are reordered accord to round-robin
// priority.
//
// the module also rotates a set of yumi signals from the intermediate
// representation (go_channels_i) back to the input representation
// to facilitate dequeing from those original input channels.
//

//`include "bsg_defines.v"

module bsg_rr_f2f_input #(parameter   width_p              = "inv"
                          , parameter num_in_p             = 0
                          , parameter middle_meet_p        = 0
                          , parameter middle_meet_data_lp  = middle_meet_p * width_p
                          , parameter min_in_middle_meet_p = `BSG_MIN(num_in_p,middle_meet_p)
                          )
   (input clk, input  reset

    // primary input
    , input  [num_in_p-1:0] valid_i
    , input  [width_p-1:0]  data_i [num_in_p-1:0]

    // to intermediate module; only send as many as middle will look at
    // note: middle_meet may be < num_in_p because num_out_p < num_in_p
    //       middle_meet may be > num_in_p because other input modules may have greater num_in_p

    , output [width_p-1:0]  data_head_o [middle_meet_p-1:0]
    , output [middle_meet_p-1:0] valid_head_o

    // from intermediate module
    , input  [min_in_middle_meet_p-1:0] go_channels_i

    // may be smaller than middle_meet because any sends are
    // limited by how many one's we output
    , input  [$clog2(min_in_middle_meet_p+1)-1:0] go_cnt_i

    // final output
    , output [num_in_p-1:0] yumi_o
    );

   logic [`BSG_SAFE_CLOG2(num_in_p)-1:0] iptr_r, iptr_r_data;

   wire [width_p*num_in_p-1:0]      data_i_flat = ({ >> {data_i} });
   wire [width_p*middle_meet_p-1:0] data_head_o_flat;

   // 2D array format converters
   //bsg_flatten_2D_array #(.width_p(width_p), .items_p(num_in_p))
   //bf2Da (.i(data_i),           .o(data_i_flat));

   bsg_make_2D_array    #(.width_p(width_p), .items_p(middle_meet_p))
   bm2Da (.i(data_head_o_flat), .o(data_head_o));

   // rotate the valid and data vectors from incoming channel
   wire [num_in_p-1:0] 		    valid_head_o_pretrunc;

   bsg_rotate_right #(.width_p(num_in_p)) valid_rr (.data_i(valid_i), .rot_i(iptr_r), .o(valid_head_o_pretrunc));

   wire [2*width_p*num_in_p-1:0] data_head_o_flat_pretrunc
                                 =  { 2 { data_i_flat } } >> (iptr_r_data*width_p);

   wire [num_in_p*2-1:0]         yumi_intermediate;

   // rotate the yumi and valid signal to account for round-robin
   if (num_in_p >= middle_meet_p)
     begin
        assign  valid_head_o      =  valid_head_o_pretrunc    [0+:middle_meet_p        ];
        assign  data_head_o_flat  =  data_head_o_flat_pretrunc[0+:width_p*middle_meet_p];
        assign  yumi_intermediate =  { 2 { num_in_p ' (go_channels_i) } } << iptr_r;
     end
   else
     begin
        assign  valid_head_o      =  middle_meet_p      ' (valid_head_o_pretrunc    [0+:num_in_p             ]);
        assign  data_head_o_flat  =  middle_meet_data_lp ' (data_head_o_flat_pretrunc[0+:width_p*num_in_p]);
        assign  yumi_intermediate = { 2 { go_channels_i } } << iptr_r;
     end

   assign yumi_o             = yumi_intermediate[num_in_p +:num_in_p];

   bsg_circular_ptr #(.slots_p(num_in_p)
                      ,.max_add_p(min_in_middle_meet_p)
                      ) c_ptr
     (.reset_i(reset), .clk(clk)
      ,.add_i(go_cnt_i)
      ,.o(iptr_r)
      ,.n_o()
      );

   // we duplicate this logic for physical design because control and data do not always belong together
   bsg_circular_ptr #(.slots_p(num_in_p)
                      ,.max_add_p(min_in_middle_meet_p)
                      ) c_ptr_data
     (.reset_i(reset), .clk(clk)
      ,.add_i(go_cnt_i)
      ,.o(iptr_r_data)
      ,.n_o()
      );

endmodule // bsg_rr_f2f_input

// bsg_rr_f2f_output
//
// this takes a number of output channel ready signals and
// rotates them to the intermediate representation (highest = 0)
// according to their priority.

// the intermediate module takes these output ready signals, combines
// with the input channel's valid signals to derive a set of
// "go" intermediate signals. these are shifted by this module
// to align with the output channels.

// the module also takes the input channel data at the intermediate
// representation and shifts it to align with output channels
// according to priority.

module bsg_rr_f2f_output #(parameter width_p="inv"
                           ,parameter num_out_p=0
                           ,parameter middle_meet_p=-1
                           ,parameter min_out_middle_meet_lp = `BSG_MIN(num_out_p,middle_meet_p)
                           )
   (input clk, input reset

    // primary input
    , input  [num_out_p-1:0]     ready_i

    // out to intermediate module
    , output  [middle_meet_p-1:0]    ready_head_o

    // in from intermediate module
    , input [min_out_middle_meet_lp-1:0] go_channels_i
    , input [$clog2(min_out_middle_meet_lp+1)-1:0] go_cnt_i

    , input [width_p-1:0]      data_head_i[min_out_middle_meet_lp-1:0]

    // final output
    , output [num_out_p-1:0]   valid_o
    , output [width_p-1:0]     data_o [num_out_p-1:0]
    );

   logic [`BSG_SAFE_CLOG2(num_out_p)-1:0] optr_r, optr_r_data;

   // instantiate module so we can cluster this logic in physical design
   // wire [num_out_p*2-1:0] 		  ready_head_o_pretr = { 2 { ready_i } } >> optr_r;

   wire [num_out_p-1:0] 		  ready_head_o_pretr;
   bsg_rotate_right #(.width_p(num_out_p)) ready_rr (.data_i(ready_i), .rot_i(optr_r), .o(ready_head_o_pretr));

   wire [num_out_p*2-1:0]    valid_pretr;

   if (num_out_p >= middle_meet_p)
     begin
        assign ready_head_o  = ready_head_o_pretr[0+:middle_meet_p];
        assign valid_pretr   = { 2 { num_out_p ' (go_channels_i) } } << optr_r;
     end
   else
     begin
        assign ready_head_o  = middle_meet_p ' (ready_head_o_pretr[0+:num_out_p]);
        assign valid_pretr   = {2 { go_channels_i } } << optr_r;
     end

   assign valid_o                     = valid_pretr[num_out_p+:num_out_p];

   genvar                 i;
   wire [width_p-1:0] data_head_double [num_out_p*2-1:0];

   for (i = 0; i < num_out_p; i=i+1)
     begin
        if (i < middle_meet_p)
          begin
             assign data_head_double[i]            = data_head_i[i];
             assign data_head_double[i+num_out_p]  = data_head_i[i];
          end
        else
          begin
             assign data_head_double[i]            = width_p ' (0);
             assign data_head_double[i+num_out_p]  = width_p ' (0);
          end
        assign data_o[i] = data_head_double[(i+num_out_p)-optr_r_data];
     end

   bsg_circular_ptr #(.slots_p(num_out_p)
                      ,.max_add_p(min_out_middle_meet_lp)
                      ) c_ptr
     (.clk(clk), .reset_i(reset)
      ,.add_i(go_cnt_i)
      ,.o(optr_r)
      ,.n_o()
      );


   // duplicate logic for physical design
   bsg_circular_ptr #(.slots_p(num_out_p)
                      ,.max_add_p(min_out_middle_meet_lp)
                      ) c_ptr_data
     (.clk(clk), .reset_i(reset)
      ,.add_i(go_cnt_i)
      ,.o(optr_r_data)
      ,.n_o()
      );


endmodule

// bsg_rr_f2f_middle
//
// this intermediate module takes the input valids
// and the output readies and derives the go_channel signals.
// it ensures that only a continuous run of channels are
// selected to "go", ensuring a true rigid round-robin priority
// on both inputs and outputs.

module bsg_rr_f2f_middle #(parameter width_p="inv"
                           , parameter middle_meet_p=1
                           , parameter use_popcount_p=0
                           )
   (input    [middle_meet_p-1:0]            valid_head_i
    , input  [middle_meet_p-1:0]            ready_head_i
    , output [middle_meet_p-1:0]            go_channels_o
    , output [$clog2(middle_meet_p+1)-1:0]  go_cnt_o
    );

   wire [middle_meet_p-1:0] happy_channels  = valid_head_i & ready_head_i;
   wire [middle_meet_p-1:0] go_channels_int;

   bsg_scan #(.width_p(middle_meet_p)
              ,.and_p(1)
              ,.lo_to_hi_p(1)
              ) and_scan (.i(happy_channels), .o(go_channels_int));

   assign go_channels_o = go_channels_int;

   // speedfix: this hack helps the critical path but net impact is fairly
   // small (.04 ns in tsmc 250)
   // it implements a priority encoder based on
   // both the original pattern and the scan.
if (0)
//   if (middle_meet_p==4)
     begin
	wire hi11 = &happy_channels[3:2];
	wire lo01 = ~happy_channels[1] & happy_channels[0];
	wire hi01 = ~happy_channels[3] & happy_channels[2];

	assign go_cnt_o[2] = go_channels_int[3];
	assign go_cnt_o[1] = ~hi11 & go_channels_int[1];
	assign go_cnt_o[0] = lo01 | (go_channels_int[1] & hi01);
     end
   else
     begin
	if (use_popcount_p)
	  bsg_popcount          #(.width_p(middle_meet_p)) pop    (.i(go_channels_int), .o(go_cnt_o));
	else
	  bsg_thermometer_count #(.width_p(middle_meet_p)) thermo (.i(go_channels_int), .o(go_cnt_o));
     end
endmodule

// bsg_round_robin_fifo_to_fifo
//
// at its simplest, this module instantiates the appropriate
// input, intermediate and output modules
// to create a complete round-robin fifo-to-fifo
// transfer engine.
//
// the module also supports variable numbers of input
// and output channels. it does this by using parameter masks to
// specific which input and output modules should be instantiated.
//
// inputs in_top_channel_i and out_top_channel_i allow the number
// of channels to change semi-dynamically (it is advisable to
// empty both inputs and outputs channels before doing so.)
//

module bsg_round_robin_fifo_to_fifo
  #(parameter width_p="inv"
    ,parameter num_in_p=-1
    ,parameter num_out_p=1

    // bitvector; set bit "X" if you want to
    // support a mode where a subset X of channels are enabled
    // note each bit set adds a couple of shifters
    // so this is not free. default is to not support any subsets

    ,parameter in_channel_count_mask_p = (1 << (num_in_p-1))
    ,parameter out_channel_count_mask_p = (1 << (num_out_p-1))
    )
   (input clk, input  reset

    // input side
    , input  [num_in_p-1:0] valid_i
    , input  [width_p-1:0]  data_i [num_in_p-1:0]
    , output [num_in_p-1:0] yumi_o

    // high water mark of how many total channels are activated.
    // e.g; if one channel is activated, it would be at 0.
    , input  [`BSG_MAX($clog2(num_in_p)-1,0):0]  in_top_channel_i
    , input  [`BSG_MAX($clog2(num_out_p)-1,0):0] out_top_channel_i

    // output side
    , output [num_out_p-1:0]   valid_o
    , output [width_p-1:0]     data_o [num_out_p-1:0]
    , input  [num_out_p-1:0]   ready_i
    );

   localparam middle_meet_lp= `BSG_MIN(num_in_p,num_out_p);

   wire [middle_meet_lp-1:0]   go_channels;

   wire [middle_meet_lp*width_p-1:0] data_head  [num_in_p-1:0];
   wire [middle_meet_lp-1:0]         valid_head [num_in_p-1:0];
   wire [middle_meet_lp-1:0]         ready_head [num_out_p-1:0];
   wire [num_in_p-1:0]         yumi_int_o [num_in_p-1:0];


   wire [num_out_p-1:0]         valid_int_o[num_out_p-1:0];
   wire [width_p*num_out_p-1:0] data_int_o[num_out_p-1:0];

   // this is for supporting variable numbers of active
   // input and output channels

   assign yumi_o  = yumi_int_o[in_top_channel_i];
   assign valid_o = valid_int_o[out_top_channel_i];

   typedef logic [width_p*num_out_p-1:0] bsg_round_robin_fifo_to_fifo_t;

   wire [width_p*num_out_p-1:0] data_o_flat = data_int_o[out_top_channel_i];
   bsg_round_robin_fifo_to_fifo_t zero_flat;

   wire [$clog2(middle_meet_lp+1)-1:0]   go_cnt;

   assign zero_flat = bsg_round_robin_fifo_to_fifo_t ' (0);

   // 2D array format converters
   // bsg_flatten_2D_array #(.width_p(width_p), .items_p(num_in_p)) bf2Da (.i(data_i),           .o(data_i_flat));
   bsg_make_2D_array #(.width_p(width_p), .items_p(num_out_p))
   bm2Da (.i(data_o_flat), .o(data_o));

   genvar                      i,j;

   // we generate separate input side logic to handle
   // different numbers of input channels
   for (i = 0; i < num_in_p; i++)
     begin: ic
        if (in_channel_count_mask_p[i])
          begin : in_chan
             wire [width_p-1:0] data_head_tmp [middle_meet_lp-1:0];

             //bsg_flatten_2D_array #(.width_p(width_p), .items_p(middle_meet_lp))
             //bf2Da (.i(data_head_tmp),.o(data_head[i]));

	     assign data_head[i] = { >> {data_head_tmp} };

             // INPUT SIDE (input: valid_i, data_i; middle input; go_channels)
             bsg_rr_f2f_input #(.width_p(width_p)
                                ,.num_in_p(i+1)
                                ,.middle_meet_p(middle_meet_lp)
                                ) bsg_rr_ff_in
               (.clk(clk), .reset(reset | (in_top_channel_i != i))
                , .valid_i(valid_i[i:0])               // inputs
                , .data_i(data_i[i:0])

                , .data_head_o(data_head_tmp)         // back to us
                ,. valid_head_o(valid_head[i])

                , .go_channels_i(go_channels[`BSG_MIN(i+1,middle_meet_lp)-1:0])     // back to them
                , .go_cnt_i(go_cnt[$clog2(`BSG_MIN(i+1,middle_meet_lp)+1)-1:0])
                , .yumi_o(yumi_int_o[i][i:0])                 // final output
                );

	     // MBT: this is redundant with the cast inside bsg_rr_f2f_input
	     // and results in a synthesis warning
	     /*
             for (j = i+1; j < middle_meet_lp; j=j+1)
	       begin
                  assign valid_head[i][j] = 1'b0;
	       end
	      */

             for (j = i+1; j < num_in_p; j=j+1)
	       begin
                  assign yumi_int_o[i][j] = 1'b0;
	       end

          end // if (in_channel_count_mask_p[i])
     end // block: c

   // MIDDLE (ties INPUT to OUTPUT)

   bsg_rr_f2f_middle #(.width_p(width_p)
                       ,.middle_meet_p(middle_meet_lp)
                       ) brrf2fm
   (.valid_head_i(valid_head[in_top_channel_i])
    , .ready_head_i(ready_head[out_top_channel_i])
    , .go_channels_o(go_channels)
    , .go_cnt_o(go_cnt)
    );

   // OUTPUT SIDE

   for (i = 0; i < num_out_p; i++)
     begin: oc
        if (out_channel_count_mask_p[i])
              begin: out_chan
                 wire [width_p-1:0] data_head_array [`BSG_MIN(i+1,middle_meet_lp)-1:0];
                 wire [width_p-1:0] data_o_array [i:0];

                 bsg_make_2D_array #(.width_p(width_p), .items_p(`BSG_MIN(i+1,middle_meet_lp)))
                 bm2Da (.i( data_head[in_top_channel_i][0+:`BSG_MIN(i+1,middle_meet_lp)*width_p])
                        ,.o(data_head_array));

                 //bsg_flatten_2D_array #(.width_p(width_p), .items_p(i+1))
                 //bf2Da (.i(data_o_array), .o(data_int_o[i][width_p*(i+1)-1:0]));

		 assign data_int_o[i][width_p*(i+1)-1:0] = { >> {data_o_array}};

                 bsg_rr_f2f_output #(.width_p(width_p)
                                     ,.num_out_p(i+1)
                                     ,.middle_meet_p(middle_meet_lp)
                                     ) bsg_rr_ff_out
                   (.clk(clk), .reset(reset | (out_top_channel_i != i))
                    , .ready_i(ready_i[i:0])
                    , .ready_head_o(ready_head[i])   // back to us

                    , .go_channels_i(go_channels[`BSG_MIN(i+1,middle_meet_lp)-1:0]) // back to them
                    , .go_cnt_i(go_cnt[$clog2(`BSG_MIN(i+1,middle_meet_lp)+1)-1:0])
                    , .data_head_i(data_head_array)

                    , .valid_o(valid_int_o[i][i:0])           // final outputs
                    , .data_o(data_o_array)
                    );

                 for (j = i+1; j < num_out_p; j=j+1)
                   begin
                      assign valid_int_o[i][j] = 1'b0;
                   end
                 if (num_out_p - i > 1)
                   assign data_int_o[i][width_p*num_out_p-1:width_p*(i+1)]
                     = zero_flat[0+: (width_p*(num_out_p-(i+1)))];
              end // block: iff
     end // block: c


endmodule // bsg_assembler_out

