/* BEGIN BaseJump STL Manifest
git HASH ae0e5d469735734b40fcf983b6b51afff28fa057
     126     296    2165 ../bsg_noc/bsg_mesh_router_pkg.v
      11      35     352 ../bsg_noc/bsg_noc_pkg.v
     199     453    4541 ../bsg_noc/bsg_mesh_router.v
     197     490    5593 ../bsg_noc/bsg_mesh_router_buffered.v
     221     828    6315 ../bsg_noc/bsg_mesh_router_decoder_dor.v
      65     259    2497 ../bsg_noc/bsg_mesh_stitch.v
      21      45     304 ../bsg_misc/bsg_abs.v
      14      44     352 ../bsg_misc/bsg_adder_cin.v
      54     191    1346 ../bsg_misc/bsg_adder_one_hot.v
      19      43     323 ../bsg_misc/bsg_adder_ripple_carry.v
      12      27     229 ../bsg_misc/bsg_and.v
      28      70     717 ../bsg_misc/bsg_arb_fixed.v
      72     288    2359 ../bsg_misc/bsg_arb_round_robin.v
      22      45     557 ../bsg_misc/bsg_array_concentrate_static.v
      18      40     333 ../bsg_misc/bsg_array_reverse.v
      64     248    1777 ../bsg_misc/bsg_binary_plus_one_to_gray.v
      11      21     189 ../bsg_misc/bsg_buf.v
      12      31     246 ../bsg_misc/bsg_buf_ctrl.v
      77     277    2269 ../bsg_misc/bsg_circular_ptr.v
      13      26     259 ../bsg_misc/bsg_clkbuf.v
      34     145    1151 ../bsg_misc/bsg_clkgate_optional.v
      25      67     630 ../bsg_misc/bsg_concentrate_static.v
      48     190    1534 ../bsg_misc/bsg_counter_clear_up.v
      49     297    1913 ../bsg_misc/bsg_counter_clear_up_one_hot.v
      37     126     996 ../bsg_misc/bsg_counter_clock_downsample.v
      24      81     689 ../bsg_misc/bsg_counter_dynamic_limit.v
      34     104    1126 ../bsg_misc/bsg_counter_dynamic_limit_en.v
      26      65     646 ../bsg_misc/bsg_counter_overflow_en.v
      29      69     723 ../bsg_misc/bsg_counter_overflow_set_en.v
      65     184    1479 ../bsg_misc/bsg_counter_set_down.v
      36      71     627 ../bsg_misc/bsg_counter_set_en.v
      69     364    2673 ../bsg_misc/bsg_counter_up_down.v
      51     213    1887 ../bsg_misc/bsg_counter_up_down_variable.v
      31      55     528 ../bsg_misc/bsg_counting_leading_zeros.v
      94     185    1932 ../bsg_misc/bsg_crossbar_control_basic_o_by_i.v
      28      81     928 ../bsg_misc/bsg_crossbar_o_by_i.v
      18      39     365 ../bsg_misc/bsg_cycle_counter.v
      24      53     419 ../bsg_misc/bsg_decode.v
      21      37     366 ../bsg_misc/bsg_decode_with_v.v
      84     409    5446 ../bsg_misc/bsg_defines.v
      20      35     327 ../bsg_misc/bsg_dff.v
      49     127    1743 ../bsg_misc/bsg_dff_chain.v
      28      63     526 ../bsg_misc/bsg_dff_en.v
      40      59     571 ../bsg_misc/bsg_dff_en_bypass.v
      17      38     319 ../bsg_misc/bsg_dff_gatestack.v
      22      39     403 ../bsg_misc/bsg_dff_negedge_reset.v
      22      40     420 ../bsg_misc/bsg_dff_reset.v
      35      67     570 ../bsg_misc/bsg_dff_reset_en.v
      41      62     604 ../bsg_misc/bsg_dff_reset_en_bypass.v
      37      91     717 ../bsg_misc/bsg_dff_reset_set_clear.v
      21      53     496 ../bsg_misc/bsg_dlatch.v
      34      56     534 ../bsg_misc/bsg_edge_detect.v
      93     333    3423 ../bsg_misc/bsg_encode_one_hot.v
      36      84     650 ../bsg_misc/bsg_expand_bitmask.v
      40      87     784 ../bsg_misc/bsg_gray_to_binary.v
     293    1650   11183 ../bsg_misc/bsg_hash_bank.v
     123     452    4295 ../bsg_misc/bsg_hash_bank_reverse.v
     106     262    2468 ../bsg_misc/bsg_id_pool.v
      12      23     208 ../bsg_misc/bsg_inv.v
      17      39     272 ../bsg_misc/bsg_less_than.v
      29     137     941 ../bsg_misc/bsg_level_shift_up_down_sink.v
      29     137     944 ../bsg_misc/bsg_level_shift_up_down_source.v
      56     194    1481 ../bsg_misc/bsg_lfsr.v
      36      94     850 ../bsg_misc/bsg_locking_arb_fixed.v
      80     323    2385 ../bsg_misc/bsg_lru_pseudo_tree_backup.v
      49     169    1372 ../bsg_misc/bsg_lru_pseudo_tree_decode.v
      70     213    1620 ../bsg_misc/bsg_lru_pseudo_tree_encode.v
      26      41     511 ../bsg_misc/bsg_mul.v
     100     231    2632 ../bsg_misc/bsg_mul_array.v
     111     264    2244 ../bsg_misc/bsg_mul_array_row.v
      19      35     266 ../bsg_misc/bsg_mul_synth.v
      31      71     738 ../bsg_misc/bsg_mux.v
      17      44     331 ../bsg_misc/bsg_mux2_gatestack.v
      26      44     467 ../bsg_misc/bsg_mux_bitwise.v
      65     226    1674 ../bsg_misc/bsg_mux_butterfly.v
      35      86     777 ../bsg_misc/bsg_mux_one_hot.v
      26      63     737 ../bsg_misc/bsg_mux_segmented.v
      17      43     325 ../bsg_misc/bsg_muxi2_gatestack.v
      12      27     233 ../bsg_misc/bsg_nand.v
      12      28     234 ../bsg_misc/bsg_nor2.v
      13      33     269 ../bsg_misc/bsg_nor3.v
      85     440    3234 ../bsg_misc/bsg_pg_tree.v
      76     237    1924 ../bsg_misc/bsg_popcount.v
      45     126    1115 ../bsg_misc/bsg_priority_encode.v
      49     133    1225 ../bsg_misc/bsg_priority_encode_one_hot_out.v
      31      95     700 ../bsg_misc/bsg_reduce.v
      37     104    1053 ../bsg_misc/bsg_reduce_segmented.v
      12      34     294 ../bsg_misc/bsg_rotate_left.v
      11      34     287 ../bsg_misc/bsg_rotate_right.v
     426    2155   16961 ../bsg_misc/bsg_round_robin_arb.v
     129     543    3571 ../bsg_misc/bsg_scan.v
     145     592    4538 ../bsg_misc/bsg_strobe.v
      21      38     323 ../bsg_misc/bsg_swap.v
      66     260    1790 ../bsg_misc/bsg_thermometer_count.v
      12      22     216 ../bsg_misc/bsg_tiehi.v
      12      22     209 ../bsg_misc/bsg_tielo.v
      18      46     359 ../bsg_misc/bsg_transpose.v
      27      71     841 ../bsg_misc/bsg_unconcentrate_static.v
      30      66     577 ../bsg_misc/bsg_wait_after_reset.v
      33      65     613 ../bsg_misc/bsg_wait_cycles.v
      12      27     233 ../bsg_misc/bsg_xnor.v
      12      27     229 ../bsg_misc/bsg_xor.v
    5317   17892  150617 total
 END BaseJump STL Manifest */
`include "bsg_defines.v"
/**
 * bsg_mesh_router_pkg.v
 *
 */
package bsg_mesh_router_pkg;
 typedef enum logic [3:0] {
 RW=4'd5
 ,RE=4'd6
 ,RN=4'd7
 ,RS=4'd8
 } ruche_dirs_e;
 localparam bit [4:0][4:0] StrictXY={
 5'b01111 
 ,5'b10111 
 ,5'b00011 
 ,5'b00101 
 ,5'b11111 
 };
 localparam bit [4:0][4:0] StrictYX={
 5'b01001 
 ,5'b10001 
 ,5'b11011 
 ,5'b11101 
 ,5'b11111 
 };
 localparam bit [6:0][6:0] HalfRucheX_StrictXY={
 7'b0100001 
 ,7'b1000001 
 ,7'b0001111 
 ,7'b0010111 
 ,7'b0100011 
 ,7'b1000101 
 ,7'b0011111 
 };
 localparam bit [6:0][6:0] HalfRucheX_StrictYX={
 7'b0100010 
 ,7'b1000100 
 ,7'b0001001 
 ,7'b0010001 
 ,7'b0011011 
 ,7'b0011101 
 ,7'b1111111 
 };
 localparam bit [8:0][8:0] FullRuche_StrictXY={
 9'b010001000 
 ,9'b100010000 
 ,9'b000100001 
 ,9'b001000001 
 ,9'b000001111 
 ,9'b000010111 
 ,9'b000100011 
 ,9'b001000101 
 ,9'b110011111 
 };
 localparam bit [8:0][8:0] FullRuche_StrictYX={
 9'b010000001 
 ,9'b100000001 
 ,9'b000100010 
 ,9'b001000100 
 ,9'b010001001 
 ,9'b100010001 
 ,9'b000011011 
 ,9'b000011101 
 ,9'b001111111 
 };
endpackage
`ifndef BSG_NOC_PKG_V
`define BSG_NOC_PKG_V
package bsg_noc_pkg;
 typedef enum logic[2:0] {P=3'd0,W,E,N,S} Dirs;
endpackage
`endif
/**
 * bsg_mesh_router.v
 *
 *
 * dims_p network
 * ------------------------
 * 1 1-D mesh
 * 2 2-D mesh
 * 3 2-D mesh + half ruche x
 * 4 2-D mesh + full ruche
 *
 * ruche_factor_X/Y_p determines the number of hops that ruche links extend in the direction.
 *
 * Currently only tested for
 * - 2-D mesh
 * - 2-D mesh + half ruche x
 */ 

module bsg_mesh_router
 import bsg_noc_pkg::*;
 import bsg_mesh_router_pkg::*;
 #(parameter width_p=-1
 ,parameter x_cord_width_p=-1
 ,parameter y_cord_width_p=-1
 ,parameter ruche_factor_X_p=0
 ,parameter ruche_factor_Y_p=0
 ,parameter dims_p=2
 ,parameter dirs_lp=(2*dims_p)+1
 ,parameter XY_order_p=1
 ,parameter bit [dirs_lp-1:0][dirs_lp-1:0] routing_matrix_p=
 (dims_p == 2) ? (XY_order_p ? StrictXY : StrictYX) : (
 (dims_p == 3) ? (XY_order_p ? HalfRucheX_StrictXY : HalfRucheX_StrictYX) : (
 (dims_p == 4) ? (XY_order_p ? FullRuche_StrictXY : FullRuche_StrictYX) : "inv"))
 ,parameter debug_p=0
 )
 (
 input clk_i
 ,input reset_i
 ,input [dirs_lp-1:0][width_p-1:0] data_i
 ,input [dirs_lp-1:0] v_i
 ,output logic [dirs_lp-1:0] yumi_o
 ,input [dirs_lp-1:0] ready_i
 ,output [dirs_lp-1:0][width_p-1:0] data_o
 ,output logic [dirs_lp-1:0] v_o
 ,input [x_cord_width_p-1:0] my_x_i 
 ,input [y_cord_width_p-1:0] my_y_i
 );
 logic [dirs_lp-1:0][x_cord_width_p-1:0] x_dirs;
 logic [dirs_lp-1:0][y_cord_width_p-1:0] y_dirs;
 for (genvar i=0; i < dirs_lp; i++) begin
 assign x_dirs[i]=data_i[i][0+:x_cord_width_p];
 assign y_dirs[i]=data_i[i][x_cord_width_p+:y_cord_width_p];
 end
 logic [dirs_lp-1:0][dirs_lp-1:0] req,req_t;
 for (genvar i=0; i < dirs_lp; i++) begin: dor
 bsg_mesh_router_decoder_dor #(
 .x_cord_width_p(x_cord_width_p)
 ,.y_cord_width_p(y_cord_width_p)
 ,.ruche_factor_X_p(ruche_factor_X_p)
 ,.ruche_factor_Y_p(ruche_factor_Y_p)
 ,.dims_p(dims_p)
 ,.XY_order_p(XY_order_p)
 ,.from_p((dirs_lp)'(1 << i))
 ,.debug_p(debug_p)
 ) dor_decoder (
 .clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.v_i(v_i[i])
 ,.x_dirs_i(x_dirs[i])
 ,.y_dirs_i(y_dirs[i])
 ,.my_x_i(my_x_i)
 ,.my_y_i(my_y_i)
 ,.req_o(req[i])
 );
 end
 bsg_transpose #(
 .width_p(dirs_lp)
 ,.els_p(dirs_lp) 
 ) req_tp (
 .i(req)
 ,.o(req_t)
 );
 logic [dirs_lp-1:0][dirs_lp-1:0] yumi_lo,yumi_lo_t;
 for (genvar i=0; i < dirs_lp; i++) begin: xbar
 localparam input_els_lp=`BSG_COUNTONES_SYNTH(routing_matrix_p[i]);
 logic [input_els_lp-1:0][width_p-1:0] conc_data;
 logic [input_els_lp-1:0] conc_req;
 logic [input_els_lp-1:0] grants;
 bsg_array_concentrate_static #(
 .pattern_els_p(routing_matrix_p[i])
 ,.width_p(width_p)
 ) conc0 (
 .i(data_i)
 ,.o(conc_data)
 );
 bsg_concentrate_static #(
 .pattern_els_p(routing_matrix_p[i])
 ) conc1 (
 .i(req_t[i])
 ,.o(conc_req)
 );
 assign v_o[i]=|conc_req;
 bsg_arb_round_robin #(
 .width_p(input_els_lp)
 ) rr (
 .clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.reqs_i(conc_req)
 ,.grants_o(grants)
 ,.yumi_i(v_o[i] & ready_i[i])
 );
 bsg_mux_one_hot #(
 .els_p(input_els_lp)
 ,.width_p(width_p)
 ) data_mux (
 .data_i(conc_data)
 ,.sel_one_hot_i(grants)
 ,.data_o(data_o[i])
 );
 bsg_unconcentrate_static #(
 .pattern_els_p(routing_matrix_p[i])
 ,.unconnected_val_p(1'b0)
 ) unconc0 (
 .i(grants & {input_els_lp{ready_i[i]}})
 ,.o(yumi_lo[i])
 );
 end
 bsg_transpose #(
 .width_p(dirs_lp)
 ,.els_p(dirs_lp) 
 ) yumi_tp (
 .i(yumi_lo)
 ,.o(yumi_lo_t)
 );
 for (genvar i=0; i < dirs_lp; i++) begin
 assign yumi_o[i]=|yumi_lo_t[i];
 end
 if (debug_p) begin
 always_ff @ (negedge clk_i) begin
 if (~reset_i) begin
 for (integer i=0; i < dirs_lp; i++) begin
 assert($countones(yumi_lo_t[i]) < 2)
 else $error("multiple yumi detected. i=%d,%b",i,yumi_lo_t[i]);
 end
 end
 end
 end
endmodule
/**
 * bsg_mesh_router_buffered.v
 *
 */

`include "bsg_noc_links.vh"
module bsg_mesh_router_buffered
 import bsg_mesh_router_pkg::*;
 #(parameter width_p=-1
 ,parameter x_cord_width_p=-1
 ,parameter y_cord_width_p=-1
 ,parameter debug_p=0
 ,parameter ruche_factor_X_p=0
 ,parameter ruche_factor_Y_p=0
 ,parameter dims_p=2
 ,parameter dirs_lp=(2*dims_p)+1
 ,parameter stub_p={ dirs_lp {1'b0}} 
 ,parameter XY_order_p=1
 ,parameter bsg_ready_and_link_sif_width_lp=`bsg_ready_and_link_sif_width(width_p)
 ,parameter repeater_output_p={ dirs_lp {1'b0}} 
 ,parameter use_credits_p={dirs_lp{1'b0}}
 ,parameter int fifo_els_p[dirs_lp-1:0]='{2,2,2,2,2}
 )
 (
 input clk_i
 ,input reset_i
 ,input [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
 ,output [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
 ,input [x_cord_width_p-1:0] my_x_i
 ,input [y_cord_width_p-1:0] my_y_i
 );
 `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
 bsg_ready_and_link_sif_s [dirs_lp-1:0] link_i_cast,link_o_cast;
 assign link_i_cast =link_i;
 assign link_o=link_o_cast;
 logic [dirs_lp-1:0] fifo_valid;
 logic [dirs_lp-1:0][width_p-1:0] fifo_data;
 logic [dirs_lp-1:0] fifo_yumi;
 genvar i;
 if (debug_p)
 for (i=0; i < dirs_lp;i=i+1)
 begin
 always_ff @(negedge clk_i)
 $display("%m x=%d y=%d SNEWP[%d] v_i=%b ready_o=%b v_o=%b ready_i=%b %b"
 ,my_x_i,my_y_i,i,link_i_cast[i].v,link_o_cast[i].ready_and_rev,
 link_o_cast[i].v,link_i_cast[i].ready_and_rev,link_i[i]);
 end
 for (i=0; i < dirs_lp; i=i+1) begin: rof
 if (stub_p[i]) begin: fi
 assign fifo_data [i]=width_p ' (0);
 assign fifo_valid [i]=1'b0;
 assign link_o_cast[i].ready_and_rev=1'b0;
 always @(negedge clk_i)
 if (link_o_cast[i].v)
 $display("## warning %m: stubbed port %x received word %x",i,link_i_cast[i].data);
 end
 else begin: fi
 logic fifo_ready_lo;
 bsg_fifo_1r1w_small #(
 .width_p(width_p)
 ,.els_p(fifo_els_p[i])
 ) fifo (
 .clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.v_i (link_i_cast[i].v )
 ,.data_i (link_i_cast[i].data )
 ,.ready_o (fifo_ready_lo)
 ,.v_o (fifo_valid[i])
 ,.data_o (fifo_data [i])
 ,.yumi_i (fifo_yumi [i])
 );
 if (use_credits_p[i]) begin: cr
 bsg_dff_reset #(
 .width_p(1)
 ,.reset_val_p(0)
 ) dff0 (
 .clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.data_i(fifo_yumi[i])
 ,.data_o(link_o_cast[i].ready_and_rev)
 );
 always_ff @ (negedge clk_i) begin
 if (~reset_i) begin
 if (link_i_cast[i].v) begin
 assert(fifo_ready_lo)
 else $error("Trying to enque when there is no space in FIFO,while using credit interface. i =%d",i);
 end
 end
 end
 end
 else begin
 assign link_o_cast[i].ready_and_rev=fifo_ready_lo; 
 end
 end
 end
 logic [dirs_lp-1:0] valid_lo;
 logic [dirs_lp-1:0][width_p-1:0] data_lo;
 logic [dirs_lp-1:0] ready_li;
 for (i=0; i < dirs_lp; i=i+1)
 begin: rof2
 assign link_o_cast[i].v=valid_lo[i];
 if (repeater_output_p[i] & ~stub_p[i])
 begin : macro
	 wire [width_p-1:0] tmp;
 initial
 begin
 $display("%m with buffers on %d",i);
 end
 bsg_inv #(.width_p(width_p),.vertical_p(i < 3)) data_lo_inv
 (.i (data_lo[i] )
 ,.o(tmp)
 );
 bsg_inv #(.width_p(width_p),.vertical_p(i < 3)) data_lo_rep
 (.i (tmp)
 ,.o(link_o_cast[i].data)
 );
 end
 else
 assign link_o_cast[i].data=data_lo [i];
 assign ready_li[i]=link_i_cast[i].ready_and_rev;
 end
 bsg_mesh_router #( .width_p (width_p )
 ,.x_cord_width_p(x_cord_width_p)
 ,.y_cord_width_p(y_cord_width_p)
 ,.ruche_factor_X_p(ruche_factor_X_p)
 ,.ruche_factor_Y_p(ruche_factor_Y_p)
 ,.dims_p (dims_p)
 ,.XY_order_p (XY_order_p )
 ) bmr
 (.clk_i
 ,.reset_i
 ,.v_i (fifo_valid)
 ,.data_i (fifo_data )
 ,.yumi_o (fifo_yumi )
 ,.v_o (valid_lo)
 ,.data_o(data_lo)
 ,.ready_i(ready_li)
 ,.my_x_i
 ,.my_y_i
 );
