// MBT 11/26/2014
//
// bsg_fsb_node_trace_replay
//
// trace format
//
// 0: wait one cycle
// 1: send data
// 2: receive data
// 3: assert done_o; test complete.
// 4: end test; call $finish
// 5: decrement cycle counter; wait for cycle_counter == 0
// 6: initialized cycle counter with 16 bits
// in theory, we could add branching, etc.
// before we know it, we have a processor =)
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

   wire [3:0] op = rom_data_i[ring_width_p+:4];

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
               1: v_o     = 1'b1;
               2: ready_o = 1'b1;
               3: done_n  = 1'b1;
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
               0:  instr_completed = 1'b1;
               1:
                 begin
                    if (yumi_i)
                      instr_completed = 1'b1;
                 end
               2:
                 begin
                    if (v_i)
                      begin
                         instr_completed = 1'b1;  
                         if (error_r == 0)
                            error_n = data_i != data_o;
                      end
                 end
               3: instr_completed = 1'b1;
               4: instr_completed = 1'b1;
               5:
                 begin
                    cycle_ctr_n = cycle_ctr_r - 1'b1;
                    instr_completed = ~(|cycle_ctr_r);
                 end
               6:
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
               1: $display("### trace sent %h (%m)", data_o);
               2:
                 begin
                    if (data_i !== data_o)
                      begin
                         $display("############################################################################");
                         $display("### %m ");
                         $display("###    ");
                         $display("### FAIL (trace mismatch) = %h", data_i);
                         $display("###              expected = %h\n", data_o);
                         $display("############################################################################");
                         $finish();
                      end
                    else
                      begin
                         $display("### trace matched %h (%m)", data_o);
                      end // else: !if(data_i != data_o)
                 end
               3:
                 begin
                    $display("############################################################################");
                    $display("###### done_o=1 (trace finished addr=%x) (%m)",rom_addr_o);
                    $display("############################################################################");
                 end
               4:
                 begin
                    $display("############################################################################");
                    $display("###### DONE (trace finished; CALLING $finish) (%m)");
                    $display("############################################################################");
                    $finish;
                 end
               5:
                 begin
                    $display("### trace cycle_ctr_r = %x (%m)",cycle_ctr_r);
                 end
               6:
                 begin
                    $display("### trace cycle_ctr_r = %x (%m)",cycle_ctr_n);
                 end
               default:
                 begin

                 end
             endcase // case (op)
             case (op)
               0,1,2,3,4,5,6:
                 begin
                 end
               default: $display("### trace unknown op %x (%m)\n", op);
             endcase // case (op)
          end // if (instr_completed & ~reset_i & ~done_r)
     end // always @ (negedge clk_i)

endmodule
