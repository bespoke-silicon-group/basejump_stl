
`include "bsg_defines.v"

module bsg_wormhole_stream_out
 #(parameter flit_width_p  = "inv"
   , parameter len_width_p     = "inv"
   , parameter cord_width_p    = "inv"
   , parameter pr_hdr_width_p  = "inv"
   , parameter pr_data_width_p = "inv"

   , parameter wh_hdr_width_lp = cord_width_p + len_width_p
   , parameter hdr_width_lp = wh_hdr_width_lp + pr_hdr_width_p
   )
  (input                       clk_i
   , input                     reset_i

   , input [flit_width_p-1:0]  link_data_i
   , input                     link_v_i
   , output                    link_ready_o

   , output [hdr_width_lp-1:0] hdr_o
   , output                    hdr_v_o
   , input                     hdr_yumi_i

   , output [pr_data_width_p-1:0] data_o
   , output                    data_v_o
   , input                     data_yumi_i
   );

  enum logic [1:0] {e_hdr, e_data} state_n, state_r;
  wire is_hdr = (state_r == e_hdr);
  wire is_data = (state_r == e_data);

  localparam [len_width_p-1:0] hdr_len_lp = `BSG_CDIV(hdr_width_lp, flit_width_p);

  wire                link_accept = link_ready_o & link_v_i;

  logic hdr_v_li, hdr_ready_lo;
  assign hdr_v_li = is_hdr & link_v_i;
  bsg_serial_in_parallel_out_full
   #(.width_p(flit_width_p)
     ,.els_p(hdr_len_lp)
     )
   hdr_sipo
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(link_data_i)
     ,.v_i(hdr_v_li)
     ,.ready_o(hdr_ready_lo)

     ,.data_o(hdr_o)
     ,.v_o(hdr_v_o)
     ,.yumi_i(hdr_yumi_i)
     );

  logic data_v_li, data_ready_lo;
  assign data_v_li = is_data & link_v_i;
  if (flit_width_p >= pr_data_width_p)
    begin : narrow
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(flit_width_p, pr_data_width_p);
      bsg_parallel_in_serial_out
       #(.width_p(pr_data_width_p)
         ,.els_p(data_len_lp)
         )
       data_piso
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(link_data_i)
         ,.valid_i(data_v_li)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_o)
         ,.valid_o(data_v_o)
         ,.yumi_i(data_yumi_i)
         );
    end
  else
    begin : narrow
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(pr_data_width_p, flit_width_p);
      bsg_serial_in_parallel_out_full
       #(.width_p(flit_width_p)
         ,.els_p(data_len_lp)
         )
       data_sipo
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(link_data_i)
         ,.valid_i(data_v_li)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_o)
         ,.valid_o(data_v_o)
         ,.yumi_i(data_yumi_i)
         );
    end
    
  wire [len_width_p-1:0] data_len_li = link_data_i[cord_width_p+:len_width_p] - hdr_len_lp + (len_width_p)'(1);

  // count from num_flits to zero, count_r_o==1 means last flit
  logic [len_width_p-1:0] hdr_flit_cnt, data_flit_cnt;

  // Sending last hdr flit
  wire hdr_flit_last  = (hdr_flit_cnt  == (len_width_p)'(1));
  // Sending last data flit
  wire data_flit_last = (data_flit_cnt == (len_width_p)'(1));
  // All hdr flits are sent
  wire hdr_flit_done  = (hdr_flit_cnt  == '0);
  // All data flits are sent
  wire data_flit_done = (data_flit_cnt == '0);

  // Set counter value when new packet hdr arrives
  // and all hdr flits are sent
  // (set data_flit_counter in same cycle)
  wire set_counter    = is_hdr & hdr_flit_done & link_v_i;

  bsg_counter_set_down
   #(.width_p(len_width_p)
     ,.init_val_p(0)
     // allow set down same cycle to aviod bubble
     ,.set_and_down_exclusive_p(0)
     )
   hdr_flit_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.set_i(set_counter)
     ,.val_i(hdr_len_lp)
     ,.down_i(is_hdr & link_accept)
     ,.count_r_o(hdr_flit_cnt)
     );

  bsg_counter_set_down
   #(.width_p(len_width_p)
     ,.init_val_p(0)
     // allow set down same cycle to aviod bubble
     ,.set_and_down_exclusive_p(0)
     )
   data_flit_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.set_i(set_counter)
     ,.val_i(data_len_li)
     ,.down_i(is_data & link_accept)
     ,.count_r_o(data_flit_cnt)
     );

  wire e_hdr_to_e_data;

  // Single hdr flit
  if (hdr_len_lp == 1)
    // When wormhole link accept flit 
    // and data flit non-zero
    // and hdr_v_lo (avoid possible X-pessimism in simulation)
    //
    // (data_flit_done signal takes one cycle to be registered, not useful
    // in this case, extract data_len_li signal directly from hdr)
    assign e_hdr_to_e_data = (link_accept & (link_v_i & data_len_li != '0));
  // Multiple hdr flits
  else
    // When wormhole link accept flit 
    // and sending last hdr flit
    // and data flit non-zero
    //
    // (data_len_li signal only meaningful in first hdr flit, not useful
    // in this case, use registered data_flit_done signal from data_flit_counter)
    assign e_hdr_to_e_data = (link_accept & hdr_flit_last & ~data_flit_done);
  
  // When wormhole link accept flit and sending last data flit
  wire e_data_to_e_hdr = link_accept & data_flit_last;

  always_comb
    case (state_r)
      e_hdr  : state_n = (e_hdr_to_e_data)? e_data : e_hdr;
      e_data : state_n = (e_data_to_e_hdr)? e_hdr : e_data;
      default: state_n = e_hdr;
    endcase

  always_ff @(posedge clk_i)
    if (reset_i)
      state_r <= e_hdr;
    else
      state_r <= state_n;

  assign link_ready_o = is_hdr ? hdr_ready_lo : data_ready_lo;

  if (hdr_width_lp % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_lp, flit_width_p);

  if ((pr_data_width_p % flit_width_p != 0) && (flit_width_p % pr_data_width_p != 0))
    $fatal("Protocol data width: %d must be multiple of flit width: %d", pr_data_width_p, flit_width_p);

endmodule