endmodule
/**
 * bsg_mesh_router_decoder_dor.v
 *
 * Dimension ordered routing decoder
 * 
 * depopulated ruche router.
 */
module bsg_mesh_router_decoder_dor
 import bsg_noc_pkg::*;
 import bsg_mesh_router_pkg::*;
 #(parameter x_cord_width_p=-1
 ,parameter y_cord_width_p=-1
 ,parameter dims_p=2
 ,parameter dirs_lp=(2*dims_p)+1
 ,parameter ruche_factor_X_p=0
 ,parameter ruche_factor_Y_p=0
 ,parameter XY_order_p=1
 ,parameter from_p={dirs_lp{1'b0}} 
 ,parameter debug_p=0
 )
 (
 input clk_i 
 ,input reset_i 
 ,input v_i
 ,input [x_cord_width_p-1:0] x_dirs_i
 ,input [y_cord_width_p-1:0] y_dirs_i
 ,input [x_cord_width_p-1:0] my_x_i
 ,input [y_cord_width_p-1:0] my_y_i
 ,output [dirs_lp-1:0] req_o
 );
 initial begin
 if (ruche_factor_X_p > 0) begin
 assert(dims_p > 2) else $fatal(1,"ruche in X direction requires dims_p greater than 2.");
 end
 if (ruche_factor_Y_p > 0) begin
 assert(dims_p > 3) else $fatal(1,"ruche in Y direction requires dims_p greater than 3.");
 end
 assert($countones(from_p) == 1) else $fatal(1,"Must define from_p as one-hot value.");
 assert(ruche_factor_X_p < (1<<x_cord_width_p)) else $fatal(1,"ruche factor in X direction is too large");
 assert(ruche_factor_Y_p < (1<<y_cord_width_p)) else $fatal(1,"ruche factor in Y direction is too large");
 end
 wire x_eq=(x_dirs_i == my_x_i);
 wire y_eq=(y_dirs_i == my_y_i);
 wire x_gt=x_dirs_i > my_x_i;
 wire y_gt=y_dirs_i > my_y_i;
 wire x_lt=~x_gt & ~x_eq;
 wire y_lt=~y_gt & ~y_eq;
 logic [dirs_lp-1:0] req;
 assign req_o={dirs_lp{v_i}} & req;
 assign req[P]=x_eq & y_eq;
 if (ruche_factor_X_p > 0) begin
 if (XY_order_p) begin
 wire [x_cord_width_p:0] re_cord=(x_cord_width_p+1)'(my_x_i + ruche_factor_X_p);
 wire send_rw=(my_x_i > (x_cord_width_p)'(ruche_factor_X_p)) & (x_dirs_i < (my_x_i - (x_cord_width_p)'(ruche_factor_X_p)));
 wire send_re=~re_cord[x_cord_width_p] & (x_dirs_i > re_cord[0+:x_cord_width_p]);
 assign req[W]=x_lt & ~send_rw;
 assign req[RW]=send_rw;
 assign req[E]=x_gt & ~send_re;
 assign req[RE]=send_re;
 end
 else begin
 if (from_p[S] | from_p[N] | from_p[P]) begin
 assign req[W]=y_eq & x_lt;
 assign req[RW]=1'b0;
 assign req[E]=y_eq & x_gt;
 assign req[RE]=1'b0;
 end
 else if(from_p[W]) begin
 wire [x_cord_width_p-1:0] dx=(x_cord_width_p)'((x_dirs_i - my_x_i) % ruche_factor_X_p);
 assign req[RE]=y_eq & x_gt & (dx == '0);
 assign req[E]=y_eq & x_gt & (dx != '0);
 assign req[RW]=1'b0;
 assign req[W]=1'b0;
 end
 else if (from_p[E]) begin
 wire [x_cord_width_p-1:0] dx=(x_cord_width_p)'((my_x_i - x_dirs_i) % ruche_factor_X_p);
 assign req[RE]=1'b0;
 assign req[E]=1'b0;
 assign req[RW]=y_eq & x_lt & (dx == '0);
 assign req[W]=y_eq & x_lt & (dx != '0);
 end
 else if (from_p[RW]) begin
 assign req[RE]=y_eq & x_gt;
 assign req[E]=1'b0;
 assign req[RW]=1'b0;
 assign req[W]=1'b0;
 end
 else if (from_p[RE]) begin
 assign req[RE]=1'b0;
 assign req[E]=1'b0;
 assign req[RW]=y_eq & x_lt;
 assign req[W]=1'b0;
 end
 end
 end
 else begin
 if (XY_order_p) begin
 assign req[W]=x_lt;
 assign req[E]=x_gt;
 end
 else begin
 assign req[W]=y_eq & x_lt;
 assign req[E]=y_eq & x_gt;
 end
 end
 if (ruche_factor_Y_p > 0) begin
 if (XY_order_p == 0) begin
 wire [y_cord_width_p:0] rs_cord=(y_cord_width_p+1)'(my_y_i + ruche_factor_Y_p);
 wire send_rn=(my_y_i > (y_cord_width_p)'(ruche_factor_Y_p)) & (y_dirs_i < (my_y_i - (y_cord_width_p)'(ruche_factor_Y_p)));
 wire send_rs=~rs_cord[y_cord_width_p] & (y_dirs_i > rs_cord[0+:y_cord_width_p]);
 assign req[N]=y_lt & ~send_rn;
 assign req[RN]=send_rn;
 assign req[S]=y_gt & ~send_rs;
 assign req[RS]=send_rs;
 end
 else begin
 if (from_p[E] | from_p[W] | from_p[P]) begin
 assign req[N]=x_eq & y_lt;
 assign req[RN]=1'b0;
 assign req[S]=x_eq & y_gt;
 assign req[RS]=1'b0;
 end
 else if (from_p[N]) begin
 wire [y_cord_width_p-1:0] dy=(y_cord_width_p)'((y_dirs_i - my_y_i) % ruche_factor_Y_p);
 assign req[RS]=x_eq & y_gt & (dy == '0);
 assign req[S]=x_eq & y_gt & (dy != '0);
 assign req[RN]=1'b0;
 assign req[N]=1'b0;
 end
 else if (from_p[S]) begin
 wire [y_cord_width_p-1:0] dy=(y_cord_width_p)'((my_y_i - y_dirs_i) % ruche_factor_Y_p);
 assign req[RS]=1'b0;
 assign req[S]=1'b0;
 assign req[RN]=x_eq & y_lt & (dy == '0);
 assign req[N]=x_eq & y_lt & (dy != '0);
 end
 else if (from_p[RN]) begin
 assign req[RS]=x_eq & y_gt;
 assign req[S]=1'b0;
 assign req[RN]=1'b0;
 assign req[N]=1'b0;
 end
 else if (from_p[RS]) begin
 assign req[RS]=1'b0;
 assign req[S]=1'b0;
 assign req[RN]=x_eq & y_lt;
 assign req[N]=1'b0;
 end
 end
 end
 else begin
 if (XY_order_p == 0) begin
 assign req[N]=y_lt;
 assign req[S]=y_gt;
 end
 else begin
 assign req[N]=x_eq & y_lt;
 assign req[S]=x_eq & y_gt;
 end
 end
 if (debug_p) begin
 always_ff @ (negedge clk_i) begin
 if (~reset_i) begin
 assert($countones(req_o) < 2)
 else $fatal(1,"multiple req_o detected. i=%d,%b",req_o);
 end
 end
 end
 else begin
 wire unused0=clk_i;
 wire unused1=reset_i;
 end
endmodule

module bsg_mesh_stitch
 import bsg_noc_pkg::*; 
 #(parameter width_p="inv" 
 ,x_max_p="inv"
 ,y_max_p="inv"
 ,nets_p=1 
 )
 (input [y_max_p-1:0][x_max_p-1:0][nets_p-1:0][S:W][width_p-1:0] outs_i 
 ,output [y_max_p-1:0][x_max_p-1:0][nets_p-1:0][S:W][width_p-1:0] ins_o
 ,input [E:W][y_max_p-1:0][nets_p-1:0][width_p-1:0] hor_i
 ,output [E:W][y_max_p-1:0][nets_p-1:0][width_p-1:0] hor_o
 ,input [S:N][x_max_p-1:0][nets_p-1:0][width_p-1:0] ver_i
 ,output [S:N][x_max_p-1:0][nets_p-1:0][width_p-1:0] ver_o
 );
 genvar r,c,net;
 for (net=0; net < nets_p; net=net+1)
 begin: _n
 for (r=0; r < y_max_p; r=r+1)
 begin: _r
 assign hor_o[E][r][net]=outs_i[r][x_max_p-1][net][E];
 assign hor_o[W][r][net]=outs_i[r][0 ][net][W];
 for (c=0; c < x_max_p; c=c+1)
 begin: _c
 assign ins_o[r][c][net][S]=(r == y_max_p-1)
 ? ver_i[S][c][net]
 : outs_i[(r == y_max_p-1) ? r : r+1][c][net][N]; 
 assign ins_o[r][c][net][N]=(r == 0)
 ? ver_i[N][c][net]
 : outs_i[r ? r-1: 0][c][net][S]; 
 assign ins_o[r][c][net][E]=(c == x_max_p-1)
 ? hor_i[E][r][net]
 : outs_i[r][(c == x_max_p-1) ? c : (c+1)][net][W]; 
 assign ins_o[r][c][net][W]=(c == 0)
 ? hor_i[W][r][net]
 : outs_i[r][c ? (c-1) :0][net][E]; 
 end 
 end 
 for (c=0; c < x_max_p; c=c+1)
 begin: _c
 assign ver_o[S][c][net]=outs_i[y_max_p-1][c][net][S];
 assign ver_o[N][c][net]=outs_i[0 ][c][net][N];
 end
 end 
endmodule
/**
 * bsg_abs.v
 *
 * calculate absolute value of signed integer.
 *
 * @author Tommy Jung
 */

module bsg_abs #( parameter width_p="inv" )
(
 input [width_p-1:0] a_i
 ,output logic [width_p-1:0] o
);
 assign o=a_i[width_p-1]
 ? (~a_i) + 1'b1
 : a_i;
endmodule

module bsg_adder_cin #(parameter width_p="inv"
 ,harden_p=1)
 ( input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,input cin_i
 ,output [width_p-1:0] o
 );
 assign o=a_i + b_i + { {(width_p-1){1'b0}},cin_i };
endmodule

module bsg_adder_one_hot #(parameter width_p=-1,parameter output_width_p=width_p)
 (input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output [output_width_p-1:0] o
 );
 genvar i,j;
 initial assert (output_width_p >= width_p)
 else begin $error("%m: unsupported output_width_p < width_p");
	$finish();
 end
 for (i=0; i < output_width_p; i++) 
 begin: rof
	wire [width_p-1:0] aggregate;
	for (j=0; j < width_p; j=j+1)
	 begin: rof2
	 if (i < j)
	 begin: rof3
	 if (output_width_p+i-j < width_p)
	 assign aggregate[j]=a_i[j] & b_i[output_width_p+i-j];
	 else
	 assign aggregate[j]=1'b0;
	 end
	 else
	 if (i-j < width_p)
	 assign aggregate[j]=a_i[j] & b_i[i-j];
	 else
	 assign aggregate[j]=1'b0;
	 end 
	assign o[i]=| aggregate;
 end 
endmodule
/**
 * bsg_adder_ripple_carry.v
 *
 * @author Tommy Jung
 */

module bsg_adder_ripple_carry #(parameter width_p="inv")
 (
 input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output logic [width_p-1:0] s_o
 ,output logic c_o
 );
 assign {c_o,s_o}=a_i + b_i;
endmodule

module bsg_and #(parameter width_p="inv"
 ,harden_p=1)
 (input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output [width_p-1:0] o
 );
 assign o=a_i & b_i;
endmodule

module bsg_arb_fixed #(parameter inputs_p="inv"
 ,parameter lo_to_hi_p="inv")
 ( input ready_i
 ,input [inputs_p-1:0] reqs_i
 ,output [inputs_p-1:0] grants_o
 );
 logic [inputs_p-1:0] grants_unmasked_lo;
 bsg_priority_encode_one_hot_out #(.width_p (inputs_p)
 ,.lo_to_hi_p(lo_to_hi_p)
 ) enc
 (.i ( reqs_i )
 ,.o( grants_unmasked_lo)
 ,.v_o( )
 );
 assign grants_o=grants_unmasked_lo & { (inputs_p) { ready_i } };
endmodule

module bsg_arb_round_robin #(parameter width_p=-1)
 (input clk_i
 ,input reset_i
 ,input [width_p-1:0] reqs_i 
 ,output logic [width_p-1:0] grants_o 
 ,input yumi_i 
 );
 if (width_p == 1)
 begin: fi
 assign grants_o=reqs_i;
 end
 else
 begin: fi2
 logic [width_p-1-1:0] thermocode_r,thermocode_n; 
 always_ff @(posedge clk_i)
 if (reset_i)
 thermocode_r <= '0; 
 else
 if (yumi_i)
 thermocode_r <= thermocode_n;
 wire [width_p*2-1:0] scan_li={ 1'b0,thermocode_r & reqs_i[width_p-1-1:0],reqs_i };
 wire [width_p*2-1:0] scan_lo;
 bsg_scan #(.width_p(width_p*2)
 ,.or_p(1)
 ) scan
 (
 .i(scan_li)
 ,.o(scan_lo) 
 ); 
 wire [width_p*2-1:0] edge_detect=~(scan_lo >> 1) & scan_lo;
 assign grants_o=edge_detect[width_p*2-1-:width_p] | edge_detect[width_p-1:0];
 always_comb
 begin
 if (|scan_li[width_p*2-1-:width_p]) 
 thermocode_n=scan_lo[width_p*2-1-:width_p-1];
 else 
 thermocode_n=scan_lo[width_p-1:1];
 end 
 end
endmodule

module bsg_array_concentrate_static 
 #(parameter pattern_els_p="inv"
 ,parameter width_p="inv"
 ,dense_els_lp=$bits(pattern_els_p)
 ,sparse_els_lp=`BSG_COUNTONES_SYNTH(pattern_els_p))
 (input [dense_els_lp-1:0][width_p-1:0] i
 ,output [sparse_els_lp-1:0][width_p-1:0] o
);
 genvar j;
 if (pattern_els_p[0])
 assign o[0]=i[0];
 for (j=1; j < dense_els_lp; j=j+1)
 begin : rof
 if (pattern_els_p[j])
 assign o[`BSG_COUNTONES_SYNTH(pattern_els_p[j-1:0])]=i[j];
 end
endmodule

module bsg_array_reverse 
 #(width_p="inv"
 ,els_p="inv")
 (input [els_p-1:0][width_p-1:0] i
 ,output [els_p-1:0][width_p-1:0] o
 );
 genvar j;
 for (j=0; j < els_p; j=j+1)
 begin: rof
 assign o[els_p-j-1]=i[j]; 
 end
endmodule
/*
 Since x and x+1 differ by at most 1 bit,we
 can figure out which bit it is that will change.
 Take for example:
 x g(x) g(x+1) diff
 000 000 001 001
 001 001 011 010
 010 011 010 001
 011 010 110 100
 100 110 111 001
 101 111 101 010
 110 101 100 001
 111 100 000 100
 We can replicate diff with:
 x and-scan drop_hi 0append1 (~(x >> 1) & x) drop_hi
 000 000 00 0001 0001 001
 001 001 01 0011 0010 010
 010 000 00 0001 0001 001
 011 011 11 0111 0100 100
 100 000 00 0001 0001 001
 101 001 01 0011 0010 010
 110 000 00 0001 0001 001
 111 111 11 0111 0100 100
 */

module bsg_binary_plus_one_to_gray #(parameter width_p=-1)
 (input [width_p-1:0] binary_i
 ,output [width_p-1:0] gray_o
 );
 wire [width_p-1:0] binary_scan;
 bsg_scan #(.width_p(width_p)
 ,.and_p(1)
 ,.lo_to_hi_p(1)
 ) scan_and (.i(binary_i),.o(binary_scan));
 wire [width_p:0] temp={ 1'b0,binary_scan[width_p-2:0],1'b1};
 wire [width_p-1:0] edge_detect=~temp[width_p:1] & temp[width_p-1:0];
 assign gray_o=(binary_i >> 1) ^ (binary_i) ^ edge_detect;
endmodule

module bsg_buf #(parameter width_p="inv"
 ,harden_p=1)
 (input [width_p-1:0] i
 ,output [width_p-1:0] o
 );
 assign o=i;
endmodule

module bsg_buf_ctrl #(parameter width_p="inv"
 ,harden_p=1)
 (input i
 ,output [width_p-1:0] o
 );
 assign o={ width_p{i}};
