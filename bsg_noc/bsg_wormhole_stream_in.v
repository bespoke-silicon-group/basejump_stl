
`include "bsg_defines.v"

module bsg_wormhole_stream_in
 #(parameter flit_width_p      = "inv"
   , parameter len_width_p     = "inv"
   , parameter cord_width_p    = "inv"
   , parameter pr_hdr_width_p  = "inv"
   , parameter pr_data_width_p = "inv"

   , parameter wh_hdr_width_lp = cord_width_p + len_width_p
   , parameter hdr_width_lp = wh_hdr_width_lp + pr_hdr_width_p
   )
  (input                         clk_i
   , input                       reset_i

   , input [hdr_width_lp-1:0]    hdr_i
   , input                       hdr_v_i
   , output                      hdr_ready_o

   , input [pr_data_width_p-1:0] data_i
   , input                       data_v_i
   , output                      data_ready_o

   , output [flit_width_p-1:0]   link_data_o
   , output                      link_v_o
   , input                       link_ready_i
   );

  enum logic [1:0] {e_hdr, e_data} state_n, state_r;
  wire is_hdr = (state_r == e_hdr);
  wire is_data = (state_r == e_data);

  localparam [len_width_p-1:0] hdr_len_lp = `BSG_CDIV(hdr_width_lp, flit_width_p);

  wire                link_accept = link_ready_i & link_v_o;
  wire [cord_width_p-1:0] cord_li = hdr_i[0+:cord_width_p];
  wire [len_width_p-1:0]   len_li = hdr_i[cord_width_p+:len_width_p] - (hdr_len_lp - 1'b1);

  logic [flit_width_p-1:0] hdr_lo;
  logic hdr_ready_lo, hdr_v_lo, hdr_yumi_li;
  bsg_parallel_in_serial_out
   #(.width_p(flit_width_p)
     ,.els_p(hdr_len_lp)
     )
   hdr_piso
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.data_i(hdr_i)
     ,.valid_i(hdr_v_i)
     ,.ready_o(hdr_ready_lo)

     ,.data_o(hdr_lo)
     ,.valid_o(hdr_v_lo)
     ,.yumi_i(hdr_yumi_li)
     );
  assign hdr_ready_o = hdr_ready_lo & is_hdr;
  assign hdr_yumi_li = hdr_v_lo & link_accept;

  logic [flit_width_p-1:0] data_lo;
  logic data_ready_lo, data_v_lo, data_yumi_li;

  if (pr_data_width_p >= flit_width_p)
    begin : wide
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(pr_data_width_p, flit_width_p);
      bsg_parallel_in_serial_out
       #(.width_p(flit_width_p)
         ,.els_p(data_len_lp)
         )
       data_piso
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(data_i)
         ,.valid_i(data_v_i)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_lo)
         ,.valid_o(data_v_lo)
         ,.yumi_i(data_yumi_li)
         );
    end
  else
    begin : narrow
      localparam [len_width_p-1:0] data_len_lp = `BSG_CDIV(flit_width_p, pr_data_width_p);
      bsg_serial_in_parallel_out_full
       #(.width_p(pr_data_width_p)
         ,.els_p(data_len_lp)
         ,.use_minimal_buffering_p(1)
         )
       data_sipo
        (.clk_i(clk_i)
         ,.reset_i(reset_i)

         ,.data_i(data_i)
         ,.v_i(data_v_i)
         ,.ready_o(data_ready_lo)

         ,.data_o(data_lo)
         ,.v_o(data_v_lo)
         ,.yumi_i(data_yumi_li)
         );
    end
    assign data_ready_o = data_ready_lo & is_data;
    assign data_yumi_li = data_v_lo & link_accept;

  logic [len_width_p-1:0] flit_cnt;
  bsg_counter_set_down
   #(.width_p(len_width_p), .init_val_p(0), .set_and_down_exclusive_p(1))
   flit_counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.set_i(hdr_v_i)
     ,.val_i(len_li)
     ,.down_i(link_accept)
     ,.count_r_o(flit_cnt)
     );
  wire flit_done = (flit_cnt == '0);

  always_comb
    case (state_r)
      e_hdr  : state_n = hdr_v_i ? e_data : e_hdr;
      e_data : state_n = flit_done ? e_hdr : e_data;
      default: state_n = e_hdr;
    endcase

  always_ff @(posedge clk_i)
    if (reset_i)
      state_r <= e_hdr;
    else
      state_r <= state_n;

  assign link_data_o = is_hdr ? hdr_lo   : data_lo;
  assign link_v_o    = is_hdr ? hdr_v_lo : data_v_lo;

  if (hdr_width_lp % flit_width_p != 0)
    $fatal("Header width: %d must be multiple of flit width: %d", hdr_width_lp, flit_width_p);

  if ((pr_data_width_p % flit_width_p != 0) && (flit_width_p % pr_data_width_p != 0))
    $fatal("Protocol data width: %d must be multiple of flit width: %d", pr_data_width_p, flit_width_p);

endmodule

