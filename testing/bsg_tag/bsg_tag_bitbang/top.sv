
`include "bsg_defines.sv"
`include "bsg_tag.svh"

module top
    import bsg_tag_pkg::bsg_tag_s;
();

// Choose your config here:
parameter els_p = 4; // number of tag client
parameter width_p = 32; // data width in each tag client

localparam lg_width_lp = `BSG_WIDTH(width_p);

initial begin
   $vcdplusfile("dump.vpd");
   $vcdpluson();
end

bit master_clk, client_clk;
logic reset_li;
logic data_li;
logic v_li;
logic ready_and_lo;

logic tag_clk_r_lo;
logic tag_data_r_lo;

// Any clock freq works as long as master clock freq <= client clock freq
always #4 master_clk = ~master_clk;
always #3 client_clk = ~client_clk;


`declare_bsg_tag_header_s(els_p, lg_width_lp)

testbench #(
   .els_p(els_p)
  ,.width_p(width_p)
) testbench (
   .clk_i(master_clk)
  ,.reset_o(reset_li)
  ,.data_o(data_li)
  ,.v_o(v_li)
  ,.ready_and_i(ready_and_lo)
);

bsg_tag_s [els_p-1:0] tag;
logic [els_p-1:0][width_p-1:0] client_data_r_lo;

bsg_tag_bitbang bsg_tag_bitbang (
   .clk_i(master_clk)
  ,.reset_i(reset_li)
  ,.data_i(data_li)
  ,.v_i(v_li)
  ,.ready_and_o(ready_and_lo)

  ,.tag_clk_r_o(tag_clk_r_lo)
  ,.tag_data_r_o(tag_data_r_lo)
);

bsg_tag_master_decentralized #(
   .els_p(els_p)
  ,.local_els_p(els_p)
  ,.lg_width_p(lg_width_lp)
) master (
   .clk_i(tag_clk_r_lo)
  ,.data_i(tag_data_r_lo)
  ,.node_id_offset_i(0)
  ,.clients_o(tag)
);

for(genvar i = 0;i < els_p;i++) begin: client

  bsg_tag_client #(
     .width_p(width_p)
  ) client (
     .bsg_tag_i(tag[i])
    ,.recv_clk_i(client_clk)
    ,.recv_new_r_o() // UNUSED
    ,.recv_data_r_o(client_data_r_lo[i])
  );

end
endmodule
