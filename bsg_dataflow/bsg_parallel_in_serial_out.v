//
// This data structure takes in a multi-word data and serializes
// it to a single word output.
//
// The input channel handshake is a ready-then-valid interface
// and the output channel handshake is a valid-then-yumi
// interface. This makes both channels "helpful" style
// handshakes.
//
//

module bsg_parallel_in_serial_out #( parameter width_p = -1
                                   , parameter els_p   = -1
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

    // A small statemachine is used to transition from the recieving
    // state to the transmission state.
    typedef enum logic [0:0] {eRX, eTX} state_e;


    state_e                        state_r, state_n;
    logic [els_p-1:0][width_p-1:0] data_r;
    logic [$clog2(els_p)-1:0]      shift_ctr_r, shift_ctr_n;
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
    assign done_tx_n = (state_r == eTX) && (shift_ctr_r == (els_p-1)) && yumi_i;


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

    /**
     * Input Data Logic
     *
     * Whenever we decide to accept new data we will take data_i and store
     * it in data_r.
     */
    always_ff @(posedge clk_i)
      begin
        if (reset_i) begin
          data_r <= '0;
        end else if (ready_o & valid_i) begin
          data_r <= data_i;
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
    always_ff @(posedge clk_i)
      begin
        if (reset_i || (ready_o & valid_i)) begin
          shift_ctr_r <= '0;
        end else begin
          shift_ctr_r <= shift_ctr_n;
        end
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


endmodule