endmodule

module bsg_circular_ptr #(parameter slots_p=-1
 ,parameter max_add_p=-1
 ,parameter ptr_width_lp=`BSG_SAFE_CLOG2(slots_p)
	 )
 (input clk
 ,input reset_i
 ,input [$clog2(max_add_p+1)-1:0] add_i
 ,output [ptr_width_lp-1:0] o
 ,output [ptr_width_lp-1:0] n_o
 );
 logic [ptr_width_lp-1:0] ptr_r,ptr_n,ptr_nowrap;
 logic [ptr_width_lp:0] ptr_wrap;
 assign o=ptr_r;
 assign n_o=ptr_n;
 always @(posedge clk)
 if (reset_i) ptr_r <= 0;
 else ptr_r <= ptr_n;
 if (slots_p == 1)
 begin
	assign ptr_n=1'b0;
	wire ignore=|add_i;
 end
 else
 if (`BSG_IS_POW2(slots_p))
 begin
	 if (max_add_p == 1)
	 begin
	 wire [ptr_width_lp-1:0] ptr_r_p1=ptr_r + 1'b1;
	 assign ptr_n=add_i ? ptr_r_p1 : ptr_r;
	 end
	 else
	 assign ptr_n=ptr_width_lp ' (ptr_r + add_i);
 end
 else
 begin: notpow2
 assign ptr_wrap=(ptr_width_lp+1)'({ 1'b0,ptr_r } - slots_p + add_i);
 assign ptr_nowrap=ptr_r + add_i;
 assign ptr_n=~ptr_wrap[ptr_width_lp] ? ptr_wrap[0+:ptr_width_lp] : ptr_nowrap;
 always_comb
 begin
 assert( (ptr_n < slots_p) || (|ptr_n === 'X) || reset_i || (add_i > slots_p))
 else $error("bsg_circular_ptr counter overflow (ptr_r=%b/add_i=%b/ptr_wrap=%b/ptr_n=%b)",ptr_r,add_i,ptr_wrap,ptr_n,slots_p);
 end
end
endmodule 

module bsg_clkbuf #(parameter width_p=1
	 ,parameter strength_p=8
 ,parameter harden_p=1
 )
 (input [width_p-1:0] i
 ,output [width_p-1:0] o
 );
 assign o=i;
endmodule

`ifndef SYNTHESIS
module bsg_clkgate_optional (input clk_i
 ,input en_i
 ,input bypass_i
 ,output gated_clock_o
 );
 wire latched_en_lo;
 bsg_dlatch #(.width_p(1),.i_know_this_is_a_bad_idea_p(1))
 en_latch
 ( .clk_i ( ~clk_i )
 ,.data_i ( en_i )
 ,.data_o ( latched_en_lo )
 );
 assign gated_clock_o=(latched_en_lo|bypass_i) & clk_i;
endmodule
`endif

module bsg_concentrate_static #(parameter pattern_els_p="inv",width_lp=$bits(pattern_els_p),set_els_lp=`BSG_COUNTONES_SYNTH(pattern_els_p))
(input [width_lp-1:0] i
 ,output [set_els_lp-1:0] o
);
 genvar j;
 if (pattern_els_p[0])
 assign o[0]=i[0];
 for (j=1; j < width_lp; j=j+1)
 begin : rof
 if (pattern_els_p[j])
 assign o[`BSG_COUNTONES_SYNTH(pattern_els_p[j-1:0])]=i[j];
 end
endmodule

module bsg_counter_clear_up #(parameter max_val_p=-1
	 ,parameter init_val_p=`BSG_UNDEFINED_IN_SIM('0)
 ,parameter ptr_width_lp =
 `BSG_SAFE_CLOG2(max_val_p+1)
	 ,parameter disable_overflow_warning_p=0
 )
 (input clk_i
 ,input reset_i
 ,input clear_i
 ,input up_i
 ,output logic [ptr_width_lp-1:0] count_o
 );
 always_ff @(posedge clk_i)
 begin
 if (reset_i)
 count_o <= init_val_p;
 else
	 count_o <= clear_i ? (ptr_width_lp ' (up_i) ) : (count_o+(ptr_width_lp ' (up_i)));
 end
 always_ff @ (negedge clk_i) 
 begin
 if ((count_o==ptr_width_lp '(max_val_p)) && up_i && (reset_i===0) && !disable_overflow_warning_p)
 $display("%m error: counter overflow at time %t",$time);
 end
endmodule

module bsg_counter_clear_up_one_hot
 #(parameter max_val_p=-1,width_lp=max_val_p+1,init_val_p=(width_lp) ' (1))
 (input clk_i
 ,input reset_i
 ,input clear_i
 ,input up_i
 ,output [width_lp-1:0] count_r_o
 );
 logic [width_lp-1:0] bits_r,bits_n;
 always_comb
 begin
 bits_n=bits_r;
 if (clear_i)
 bits_n=(width_lp) ' (1);
 if (up_i)
 bits_n={ bits_n[width_lp-2:0],bits_n[width_lp-1] }; 
 if (reset_i)
 bits_n=(width_lp) ' (init_val_p);
 end
 always_ff @(posedge clk_i)
 if (reset_i | up_i | clear_i)
 bits_r <= bits_n;
 assign count_r_o=bits_r;
endmodule

module bsg_counter_clock_downsample #(parameter width_p="inv",parameter harden_p=0)
 (input clk_i
 ,input reset_i
 ,input [width_p-1:0] val_i
 ,output logic clk_r_o
 );
 wire strobe_r;
 bsg_strobe #(.width_p(width_p),.harden_p(harden_p)) strobe
 (.clk_i
 ,.reset_r_i(reset_i)
 ,.init_val_r_i(val_i)
 ,.strobe_r_o(strobe_r)
 );
 always_ff @(posedge clk_i)
 begin
 if (reset_i)
 clk_r_o <= 1'b0;
 else if (strobe_r)
 clk_r_o <= ~clk_r_o;
 end
endmodule

module bsg_counter_dynamic_limit #(parameter width_p=-1)
 ( input clk_i
 ,input reset_i
 ,input [width_p-1:0] limit_i
 ,output logic [width_p-1:0] counter_o
 );
always_ff @ (posedge clk_i)
 if (reset_i)
 counter_o <= 0;
 else if (counter_o == limit_i)
 counter_o <= 0;
 else
 counter_o <= counter_o + width_p'(1);
endmodule

module bsg_counter_dynamic_limit_en #(parameter width_p=-1)
 ( input clk_i
 ,input reset_i
 ,input en_i
 ,input [width_p-1:0] limit_i
 ,output logic [width_p-1:0] counter_o
 ,output overflowed_o
 );
wire [width_p-1:0] counter_plus_1=counter_o + width_p'(1);
assign overflowed_o=( counter_plus_1 == limit_i );
always_ff @ (posedge clk_i)
 if (reset_i)
 counter_o <= 0;
 else if (en_i) begin
 if(overflowed_o ) counter_o <= 0;
 else counter_o <= counter_plus_1 ;
 end
endmodule

module bsg_counter_overflow_en #(parameter max_val_p=-1
 ,parameter init_val_p=-1
 ,parameter ptr_width_lp=`BSG_SAFE_CLOG2(max_val_p)
 )
 ( input clk_i
 ,input reset_i
 ,input en_i
 ,output logic [ptr_width_lp-1:0] count_o
 ,output logic overflow_o
 );
 assign overflow_o=(count_o == max_val_p);
 always_ff @(posedge clk_i)
 begin
 if (reset_i | overflow_o)
 count_o <= init_val_p;
 else if (en_i)
 count_o <= count_o + 1'b1;
 end
endmodule

module bsg_counter_overflow_set_en #( parameter max_val_p=-1
 ,parameter lg_max_val_lp=`BSG_SAFE_CLOG2(max_val_p+1)
 )
 ( input clk_i
 ,input en_i
 ,input set_i
 ,input [lg_max_val_lp-1:0] val_i
 ,output logic [lg_max_val_lp-1:0] count_o
 ,output logic overflow_o
 );
 assign overflow_o=(count_o == max_val_p);
 always_ff @(posedge clk_i)
 begin
 if (set_i)
 count_o <= val_i;
 else if (overflow_o)
 count_o <= {lg_max_val_lp{1'b0}};
 else if (en_i)
 count_o <= count_o + 1'b1;
 end
endmodule

module bsg_counter_set_down #(parameter width_p="inv",parameter init_val_p='0,parameter set_and_down_exclusive_p=0)
 (input clk_i
 ,input reset_i
 ,input set_i
 ,input [width_p-1:0] val_i
 ,input down_i
 ,output [width_p-1:0] count_r_o
 );
 logic [width_p-1:0] ctr_r,ctr_n;
 always_ff @(posedge clk_i)	 
 if (reset_i)
 ctr_r <= width_p ' (init_val_p);
 else
 ctr_r <= ctr_n;
 if (set_and_down_exclusive_p)
 begin: excl
 always_comb 
	 begin
	 ctr_n=ctr_r;
	 if (set_i)
 ctr_n=val_i;
	 else
 if (down_i)
	ctr_n=ctr_n - 1; 
	 end
 end
 else
 begin : non_excl 
 always_comb
 	begin
 ctr_n=ctr_r;
 if (set_i)
 ctr_n=val_i;
 if (down_i)
 ctr_n=ctr_n - 1;
 end
 end
 assign count_r_o=ctr_r;
`ifndef SYNTHESIS
 always_ff @(negedge clk_i)
 begin
 if (!reset_i && down_i && (ctr_n == '1))
 $display("%m error: counter underflow at time %t",$time);
 if (~reset_i & set_and_down_exclusive_p & set_i & down_i)
	 $display("%m error: set and down non-exclusive at time %t",$time);
 end
`endif
endmodule
/**
 * bsg_counter_set_en.v
 */

module bsg_counter_set_en
 #(parameter max_val_p="inv"
 ,parameter lg_max_val_lp=`BSG_WIDTH(max_val_p)
 ,parameter reset_val_p=0
 )
 (
 input clk_i
 ,input reset_i
 ,input set_i
 ,input en_i
 ,input [lg_max_val_lp-1:0] val_i
 ,output logic [lg_max_val_lp-1:0] count_o
 );
 always_ff @ (posedge clk_i) begin
 if (reset_i) begin
 count_o <= (lg_max_val_lp)'(reset_val_p);
 end
 else if (set_i) begin
 count_o <= val_i;
 end
 else if (en_i) begin
 count_o <= count_o + 1'b1;
 end
 end
endmodule

module bsg_counter_up_down #( parameter max_val_p=-1
 ,parameter init_val_p=-1
 ,parameter max_step_p=-1
 ,parameter step_width_lp =
 `BSG_WIDTH(max_step_p)
 ,parameter ptr_width_lp =
 `BSG_WIDTH(max_val_p))
 ( input clk_i
 ,input reset_i
 ,input [step_width_lp-1:0] up_i
 ,input [step_width_lp-1:0] down_i
 ,output logic [ptr_width_lp-1:0] count_o
 );
always_ff @(posedge clk_i)
 begin
 if (reset_i)
	count_o <= init_val_p;
 else
 count_o <= count_o - down_i + up_i;
 end
 always_ff @ (negedge clk_i) begin
 if ((count_o==max_val_p) & up_i & (reset_i === 1'b0))
	 $display("%m error: counter overflow at time %t",$time);
	 if ((count_o==0) & down_i & (reset_i === 1'b0))
	 $display("%m error: counter underflow at time %t",$time);
 end
endmodule

module bsg_counter_up_down_variable #( parameter max_val_p=-1
 ,parameter init_val_p=-1
 ,parameter max_step_p=-1
 ,parameter step_width_lp =
 `BSG_WIDTH(max_step_p)
 ,parameter ptr_width_lp =
 `BSG_WIDTH(max_val_p)
 )
 ( input clk_i
 ,input reset_i
 ,input [step_width_lp-1:0] up_i
 ,input [step_width_lp-1:0] down_i
 ,output logic [ptr_width_lp-1:0] count_o
 );
always_ff @(posedge clk_i)
 begin
 if (reset_i)
	count_o <= init_val_p;
 else
 count_o <= count_o - down_i + up_i;
 end
 always_ff @ (posedge clk_i) begin
 if ((count_o==max_val_p) & up_i & (reset_i===0))
 $display("%m error: counter overflow at time %t",$time);
 if ((count_o==0) & down_i & (reset_i===0))
 $display("%m error: counter underflow at time %t",$time);
 end
endmodule
/**
 *	bsg_counting_leading_zeros.v
 *
 *	@author Tommy Jung
 */

module bsg_counting_leading_zeros #(parameter width_p="inv")
(
 input [width_p-1:0] a_i
 ,output logic [`BSG_SAFE_CLOG2(width_p)-1:0] num_zero_o
);
 logic [width_p-1:0] reversed;
 genvar i;
 for (i=0; i < width_p; i++) begin
 assign reversed[i]=a_i[width_p-1-i];
 end 
 bsg_priority_encode #(
 .width_p(width_p)
 ,.lo_to_hi_p(1)
 ) pe0 (
 .i(reversed)
 ,.addr_o(num_zero_o)
 ,.v_o()
 );
endmodule
/**
 * bsg_crossbar_control_basic_o_by_i.v
 *
 * This module generates the control signals for bsg_router_crossbar_o_by_i.
 */

module bsg_crossbar_control_basic_o_by_i
 #(parameter i_els_p="inv"
 ,parameter o_els_p="inv"
 ,parameter lg_o_els_lp=`BSG_SAFE_CLOG2(o_els_p)
 )
 (
 input clk_i
 ,input reset_i
 ,input [i_els_p-1:0] valid_i
 ,input [i_els_p-1:0][lg_o_els_lp-1:0] sel_io_i
 ,output [i_els_p-1:0] yumi_o
 ,input [o_els_p-1:0] ready_and_i
 ,output [o_els_p-1:0] valid_o
 ,output [o_els_p-1:0][i_els_p-1:0] grants_oi_one_hot_o
 );
 logic [i_els_p-1:0][o_els_p-1:0] o_select;
 logic [o_els_p-1:0][i_els_p-1:0] o_select_t;
 for (genvar i=0; i < i_els_p; i++) begin: dv
 bsg_decode_with_v #(
 .num_out_p(o_els_p)
 ) dv0 (
 .i(sel_io_i[i])
 ,.v_i(valid_i[i])
 ,.o(o_select[i])
 );
 end
 bsg_transpose #(
 .width_p(o_els_p)
 ,.els_p(i_els_p)
 ) trans0 (
 .i(o_select)
 ,.o(o_select_t)
 );
 logic [o_els_p-1:0] rr_yumi_li;
 logic [o_els_p-1:0][i_els_p-1:0] rr_yumi_lo;
 logic [i_els_p-1:0][o_els_p-1:0] rr_yumi_lo_t;
 for (genvar i=0 ; i < o_els_p; i++) begin: rr
 assign valid_o[i]=|o_select_t[i];
 assign rr_yumi_li[i]=valid_o[i] & ready_and_i[i];
 bsg_arb_round_robin #(
 .width_p(i_els_p)
 ) rr0 (
 .clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.reqs_i(o_select_t[i])
 ,.grants_o(grants_oi_one_hot_o[i])
 ,.yumi_i(rr_yumi_li[i])
 );
 assign rr_yumi_lo[i]=grants_oi_one_hot_o[i] & {i_els_p{rr_yumi_li[i]}};
 end 
 bsg_transpose #(
 .width_p(i_els_p)
 ,.els_p(o_els_p)
 ) trans1 (
 .i(rr_yumi_lo)
 ,.o(rr_yumi_lo_t)
 );
 for (genvar i=0; i < i_els_p; i++) begin
 assign yumi_o[i]=|rr_yumi_lo_t[i];
 end
endmodule

module bsg_crossbar_o_by_i #( parameter i_els_p=-1
 ,parameter o_els_p=-1
 ,parameter width_p=-1
 )
 ( input [i_els_p-1:0][width_p-1:0] i
 ,input [o_els_p-1:0][i_els_p-1:0] sel_oi_one_hot_i
 ,output [o_els_p-1:0][width_p-1:0] o
 );
 genvar lineout;
 for(lineout=0; lineout<o_els_p; lineout++)
 begin
 bsg_mux_one_hot #( .width_p(width_p)
 ,.els_p (i_els_p)
 ) mux_one_hot
 ( .data_i (i)
 ,.sel_one_hot_i (sel_oi_one_hot_i[lineout])
 ,.data_o (o[lineout])
 );
 end
