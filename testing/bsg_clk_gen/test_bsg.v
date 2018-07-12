`define WIDTH_P 8   // unused for now...
`define NUM_ADGS_P 1

`include "bsg_tag.vh"

module test_bsg;

   import bsg_tag_pkg::bsg_tag_s;

   localparam bsg_num_adgs_lp  = `NUM_ADGS_P;
   localparam bsg_ds_width_lp  = `WIDTH_P;
   localparam bsg_tag_els_lp  = 2;

   `declare_bsg_clk_gen_osc_tag_payload_s(bsg_num_adgs_lp)
   `declare_bsg_clk_gen_ds_tag_payload_s(bsg_ds_width_lp)

   localparam max_payload_length_lp    = `BSG_MAX($bits(bsg_clk_gen_osc_tag_payload_s),$bits(bsg_clk_gen_ds_tag_payload_s));
   localparam lg_max_payload_length_lp = $clog2(max_payload_length_lp+1);

   `declare_bsg_tag_header_s(bsg_tag_els_lp,lg_max_payload_length_lp)

   wire clk_i, reset_i, bsg_tag_clk_o, bsg_tag_en_o, bsg_tag_data_o;

   wire [1:0] bsg_clk_gen_sel_o;
   wire       bsg_clk_gen_external_clk_o;
   wire       bsg_clk_gen_async_reset_o;
   wire       bsg_clk_gen_i;
   wire       ext_clk_i;

   bsg_nonsynth_clock_gen #(5ns) cfg_clk_gen (ext_clk_i);

   bsg_nonsynth_clk_gen_tester #(.num_adgs_p(bsg_num_adgs_lp)
                                 ,.ds_width_p(bsg_ds_width_lp)
                                 ,.tag_els_p(bsg_tag_els_lp)
                                 ) tester
     (.ext_clk_i
      ,.bsg_tag_clk_o
      ,.bsg_tag_en_o
      ,.bsg_tag_data_o

      ,.bsg_clk_gen_sel_o
      ,.bsg_clk_gen_async_reset_o

      ,.bsg_clk_gen_i
      );

  // Enable VPD dump file
  //
  initial
    begin
      $vcdpluson;
      $vcdplusmemon;
    end


  // Clock generator signals
  //

   bsg_tag_s [1:0] tags;

   bsg_tag_master #(.els_p(bsg_tag_els_lp)
                    ,.lg_width_p(lg_max_payload_length_lp)
                    ) btm
     (.clk_i       (bsg_tag_clk_o)
      ,.data_i     (bsg_tag_data_o)
      ,.en_i       (bsg_tag_en_o)
      ,.clients_r_o(tags)
      );

  bsg_clk_gen #(.downsample_width_p(bsg_ds_width_lp), .num_adgs_p(bsg_num_adgs_lp)) DUT
    (.bsg_osc_tag_i(tags[0])
     ,.bsg_ds_tag_i(tags[1])
     ,.async_osc_reset_i(bsg_clk_gen_async_reset_o)

    ,.ext_clk_i
    ,.select_i(bsg_clk_gen_sel_o)
    ,.clk_o(bsg_clk_gen_i)
    );


endmodule
