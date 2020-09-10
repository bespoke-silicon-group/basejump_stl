// mbt 9-7-14
//
// bsg_sbox
//
// The switchbox concentrates working channel signals to reduce
// the complexity of downstream logic.
//
// the one_hot_p option selectively uses one-hot muxes,
// pipelining the mux decode logic at the expensive of
// energy and area.
//
// pipeline_indir_p and pipeline_outdir_p add
// pipelining (two element fifos) in each direction
//
// NB: An implementation based on Benes networks could potentially
// use less area, at the cost of complexity and wire congestion.
//

`include "bsg_defines.v"

module bsg_sbox
  #(parameter   num_channels_p    = "inv"
    , parameter channel_width_p   = "inv"
    , parameter pipeline_indir_p  = 0
    , parameter pipeline_outdir_p = 0
    , parameter one_hot_p         = 1
    )
   (input                         clk_i
    , input reset_i

    , input calibration_done_i
    // which channels are active
    , input [num_channels_p-1:0] channel_active_i

    // unconcentrated to concentrated
    , input  [num_channels_p-1:0 ] in_v_i
    , input  [channel_width_p-1:0] in_data_i [num_channels_p-1:0]
    , output [num_channels_p-1:0 ] in_yumi_o

    , output [num_channels_p-1:0 ] in_v_o
    , output [channel_width_p-1:0] in_data_o [num_channels_p-1:0]
    , input  [num_channels_p-1:0 ] in_yumi_i

    // concentrated to unconcentrated
    , input  [num_channels_p-1:0 ] out_me_v_i
    , input  [channel_width_p-1:0] out_me_data_i [num_channels_p-1:0]
    , output [num_channels_p-1:0 ] out_me_ready_o

    , output [num_channels_p-1:0 ] out_me_v_o
    , output [channel_width_p-1:0] out_me_data_o [num_channels_p-1:0]
    , input  [num_channels_p-1:0 ] out_me_ready_i
    );

   logic [`BSG_SAFE_CLOG2(num_channels_p)*num_channels_p-1:0]   fwd_sel  , fwd_dpath_sel
                                                               ,fwd_sel_r, fwd_dpath_sel_r;

   logic [`BSG_SAFE_CLOG2(num_channels_p)*num_channels_p-1:0]   bk_sel  ,  bk_dpath_sel
                                                               ,bk_sel_r,  bk_dpath_sel_r;



   genvar i,j;

   bsg_scatter_gather #(.vec_size_lp(num_channels_p)) bsg
     (.vec_i(channel_active_i)
      ,.fwd_o         (fwd_sel      )
      ,.fwd_datapath_o(fwd_dpath_sel)
      ,.bk_o          (bk_sel       )
      ,.bk_datapath_o (bk_dpath_sel )
      );

   always @(posedge clk_i)
     begin
        fwd_sel_r        <= fwd_sel;
        fwd_dpath_sel_r  <= fwd_dpath_sel;
        bk_sel_r         <= bk_sel;
        bk_dpath_sel_r   <= bk_dpath_sel;
     end

   wire [num_channels_p-1:0 ] in_v_o_int;
   wire [channel_width_p-1:0] in_data_o_int [num_channels_p-1:0];
   wire [num_channels_p-1:0 ] in_yumi_i_int;

   wire [num_channels_p-1:0 ] out_me_v_i_int;
   wire [channel_width_p-1:0] out_me_data_i_int [num_channels_p-1:0];
   wire [num_channels_p-1:0 ] out_me_ready_o_int;


   for (i = 0; i < num_channels_p; i = i + 1)
     begin : sbox

        if (one_hot_p)
          begin : fi1hot
             logic [num_channels_p-1:0][num_channels_p-1:0] fwd_sel_one_hot_r;

             always @(posedge clk_i)
               fwd_sel_one_hot_r[i] <= (1 << fwd_sel[i*`BSG_SAFE_CLOG2(num_channels_p)+:`BSG_SAFE_CLOG2(num_channels_p)]);

             assign in_v_o_int[i]        = |(in_v_i & fwd_sel_one_hot_r[i]);
          end
        else
             assign in_v_o_int[i]
               = in_v_i [fwd_sel_r[i*`BSG_SAFE_CLOG2(num_channels_p)+:`BSG_SAFE_CLOG2(num_channels_p)]];

        assign in_yumi_o[i]
          = in_yumi_i_int[bk_sel_r[i*`BSG_SAFE_CLOG2(num_channels_p)+:`BSG_SAFE_CLOG2(num_channels_p)]];

        // shift forward data over to exclude data that cannot be selected
        wire [channel_width_p-1:0] forward [num_channels_p-i-1:0];

        for (j = 0; j < num_channels_p - i; j++)
          begin
             assign forward[j] = in_data_i[i+j];
          end

        assign in_data_o_int[i]
          = forward[fwd_dpath_sel_r[(i*`BSG_SAFE_CLOG2(num_channels_p))+:`BSG_SAFE_CLOG2(num_channels_p)]];

        assign out_me_v_o[i]
          = out_me_v_i_int [bk_sel_r[(i*`BSG_SAFE_CLOG2(num_channels_p))+:`BSG_SAFE_CLOG2(num_channels_p)]];

        assign out_me_ready_o_int[i]
          = out_me_ready_i[fwd_sel_r[(i*`BSG_SAFE_CLOG2(num_channels_p))+:`BSG_SAFE_CLOG2(num_channels_p)]];

        // shift backward data over to exclude data that cannot be selected
        wire [channel_width_p-1:0] backward [i+1-1:0];

        for (j = 0; j <= i; j++)
          begin : rofj
             assign backward[j] = out_me_data_i_int[j];
          end

        assign out_me_data_o[i]
          = backward[bk_dpath_sel_r[(i*`BSG_SAFE_CLOG2(num_channels_p))+:`BSG_SAFE_CLOG2(num_channels_p)]];

        if (pipeline_indir_p)
          begin :pipe_in
             wire ready_int;
             assign in_yumi_i_int[i] = ready_int & in_v_o_int[i];

             bsg_two_fifo #(.width_p(channel_width_p)) infifo
             (.clk_i(clk_i)
              ,.reset_i(reset_i)

              ,.ready_o(ready_int)
              ,.data_i(in_data_o_int[i])
              ,.v_i   (in_v_o_int   [i] & calibration_done_i)
              ,.v_o   (in_v_o       [i])
              ,.data_o(in_data_o    [i])
              ,.yumi_i(in_yumi_i    [i])
              );
          end
        else
          begin : pipe_in
	     // default: route signals out
             assign in_v_o       [i] = in_v_o_int   [i];
             assign in_data_o    [i] = in_data_o_int[i];
             assign in_yumi_i_int[i] = in_yumi_i    [i];
          end

        if (pipeline_outdir_p)
          begin : pipe_out
             bsg_two_fifo #(.width_p(channel_width_p)) outfifo
             (.clk_i(clk_i)
              ,.reset_i(reset_i)

              ,.ready_o(out_me_ready_o   [i])
              ,.data_i(out_me_data_i     [i])
              ,.v_i   (out_me_v_i        [i] & calibration_done_i)

              ,.v_o   (out_me_v_i_int    [i])
              ,.data_o(out_me_data_i_int [i])
              ,.yumi_i(out_me_ready_o_int [i] & out_me_v_i_int[i])
              );
          end
        else
          begin : pipe_out
	     // default: route signals out
             assign out_me_v_i_int     [i] = out_me_v_i    [i];
             assign out_me_data_i_int  [i] = out_me_data_i [i];
             assign out_me_ready_o     [i] = out_me_ready_o_int [i];
          end



     end



endmodule

//
// end SBOX
// *********************************************************************