endmodule 

module bsg_cycle_counter #(parameter width_p=32
 ,init_val_p=0)
 (input clk_i
 ,input reset_i
 ,output logic [width_p-1:0] ctr_r_o);
 always @(posedge clk_i)
 if (reset_i)
 ctr_r_o <= init_val_p;
 else
 ctr_r_o <= ctr_r_o+1;
endmodule 
/**
 * bsg_decode.v
 *
 * https:
 */

module bsg_decode #(parameter num_out_p="inv")
(
 input [`BSG_SAFE_CLOG2(num_out_p)-1:0] i
 ,output logic [num_out_p-1:0] o
);
 if (num_out_p == 1) begin
 wire unused=i;
 assign o=1'b1;
 end
 else begin
 assign o=(num_out_p) ' (1'b1 << i);
 end
endmodule

module bsg_decode_with_v #(num_out_p=-1)
 (
 input [`BSG_SAFE_CLOG2(num_out_p)-1:0] i
 ,input v_i
 ,output [num_out_p-1:0] o
 );
 wire [num_out_p-1:0] lo;
 bsg_decode #(.num_out_p(num_out_p)
 ) bd
 (.i
 ,.o(lo)
 );
 assign o={ (num_out_p) { v_i } } & lo;
endmodule
`ifndef BSG_DEFINES_V
`define BSG_DEFINES_V
`define BSG_MAX(x,y) (((x)>(y)) ? (x) : (y))
`define BSG_MIN(x,y) (((x)<(y)) ? (x) : (y))
`define BSG_ABSTRACT_MODULE(fn) module fn``__abstract(); if (0) fn not_used(); endmodule
`define BSG_INV_PARAM(param) param
`define BSG_SAFE_CLOG2(x) ( ((x)==1) ? 1 : $clog2((x)))
`define BSG_IS_POW2(x) ( (1 << $clog2(x)) == (x))
`define BSG_WIDTH(x) ($clog2(x+1))
`define BSG_SAFE_MINUS(x,y) (((x)-(y)) < 0) ? 0 : ((x)-(y))
`define BSG_CDIV(x,y) (((x)+(y)-1)/(y))
`ifdef SYNTHESIS
`define BSG_UNDEFINED_IN_SIM(val) (val)
`else
`define BSG_UNDEFINED_IN_SIM(val) ('X)
`endif
`ifdef VERILATOR
`define BSG_HIDE_FROM_VERILATOR(val)
`else
`define BSG_HIDE_FROM_VERILATOR(val) val
`endif
`ifdef SYNTHESIS
`define BSG_DISCONNECTED_IN_SIM(val) (val)
`elsif VERILATOR
`define BSG_DISCONNECTED_IN_SIM(val) (val)
`else
`define BSG_DISCONNECTED_IN_SIM(val) ('z)
`endif
`define BSG_STRINGIFY(x) `"x`"
`define BSG_GET_BIT(X,NUM) (((X)>>(NUM))&1'b1)
`define BSG_COUNTONES_SYNTH(y) (($bits(y) < 65) ? 1'b0 : `BSG_UNDEFINED_IN_SIM(1'b0)) + (`BSG_GET_BIT(y,0) +`BSG_GET_BIT(y,1) +`BSG_GET_BIT(y,2) +`BSG_GET_BIT(y,3) +`BSG_GET_BIT(y,4) +`BSG_GET_BIT(y,5) +`BSG_GET_BIT(y,6)+`BSG_GET_BIT(y,7) +`BSG_GET_BIT(y,8)+`BSG_GET_BIT(y,9) \
 +`BSG_GET_BIT(y,10)+`BSG_GET_BIT(y,11)+`BSG_GET_BIT(y,12)+`BSG_GET_BIT(y,13)+`BSG_GET_BIT(y,14)+`BSG_GET_BIT(y,15)+`BSG_GET_BIT(y,16)+`BSG_GET_BIT(y,17)+`BSG_GET_BIT(y,18)+`BSG_GET_BIT(y,19) \
 +`BSG_GET_BIT(y,20)+`BSG_GET_BIT(y,21)+`BSG_GET_BIT(y,22)+`BSG_GET_BIT(y,23)+`BSG_GET_BIT(y,24)+`BSG_GET_BIT(y,25)+`BSG_GET_BIT(y,26)+`BSG_GET_BIT(y,27)+`BSG_GET_BIT(y,28)+`BSG_GET_BIT(y,29) \
 +`BSG_GET_BIT(y,30)+`BSG_GET_BIT(y,31)+`BSG_GET_BIT(y,32)+`BSG_GET_BIT(y,33)+`BSG_GET_BIT(y,34)+`BSG_GET_BIT(y,35)+`BSG_GET_BIT(y,36)+`BSG_GET_BIT(y,37)+`BSG_GET_BIT(y,38)+`BSG_GET_BIT(y,39) \
 +`BSG_GET_BIT(y,40)+`BSG_GET_BIT(y,41)+`BSG_GET_BIT(y,42)+`BSG_GET_BIT(y,43)+`BSG_GET_BIT(y,44)+`BSG_GET_BIT(y,45)+`BSG_GET_BIT(y,46)+`BSG_GET_BIT(y,47)+`BSG_GET_BIT(y,48)+`BSG_GET_BIT(y,49) \
 +`BSG_GET_BIT(y,50)+`BSG_GET_BIT(y,51)+`BSG_GET_BIT(y,52)+`BSG_GET_BIT(y,53)+`BSG_GET_BIT(y,54)+`BSG_GET_BIT(y,55)+`BSG_GET_BIT(y,56)+`BSG_GET_BIT(y,57)+`BSG_GET_BIT(y,58)+`BSG_GET_BIT(y,59) \
 +`BSG_GET_BIT(y,60)+`BSG_GET_BIT(y,61)+`BSG_GET_BIT(y,62)+`BSG_GET_BIT(y,63))
`ifndef rpgroup
`define rpgroup(x)
`endif
`endif

module bsg_dff #(width_p=-1
	 ,harden_p=0
	 ,strength_p=1 
	 )
 (input clk_i
 ,input [width_p-1:0] data_i
 ,output [width_p-1:0] data_o
 );
 reg [width_p-1:0] data_r;
 assign data_o=data_r;
 always @(posedge clk_i)
 data_r <= data_i;
endmodule

module bsg_dff_chain #(
 parameter width_p=-1
 ,parameter num_stages_p=1
 )
 (
 input clk_i
 ,input [width_p-1:0] data_i
 ,output[width_p-1:0] data_o
 );
 if( num_stages_p == 0) begin:pass_through
 assign data_o=data_i;
 end:pass_through
 else begin:chained
 logic [num_stages_p:0][width_p-1:0] data_delayed;
 assign data_delayed[0]=data_i ;
 assign data_o=data_delayed[num_stages_p] ;
 genvar i;
 for(i=1; i<= num_stages_p; i++) begin
 bsg_dff #( .width_p ( width_p ) )
 ch_reg (
 .clk_i ( clk_i )
 ,.data_i ( data_delayed[ i-1 ] )
 ,.data_o ( data_delayed[ i ] )
 );
 end
 end:chained
endmodule
/**
 * bsg_dff_en.v
 * @param width_p data width
 */

module bsg_dff_en #(parameter width_p="inv"
 ,parameter harden_p=1 
 ,parameter strength_p=1)
(
 input clk_i
 ,input [width_p-1:0] data_i
 ,input en_i
 ,output logic [width_p-1:0] data_o
);
 logic [width_p-1:0] data_r;
 assign data_o=data_r;
 always_ff @ (posedge clk_i) begin
 if (en_i) begin
 data_r <= data_i;
 end
 end
endmodule
/**
 * bsg_dff_en_bypass.v
 *
 */

module bsg_dff_en_bypass
 #(parameter width_p="inv"
 ,parameter harden_p=0
 ,parameter strength_p=0
 )
 (
 input clk_i
 ,input en_i
 ,input [width_p-1:0] data_i
 ,output logic [width_p-1:0] data_o
 );
 logic [width_p-1:0] data_r;
 bsg_dff_en #(
 .width_p(width_p)
 ,.harden_p(harden_p)
 ,.strength_p(strength_p)
 ) dff (
 .clk_i(clk_i)
 ,.en_i(en_i)
 ,.data_i(data_i)
 ,.data_o(data_r)
 );
 assign data_o=en_i
 ? data_i
 : data_r;
endmodule

module bsg_dff_gatestack #(width_p="inv",harden_p=1)
 (input [width_p-1:0] i0
 ,input [width_p-1:0] i1
 ,output logic [width_p-1:0] o
 );
 genvar j;
 for (j=0; j < width_p; j=j+1)
 begin
 always_ff @(posedge i1[j])
 o[j] <= i0[j];
 end
endmodule

module bsg_dff_negedge_reset #(width_p=-1,harden_p=0)
 (input clk_i
 ,input reset_i
 ,input [width_p-1:0] data_i
 ,output [width_p-1:0] data_o
 );
 reg [width_p-1:0] data_r;
 assign data_o=data_r;
 always @(negedge clk_i)
 begin
 if (reset_i)
 data_r <= width_p'(0);
 else
 data_r <= data_i;
 end
endmodule

module bsg_dff_reset #(width_p=-1,reset_val_p=0,harden_p=0)
 (input clk_i
 ,input reset_i
 ,input [width_p-1:0] data_i
 ,output [width_p-1:0] data_o
 );
 reg [width_p-1:0] data_r;
 assign data_o=data_r;
 always @(posedge clk_i)
 begin
 if (reset_i)
 data_r <= width_p'(reset_val_p);
 else
 data_r <= data_i;
 end
endmodule
/**
 * bsg_dff_reset_en.v
 */

module bsg_dff_reset_en
 #(parameter width_p="inv"
 ,parameter reset_val_p=0
 ,parameter harden_p=0
 )
 (
 input clk_i
 ,input reset_i
 ,input en_i
 ,input [width_p-1:0] data_i
 ,output logic [width_p-1:0] data_o
 );
 logic [width_p-1:0] data_r;
 assign data_o=data_r;
 always_ff @ (posedge clk_i) begin
 if (reset_i) begin
 data_r <= width_p'(reset_val_p);
 end
 else begin
 if (en_i) begin
 data_r <= data_i;
 end
 end
 end
endmodule
/**
 * bsg_dff_reset_en_bypass.v
 *
 */

module bsg_dff_reset_en_bypass
 #(parameter width_p="inv"
 ,parameter reset_val_p=0
 ,parameter harden_p=0
 )
 (
 input clk_i
 ,input reset_i
 ,input en_i
 ,input [width_p-1:0] data_i
 ,output logic [width_p-1:0] data_o
 );
 logic [width_p-1:0] data_r;
 bsg_dff_reset_en #(
 .width_p(width_p)
 ,.harden_p(harden_p)
 ) dff (
 .clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.en_i(en_i)
 ,.data_i(data_i)
 ,.data_o(data_r)
 );
 assign data_o=en_i
 ? data_i
 : data_r;
endmodule
/**
 * bsg_dff_reset_set_clear.v
 *
 * Reset has priority over set.
 * Set has priority over clear (by default).
 *
 */

module bsg_dff_reset_set_clear
 #(parameter width_p="inv"
 ,parameter clear_over_set_p=0 
 )
 (
 input clk_i
 ,input reset_i
 ,input [width_p-1:0] set_i
 ,input [width_p-1:0] clear_i
 ,output logic [width_p-1:0] data_o
 );
 logic [width_p-1:0] data_r;
 always_ff @ (posedge clk_i)
 if (reset_i)
 data_r <= '0;
 else
 if (clear_over_set_p)
 data_r <= (data_r | set_i) & (~clear_i);
 else
 data_r <= (data_r & ~clear_i) | set_i;
 assign data_o=data_r;
endmodule

module bsg_dlatch #(parameter width_p="inv"
 ,parameter i_know_this_is_a_bad_idea_p=0
 )
 (input clk_i
 ,input [width_p-1:0] data_i
 ,output logic [width_p-1:0] data_o
 );
 if (i_know_this_is_a_bad_idea_p == 0)
 $fatal( 1,"Error: you must admit this is a bad idea before you are allowed to use the bsg_dlatch module!" );
 always_latch
 begin
 if (clk_i)
 data_o <= data_i;
 end
endmodule

module bsg_edge_detect
 #(parameter falling_not_rising_p=0)
 (input clk_i
 ,input reset_i
 ,input sig_i
 ,output detect_o
 );
 logic sig_r;
 bsg_dff_reset
 #(.width_p(1))
 sig_reg
 (.clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.data_i(sig_i)
 ,.data_o(sig_r)
 );
 if (falling_not_rising_p == 1)
 begin : falling
 assign detect_o=~sig_i & sig_r;
 end
 else
 begin : rising
 assign detect_o=sig_i & ~sig_r;
 end
endmodule

