// mbt 11-10-14
//
// bsg_two_buncher
//
// see also serial_in_parallel_out
// 
// this module takes an incoming stream of words.
// if the output is read every cycle, the data passes
// straight through without latency. if the output
// is not read, then one element is buffered internally
// and either one or two elements may be pulled out
// on the next cycle. this is useful for when we want to
// process two words at a time.
//
// is this what they call a gearbox?
//
// note that the interface has double ready lines
// and it is an error to assert ready_i[1] without
// asserting ready_i[0]
//
//

`include "bsg_defines.v"

module bsg_two_buncher #(parameter width_p=-1)
   (input    clk_i
    , input  reset_i
    , input  [width_p-1:0]   data_i
    , input                  v_i
    , output                 ready_o

    , output [width_p*2-1:0] data_o
    , output [1:0]           v_o
    , input  [1:0]           ready_i
    );

   logic [width_p-1:0] data_r,   data_n;
   logic              data_v_r, data_v_n, data_en;

   // synopsys translate_off
   always @(posedge clk_i)
     assert (  (ready_i[1] !== 1'b1) | ready_i[0])
       else $error("potentially invalid ready pattern\n");

   always @(posedge clk_i)
     assert ( (v_o[1] !== 1'b1) | v_o[0])
       else $error("invalide valid output pattern\n");

   // synopsys translate_on

   always_ff @(posedge clk_i)
     if (reset_i)
       data_v_r <= 0;
     else
       data_v_r <= data_v_n;

   always_ff @(posedge clk_i)
     if (data_en)
       data_r <= data_i;

   assign v_o = { data_v_r & v_i, data_v_r | v_i };
   assign data_o  = { data_i,             data_v_r ? data_r : data_i };

   // we will absorb outside data if the downstream channel is ready
   // and we move forward on at least one elements
   // or, if we are empty

   assign ready_o = (ready_i[0] & v_i) | ~data_v_r;

   // determine if we will latch data next cycle
   always_comb
     begin
        data_v_n = data_v_r;
        data_en  = 1'b0;

        // if we are empty
        if (~data_v_r)
          begin
             // and there is new data that we don't forward
             // we grab it
             if (v_i)
               begin
                  data_v_n = ~ready_i[0];
                  data_en  = ~ready_i[0];
               end
          end
        // or if we are not empty
        else
          begin
             // if we are going to send data
             if (ready_i[0])
               begin
                  // but there is new data
                  // and we are not going to
                  // send it too
                  if (v_i)
                    begin
                       data_v_n = ~ready_i[1];
                       data_en  = ~ready_i[1];
                    end
                  else
                    // oops, we send the new data too
                    data_v_n = 1'b0;
               end
          end
     end

endmodule // bsg_two_buncher
