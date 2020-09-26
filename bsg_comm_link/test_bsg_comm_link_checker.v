   //************************************************************
   //  CHECKS
   //    ______ _     _ _______ ______ _    _    _
   //   / _____) |   | (_______) _____) |  / )  | |
   //  | /     | |__ | |_____ | /     | | / /    \ \
   //  | |     |  __)| |  ___)| |     | |< <      \ \
   //  | \_____| |   | | |____| \_____| | \ \ _____) )
   //   \______)_|   |_|_______)______)_|  \_|______/
   //
   //
   // Logging.
   //
   // Allow you to see, in time, when values are transmitted and received.
   //
   //
   // For this test, the number of cycles on the slowest clock should match the
   // number of words transmitted plus a small constant.
   //


`include "bsg_defines.v"

module test_bsg_comm_link_checker #(parameter channel_width_p="inv"
                                    , parameter num_channels_p="inv"
                                    , parameter ring_bytes_p="inv"
				    , parameter check_bytes_p="inv"
                                    , parameter verbose_p="inv"
                                    , parameter iterations_p="inv"
                                    , parameter core_0_period_p="inv"
                                    , parameter core_1_period_p="inv"
                                    , parameter io_master_0_period_p="inv"
                                    , parameter io_master_1_period_p="inv"
                                    , parameter chip_num_p=0
                                    , parameter node_num_p=0
                                    , parameter cycle_counter_width_p="inv"
				    , parameter skip_checks_p=0
                                    )
(input  clk
 , input  valid_in
 , input  ready_in
 , input  yumi_out
 , input  [ring_bytes_p*channel_width_p-1:0] data_in
 , input  [ring_bytes_p*channel_width_p-1:0] data_out
 , input  async_reset
 , input  slave_reset_tline
// , input [num_channels_p-1:0] io_clk_tline
 , input [num_channels_p-1:0] io_valid_tline
 , input [channel_width_p-1:0] io_data_tline    [num_channels_p-1:0]
// , input [num_channels_p-1:0]  token_clk_tline
  , input [cycle_counter_width_p-1:0] core_ctr[1:0]
  , input [cycle_counter_width_p-1:0] io_ctr  [1:0]
 , output done_o
 );

   localparam channel_verbose_p = 1'b0;

   // non-synthesizeable; testing only
   logic [5:0] top_bits = 0;


   logic [31:0]                       words_received_r ;
   wire [check_bytes_p*channel_width_p-1:0] data_in_check;
   genvar                                    j;

   always_ff @(negedge clk)
     if (async_reset)
       words_received_r <= 0;
     else
       words_received_r <= words_received_r + (valid_in & ready_in);


   logic 				     done_r;

   assign done_o = done_r;

   test_bsg_data_gen #(.channel_width_p(channel_width_p)
                       ,.num_channels_p(check_bytes_p)
                       ) tbdg_receive
     (.clk_i(clk            )
      ,.reset_i(async_reset        )
      ,.yumi_i (ready_in & valid_in)
      ,.o      (data_in_check)
      );


   always_ff @(negedge clk)
     begin
        if (valid_in & ready_in)
          begin
             if (verbose_p)
               $display("## SR=%1d", slave_reset_tline
                        , core_ctr[0], io_ctr[0], core_ctr[1], io_ctr[1]
                        , " ## chip %1d node %1d recv %-d, %x"
                        , chip_num_p, node_num_p, words_received_r, data_in);

	     if (!skip_checks_p)
             assert (data_in_check == data_in[check_bytes_p*channel_width_p-1:0])
               else
                 begin
                    $error("## transmission error %x, %x, difference = %x"
                           , data_in_check, data_in, data_in_check ^ data_in);
                    // $finish();
                 end

             // we only terminate when all nodes on core 0 have received all the words
             if ((words_received_r
                 >=
                 (iterations_p << (channel_width_p-$clog2(num_channels_p)))
                 ) & (chip_num_p == 0) & ~done_r)
               begin
		  done_r <= 1'b1;

                  $display("## DONE node = %-d words = %-d CHANNEL_BITWIDTH = %-d",node_num_p,words_received_r,channel_width_p
                           ," RING_BYTES = %-d;",ring_bytes_p
                           ," NUM_CHAN = %-d;",num_channels_p
                           ," C0 = %-d;",core_0_period_p
                           ," I0 = %-d; I1 = %-d;",io_master_0_period_p
                           ,io_master_1_period_p
                           ," C1 = %-d;",core_1_period_p,
                           ," (Cycles Per Word) "
                           , real'(core_ctr[0])
                           / real'(words_received_r)
                           ," ", real'(io_ctr  [0])
                           / real'(words_received_r)
                           ," ", real'(io_ctr  [1])
                           / real'(words_received_r)
                           ," ", real'(core_ctr[1])
                           / real'(words_received_r)
                           );
               end
          end

        if (yumi_out)
          if (verbose_p)
            $display("## SR=%1d", slave_reset_tline
                     , core_ctr[0], io_ctr[0], core_ctr[1], io_ctr[1]
                     , " ## chip %1d node %1d sent %x",chip_num_p, node_num_p, data_out);

	if (async_reset) done_r <= 1'b0;

     end // always_ff @

`ifdef BSG_IP_CORES_UNIT_TEST   
`define  TEST_BSG_COMM_LINK_CHECKER_PREFIX core[chip_num_p].
`else
`define TEST_BSG_COMM_LINK_CHECKER_PREFIX 
`endif
   
   // avoid redundant printing of channel info
   if (node_num_p == 0)
   for (j = 0; j < num_channels_p; j=j+1)
     begin
        // in parent

        always @(slave_reset_tline or io_valid_tline[j] or io_data_tline[j]
                 or `TEST_BSG_COMM_LINK_CHECKER_PREFIX guts.comm_link.ch[j].sso.pos_credit_ctr.r_free_credits_r
                 or `TEST_BSG_COMM_LINK_CHECKER_PREFIX guts.comm_link.ch[j].sso.neg_credit_ctr.r_free_credits_r
                 )
          if (verbose_p)
            begin
               if (channel_verbose_p)
               $display("## SR=%1d", slave_reset_tline
                        , core_ctr[0], io_ctr[0], core_ctr[1], io_ctr[1],
                        " ## chip %1d channel %1d", chip_num_p, j, " (p,n)=(%2d %2d)"
                        , `TEST_BSG_COMM_LINK_CHECKER_PREFIX guts.comm_link.ch[j].sso.pos_credit_ctr.r_free_credits_r
                        , `TEST_BSG_COMM_LINK_CHECKER_PREFIX guts.comm_link.ch[j].sso.neg_credit_ctr.r_free_credits_r
                        , " ## io     xmit %1d,%x"
                        , io_valid_tline[j],io_data_tline[j]
                        );
            end
    end // for (j = 0; j < num_channels_p; j=j+1)

endmodule