module bsg_encode_one_hot #(parameter width_p=8,parameter lo_to_hi_p=1,parameter debug_p=0)
(input [width_p-1:0] i
 ,output [`BSG_SAFE_CLOG2(width_p)-1:0] addr_o
 ,output v_o 
);
 localparam levels_lp=$clog2(width_p);
 localparam aligned_width_lp=1 << $clog2(width_p);
 genvar level;
 genvar segment;
 wire [levels_lp:0][aligned_width_lp-1:0] addr;
 wire [levels_lp:0][aligned_width_lp-1:0] v; 
 assign v [0]=lo_to_hi_p ? ((aligned_width_lp) ' (i)) : i << (aligned_width_lp - width_p);
 assign addr[0]=(width_p == 1) ? '0 : `BSG_UNDEFINED_IN_SIM('0);
 for (level=1; level < levels_lp+1; level=level+1)
 begin : rof
 localparam segments_lp=2**(levels_lp-level);
 localparam segment_slot_lp=aligned_width_lp/segments_lp;
 localparam segment_width_lp=level; 
 for (segment=0; segment < segments_lp; segment=segment+1)
 begin : rof1
 wire [1:0] vs={
 v[level-1][segment*segment_slot_lp+(segment_slot_lp >> 1)] 
 ,v[level-1][segment*segment_slot_lp]
 };
 assign v[level][segment*segment_slot_lp]=| vs;
 if (level == 1)
 assign addr[level][(segment*segment_slot_lp)+:segment_width_lp]={ vs[lo_to_hi_p] }; 
 else
 begin : fi
 assign addr[level][(segment*segment_slot_lp)+:segment_width_lp]
={ vs[lo_to_hi_p]
 ,addr[level-1][segment*segment_slot_lp+:segment_width_lp-1]
 | addr[level-1][segment*segment_slot_lp+(segment_slot_lp >> 1)+:segment_width_lp-1]
 };
 end 
 end 
 end	
 assign v_o=v[levels_lp][0];
`ifdef SYNTHESIS
 assign addr_o=addr[levels_lp][`BSG_SAFE_CLOG2(width_p)-1:0];
`else
 assign addr_o=(((i-1) & i) == '0) 
 ? addr[levels_lp][`BSG_SAFE_CLOG2(width_p)-1:0] 
 : { `BSG_SAFE_CLOG2(width_p){1'bx}};
 if (debug_p)
 always @(addr_o or v_o)
 begin
 `BSG_HIDE_FROM_VERILATOR(#1)
 for (integer k=0; k <= $clog2(width_p); k=k+1)
 $display("%b %b",addr[k],v[k]);
 $display("addr_o=%b v_o=%b",addr_o,v_o);
 end
`endif
endmodule
/**
 * bsg_expand_bitmask.v
 *
 * This module expands each bit in the input vector by the factor of
 * expand_p.
 * 
 * @author tommy
 * 
 *
 * example
 * ------------------------
 * in_width_p=2,expand_p=4
 * ------------------------
 * i=00 -> o=0000_0000
 * i=01 -> o=0000_1111
 * i=10 -> o=1111_0000
 * i=11 -> o=1111_1111
 *
 */

module bsg_expand_bitmask #(parameter in_width_p="inv",expand_p="inv")
(
 input [in_width_p-1:0] i
 ,output logic [(in_width_p*expand_p)-1:0] o
);
 always_comb
 for (integer k=0; k < in_width_p; k++)
 o[expand_p*k+:expand_p]={expand_p{i[k]}};
endmodule

module bsg_gray_to_binary #(parameter width_p=-1)
 (input [width_p-1:0] gray_i
 ,output [width_p-1:0] binary_o
 );
/*
 assign binary_o[width_p-1]=gray_i[width_p-1];
 generate
 genvar i;
 for (i=0; i < width_p-1; i=i+1)
 begin
 assign binary_o[i]=binary_o[i+1] ^ gray_i[i];
 end
 endgenerate
 */
 bsg_scan #(.width_p(width_p)
	 ,.xor_p(1)
	 ) scan_xor
 (.i(gray_i)
 ,.o(binary_o));
endmodule

module bsg_hash_bank #(parameter banks_p="inv",width_p="inv",
 index_width_lp=$clog2((2**width_p+banks_p-1)/banks_p),
 lg_banks_lp=`BSG_SAFE_CLOG2(banks_p),debug_lp=0)
 (/* input clk,*/
 input [width_p-1:0] i
 ,output [lg_banks_lp-1:0] bank_o
 ,output [index_width_lp-1:0] index_o
 );
 genvar j;
 if (banks_p == 1)
 begin: hash1
 assign index_o=i;
 assign bank_o=1'b0;
 end	
 else
 if (banks_p == 2)
 begin: hash2
 assign bank_o=i[width_p-1];
 assign index_o=i[width_p-2:0];
 end 
 else
 if (~banks_p[0])
 begin: hashpow2
 assign bank_o [0]=i[width_p-1];
 bsg_hash_bank #(.banks_p(banks_p >> 1),.width_p(width_p-1)) bhb (/* .clk(clk),*/.i(i[width_p-2:0]),.bank_o(bank_o[lg_banks_lp-1:1]),.index_o(index_o));
 end
 else
 if ((banks_p & (banks_p+1))==0) 
 begin : hash3
 if ((width_p % lg_banks_lp)!=0)
 begin : odd
 wire _unused;
 bsg_hash_bank #(.banks_p(banks_p),.width_p(width_p+1))
 hf (/* .clk,*/ .i({i,1'b0}),.bank_o(bank_o),.index_o({index_o,_unused}));
 end
 else 
 begin : even
 localparam frac_width_lp=width_p/lg_banks_lp;
 wire [lg_banks_lp-1:0][frac_width_lp-1:0] unzippered;
 wire [frac_width_lp-1:0] one_one;
 bsg_reduce_segmented #(.segments_p(frac_width_lp),.segment_width_p(lg_banks_lp),.and_p(1'b1)) brs
 (.i(i),.o(one_one));
 bsg_transpose #(.width_p(lg_banks_lp),.els_p(frac_width_lp)) unzip (.i(i),.o(unzippered));
 wire [frac_width_lp-1:0] one_one_and_scan;
 bsg_scan #(.width_p(frac_width_lp),.and_p(1)) scan(.i(one_one),.o(one_one_and_scan));
 wire [frac_width_lp-1:0] not_one_one_and_scan=~one_one_and_scan;
 wire [frac_width_lp-1:0] shifty;
 if (frac_width_lp > 1)
 assign shifty={ 1'b1,one_one_and_scan[frac_width_lp-1:1] };
 else
 assign shifty={ 1'b1 };
 wire [frac_width_lp-1:0] border=not_one_one_and_scan & shifty;
 wire [lg_banks_lp-1:0][frac_width_lp-1:0] bits;
 for (j=1; j < lg_banks_lp; j=j + 1)
 begin: rof2
 assign bits[j]=unzippered[j] & ~(border | one_one_and_scan);
 end
 assign bits[0]=(one_one_and_scan) | (unzippered[0] & ~one_one_and_scan & ~border);
 wire [width_p-1:0] transpose_lo;
 bsg_transpose #(.els_p(lg_banks_lp),.width_p(frac_width_lp)) zip (.i({bits}),.o(transpose_lo));
 assign index_o=transpose_lo[index_width_lp-1:0];
 for (j=0; j < lg_banks_lp; j=j + 1)
 begin: rof1
 assign bank_o[j]=| (border & unzippered[j]);
 end
/* if (debug_lp)
	 always @(negedge clk)
 	 begin
	 $display ("%b -> %b %b %b %b %b %b %b %b %b %b",
	 i,one_one,one_one_and_scan,not_one_one_and_scan,shifty,border,unzippered[1],
 unzippered[0],bits[1],bits[0],index_o);
 end	
 */
 end 	 
 end 
 else
 initial 
 begin 
 assert(0) else $error("unhandled case,banks_p=",banks_p); 
 end
endmodule

module bsg_hash_bank_reverse #(parameter banks_p="inv",width_p="inv",index_width_lp=$clog2((2**width_p+banks_p-1)/banks_p),lg_banks_lp=`BSG_SAFE_CLOG2(banks_p),debug_lp=0)
 (/* input clk,*/ 
 input [index_width_lp-1:0] index_i
 ,input [lg_banks_lp-1:0] bank_i
 ,output [width_p-1:0] o
 );
 if (banks_p == 1)
 begin: hash1
 assign o=index_i;
 end	
 else 
 if (banks_p == 2)
 begin: hash2
 assign o={ bank_i,index_i };
 end 
 else
 if (~banks_p[0])
 begin: hashpow2
 assign o[width_p-1]=bank_i[0];
 bsg_hash_bank_reverse #(.banks_p(banks_p >> 1),.width_p(width_p-1)) bhbr (/* .clk(clk) ,*/ .index_i(index_i[index_width_lp-1:0]),.bank_i(bank_i[lg_banks_lp-1:1]),.o(o[width_p-2:0]));
 end
 else 
 if ((banks_p & (banks_p+1)) == 0) 
 begin : hash3
 if (width_p % lg_banks_lp)
 begin : odd
 wire _unused;
 bsg_hash_bank_reverse #(.banks_p(banks_p),.width_p(width_p+1)) rhf
 ( /* .clk(clk),*/ .index_i({index_i,1'b0}),.bank_i(bank_i),.o({o[width_p-1:0],_unused}));
 end
 else 
 begin : even 
 /* This is the hash function we implement.
 Bank Zero,0 XX XX --> 00 XX XX
	 Bank One,0 XX XX --> 01 XX XX
	 Bank Two,0 XX XX --> 10 XX XX
 Bank Zero,1 00 XX --> 11 00 XX
	 Bank One,1 00 XX --> 11 01 XX 
	 Bank Two,1 00 XX --> 11 10 XX 
	 Bank Zero,1 01 00 --> 11 11 00
	 Bank One,1 01 00 --> 11 11 01
	 Bank Two,1 01 00 --> 11 11 10
	 Bank Zero,1 01 01 --> 11 11 11
 the algorithm is:
 starting from the left; the first 00 you see,substitute the bank number
 starting from the left; as long as you see 01,substitute 11.
 */
 localparam frac_width_lp=width_p/lg_banks_lp;
 wire [lg_banks_lp-1:0][frac_width_lp-1:0] unzippered;
 wire [width_p-1:0] index_i_ext=(width_p) ' (index_i); 
 bsg_transpose #(.width_p(lg_banks_lp),.els_p(frac_width_lp)) unzip (.i(index_i_ext),.o(unzippered));
 genvar j;
 wire [frac_width_lp-1:0] zero_pair;
 bsg_reduce_segmented #(.segments_p(frac_width_lp),.segment_width_p(lg_banks_lp),.nor_p(1)) brs
 (.i(index_i_ext),.o(zero_pair));
 wire [frac_width_lp-1:0] zero_pair_or_scan;
 bsg_scan #(.width_p(frac_width_lp),.or_p(1)) scan
 (.i(zero_pair),.o(zero_pair_or_scan)); 
 wire [frac_width_lp-1:0] first_one;
 if (frac_width_lp > 1)
 assign first_one=zero_pair_or_scan & ~{1'b0,zero_pair_or_scan[frac_width_lp-1:1]};
 else
 assign first_one=zero_pair_or_scan;
 wire [lg_banks_lp-1:0][frac_width_lp-1:0] bits;
 for (j=0; j < lg_banks_lp; j=j+1)
 begin: rof2
 assign bits[j]=(zero_pair_or_scan & ~first_one & unzippered[j]) | (first_one & { frac_width_lp { bank_i[j] }}) | ~zero_pair_or_scan;
 end
 /* if (debug_lp)
 begin
 always @(negedge clk)
 begin
 $display ("%b %b -> ZP(%b) ZPS(%b) FO(%b) TB(%b) BB(%b) %b ",
 index_i,bank_i,zero_pair,zero_pair_or_scan,first_one,top_bits,bot_bits,o);
 end
 end
 */ 
 wire [width_p-1:0] transpose_lo;
 bsg_transpose #(.els_p(lg_banks_lp),.width_p(frac_width_lp)) zip (.i({bits}),.o(transpose_lo)); 
 assign o=transpose_lo[width_p-1:0];
 end
 end
 else
 initial 
 begin 
 assert(0) else $error("unhandled case,banks_p=",banks_p); 
 end	
endmodule	
/**
 * bsg_id_pool.v
 *
 * This module maintains of a pool of IDs,and supports allocation and deallocation of these IDs.
 *
 */

module bsg_id_pool
 #(parameter els_p="inv"
 ,parameter id_width_lp=`BSG_SAFE_CLOG2(els_p)
 ) 
 (
 input clk_i,
 input reset_i
 ,output logic [id_width_lp-1:0] alloc_id_o
 ,output logic alloc_v_o
 ,input alloc_yumi_i
 ,input dealloc_v_i
 ,input [id_width_lp-1:0] dealloc_id_i 
 );
 logic [els_p-1:0] allocated_r;
 logic [els_p-1:0] dealloc_decode;
 bsg_decode_with_v #(
 .num_out_p(els_p)
 ) d1 (
 .i(dealloc_id_i)
 ,.v_i(dealloc_v_i)
 ,.o(dealloc_decode)
 );
 logic [id_width_lp-1:0] alloc_id_lo;
 logic alloc_v_lo;
 logic [els_p-1:0] one_hot_out;
 bsg_priority_encode_one_hot_out #(
 .width_p(els_p)
 ,.lo_to_hi_p(1)
 ) pe0 (
 .i(~allocated_r | dealloc_decode)
 ,.o(one_hot_out)
 ,.v_o(alloc_v_lo)
 );
 bsg_encode_one_hot #(
 .width_p(els_p)
 ,.lo_to_hi_p(1)
 ) enc0 (
 .i(one_hot_out)
 ,.addr_o(alloc_id_lo)
 ,.v_o()
 );
 assign alloc_id_o=alloc_id_lo;
 assign alloc_v_o=alloc_v_lo;
 wire [els_p-1:0] alloc_decode=one_hot_out & {els_p{alloc_yumi_i}};
 bsg_dff_reset_set_clear #(
 .width_p(els_p)
 ) dff_alloc0 (
 .clk_i(clk_i)
 ,.reset_i(reset_i)
 ,.set_i(alloc_decode)
 ,.clear_i(dealloc_decode)
 ,.data_o(allocated_r)
 );
 always_ff @ (negedge clk_i) begin
 if (~reset_i) begin
 if (dealloc_v_i) begin
 assert(allocated_r[dealloc_id_i]) else $error("Cannot deallocate an id that hasn't been allocated.");
 assert(dealloc_id_i < els_p) else $error("Cannot deallocate an id that is outside the range.");
 end
 if (alloc_yumi_i)
 assert(alloc_v_o) else $error("Handshaking error. alloc_yumi_i raised without alloc_v_o.");
 if (alloc_yumi_i & dealloc_v_i & (alloc_id_o == dealloc_id_i))
 assert(allocated_r[dealloc_id_i]) else $error("Cannot immediately dellocate an allocated id.");
 end
 end
endmodule

module bsg_inv #(parameter width_p="inv"
 ,harden_p=1
	 ,vertical_p=1)
 (input [width_p-1:0] i
 ,output [width_p-1:0] o
 );
 assign o=~i;
endmodule
/**
 * bsg_less_than.v
 *
 * @author Tommy Jung
 */

module bsg_less_than #(parameter width_p="inv") (
 input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output logic o 
 );
 assign o=(a_i < b_i);
endmodule

module bsg_level_shift_up_down_sink #(parameter width_p="inv")
(
 input [width_p-1:0] v0_data_i,
 input v1_en_i,
 output logic [width_p-1:0] v1_data_o
);
 initial
 $display("%m - warning: using non-hard up/down sink-side level shifter");
 assign v1_data_o=v0_data_i & {width_p{v1_en_i}};
endmodule

module bsg_level_shift_up_down_source #(parameter width_p="inv")
(
 input v0_en_i,
 input [width_p-1:0] v0_data_i,
 output logic [width_p-1:0] v1_data_o
);
 initial
 $display("%m - warning: using non-hard up/down source-side level shifter");
 assign v1_data_o=v0_data_i & {width_p{v0_en_i}};
endmodule

module bsg_lfsr #(parameter width_p=-1
 ,init_val_p=1 
 ,xor_mask_p=0)
 (input clk
 ,input reset_i
 ,input yumi_i
 ,output logic [width_p-1:0] o
 );
 logic [width_p-1:0] o_r,o_n,xor_mask;
 assign o=o_r;
 if (xor_mask_p == 0)
 begin : automask
 case (width_p)
 32:
 assign xor_mask=(1 << 31) | (1 << 29) | (1 << 26) | (1 << 25);
 60:
 assign xor_mask=(1 << 59) | (1 << 58);
 64:
 assign xor_mask=(1 << 63) | (1 << 62) | (1 << 60) | (1 << 59);
 default:
 initial assert(width_p==-1)
 else
 begin
 $display("unhandled default mask for width %d in bsg_lfsr",width_p); $finish();
 end
 endcase 
 end
 else
 begin: fi
 assign xor_mask=xor_mask_p;
 end
 always @(posedge clk)
 begin
 if (reset_i)
 o_r <= (width_p) ' (init_val_p);
 else if (yumi_i)
 o_r <= o_n;
 end
 assign o_n=(o_r >> 1) ^ ({width_p {o_r[0]}} & xor_mask);
endmodule 

module bsg_locking_arb_fixed #( parameter inputs_p="inv"
 ,parameter lo_to_hi_p=0
 )
 ( input clk_i
 ,input ready_i
 ,input unlock_i
 ,input [inputs_p-1:0] reqs_i
 ,output logic [inputs_p-1:0] grants_o
 ); 
 wire [inputs_p-1:0] not_req_mask_r,req_mask_r;
 bsg_dff_reset_en #( .width_p(inputs_p) )
 req_words_reg
 ( .clk_i ( clk_i )
 ,.reset_i( unlock_i )
 ,.en_i ( (&req_mask_r) & (|grants_o) )
 ,.data_i ( ~grants_o )
 ,.data_o ( not_req_mask_r )
 );
 assign req_mask_r=~not_req_mask_r;
 bsg_arb_fixed #( .inputs_p(inputs_p),.lo_to_hi_p(lo_to_hi_p) )
 fixed_arb
 ( .ready_i ( ready_i )
 ,.reqs_i ( reqs_i & req_mask_r )
 ,.grants_o( grants_o )
 ); 
endmodule
/**
 * bsg_lru_pseudo_tree_backup.v
 *
 * tree pseudo LRU backup finder.
 *
 * Given the bit vector of disabled ways,it will tell
 * you bit-mask and data to modify the original LRU bits to obtain
 * the backup LRU.
 * 
 * The algorithm to find backup_LRU is:
 * start from the root of the LRU tree,and traverse down the tree in the
 * direction of the LRU bits,if there is at least one unlocked way in that
 * direction. If not,take the opposite direction.
 * 
 *
 * ==== Example ==============================================
 *
 * rank=0 [0]
 * 0
 * / \
 * rank=1 [1] [2]
 * 1 0
 * / \ / \
 * rank=2 [3] [4] [5] [6]
 * 1 0 1 1
 * / \ / \ / \ / \
 * way w0 w1 w2 w3 w4 w5 w6 w7
 *
 *
 * Let say LRU bits were 7'b110_1010 so that LRU way is w2.
 * If the disabled ways are {w2},then backup_LRU=w3.
 * If the disabled are {w2,w3},then backup_LRU=w1
 * If the disabled are {w0,w1,w2,w3},the backup_LRU=w5.
 *
 * ============================================================
 *
 * @author tommy
 *
 *
 */

module bsg_lru_pseudo_tree_backup
 #(parameter ways_p="inv"
 ,parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
 )
 (
 input [ways_p-1:0] disabled_ways_i
 ,output logic [`BSG_SAFE_MINUS(ways_p,2):0] modify_mask_o
 ,output logic [`BSG_SAFE_MINUS(ways_p,2):0] modify_data_o
 );
 if (ways_p == 1) begin: no_lru
 assign modify_mask_o=1'b1;
 assign modify_data_o=1'b0;
 end
 else begin: lru
 for (genvar i=0; i < lg_ways_lp; i++) begin
 logic [(2**(i+1))-1:0] and_reduce;
 for (genvar j=0; j < (2**(i+1)); j++)
 assign and_reduce[j]=&disabled_ways_i[(ways_p/(2**(i+1)))*j+:(ways_p/(2**(i+1)))];
 for (genvar k=0; k < (2**(i+1))/2; k++) begin
 assign modify_data_o[(2**i)-1+k]=and_reduce[2*k];
 assign modify_mask_o[(2**i)-1+k]=|and_reduce[2*k+:2];
 end
 end
 end
endmodule
/**
 * Name:
 * bsg_lru_pseudo_tree_decode.v
 *
 * Description:
 * Pseudo-Tree-LRU decode unit.
 * Given input referred way_id,generates data and mask that updates
 * the pseudo-LRU tree. Data and mask are chosen in a way that referred way_id is
 * no longer the LRU way. The mask and data signals can be given to a 
 * bitmaskable memory to update the corresponding LRU bits.
 */

module bsg_lru_pseudo_tree_decode
 #(parameter ways_p="inv"
 ,localparam lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
 )
 (input [lg_ways_lp-1:0] way_id_i
 ,output logic [`BSG_SAFE_MINUS(ways_p,2):0] data_o
 ,output logic [`BSG_SAFE_MINUS(ways_p,2):0] mask_o
 );
 genvar i;
 generate
 if (ways_p == 1) begin: no_lru
 assign mask_o[0]=1'b1;
 assign data_o[0]=1'b0;
 end
 else begin: lru
 for(i=0; i<ways_p-1; i++) begin: rof
	 if(i == 0) begin: fi
	 assign mask_o[i]=1'b1;
	 end
	 else if(i%2 == 1) begin: fi
	 assign mask_o[i]=mask_o[(i-1)/2] & ~way_id_i[lg_ways_lp-`BSG_SAFE_CLOG2(i+2)+1];
	 end
	 else begin: fi
	 assign mask_o[i]=mask_o[(i-2)/2] & way_id_i[lg_ways_lp-`BSG_SAFE_CLOG2(i+2)+1];
	 end
	 assign data_o[i]=mask_o[i] & ~way_id_i[lg_ways_lp-`BSG_SAFE_CLOG2(i+2)];
 end
 end
 endgenerate
endmodule
/**
 * bsg_lru_pseudo_tree_encode.v
 *
 * Pseudo-Tree-LRU encode unit.
 * Given the LRU bits,traverses the pseudo-LRU tree and returns the
 * LRU way_id.
 * Only for power-of-2 ways.
 *
 * --------------------
 * Example (ways_p=8)
 * --------------------
 * lru_i way_id_o
 * ----- --------
 * xxx_0x00 0
 * xxx_1x00 1
 * xx0 xx10 2
 * xx1 xx10 3
 * x0x x0x1 4
 * x1x x0x1 5
 * 0xx x1x1 6
 * 1xx x1x1 7
 * --------------------
 * 'x' means don't care.
 *
 * @author tommy
 *
 */

module bsg_lru_pseudo_tree_encode
 #(parameter ways_p="inv"
 ,parameter lg_ways_lp=`BSG_SAFE_CLOG2(ways_p)
 )
 (
 input [`BSG_SAFE_MINUS(ways_p,2):0] lru_i
 ,output logic [lg_ways_lp-1:0] way_id_o
 );
 if (ways_p == 1) begin: no_lru
 assign way_id_o=1'b0;
 end
 else begin: lru
 for (genvar i=0; i < lg_ways_lp; i++) begin: rank
 if (i == 0) begin: z
 assign way_id_o[lg_ways_lp-1]=lru_i[0]; 
 end
 else begin: nz
 bsg_mux #(
 .width_p(1)
 ,.els_p(2**i)
 ) mux (
 .data_i(lru_i[((2**i)-1)+:(2**i)])
 ,.sel_i(way_id_o[lg_ways_lp-1-:i])
 ,.data_o(way_id_o[lg_ways_lp-1-i])
 );
 end
 end
 end
endmodule

module bsg_mul #(parameter width_p="inv"
 ,harden_p=1
 )
 (input [width_p-1:0] x_i
 ,input [width_p-1:0] y_i
 ,input signed_i
 ,output [width_p*2-1:0] z_o
 );
 bsg_mul_pipelined #(.width_p (width_p )
 ,.pipeline_p(0 )
 ,.harden_p (harden_p)
 ) bmp
 (.clock_i(1'b0)
 ,.en_i(1'b0)
 ,.x_i
 ,.y_i
 ,.signed_i
 ,.z_o
 );
endmodule
/**
 *	bsg_mul_array.v
 *	pipelined unsigned array multiplier.
 * @param width_p width of inputs
 * @param pipeline_p binary vector that is (width_p-1) wide.
 * There are width_p-1 rows of ripple carry adders.
 * Having 1 in this binary vector means that that row is pipelined.
 *	@author Tommy Jung
 */

module bsg_mul_array #(parameter width_p="inv",pipeline_p="inv")
 (
 input clk_i
 ,	input rst_i
 ,input v_i
 ,input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output logic [(width_p*2)-1:0] o
 );
 logic [width_p-1:0] a_r [width_p-3:0];
 logic [width_p-1:0] b_r [width_p-3:0];
 logic [width_p-1:0] s_r [width_p-2:0];
 logic c_r [width_p-2:0];
 logic [width_p-1:0] prod_accum [width_p-2:0];
 logic [width_p-1:0] pp0;
 bsg_and #(.width_p(width_p)) and0 (
 .a_i(a_i)
 ,.b_i({width_p{b_i[0]}})
 ,.o(pp0)
 );
 genvar i; 
 for (i=0; i < width_p-1; i++) begin
 if (i == 0) begin
 bsg_mul_array_row #(.width_p(width_p),.row_idx_p(i),.pipeline_p(pipeline_p[i]))
 first_row (
 .clk_i(clk_i)
 ,.rst_i(rst_i)
 ,.v_i(v_i)
 ,.a_i(a_i)
 ,.b_i(b_i)
 ,.s_i(pp0)
 ,.c_i(1'b0)
 ,.prod_accum_i(pp0[0])
 ,.a_o(a_r[i])
 ,.b_o(b_r[i])
 ,.s_o(s_r[i])
 ,.c_o(c_r[i])
 ,.prod_accum_o(prod_accum[i][i+1:0])
 );
 end
 else if (i == width_p-2) begin
 bsg_mul_array_row #(.width_p(width_p),.row_idx_p(i),.pipeline_p(pipeline_p[i]))
 last_row (
 .clk_i(clk_i)
 ,.rst_i(rst_i)
 ,.v_i(v_i)
 ,.a_i(a_r[i-1])
 ,.b_i(b_r[i-1])
 ,.s_i(s_r[i-1])
 ,.c_i(c_r[i-1])
 ,.prod_accum_i(prod_accum[i-1][i:0])
 ,.a_o() 
 ,.b_o() 
 ,.s_o(s_r[i])
 ,.c_o(c_r[i])
 ,.prod_accum_o(prod_accum[i])
 );
 end
 else begin
 bsg_mul_array_row #(.width_p(width_p),.row_idx_p(i),.pipeline_p(pipeline_p[i]))
 mid_row (
 .clk_i(clk_i)
 ,.rst_i(rst_i)
 ,.v_i(v_i)
 ,.a_i(a_r[i-1])
 ,.b_i(b_r[i-1])
 ,.s_i(s_r[i-1])
 ,.c_i(c_r[i-1])
 ,.prod_accum_i(prod_accum[i-1][i:0])
 ,.a_o(a_r[i])
 ,.b_o(b_r[i])
 ,.s_o(s_r[i])
 ,.c_o(c_r[i])
 ,.prod_accum_o(prod_accum[i][i+1:0])
 );
 end
 end
 assign o[(2*width_p)-1]=c_r[width_p-2];
 assign o[(2*width_p)-2:width_p-1]=s_r[width_p-2];
 assign o[width_p-2:0]=prod_accum[width_p-2][width_p-2:0];
endmodule
/**
 * bsg_mul_array_row.v
 *
 * @author Tommy Jung
 */

module bsg_mul_array_row #(parameter width_p="inv"
 ,parameter row_idx_p="inv"
 ,parameter pipeline_p="inv")
 ( 
 input clk_i
 ,input rst_i
 ,input v_i
 ,input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,input [width_p-1:0] s_i
 ,input c_i
 ,input [row_idx_p:0] prod_accum_i
 ,output logic [width_p-1:0] a_o
 ,output logic [width_p-1:0] b_o
 ,output logic [width_p-1:0] s_o
 ,output logic c_o
 ,output logic [row_idx_p+1:0] prod_accum_o 
 );
 logic [width_p-1:0] pp;
 logic [width_p-1:0] ps;
 logic pc;
 bsg_and #(.width_p(width_p)) and0 (
 .a_i(a_i)
 ,.b_i({width_p{b_i[row_idx_p+1]}})
 ,.o(pp)
 );
 bsg_adder_ripple_carry #(.width_p(width_p)) adder0 (
 .a_i(pp)
 ,.b_i({c_i,s_i[width_p-1:1]})
 ,.s_o(ps)
 ,.c_o(pc)
 );
 logic [width_p-1:0] a_r;
 logic [width_p-1:0] b_r;
 logic [width_p-1:0] s_r;
 logic c_r;
 logic [row_idx_p+1:0] prod_accum_r;
 logic [width_p-1:0] a_n;
 logic [width_p-1:0] b_n;
 logic [width_p-1:0] s_n;
 logic c_n;
 logic [row_idx_p+1:0] prod_accum_n;
 if (pipeline_p) begin
 always_ff @ (posedge clk_i) begin
 if (rst_i) begin
 a_r <= 0;
 b_r <= 0;
 s_r <= 0;
 c_r <= 0;
 prod_accum_r <= 0;
 end
 else begin
 a_r <= a_n;
 b_r <= b_n;
 s_r <= s_n;
 c_r <= c_n;
 prod_accum_r <= prod_accum_n;
 end
 end
 always_comb begin
 if (v_i) begin
 a_n=a_i;
 b_n=b_i;
 s_n=ps;
 c_n=pc;
 prod_accum_n={ps[0],prod_accum_i};
 end
 else begin
 a_n=a_r;
 b_n=b_r;
 s_n=s_r;
 c_n=c_r;
 prod_accum_n=prod_accum_r;
 end
 a_o=a_r;
 b_o=b_r;
 s_o=s_r;
 c_o=c_r;
 prod_accum_o=prod_accum_r;
 end
 end
 else begin
 always_comb begin
 a_o=a_i;
 b_o=b_i;
 s_o=ps;
 c_o=pc;
 prod_accum_o={ps[0],prod_accum_i};
 end
 end
endmodule
/**
 * bsg_mul_synth.v
 *
 * synthesized multiplier
 */

module bsg_mul_synth #(parameter width_p="inv")
(
 input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output logic [(2*width_p)-1:0] o
);
 assign o=a_i * b_i;
endmodule

module bsg_mux #(`BSG_INV_PARAM(width_p)
 ,els_p=1
 ,harden_p=0
 ,balanced_p=0
 ,lg_els_lp=`BSG_SAFE_CLOG2(els_p)
 )
 (
 input [els_p-1:0][width_p-1:0] data_i
 ,input [lg_els_lp-1:0] sel_i
 ,output [width_p-1:0] data_o
 );
 if (els_p == 1)
 begin
 assign data_o=data_i;
 wire unused=sel_i;
 end
 else
 assign data_o=data_i[sel_i];
 initial
 assert(balanced_p == 0)
 else $error("%m warning: synthesizable implementation of bsg_mux does not support balanced_p");
endmodule
`BSG_ABSTRACT_MODULE(bsg_mux)

module bsg_mux2_gatestack #(parameter width_p="inv",harden_p=1)
 (input [width_p-1:0] i0
 ,input [width_p-1:0] i1
 ,input [width_p-1:0] i2
 ,output [width_p-1:0] o
 );
 genvar j;
 for (j=0; j < width_p; j=j+1)
 begin
	assign o[j]=i2[j] ? i1[j] : i0[j];
 end
endmodule
/**
 * bsg_mux_bitwise.v
 * @param width_p width of data
 */

module bsg_mux_bitwise #(parameter width_p="inv")
(
 input [width_p-1:0] data0_i
 ,input [width_p-1:0] data1_i
 ,input [width_p-1:0] sel_i
 ,output logic [width_p-1:0] data_o
);
 bsg_mux_segmented #(
 .segments_p(width_p)
 ,.segment_width_p(1)
 ) mux_segmented (
 .data0_i(data0_i)
 ,.data1_i(data1_i)
 ,.sel_i(sel_i)
 ,.data_o(data_o)
 );
endmodule
/**
 * bsg_mux_butterfly.v
 *
 * @author tommy
 *
 * This module has stages of mux which interleaves input data.
 * Output data width is same as the input data width.
 * The unit of swapping increases in higher stage.
 *
 * The lowest order bit swaps odd and even words
 * the highest order bit swaps the upper half of all
 * the words and the lower half of all the words. 
 * The second lowest order bit swaps odd and even pairs of words.
 * Etc.
 *
 * The pattern mirrors that of a FFT butterfly network.
 *
 * In the first stage,the swapping is done by LSB of sel_i.
 *
 * example (els_p=4):
 * For input={b3,b2,b1,b0}
 * ---------------------------
 * sel_i=00 => {b3,b2,b1,b0}
 * sel_i=01 => {b2,b3,b0,b1}
 * sel_i=10 => {b1,b0,b3,b2}
 * sel_i=11 => {b0,b1,b2,b3}
 * ---------------------------
 *
 */

module bsg_mux_butterfly
 #(parameter width_p="inv"
 ,parameter els_p="inv"
 ,localparam lg_els_lp=`BSG_SAFE_CLOG2(els_p)
 )
 (
 input [els_p-1:0][width_p-1:0] data_i
 ,input [lg_els_lp-1:0] sel_i
 ,output logic [els_p-1:0][width_p-1:0] data_o
 );
 logic [lg_els_lp:0][(els_p*width_p)-1:0] data_stage;
 assign data_stage[0]=data_i;
 for (genvar i=0; i < lg_els_lp; i++) begin: mux_stage
 for (genvar j=0; j < els_p/(2**(i+1)); j++) begin: mux_swap
 bsg_swap #(
 .width_p(width_p*(2**i))
 ) swap_inst (
 .data_i(data_stage[i][2*width_p*(2**i)*j+:2*width_p*(2**i)])
 ,.swap_i(sel_i[i])
 ,.data_o(data_stage[i+1][2*width_p*(2**i)*j+:2*width_p*(2**i)])
 );
 end 
 end
 assign data_o=data_stage[lg_els_lp];
endmodule

module bsg_mux_one_hot #(parameter width_p="inv"
 ,els_p=1
	 ,harden_p=1
 )
 (
 input [els_p-1:0][width_p-1:0] data_i
 ,input [els_p-1:0] sel_one_hot_i
 ,output [width_p-1:0] data_o
 );
 wire [els_p-1:0][width_p-1:0] data_masked;
 genvar i,j;
 for (i=0; i < els_p; i++)
 begin : mask
 assign data_masked[i]=data_i[i] & { width_p { sel_one_hot_i[i] } };
 end
 for (i=0; i < width_p; i++)
 begin: reduce
 wire [els_p-1:0] gather;
 for (j=0; j < els_p; j++)
 begin : reduce2
 assign gather[j]=data_masked[j][i];
 end
 assign data_o[i]=| gather;
 end
endmodule
/**
 * bsg_mux_segmented.v
 * @param segments_p number of segments.
 * @param segment_width_p width of each segment.
 */

module bsg_mux_segmented #(parameter segments_p="inv"
 ,parameter segment_width_p="inv"
 ,parameter data_width_lp=segments_p*segment_width_p)
(
 input [data_width_lp-1:0] data0_i
 ,input [data_width_lp-1:0] data1_i
 ,input [segments_p-1:0] sel_i
 ,output logic [data_width_lp-1:0] data_o
);
 genvar i;
 for (i=0; i < segments_p; i++) begin
 assign data_o[i*segment_width_p+:segment_width_p]=sel_i[i]
 ? data1_i[i*segment_width_p+:segment_width_p]
 : data0_i[i*segment_width_p+:segment_width_p];
 end
endmodule

module bsg_muxi2_gatestack #(width_p="inv",harden_p=1)
 (input [width_p-1:0] i0
 ,input [width_p-1:0] i1
 ,input [width_p-1:0] i2
 ,output [width_p-1:0] o
 );
 genvar j;
 for (j=0; j < width_p; j=j+1)
 begin
	assign o[j]=~(i2[j] ? i1[j] : i0[j]);
 end
endmodule

module bsg_nand #(parameter width_p="inv"
 ,harden_p=1)
 (input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output [width_p-1:0] o
 );
 assign o=~(a_i & b_i);
endmodule

module bsg_nor2 #(parameter width_p="inv"
 ,harden_p=1)
 (input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output [width_p-1:0] o
 );
 assign o=~(a_i | b_i );
endmodule

module bsg_nor3 #(parameter width_p="inv"
 ,harden_p=1)
 (input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,input [width_p-1:0] c_i
 ,output [width_p-1:0] o
 );
 assign o=~(a_i | b_i | c_i);
endmodule

module bsg_pg_tree
#(parameter input_width_p="inv"
 ,parameter output_width_p="inv"
 ,parameter nodes_p=1 
 ,parameter edges_lp=nodes_p*3
 ,parameter int l_edge_p [nodes_p-1:0]=' {0}
 ,parameter int r_edge_p [nodes_p-1:0]=' {0}
 ,parameter int o_edge_p [nodes_p-1:0]=' {0}
 ,parameter int node_type_p [nodes_p-1:0]=' {0}
 ,parameter int row_p [nodes_p-1:0]=' {0}
 )	
 (input [input_width_p-1:0] p_i
 ,input [input_width_p-1:0] g_i
 ,output [output_width_p-1:0] p_o
 ,output [output_width_p-1:0] g_o
 );
 wire [edges_lp-1:0] p;
 wire [edges_lp-1:0] g;
 assign p[input_width_p-1:0]=p_i; 
 assign g[input_width_p-1:0]=g_i;
 assign p_o=p[edges_lp-1-:output_width_p];
 assign g_o=g[edges_lp-1-:output_width_p];
 genvar i;
 for (i=0; i < nodes_p; i=i+1)
	begin: rof
 if (node_type_p[i] == 0) 
 begin: blk 
 	assign p[o_edge_p[i]]=p[l_edge_p[i]] | p[r_edge_p[i]];
 	assign g[o_edge_p[i]]=g[r_edge_p[i]] | (g[l_edge_p[i]] & p[r_edge_p[i]]); 
 end
 else if (node_type_p[i] == 1) 
 begin: gry 
 assign p[o_edge_p[i]]=`BSG_UNDEFINED_IN_SIM(0);
 	 assign g[o_edge_p[i]]=g[r_edge_p[i]] | (g[l_edge_p[i]] & p[r_edge_p[i]]); 
 end
 else if (node_type_p[i] == 2) 
 	begin: bbuf 
 assign p[o_edge_p[i]]=p[l_edge_p[i]];
 assign g[o_edge_p[i]]=g[l_edge_p[i]]; 
 end
 else if (node_type_p[i] == 3) 
 	begin: gbuf 
 assign p[o_edge_p[i]]=`BSG_UNDEFINED_IN_SIM(0);
 assign g[o_edge_p[i]]=g[l_edge_p[i]]; 
 end
	 else
 begin
 	initial $error("unknown node_type: ",node_type_p[i]);
 end
 end
endmodule
module bsg_popcount #(parameter width_p="inv")
 (input [width_p-1:0] i
 ,output [$clog2(width_p+1)-1:0] o
 );
 localparam first_half_lp=`BSG_MAX(4,width_p - (width_p >> 1));
 localparam second_half_lp=width_p - first_half_lp;
 if (width_p <= 3)
 begin : lt3
 assign o[0]=^i;
 if (width_p == 2)
 assign o[1]=& i;
 else
 if (width_p == 3)
 assign o[1]=(&i[1:0]) | (&i[2:1]) | (i[0]&i[2]);
 end
 else
 if (width_p == 4)
 begin : four
 wire [1:0] s0={ ^i[3:2],^i[1:0]};
 wire [1:0] c0={ &i[3:2],&i[1:0]};
 assign o[0]=^s0;
 assign o[1]=(^c0) | (&s0);
 assign o[2]=&c0;
 end
 else
 begin : recurse
 wire [$clog2(first_half_lp+1)-1:0] lo;
 wire [$clog2(second_half_lp+1)-1:0] hi;
 bsg_popcount #(.width_p(first_half_lp))
 left(.i(i[0+:first_half_lp])
 ,.o(lo)
 );
 bsg_popcount #(.width_p(second_half_lp))
 right(.i(i[first_half_lp+:second_half_lp])
 ,.o(hi)
 );
 assign o=lo+hi;
 end
endmodule 

module bsg_priority_encode #(parameter width_p="inv"
 ,parameter lo_to_hi_p="inv"
 )
 (input [width_p-1:0] i
 ,output [`BSG_SAFE_CLOG2(width_p)-1:0] addr_o
 ,output v_o
 );
 logic [width_p-1:0] enc_lo;
 bsg_priority_encode_one_hot_out #(.width_p(width_p)
 ,.lo_to_hi_p(lo_to_hi_p)
 ) a
 (.i(i)
 ,.o(enc_lo)
 ,.v_o(v_o)
 );
 bsg_encode_one_hot #(.width_p(width_p)
 ,.lo_to_hi_p(lo_to_hi_p)
 ) b
 (.i (enc_lo)
 ,.addr_o(addr_o)
 ,.v_o ()
 );
endmodule

module bsg_priority_encode_one_hot_out #(parameter width_p="inv"
 ,parameter lo_to_hi_p="inv"
 )
 (input [width_p-1:0] i
 ,output [width_p-1:0] o
 ,output v_o
 );
 logic [width_p-1:0] scan_lo;
 if (width_p == 1)
 begin: w1
 assign o=i;
 assign v_o=i;
 end
 else
 begin: nw1
 bsg_scan #(.width_p(width_p)
 ,.or_p (1)
 ,.lo_to_hi_p(lo_to_hi_p)
 ) scan (.i (i)
 ,.o(scan_lo)
 );
 if (lo_to_hi_p)
 begin : fi1
 assign o=scan_lo & { (~scan_lo[width_p-2:0]),1'b1 };
 assign v_o=scan_lo[width_p-1];
 end
 else
 begin : fi1
 assign o=scan_lo & { 1'b1,(~scan_lo[width_p-1:1]) };
 assign v_o=scan_lo[0];
 end
 end
endmodule

module bsg_reduce #(parameter width_p="inv"
 ,parameter xor_p=0
 ,parameter and_p=0
 ,parameter or_p=0
 ,parameter harden_p=0
 )
 (input [width_p-1:0] i
 ,output o
 );
 initial
 assert( $countones({xor_p & 1'b1,and_p & 1'b1,or_p & 1'b1}) == 1)
 else $error("bsg_reduce: exactly one function may be selected\n");
 if (xor_p)
 assign o=^i;
 else if (and_p)
 assign o=&i;
 else if (or_p)
 assign o=|i;
endmodule

module bsg_reduce_segmented #(parameter segments_p="inv"
 ,parameter segment_width_p="inv"
 ,parameter xor_p=0
 ,parameter and_p=0
 ,parameter or_p=0
 ,parameter nor_p=0 
 )
 (input [segments_p*segment_width_p-1:0] i
 ,output [segments_p-1:0] o
 );
 initial
 assert( $countones({xor_p[0],and_p[0],or_p[0],nor_p[0]}) == 1)
 else $error("%m: exactly one function may be selected\n");
 genvar j;
 for (j=0; j < segments_p; j=j+1)
 begin: rof2
 if (xor_p)
 assign o[j]=^i[(j*segment_width_p)+:segment_width_p];
 else if (and_p)
 assign o[j]=&i[(j*segment_width_p)+:segment_width_p];
 else if (or_p)
 assign o[j]=|i[(j*segment_width_p)+:segment_width_p];
 else if (nor_p)
 assign o[j]=~(|i[(j*segment_width_p)+:segment_width_p]);
 end
endmodule

module bsg_rotate_left #(width_p=-1)
 (input [width_p-1:0] data_i
 ,input [`BSG_SAFE_CLOG2(width_p)-1:0] rot_i
 ,output [width_p-1:0] o
 );
 wire [width_p*3-1:0] temp={ 2 { data_i } } << rot_i;
 assign o=temp[width_p*2-1:width_p];
endmodule

module bsg_rotate_right #(width_p=-1)
 (input [width_p-1:0] data_i
 ,input [`BSG_SAFE_CLOG2(width_p)-1:0] rot_i
 ,output [width_p-1:0] o
 );
 wire [width_p*2-1:0] temp={ 2 { data_i } } >> rot_i;
 assign o=temp[0+:width_p];
endmodule

module bsg_round_robin_arb #(inputs_p=-1
 ,lg_inputs_p =`BSG_SAFE_CLOG2(inputs_p)
 ,reset_on_sr_p=1'b0
 ,hold_on_sr_p=1'b0 )
 (input clk_i
 ,input reset_i
 ,input grants_en_i 
 ,input [inputs_p-1:0] reqs_i
 ,output logic [inputs_p-1:0] grants_o
 ,output logic [inputs_p-1:0] sel_one_hot_o
 ,output v_o 
 ,output logic [lg_inputs_p-1:0] tag_o 
 ,input yumi_i 
 );
logic [lg_inputs_p-1:0] last,last_n,last_r;
logic hold_on_sr,reset_on_sr;
if(inputs_p == 1)
begin: inputs_1
logic [1-1: 0 ] sel_one_hot_n;
always_comb
begin
 unique casez({last_r,reqs_i})
 2'b?_0: begin sel_one_hot_n=1'b0; tag_o=(lg_inputs_p) ' (0); end 
 2'b0_1: begin sel_one_hot_n= 1'b1; tag_o=(lg_inputs_p) ' (0); end
 default: begin sel_one_hot_n= {1{1'bx}}; tag_o=(lg_inputs_p) ' (0); end 
 endcase
end 
assign sel_one_hot_o=sel_one_hot_n;
assign grants_o=sel_one_hot_n & {1{grants_en_i}} ; 
if ( hold_on_sr_p ) begin 
 always_comb begin
 unique casez( last_r )
 1'b0 : hold_on_sr=( reqs_i == 1'b1 );
 default : hold_on_sr=1'b0;
 endcase
 end 
end else begin:not_hold_on_sr_p
 assign hold_on_sr='0;
end 
if ( reset_on_sr_p ) begin:reset_on_1 
 assign reset_on_sr=( reqs_i == 1'b1 ) 
 ;
end else begin:not_reset_on_sr_p
 assign reset_on_sr='0;
end 
end: inputs_1
if(inputs_p == 2)
begin: inputs_2
logic [2-1: 0 ] sel_one_hot_n;
always_comb
begin
 unique casez({last_r,reqs_i})
 3'b?_00: begin sel_one_hot_n=2'b00; tag_o=(lg_inputs_p) ' (0); end 
 3'b0_1?: begin sel_one_hot_n= 2'b10; tag_o=(lg_inputs_p) ' (1); end
 3'b0_01: begin sel_one_hot_n= 2'b01; tag_o=(lg_inputs_p) ' (0); end
 3'b1_?1: begin sel_one_hot_n= 2'b01; tag_o=(lg_inputs_p) ' (0); end
 3'b1_10: begin sel_one_hot_n= 2'b10; tag_o=(lg_inputs_p) ' (1); end
 default: begin sel_one_hot_n= {2{1'bx}}; tag_o=(lg_inputs_p) ' (0); end 
 endcase
end 
assign sel_one_hot_o=sel_one_hot_n;
assign grants_o=sel_one_hot_n & {2{grants_en_i}} ; 
if ( hold_on_sr_p ) begin 
 always_comb begin
 unique casez( last_r )
 1'b0 : hold_on_sr=( reqs_i == 2'b01 );
 default: hold_on_sr=( reqs_i == 2'b10 );
 endcase
 end 
end else begin:not_hold_on_sr_p
 assign hold_on_sr='0;
end 
if ( reset_on_sr_p ) begin:reset_on_2 
 assign reset_on_sr=( reqs_i == 2'b01 ) 
 | ( reqs_i == 2'b10 ) 
 ;
end else begin:not_reset_on_sr_p
 assign reset_on_sr='0;
end 
end: inputs_2
if(inputs_p == 3)
begin: inputs_3
logic [3-1: 0 ] sel_one_hot_n;
always_comb
begin
 unique casez({last_r,reqs_i})
 5'b??_000: begin sel_one_hot_n=3'b000; tag_o=(lg_inputs_p) ' (0); end 
 5'b00_?1?: begin sel_one_hot_n= 3'b010; tag_o=(lg_inputs_p) ' (1); end
 5'b00_10?: begin sel_one_hot_n= 3'b100; tag_o=(lg_inputs_p) ' (2); end
 5'b00_001: begin sel_one_hot_n= 3'b001; tag_o=(lg_inputs_p) ' (0); end
 5'b01_1??: begin sel_one_hot_n= 3'b100; tag_o=(lg_inputs_p) ' (2); end
 5'b01_0?1: begin sel_one_hot_n= 3'b001; tag_o=(lg_inputs_p) ' (0); end
 5'b01_010: begin sel_one_hot_n= 3'b010; tag_o=(lg_inputs_p) ' (1); end
 5'b10_??1: begin sel_one_hot_n= 3'b001; tag_o=(lg_inputs_p) ' (0); end
 5'b10_?10: begin sel_one_hot_n= 3'b010; tag_o=(lg_inputs_p) ' (1); end
 5'b10_100: begin sel_one_hot_n= 3'b100; tag_o=(lg_inputs_p) ' (2); end
 default: begin sel_one_hot_n= {3{1'bx}}; tag_o=(lg_inputs_p) ' (0); end 
 endcase
end 
assign sel_one_hot_o=sel_one_hot_n;
assign grants_o=sel_one_hot_n & {3{grants_en_i}} ; 
if ( hold_on_sr_p ) begin 
 always_comb begin
 unique casez( last_r )
 2'b00 : hold_on_sr=( reqs_i == 3'b010 );
 2'b01 : hold_on_sr=( reqs_i == 3'b001 );
 2'b10 : hold_on_sr=( reqs_i == 3'b100 );
 default : hold_on_sr=1'b0;
 endcase
 end 
end else begin:not_hold_on_sr_p
 assign hold_on_sr='0;
end 
if ( reset_on_sr_p ) begin:reset_on_3 
 assign reset_on_sr=( reqs_i == 3'b010 ) 
 | ( reqs_i == 3'b001 ) 
 | ( reqs_i == 3'b100 ) 
 ;
end else begin:not_reset_on_sr_p
 assign reset_on_sr='0;
end 
end: inputs_3
if(inputs_p == 4)
begin: inputs_4
logic [4-1: 0 ] sel_one_hot_n;
always_comb
begin
 unique casez({last_r,reqs_i})
 6'b??_0000: begin sel_one_hot_n=4'b0000; tag_o=(lg_inputs_p) ' (0); end 
 6'b00_??1?: begin sel_one_hot_n= 4'b0010; tag_o=(lg_inputs_p) ' (1); end
 6'b00_?10?: begin sel_one_hot_n= 4'b0100; tag_o=(lg_inputs_p) ' (2); end
 6'b00_100?: begin sel_one_hot_n= 4'b1000; tag_o=(lg_inputs_p) ' (3); end
 6'b00_0001: begin sel_one_hot_n= 4'b0001; tag_o=(lg_inputs_p) ' (0); end
 6'b01_?1??: begin sel_one_hot_n= 4'b0100; tag_o=(lg_inputs_p) ' (2); end
 6'b01_10??: begin sel_one_hot_n= 4'b1000; tag_o=(lg_inputs_p) ' (3); end
 6'b01_00?1: begin sel_one_hot_n= 4'b0001; tag_o=(lg_inputs_p) ' (0); end
 6'b01_0010: begin sel_one_hot_n= 4'b0010; tag_o=(lg_inputs_p) ' (1); end
 6'b10_1???: begin sel_one_hot_n= 4'b1000; tag_o=(lg_inputs_p) ' (3); end
 6'b10_0??1: begin sel_one_hot_n= 4'b0001; tag_o=(lg_inputs_p) ' (0); end
 6'b10_0?10: begin sel_one_hot_n= 4'b0010; tag_o=(lg_inputs_p) ' (1); end
 6'b10_0100: begin sel_one_hot_n= 4'b0100; tag_o=(lg_inputs_p) ' (2); end
 6'b11_???1: begin sel_one_hot_n= 4'b0001; tag_o=(lg_inputs_p) ' (0); end
 6'b11_??10: begin sel_one_hot_n= 4'b0010; tag_o=(lg_inputs_p) ' (1); end
 6'b11_?100: begin sel_one_hot_n= 4'b0100; tag_o=(lg_inputs_p) ' (2); end
 6'b11_1000: begin sel_one_hot_n= 4'b1000; tag_o=(lg_inputs_p) ' (3); end
 default: begin sel_one_hot_n= {4{1'bx}}; tag_o=(lg_inputs_p) ' (0); end 
 endcase
end 
assign sel_one_hot_o=sel_one_hot_n;
assign grants_o=sel_one_hot_n & {4{grants_en_i}} ; 
if ( hold_on_sr_p ) begin 
 always_comb begin
 unique casez( last_r )
 2'b00 : hold_on_sr=( reqs_i == 4'b0100 );
 2'b01 : hold_on_sr=( reqs_i == 4'b0010 );
 2'b10 : hold_on_sr=( reqs_i == 4'b0001 );
 default: hold_on_sr=( reqs_i == 4'b1000 );
 endcase
 end 
end else begin:not_hold_on_sr_p
 assign hold_on_sr='0;
end 
if ( reset_on_sr_p ) begin:reset_on_4 
 assign reset_on_sr=( reqs_i == 4'b0100 ) 
 | ( reqs_i == 4'b0010 ) 
 | ( reqs_i == 4'b0001 ) 
 | ( reqs_i == 4'b1000 ) 
 ;
end else begin:not_reset_on_sr_p
 assign reset_on_sr='0;
end 
end: inputs_4
if(inputs_p == 5)
begin: inputs_5
logic [5-1: 0 ] sel_one_hot_n;
always_comb
begin
 unique casez({last_r,reqs_i})
 8'b???_00000: begin sel_one_hot_n=5'b00000; tag_o=(lg_inputs_p) ' (0); end 
 8'b000_???1?: begin sel_one_hot_n= 5'b00010; tag_o=(lg_inputs_p) ' (1); end
 8'b000_??10?: begin sel_one_hot_n= 5'b00100; tag_o=(lg_inputs_p) ' (2); end
 8'b000_?100?: begin sel_one_hot_n= 5'b01000; tag_o=(lg_inputs_p) ' (3); end
 8'b000_1000?: begin sel_one_hot_n= 5'b10000; tag_o=(lg_inputs_p) ' (4); end
 8'b000_00001: begin sel_one_hot_n= 5'b00001; tag_o=(lg_inputs_p) ' (0); end
 8'b001_??1??: begin sel_one_hot_n= 5'b00100; tag_o=(lg_inputs_p) ' (2); end
 8'b001_?10??: begin sel_one_hot_n= 5'b01000; tag_o=(lg_inputs_p) ' (3); end
 8'b001_100??: begin sel_one_hot_n= 5'b10000; tag_o=(lg_inputs_p) ' (4); end
 8'b001_000?1: begin sel_one_hot_n= 5'b00001; tag_o=(lg_inputs_p) ' (0); end
 8'b001_00010: begin sel_one_hot_n= 5'b00010; tag_o=(lg_inputs_p) ' (1); end
 8'b010_?1???: begin sel_one_hot_n= 5'b01000; tag_o=(lg_inputs_p) ' (3); end
 8'b010_10???: begin sel_one_hot_n= 5'b10000; tag_o=(lg_inputs_p) ' (4); end
 8'b010_00??1: begin sel_one_hot_n= 5'b00001; tag_o=(lg_inputs_p) ' (0); end
 8'b010_00?10: begin sel_one_hot_n= 5'b00010; tag_o=(lg_inputs_p) ' (1); end
 8'b010_00100: begin sel_one_hot_n= 5'b00100; tag_o=(lg_inputs_p) ' (2); end
 8'b011_1????: begin sel_one_hot_n= 5'b10000; tag_o=(lg_inputs_p) ' (4); end
 8'b011_0???1: begin sel_one_hot_n= 5'b00001; tag_o=(lg_inputs_p) ' (0); end
 8'b011_0??10: begin sel_one_hot_n= 5'b00010; tag_o=(lg_inputs_p) ' (1); end
 8'b011_0?100: begin sel_one_hot_n= 5'b00100; tag_o=(lg_inputs_p) ' (2); end
 8'b011_01000: begin sel_one_hot_n= 5'b01000; tag_o=(lg_inputs_p) ' (3); end
 8'b100_????1: begin sel_one_hot_n= 5'b00001; tag_o=(lg_inputs_p) ' (0); end
 8'b100_???10: begin sel_one_hot_n= 5'b00010; tag_o=(lg_inputs_p) ' (1); end
 8'b100_??100: begin sel_one_hot_n= 5'b00100; tag_o=(lg_inputs_p) ' (2); end
 8'b100_?1000: begin sel_one_hot_n= 5'b01000; tag_o=(lg_inputs_p) ' (3); end
 8'b100_10000: begin sel_one_hot_n= 5'b10000; tag_o=(lg_inputs_p) ' (4); end
 default: begin sel_one_hot_n= {5{1'bx}}; tag_o=(lg_inputs_p) ' (0); end 
 endcase
end 
assign sel_one_hot_o=sel_one_hot_n;
assign grants_o=sel_one_hot_n & {5{grants_en_i}} ; 
if ( hold_on_sr_p ) begin 
 always_comb begin
 unique casez( last_r )
 3'b000 : hold_on_sr=( reqs_i == 5'b01000 );
 3'b001 : hold_on_sr=( reqs_i == 5'b00100 );
 3'b010 : hold_on_sr=( reqs_i == 5'b00010 );
 3'b011 : hold_on_sr=( reqs_i == 5'b00001 );
 3'b100 : hold_on_sr=( reqs_i == 5'b10000 );
 default : hold_on_sr=1'b0;
 endcase
 end 
end else begin:not_hold_on_sr_p
 assign hold_on_sr='0;
end 
if ( reset_on_sr_p ) begin:reset_on_5 
 assign reset_on_sr=( reqs_i == 5'b01000 ) 
 | ( reqs_i == 5'b00100 ) 
 | ( reqs_i == 5'b00010 ) 
 | ( reqs_i == 5'b00001 ) 
 | ( reqs_i == 5'b10000 ) 
 ;
end else begin:not_reset_on_sr_p
 assign reset_on_sr='0;
end 
end: inputs_5
if(inputs_p == 6)
begin: inputs_6
logic [6-1: 0 ] sel_one_hot_n;
always_comb
begin
 unique casez({last_r,reqs_i})
 9'b???_000000: begin sel_one_hot_n=6'b000000; tag_o=(lg_inputs_p) ' (0); end 
 9'b000_????1?: begin sel_one_hot_n= 6'b000010; tag_o=(lg_inputs_p) ' (1); end
 9'b000_???10?: begin sel_one_hot_n= 6'b000100; tag_o=(lg_inputs_p) ' (2); end
 9'b000_??100?: begin sel_one_hot_n= 6'b001000; tag_o=(lg_inputs_p) ' (3); end
 9'b000_?1000?: begin sel_one_hot_n= 6'b010000; tag_o=(lg_inputs_p) ' (4); end
 9'b000_10000?: begin sel_one_hot_n= 6'b100000; tag_o=(lg_inputs_p) ' (5); end
 9'b000_000001: begin sel_one_hot_n= 6'b000001; tag_o=(lg_inputs_p) ' (0); end
 9'b001_???1??: begin sel_one_hot_n= 6'b000100; tag_o=(lg_inputs_p) ' (2); end
 9'b001_??10??: begin sel_one_hot_n= 6'b001000; tag_o=(lg_inputs_p) ' (3); end
 9'b001_?100??: begin sel_one_hot_n= 6'b010000; tag_o=(lg_inputs_p) ' (4); end
 9'b001_1000??: begin sel_one_hot_n= 6'b100000; tag_o=(lg_inputs_p) ' (5); end
 9'b001_0000?1: begin sel_one_hot_n= 6'b000001; tag_o=(lg_inputs_p) ' (0); end
 9'b001_000010: begin sel_one_hot_n= 6'b000010; tag_o=(lg_inputs_p) ' (1); end
 9'b010_??1???: begin sel_one_hot_n= 6'b001000; tag_o=(lg_inputs_p) ' (3); end
 9'b010_?10???: begin sel_one_hot_n= 6'b010000; tag_o=(lg_inputs_p) ' (4); end
 9'b010_100???: begin sel_one_hot_n= 6'b100000; tag_o=(lg_inputs_p) ' (5); end
 9'b010_000??1: begin sel_one_hot_n= 6'b000001; tag_o=(lg_inputs_p) ' (0); end
 9'b010_000?10: begin sel_one_hot_n= 6'b000010; tag_o=(lg_inputs_p) ' (1); end
 9'b010_000100: begin sel_one_hot_n= 6'b000100; tag_o=(lg_inputs_p) ' (2); end
 9'b011_?1????: begin sel_one_hot_n= 6'b010000; tag_o=(lg_inputs_p) ' (4); end
 9'b011_10????: begin sel_one_hot_n= 6'b100000; tag_o=(lg_inputs_p) ' (5); end
 9'b011_00???1: begin sel_one_hot_n= 6'b000001; tag_o=(lg_inputs_p) ' (0); end
 9'b011_00??10: begin sel_one_hot_n= 6'b000010; tag_o=(lg_inputs_p) ' (1); end
 9'b011_00?100: begin sel_one_hot_n= 6'b000100; tag_o=(lg_inputs_p) ' (2); end
 9'b011_001000: begin sel_one_hot_n= 6'b001000; tag_o=(lg_inputs_p) ' (3); end
 9'b100_1?????: begin sel_one_hot_n= 6'b100000; tag_o=(lg_inputs_p) ' (5); end
 9'b100_0????1: begin sel_one_hot_n= 6'b000001; tag_o=(lg_inputs_p) ' (0); end
 9'b100_0???10: begin sel_one_hot_n= 6'b000010; tag_o=(lg_inputs_p) ' (1); end
 9'b100_0??100: begin sel_one_hot_n= 6'b000100; tag_o=(lg_inputs_p) ' (2); end
 9'b100_0?1000: begin sel_one_hot_n= 6'b001000; tag_o=(lg_inputs_p) ' (3); end
 9'b100_010000: begin sel_one_hot_n= 6'b010000; tag_o=(lg_inputs_p) ' (4); end
 9'b101_?????1: begin sel_one_hot_n= 6'b000001; tag_o=(lg_inputs_p) ' (0); end
 9'b101_????10: begin sel_one_hot_n= 6'b000010; tag_o=(lg_inputs_p) ' (1); end
 9'b101_???100: begin sel_one_hot_n= 6'b000100; tag_o=(lg_inputs_p) ' (2); end
 9'b101_??1000: begin sel_one_hot_n= 6'b001000; tag_o=(lg_inputs_p) ' (3); end
 9'b101_?10000: begin sel_one_hot_n= 6'b010000; tag_o=(lg_inputs_p) ' (4); end
 9'b101_100000: begin sel_one_hot_n= 6'b100000; tag_o=(lg_inputs_p) ' (5); end
 default: begin sel_one_hot_n= {6{1'bx}}; tag_o=(lg_inputs_p) ' (0); end 
 endcase
end 
assign sel_one_hot_o=sel_one_hot_n;
assign grants_o=sel_one_hot_n & {6{grants_en_i}} ; 
if ( hold_on_sr_p ) begin 
 always_comb begin
 unique casez( last_r )
 3'b000 : hold_on_sr=( reqs_i == 6'b010000 );
 3'b001 : hold_on_sr=( reqs_i == 6'b001000 );
 3'b010 : hold_on_sr=( reqs_i == 6'b000100 );
 3'b011 : hold_on_sr=( reqs_i == 6'b000010 );
 3'b100 : hold_on_sr=( reqs_i == 6'b000001 );
 3'b101 : hold_on_sr=( reqs_i == 6'b100000 );
 default : hold_on_sr=1'b0;
 endcase
 end 
end else begin:not_hold_on_sr_p
 assign hold_on_sr='0;
end 
if ( reset_on_sr_p ) begin:reset_on_6 
 assign reset_on_sr=( reqs_i == 6'b010000 ) 
 | ( reqs_i == 6'b001000 ) 
 | ( reqs_i == 6'b000100 ) 
 | ( reqs_i == 6'b000010 ) 
 | ( reqs_i == 6'b000001 ) 
 | ( reqs_i == 6'b100000 ) 
 ;
end else begin:not_reset_on_sr_p
 assign reset_on_sr='0;
end 
end: inputs_6
assign v_o=| reqs_i ;
if(inputs_p == 1)
 assign last_r=1'b0;
else
 begin
 always_comb
 if( hold_on_sr_p ) begin: last_n_gen
 last_n=hold_on_sr ? last_r :
 ( yumi_i ? tag_o : last_r ); 
 end else if( reset_on_sr_p ) begin: reset_on_last_n_gen
 last_n=reset_on_sr? (inputs_p-2) :
 ( yumi_i ?tag_o : last_r ); 
 end else
 last_n=(yumi_i ? tag_o:last_r);
 always_ff @(posedge clk_i)
 last_r <= (reset_i) ? (lg_inputs_p)'(0):last_n;
 end
endmodule

module bsg_scan #(parameter width_p=-1
 ,parameter xor_p=0
 ,parameter and_p=0
 ,parameter or_p=0
 ,parameter lo_to_hi_p=0
 ,parameter debug_p=0
	 )
 (input [width_p-1:0] i
 ,output logic [width_p-1:0] o
 );
 genvar j;
 wire [$clog2(width_p):0][width_p-1:0] t;
 wire [width_p-1:0] fill;
 initial
 assert( $countones({xor_p[0],and_p[0],or_p[0]}) == 1)
 else $error("bsg_scan: only one function may be selected\n");
 if (debug_p)
 always @(o)
 begin
 `BSG_HIDE_FROM_VERILATOR(#1)
 for (integer k=0; k <= $clog2(width_p); k=k+1)
 $display("%b",t[k]);
 $display("i=%b,o=%b",i,o);
 end
 if (lo_to_hi_p)
 assign t[0]={<< {i}};
 else
 assign t[0]=i;
 if ((width_p == 4) & and_p)
 begin : scand4
	assign t[$clog2(width_p)]={ t[0][3],&t[0][3:2],&t[0][3:1],&t[0][3:0] };
 end
 else if ((width_p == 3) & and_p)
 begin: scand3
	assign t[$clog2(width_p)]={ t[0][2],&t[0][2:1],&t[0][2:0] };
 end
 else if ((width_p == 2) & and_p)
 begin: scand3
	assign t[$clog2(width_p)]={ t[0][1],&t[0][1:0] };
 end
 else
 begin : scanN
	for (j=0; j < $clog2(width_p); j=j + 1)
	 begin : row
 wire [width_p-1:0] shifted=width_p ' ({fill,t[j]} >> (1 << j));
 if (xor_p)
 begin
	 assign fill={ width_p {1'b0} };
	 assign t[j+1]=t[j] ^ shifted;
 end
 else if (and_p)
 begin
	 assign fill={ width_p {1'b1} };
	 assign t[j+1]=t[j] & shifted;
 end
 else if (or_p)
 begin
	 assign fill={ width_p {1'b0} };
	 assign t[j+1]=t[j] | shifted;
 end
	 end
 end 
 if (lo_to_hi_p)
for (genvar j=0; j < width_p; j++) begin
 assign o[j]=t[$clog2(width_p)][width_p-1-j];
 end
 else
 assign o=t[$clog2(width_p)];
endmodule

module bsg_strobe #(width_p="inv"
 ,harden_p=0)
 (input clk_i
 ,input reset_r_i
 ,input [width_p-1:0] init_val_r_i
 ,output logic strobe_r_o
 );
 localparam debug_lp=0;
 logic strobe_n,strobe_n_buf;
 logic [width_p-1:0 ] S_r,S_n,S_n_n,C_n_prereset;
 logic [width_p-1-1:0] C_r,C_n;
 wire new_val=reset_r_i | strobe_n;
 bsg_dff #(.width_p(width_p-1)
 ,.harden_p(harden_p)
 ,.strength_p(2)
 ) C_reg
 (.clk_i (clk_i)
 ,.data_i (C_n )
 ,.data_o (C_r )
 );
 bsg_xnor #(.width_p(width_p),.harden_p(1)) xnor_S_n
 (.a_i(S_r),.b_i({C_r,1'b1}),.o(S_n));
 bsg_muxi2_gatestack #(.width_p(width_p),.harden_p(1)) muxi2_S_n
 (.i0(S_n) 
 ,.i1(init_val_r_i) 
 ,.i2( {width_p {new_val} })
 ,.o(S_n_n) 
 );
 bsg_dff #(.width_p(width_p)
 ,.harden_p(harden_p)
 ,.strength_p(4) 
 ) S_reg
 (.clk_i(clk_i)
 ,.data_i(S_n_n)
 ,.data_o(S_r)
 );
 bsg_nand #(.width_p(width_p),.harden_p(1)) nand_C_n
 (.a_i(S_r)
 ,.b_i({C_r,1'b1})
 ,.o(C_n_prereset) 
 );
 bsg_nor3 #(.width_p(width_p-1),.harden_p(1)) nor3_C_n
 (.a_i ({ (width_p-1) {strobe_n_buf} })
 ,.b_i(C_n_prereset[0+:width_p-1])
 ,.c_i({ (width_p-1) {reset_r_i}})
 ,.o (C_n)
 );
 bsg_reduce #(.and_p(1)
 ,.harden_p(1)
 ,.width_p(width_p)
 ) andr
 (.i(S_r)
 ,.o(strobe_n)
 );
 bsg_buf #(.width_p(1)) strobe_buf_gate
 (.i(strobe_n)
 ,.o(strobe_n_buf)
 );
 always_ff @(posedge clk_i)
 strobe_r_o <= strobe_n_buf;
 if (debug_lp)
 begin : debug
 always @(negedge clk_i)
 $display("%t (C=%b,S=%b) reset_r_i=%d new_val=%b init_val=%d val(C,S)=%b C^S=%b",$time
 ,C_r,S_r,reset_r_i,new_val,init_val_r_i,(C_r << 1)+S_r,strobe_n);
 end
 always @(negedge clk_i)
 assert((strobe_n === 'X) || strobe_n == & ((C_r << 1) ^ S_r))
 else $error("## faulty assumption about strobe signal in %m (C_r=%b,S_r=%b,strobe_n=%b)",C_r,S_r,strobe_n);
endmodule
/**
 * bsg_swap.v
 *
 * @author tommy
 */

module bsg_swap
 #(parameter width_p="inv")
 (
 input [1:0][width_p-1:0] data_i
 ,input swap_i
 ,output logic [1:0][width_p-1:0] data_o
 );
 assign data_o=swap_i
 ? {data_i[0],data_i[1]}
 : {data_i[1],data_i[0]};
endmodule

module bsg_thermometer_count #(parameter width_p=-1)
 (input [width_p-1:0] i
 ,output [$clog2(width_p+1)-1:0] o
 );
 if (width_p == 1)
 assign o=i;
 else
 if (width_p == 2)
 assign o={ i[1],i[0] & ~ i[1] };
 else
 if (width_p == 3)
 assign o={ i[1],i[2] | (i[0] & ~i[1]) };
 else
 if (width_p == 4)
 assign o={i[3],~i[3] & i[1],^i };
 else
 begin : big
 wire [width_p:0] one_hot=( ~{ 1'b0,i } )
 & ( { i ,1'b1 } );
 bsg_encode_one_hot #(.width_p(width_p+1)) encode_one_hot
 (.i(one_hot)
 ,.addr_o(o)
 ,.v_o()
 );
 end
endmodule

module bsg_tiehi #(parameter width_p="inv"
 ,parameter harden_p=1
 )
 (output [width_p-1:0] o
 );
 assign o={ width_p {1'b1} };
endmodule

module bsg_tielo #(parameter width_p="inv"
 ,parameter harden_p=1
 )
 (output [width_p-1:0] o
 );
 assign o={ width_p {1'b0} };
endmodule

module bsg_transpose #(width_p="inv"
	 ,els_p="inv"
	 ) (input [els_p-1:0 ][width_p-1:0] i
	 ,output [width_p-1:0][els_p-1:0] o
	 );
 genvar x,y;
 for (x=0; x < els_p; x++)
 begin: rof
	for (y=0; y < width_p; y++)
	 begin: rof2
	 assign o[y][x]=i[x][y];
	 end
 end
endmodule

module bsg_unconcentrate_static #(pattern_els_p="inv"
 ,width_lp=`BSG_COUNTONES_SYNTH(pattern_els_p)
 ,unconnected_val_p=`BSG_DISCONNECTED_IN_SIM(1'b0)
 )
(input [width_lp-1:0] i
 ,output [$bits(pattern_els_p)-1:0] o
 );
 genvar j;
 if (pattern_els_p[0])
 assign o[0]=i[0];
 else
 assign o[0]=unconnected_val_p;
 for (j=1; j < $bits(pattern_els_p); j=j+1)
 begin: rof
 if (pattern_els_p[j])
 assign o[j]=i[`BSG_COUNTONES_SYNTH(pattern_els_p[j-1:0])];
 else
 assign o[j]=unconnected_val_p;
 end
endmodule

module bsg_wait_after_reset #(parameter lg_wait_cycles_p="inv")
 (input reset_i
 ,input clk_i
 ,output reg ready_r_o);
 logic [lg_wait_cycles_p-1:0] counter_r;
 always @(posedge clk_i)
 begin
 if (reset_i)
 begin
 counter_r <= 1;
 ready_r_o <= 0;
 end
 else
 if (counter_r == 0)
 ready_r_o <= 1;
 else
 counter_r <= counter_r + 1;
 end
endmodule

module bsg_wait_cycles #(parameter cycles_p="inv")
 (
 input clk_i
 ,input reset_i
 ,input activate_i
 ,output reg ready_r_o
 );
 logic [$clog2(cycles_p+1)-1:0] ctr_r,ctr_n;
 always_ff @(posedge clk_i)
 begin
 ctr_r <= ctr_n;
 ready_r_o <= (ctr_n == cycles_p);
 end
 always_comb
 begin
 ctr_n=ctr_r;
 if (reset_i)
 ctr_n=cycles_p;
 else
 if (activate_i)
 ctr_n=0;
 else
 if (ctr_r != cycles_p)
 ctr_n=ctr_r + 1'b1;
 end
endmodule

module bsg_xnor #(parameter width_p="inv"
 ,harden_p=1)
 (input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output [width_p-1:0] o
 );
 assign o=~(a_i ^ b_i);
endmodule

module bsg_xor #(parameter width_p="inv"
 ,harden_p=1)
 (input [width_p-1:0] a_i
 ,input [width_p-1:0] b_i
 ,output [width_p-1:0] o
 );
 assign o=a_i ^ b_i;
endmodule
