`include "bsg_defines.v"

// MBT 11/26/2014
//
// bsg_fsb_node_trace_replay
//
// trace format (see enum below)
//
//
// note: this trace replay module essentially
// could be used to replay communication over
// any latency insensitive channel. later, it
// may make sense to rename it.
//

module bsg_fsb_node_trace_replay
  #(parameter   ring_width_p=80
    , parameter rom_addr_width_p=6
    , parameter counter_width_p=`BSG_MIN(ring_width_p,16)
    )
   (input clk_i
    , input reset_i
    , input en_i

    // input channel
    , input v_i
    , input [ring_width_p-1:0] data_i
    , output logic ready_o

    // output channel
    , output logic v_o
    , output logic [ring_width_p-1:0] data_o
    , input yumi_i

    // connection to rom
    // note: asynchronous reads

    , output [rom_addr_width_p-1:0] rom_addr_o
    , input  [ring_width_p+4-1:0]   rom_data_i

    // true outputs
    , output logic done_o
    , output logic error_o
    );

   // 0: wait one cycle
   // 1: send data
   // 2: receive data (and check its value)
   // 3: assert done_o; test complete.
   // 4: end test; call $finish
   // 5: decrement cycle counter; wait for cycle_counter == 0
   // 6: initialized cycle counter with 16 bits
   // in theory, we could add branching, etc.
   // before we know it, we have a processor =)
   
   typedef enum logic [3:0] {
      eNop=4'd0,
      eSend=4'd1,
      eReceive=4'd2,
      eDone=4'd3,
      eFinish=4'd4,
      eCycleDec=4'd5,
      eCycleInit=4'd6
   } eOp;
 
   
   logic [counter_width_p-1:0] cycle_ctr_r, cycle_ctr_n;

   logic [rom_addr_width_p-1:0] addr_r, addr_n;
   logic                        done_r, done_n;
   logic                        error_r, error_n;

   assign rom_addr_o = addr_r;
   assign data_o     = rom_data_i[0+:ring_width_p];
   assign done_o     = done_r;
   assign error_o    = error_r;

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          begin
             addr_r      <= 0;
             done_r      <= 0;
             error_r     <= 0;
             cycle_ctr_r <= 16'b1;
          end
        else
          begin
             addr_r      <= addr_n;
             done_r      <= done_n;
             error_r     <= error_n;
             cycle_ctr_r <= cycle_ctr_n;
          end
     end // always_ff @

   logic [3:0] op;
   assign op = rom_data_i[ring_width_p+:4];

   logic      instr_completed;

   assign addr_n =  instr_completed ? (addr_r+1'b1) : addr_r;

   // handle outputs
   always_comb
     begin
        // defaults; not sending and not receiving unless done
        v_o             = 1'b0;
        ready_o         = done_r;
        done_n          = done_r;

        if (!done_r & en_i & ~reset_i)
          begin
             case (op)
               eSend:    v_o     = 1'b1;
               eReceive: ready_o = 1'b1;
               eDone:    done_n  = 1'b1;
               default:
                 begin
                 end
             endcase
          end
     end // always_comb

   // next instruction logic
   always_comb
     begin
        instr_completed = 1'b0;
        error_n = error_r;
        cycle_ctr_n = cycle_ctr_r;

        if (!done_r & en_i & ~reset_i)
          begin
             case (op)
               eNop:  instr_completed = 1'b1;
               eSend:
                 begin
                    if (yumi_i)
                      instr_completed = 1'b1;
                 end
               eReceive:
                 begin
                    if (v_i)
                      begin
                         instr_completed = 1'b1;  
                         if (error_r == 0)
                            error_n = data_i != data_o;
                      end
                 end
               eDone: instr_completed = 1'b1;
               eFinish: instr_completed = 1'b1;
               eCycleDec:
                 begin
                    cycle_ctr_n = cycle_ctr_r - 1'b1;
                    instr_completed = ~(|cycle_ctr_r);
                 end
               eCycleInit:
                 begin
                    cycle_ctr_n = rom_data_i[counter_width_p-1:0];
                    instr_completed = 1;
                 end
               default:
                 begin
                 end
             endcase // case (op)
          end
     end

   // non-synthesizeable components
   always @(negedge clk_i)
     begin
        if (instr_completed & ~reset_i & ~done_r)
          begin
             case(op)
               eSend: $display("### bsg_fsb_node_trace_replay SEND %d'b%b (%m)", ring_width_p,data_o);
               eReceive:
                 begin
                    if (data_i !== data_o)
                      begin
                         $display("############################################################################");
                         $display("### bsg_fsb_node_trace_replay RECEIVE unmatched (%m) ");
                         $display("###    ");
                         $display("### FAIL (trace mismatch) = %h", data_i);
                         $display("###              expected = %h\n", data_o);
                         $display("###              diff     = %h\n", data_o ^ data_i);
                         $display("############################################################################");
                         $finish();
                      end
                    else
                      begin
                         $display("### bsg_fsb_node_trace_replay RECEIVE matched %h (%m)", data_o);
                      end // else: !if(data_i != data_o)
                 end
               eDone:
                 begin
                    $display("############################################################################");
                    $display("###### bsg_fsb_node_trace_replay DONE done_o=1 (trace finished addr=%x) (%m)",rom_addr_o);
                    $display("############################################################################");
                 end
               eFinish:
                 begin
                    $display("############################################################################");
                    $display("###### bsg_fsb_node_trace_replay FINISH (trace finished; CALLING $finish) (%m)");
                    $display("############################################################################");
                    $finish;
                 end
               eCycleDec:
                 begin
                    $display("### bsg_fsb_node_trace_replay CYCLE DEC cycle_ctr_r = %x (%m)",cycle_ctr_r);
                 end
               eCycleInit:
                 begin
                    $display("### bsg_fsb_node_trace_replay CYCLE INIT = %x (%m)",cycle_ctr_n);
                 end
               default:
                 begin

                 end
             endcase // case (op)
             case (op)
               eNop, eSend, eReceive, eDone, eFinish, eCycleDec, eCycleInit:
                 begin
                 end
               default: $display("### bsg_fsb_node_trace_replay UNKNOWN op %x (%m)\n", op);
             endcase // case (op)
          end // if (instr_completed & ~reset_i & ~done_r)
     end // always @ (negedge clk_i)

endmodule
