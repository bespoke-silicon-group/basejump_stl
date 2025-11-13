// bsg_tag_master
//
// 8/30/2016
//
// Usage: send a stream of 0's to reset master node and/or noop.
// Then, send a single <1> followed by a packet:
//        < id >       < data_not_reset > < payload length >             < payload >
// ****************************************************************************
// $clog2(els_p+1)      1        $clog2(max_payload_length+1)  (variable size)
//
// To reset client nodes, set data_not_reset to 0, and payload to 1's.
//
//

`include "bsg_defines.sv"

`include "bsg_tag.svh"

// will not build in verilator without this
// possibly resulting incorrect behavior :(

// verilator lint_off BLKANDNBLK

module bsg_tag_master_decentralized
  import bsg_tag_pkg::bsg_tag_s;

   // els_p is the maximum number of clients supported in system
   // local_els_p is the number of clients to attach
   // lg_width_p is the number of bits used to describe the payload size

   #(`BSG_INV_PARAM(els_p)
    ,`BSG_INV_PARAM(local_els_p)
    ,`BSG_INV_PARAM(lg_width_p)
    ,debug_level_lp=1
    ,lg_els_lp=`BSG_SAFE_CLOG2(els_p)
    ,lg_local_els_lp=`BSG_SAFE_CLOG2(local_els_p)
    )

   (
    // from pins
    input clk_i
    ,input data_i
    // node_id_offset_i is used to filter incoming packets.
    // packets with nodeID < node_id_offset_i or nodeID >= node_id_offset_i+local_els_p
    // will be ignored.
    ,input [lg_els_lp-1:0] node_id_offset_i
    ,output bsg_tag_s [local_els_p-1:0] clients_o
    );

   `declare_bsg_tag_header_s(els_p,lg_width_p)

   localparam max_packet_len_lp    = `bsg_tag_max_packet_len(els_p,lg_width_p);

   localparam reset_len_lp = `bsg_tag_reset_len(els_p,lg_width_p);
   
   // counts 0..max_packet_len_lp
   localparam lg_max_packet_len_lp = `BSG_SAFE_CLOG2(max_packet_len_lp+1);

