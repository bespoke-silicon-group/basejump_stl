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
// To reset slave nodes, set data_not_reset to 0, and payload to 1's.
//
//

`include "bsg_tag.vh"

module bsg_tag_master
  import bsg_tag_pkg::bsg_tag_s;

   #(els_p="inv", lg_width_p="inv")
   (
    // from pins
    input clk_i
    ,input en_i
    ,input data_i
    , output bsg_tag_s [els_p-1:0] clients_r_o
    );

   `declare_bsg_tag_header_s(els_p,lg_width_p)

   localparam debug_level_lp = 0;

   localparam max_packet_len_lp    = `bsg_tag_max_packet_len(els_p,lg_width_p);

   // counts 0..max_packet_len_lp
   localparam lg_max_packet_len_lp = `BSG_SAFE_CLOG2(max_packet_len_lp+1);

   // synopsys translate_off
   if (debug_level_lp > 2)
     always @(negedge clk_i)
       $display("## bsg_tag_master %m %b",clients_r_o);
   // synopsys translate_on

   logic  data_i_r;

   always @(posedge clk_i)
     data_i_r <= data_i;

   // ***************************
   // RESET LOGIC
   // extra bit to detect carry out in counter

   localparam ctr_width_lp = lg_max_packet_len_lp+1;
   logic [ctr_width_lp-1:0] zeros_ctr_r;


   wire tag_reset_req = zeros_ctr_r[ctr_width_lp-1];

   // this saturating counter detects a certain number
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

   // synopsys translate_off
   initial
        $display("## %m instantiating bsg_tag_master with els_p=%-d and lg_width_p=%-d, max_packet_len_lp=%-d, reset_zero_len=%-d"
                 ,els_p,lg_width_p,max_packet_len_lp,(1<<(ctr_width_lp)));
   // synopsys translate_on

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
          // synopsys translate_off
          if (debug_level_lp > 1) $display("## bsg_tag_master RESET (%m)");
          // synopsys translate_on
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

   // synopsys translate_off
   always_ff @(negedge clk_i)
     if (state_n != state_r)
       if (debug_level_lp > 1) $display("## bsg_tag_master STATE CHANGE  # %s --> %s #",state_r,state_n);
   // synopsys translate_on

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
                  // synopsys translate_off
                  if (debug_level_lp > 1)
                    $display("## bsg_tag_master RECEIVING HEADER (%m) (%d)",hdr_ptr_r);
                  // synopsys translate_on

                  hdr_n     = { data_i_r, hdr_r[1+:($bits(bsg_tag_header_s)-1)] };
                  hdr_ptr_n = hdr_ptr_r + 1'b1;
                  // if we are at the next to last value
                  if (hdr_ptr_r == ($bits(bsg_tag_header_s)-1))
                    begin
                       if (hdr_n.len == 0)
                         begin
                            state_n = eStart;
                            // synopsys translate_off
                            $display("## %m (NULL PACKET)");
                            // synopsys translate_on
                         end
                       else
                         begin

                            // synopsys translate_off
                            if (debug_level_lp > 1)
                              $display("## bsg_tag_master PACKET HEADER RECEIVED (length=%b,data_not_reset=%b,nodeID=%b) (%m) "
                                       ,hdr_n.len,hdr_n.data_not_reset,hdr_n.nodeID);
                            // synopsys translate_on

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

                  // synopsys translate_off
                  if (debug_level_lp > 2)
                    $display("## %m PACKET TRANSFER op,param=<%b,%b>", bsg_tag_n.op, bsg_tag_n.param);
                  // synopsys translate_on

                  // finishing words
                  if (hdr_r.len== lg_width_p ' (1))
                    begin
                       state_n = eStart;

                       // synopsys translate_off
                       if (debug_level_lp > 1) $display("## %m PACKET END");
                       // synopsys translate_on

                    end
                  hdr_n.len = hdr_r.len - 1;
               end
          eStuck:
            state_n = eStuck;

            default:
              begin
                 state_n = eStuck;

                 // synopsys translate_off
                 $display("## bsg_tag_master transitioning to error state; be sure to run gate-level netlist to avoid sim/synth mismatch (%m)");
                 // synopsys translate_on

              end
        endcase // case (state_r)

     end // always_comb

   genvar i;

   // demultiplex the stream to the target node

   wire [els_p-1:0] clients_decode = (v_n << hdr_r.nodeID);

   for (i = 0; i < els_p; i=i+1)
     begin: rof
        always_ff @(posedge clk_i)
          begin
             clients_r_o[i].op    <= clients_decode[i] & bsg_tag_n.op;
             clients_r_o[i].param <= clients_decode[i] & bsg_tag_n.param;
          end

        assign clients_r_o[i].clk = clk_i;
        assign clients_r_o[i].en  = en_i;
     end

endmodule
