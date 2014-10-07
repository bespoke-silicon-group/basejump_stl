// mbt 9-7-14
//
// bsg_sbox
//
// The switchbox concentrates working channel signals to reduce
// the complexity of downstream logic.
//

module bsg_sbox
  #(parameter   num_channels_p   = "inv"
    , parameter channel_width_p  = "inv"
    )
   (input                         clk_i
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

   logic [$clog2(num_channels_p)*num_channels_p-1:0]   fwd_sel  , fwd_dpath_sel
                                                      ,fwd_sel_r, fwd_dpath_sel_r;

   logic [$clog2(num_channels_p)*num_channels_p-1:0]   bk_sel  ,  bk_dpath_sel
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

   for (i = 0; i < num_channels_p; i = i + 1)
     begin : sbox
        assign in_v_o[i]
          = in_v_i [fwd_sel_r[i*$clog2(num_channels_p)+:$clog2(num_channels_p)]];

        assign in_yumi_o[i]
          = in_yumi_i[bk_sel_r[i*$clog2(num_channels_p)+:$clog2(num_channels_p)]];

        // shift forward data over to exclude data that cannot be selected
        wire [channel_width_p-1:0] forward [num_channels_p-i-1:0];

        for (j = 0; j < num_channels_p - i; j++)
          begin
             assign forward[j] = in_data_i[i+j];
          end

        assign in_data_o[i]
          = forward[fwd_dpath_sel_r[(i*$clog2(num_channels_p))+:$clog2(num_channels_p)]];

        assign out_me_v_o[i]
          = out_me_v_i [bk_sel_r[(i*$clog2(num_channels_p))+:$clog2(num_channels_p)]];

        assign out_me_ready_o[i]
          = out_me_ready_i[fwd_sel_r[(i*$clog2(num_channels_p))+:$clog2(num_channels_p)]];

        // shift backward data over to exclude data that cannot be selected
        wire [channel_width_p-1:0] backward [i+1-1:0];

        for (j = 0; j <= i; j++)
          begin
             assign backward[j] = out_me_data_i[j];
          end

        assign out_me_data_o[i]
          = backward[bk_dpath_sel_r[(i*$clog2(num_channels_p))+:$clog2(num_channels_p)]];
     end

endmodule

//
// end SBOX
// *********************************************************************