`ifndef BSG_HIDE_FROM_SYNTHESIS
   if (debug_level_lp > 2)
     always @(negedge clk_i)
       $display("## bsg_tag_master clients=%b (%m)",clients_o);
`endif

   logic  data_i_r;

   always @(posedge clk_i)
     data_i_r <= data_i;

   // ***************************
   // RESET LOGIC
   // extra bit to detect carry out in counter

   localparam ctr_width_lp = lg_max_packet_len_lp+1;
   logic [ctr_width_lp-1:0] zeros_ctr_r;


   wire tag_reset_req = zeros_ctr_r[ctr_width_lp-1];

   // this self-clearing counter detects a certain number
   // of consecutive 0's
   // indicating a tag_master reset condition
   //

   bsg_counter_clear_up #(.max_val_p((1 << ctr_width_lp)-1)
                          ,.init_val_p(0)
                          ) bccu
   (.clk_i   (clk_i)
    ,.reset_i(1'b0)
    // we clear the counter if we hit the limit
    ,.clear_i(data_i_r | tag_reset_req)
    ,.up_i   (~data_i_r)
    ,.count_o(zeros_ctr_r)
    );

   // veri lator doesn't support -d
`ifndef BSG_HIDE_FROM_SYNTHESIS
   initial
        $display("## %m instantiating bsg_tag_master_decentralized with els_p=%d, local_els_p=%d, lg_width_p=%d, max_packet_len_lp=%d, reset_zero_len=%d"
                 ,els_p,local_els_p,lg_width_p,max_packet_len_lp,reset_len_lp);
`endif

   //
   // END RESET LOGIC
   // ***************************

   logic [lg_max_packet_len_lp-1:0] hdr_ptr_r, hdr_ptr_n;
   bsg_tag_header_s hdr_r, hdr_n;

   // sending
   logic  v_n;
   // value to send
   bsg_tag_s bsg_tag_n;

   typedef enum logic [1:0] {eStart, eHeader, eTransfer, eStuck} state_e;

   state_e state_r, state_n;

   // synopsys sync_set_reset "tag_reset_req, data_i_r"

   always_ff @(posedge clk_i)
     // if we hit the counter AND (subtle bug) there is no valid incoming data that would get lost
     if (tag_reset_req & ~data_i_r)
       begin
`ifndef BSG_HIDE_FROM_SYNTHESIS
          if (debug_level_lp > 2) $display("## bsg_tag_master RESET time %t (%m)",$time);
`endif
          state_r   <= eStart;

          // we put this here because DC did not currently infer "reset" logic
          hdr_ptr_r <= 0;
       end
     else
       begin
          state_r   <= state_n;
          hdr_ptr_r <= hdr_ptr_n;
       end

   always_ff @(posedge clk_i)
        hdr_r <= hdr_n;

`ifndef BSG_HIDE_FROM_SYNTHESIS
   always_ff @(negedge clk_i)
     if (state_n != state_r)
       if (debug_level_lp > 1) $display("## bsg_tag_master STATE CHANGE  # %s --> %s #",state_r.name(),state_n.name());
`endif

   always_comb
     begin
        state_n   = state_r;
        hdr_ptr_n = hdr_ptr_r;
        hdr_n     = hdr_r;

        // outgoing
        v_n             = 1'b0;
        bsg_tag_n.op    = 1'b0;
        bsg_tag_n.param = 1'b0;

        case (state_r)
          // first 1 after zero indicates beginning of packet
          eStart:
               begin
                  if (data_i_r)
                    state_n = eHeader;

                  hdr_ptr_n = 0;
                  hdr_n     = 0;
               end
          eHeader:
               begin
`ifndef BSG_HIDE_FROM_SYNTHESIS
                  if (debug_level_lp > 1)
                    $display("## bsg_tag_master RECEIVING HEADER (%m) (%d) = %b",hdr_ptr_r,data_i_r);
`endif

                  hdr_n     = { data_i_r, hdr_r[1+:($bits(bsg_tag_header_s)-1)] };
                  hdr_ptr_n = hdr_ptr_r + 1'b1;
                  // if we are at the next to last value
                  if (hdr_ptr_r == lg_max_packet_len_lp'($bits(bsg_tag_header_s)-1))
                    begin
                       if (hdr_n.len == 0)
                         begin
                            state_n = eStart;
`ifndef BSG_HIDE_FROM_SYNTHESIS
                            $display("## bsg_tag_master NULL PACKET, len=0 (%m)");
`endif
                         end
                       else
                         begin

`ifndef BSG_HIDE_FROM_SYNTHESIS
                            if (debug_level_lp > 1)
                              $display("## bsg_tag_master PACKET HEADER RECEIVED (length=%b,data_not_reset=%b,nodeID=%b) (%m) "
                                       ,hdr_n.len,hdr_n.data_not_reset,hdr_n.nodeID);
`endif

                            // if we have data to transfer go to transfer state
                            state_n = eTransfer;
                         end
                    end
               end // case: eHeader
          eTransfer:
               begin
                  // transmit data
                  // if hdr_r.reset = 1, then we send <0,data> for hdr_r.len cycles
                  // otherwise we send <1,data> for hdr_r.len cycles
                  // typically for reset, we will send 1's.

                  v_n             = 1'b1;
                  bsg_tag_n.op    = hdr_r.data_not_reset;
                  bsg_tag_n.param = data_i_r;

`ifndef BSG_HIDE_FROM_SYNTHESIS
                  if (debug_level_lp > 2)
                    $display("## bsg_tag_master PACKET TRANSFER op,param=<%b,%b> (%m)", bsg_tag_n.op, bsg_tag_n.param);
`endif

                  // finishing words
                  if (hdr_r.len== lg_width_p ' (1))
                    begin
                       state_n = eStart;

`ifndef BSG_HIDE_FROM_SYNTHESIS
                       if (debug_level_lp > 1) $display("## bsg_tag_master PACKET END (%m)");
`endif

                    end
                  hdr_n.len = hdr_r.len - 1;
               end
          eStuck:
            state_n = eStuck;

            default:
              begin
                 state_n = eStuck;

`ifndef BSG_HIDE_FROM_SYNTHESIS
                 $display("## bsg_tag_master transitioning to error state; be sure to run gate-level netlist to avoid sim/synth mismatch (%m)");
`endif

              end
        endcase // case (state_r)

     end // always_comb

   genvar i;

   // calculate local nodeID
   // must have lg_els_lp bits to prevent overflow
   // (underflow is okay in this case)
   wire [lg_els_lp-1:0] local_node_id = hdr_r.nodeID - node_id_offset_i;

   // demultiplex the stream to the target node
   // use only lg_local_els_lp bits to simplify decoder logic
   wire [local_els_p-1:0] clients_decode = (v_n << local_node_id[lg_local_els_lp-1:0]);

   // determine if incoming packet is within the nodeID range
   wire node_id_above_offset = (hdr_r.nodeID >= node_id_offset_i);
   wire local_node_id_below_limit = (local_node_id < local_els_p);
   wire node_id_match = (node_id_above_offset && local_node_id_below_limit);

   // output to bsg_tag_clients directly without flops
   for (i = 0; i < local_els_p; i=i+1)
     begin: rof
        assign clients_o[i].clk   = clk_i;
        assign clients_o[i].op    = node_id_match & clients_decode[i] & bsg_tag_n.op;
        assign clients_o[i].param = node_id_match & clients_decode[i] & bsg_tag_n.param;
     end

   
endmodule // bsg_tag_master

`BSG_ABSTRACT_MODULE(bsg_tag_master_decentralized)

// verilator lint_on BLKANDNBLK
