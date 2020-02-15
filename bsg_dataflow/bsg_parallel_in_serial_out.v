//
// This data structure takes in a multi-word data and serializes
// it to a single word output.
//
// The input channel handshake is a ready-then-valid interface
// and the output channel handshake is a valid-then-yumi
// interface. This makes both channels "helpful" style
// handshakes.
//
// FIXME: this module purports to be doubly helpful
// but it waits for the output yumi signal to be asserted
// before asserting the input ready signal, creating a dependence
// from output to input. This avoids a bubble between successive parallel words. 
// but is a little distasteful. Logically, it is helpful on both ends,
// since for each interface, it does not require info ahead of time.
// But timing wise, its input helpfulness is a late helpfulness.
//
// There are three design choices for this module:
// 1) zero bubbles, dependence from output to input, 1 el buffering
// 2) one bubble, no dependence, 1 element buffer
// 3) zero bubbles, no dependence, 2 element buffer
//
// a potentially better design would be to eliminate the register
// and make that something the user can specify outside the module.
//
// that version would be helpful on output and demanding on input.

module bsg_parallel_in_serial_out #( parameter width_p    = -1
                                   , parameter els_p      = -1
                                   , parameter hi_to_lo_p = 0
                                   )
    ( input clk_i
    , input reset_i

    // Data Input Channel (Ready then Valid)
    , input                           valid_i
    , input  [els_p-1:0][width_p-1:0] data_i
    , output                          ready_o

    // Data Output Channel (Valid then Yumi)
    , output               valid_o
    , output [width_p-1:0] data_o
    , input                yumi_i
    );
  
  
  typedef enum logic [0:0] {eRX, eTX} state_e;
  
  // When els_p equals to 1, use fifo to minimize hardware.
  if (els_p == 1) 
  begin: fifo
    bsg_two_fifo
   #(.width_p(width_p)
    ) two_fifo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)
    ,.ready_o(ready_o)
    ,.data_i (data_i)
    ,.v_i    (valid_i)
    ,.v_o    (valid_o)
    ,.data_o (data_o)
    ,.yumi_i (yumi_i)
    );
  end 
  // When els_p is larger than 1, use the real PISO.
  else 
  begin: piso

    // A small statemachine is used to transition from the recieving
    // state to the transmission state.

   localparam clog2els_lp = $clog2(els_p);
   
    state_e                        state_r, state_n;
    logic [els_p-1:0][width_p-1:0] data_r;
    logic [clog2els_lp-1:0]      shift_ctr_r, shift_ctr_n;
    logic                          done_tx_n;
    

    /**
     * Done TX Signal
     *
     * The done_tx_n signals that we are done with our current transmission.
     * This occurs when we are in the eTX state, we are sending the last word
     * of data, and the outside world is accepting the data (yumi_i). This
     * signal indicates that we should return to the eRX state or we should
     * accept the next data and continue transmission.
     */
    assign done_tx_n = (state_r == eTX) && (shift_ctr_r == clog2els_lp ' (els_p-1)) && yumi_i;


    /**
     * Ready Out Signal
     *
     * The ready_o signal means that we are ready for new input data. If we
     * are in the eRX state then we are ready by definition. Otherwise, if
     * we are in the eTX state but we are sending the last word and it is
     * being accepted from the outside word, we can accept data on that cycle. 
     */
    assign ready_o = (state_r == eRX) || done_tx_n;


    /**
     * State Machine Logic
     *
     * There are two states to this state machine: eRX (or recieve) and
     * eTX (or transmission). We start in the eRX state and move to the
     * eTX state whenever we accept new data. From the eTX state, we move
     * back to the eRX state when we are done tranmitting (done_tx_n).
     */
    always_ff @(posedge clk_i)
      begin
        if (reset_i) begin
          state_r <= eRX;
        end else begin
          state_r <= state_n;
        end
      end

    always_comb
      begin
        if (ready_o & valid_i) begin
          state_n = eTX;
        end else if (done_tx_n) begin
          state_n = eRX;
        end else begin
          state_n = state_r;
        end
      end
      
    
    // If send hi_to_lo, reverse the input data array
    logic [els_p-1:0][width_p-1:0] data_li;
    
    if (hi_to_lo_p == 0)
      begin: lo2hi
        assign data_li = data_i;
      end
    else
      begin: hi2lo
        bsg_array_reverse 
       #(.width_p(width_p)
        ,.els_p(els_p)
        ) bar
        (.i(data_i)
        ,.o(data_li)
        );
      end

    /**
     * Input Data Logic
     *
     * Whenever we decide to accept new data we will take data_li and store
     * it in data_r.
     */
    always_ff @(posedge clk_i)
      begin
        if (reset_i) begin
          data_r <= '0;
        end else if (ready_o & valid_i) begin
          data_r <= data_li;
        end
      end


    /**
     * Shift Counter Logic
     *
     * The shift_ctr_r register stores the bit we are transmitting. Whenever
     * we reset or accept new data, we clear the shift_ctr_r register. While
     * in the eTX state, we will increment the register if the outside world
     * is going to accept our data (ie. yumi_i). If we are done transmitting
     * data, we should stall the counter on the last bit. 
     */

   // synopsys sync_set_reset "reset_i"
    always_ff @(posedge clk_i)
      begin
        if (reset_i)
          shift_ctr_r <= '0;
        else
          if (ready_o & valid_i)
            shift_ctr_r <= '0;
          else
            shift_ctr_r <= shift_ctr_n;
      end

    assign shift_ctr_n = ((state_r == eTX) && yumi_i && ~done_tx_n)
                           ? shift_ctr_r + 1'b1
                           : shift_ctr_r;

    /**
     * Valid Output Signal
     *
     * The valid_o signal means the output data is valid. For this
     * module, the output is valid iff we are in the eTX state.
     */
    assign valid_o = (state_r == eTX);


    /**
     * Data Output Signal
     *
     * Assign data_o to the word that we have shifted to.
     */
    assign data_o = data_r[shift_ctr_r];

  end

endmodule

