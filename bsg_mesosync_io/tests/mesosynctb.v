// This testbench goes through different steps of initializing 
// mesosynchronous I/O. The patterns are generated based on a 
// clock and both modules works according to their clock. 

// For simulation purposes, and having non-deterministic delays
// on config tag, delays of values not multiple of clock cycles
// are selected.

//`include "definitions.v"
`define half_period 16
parameter bit_num_p = 3;

// -------------------------------------------------------------//
// ------------------------ Config tag messages ----------------//
// -------------------------------------------------------------//

// 6 type of messages that would be send to config_tag for configuration
`define reset_config_tag  send_config_tag(cfg_clk,1'b1,config_data);
`define send_input(R) send_config_tag(cfg_clk,1'b0,config_data, \
                {R,input_clk_divider,la_input_bit_selector}, \
                8'd11,2+maxDivisionWidth_p+`BSG_SAFE_CLOG2(2*bit_num_p));

`define send_output(R) send_config_tag(cfg_clk,1'b0,config_data, \
                {R,output_clk_divider,la_output_bit_selector,v_output_bit_selector}, \
                8'd12,2+maxDivisionWidth_p+2*`BSG_SAFE_CLOG2(2*bit_num_p));

`define send_link_config  send_config_tag(cfg_clk,1'b0,config_data, \
                {mode_cfg,fifo_en,loopback_en}, 8'd10,$bits(mode_cfg)+2);
  
`define send_ch1_bit_cnfg send_config_tag(cfg_clk,1'b0,config_data, \
                bit_cfg_ch1,8'd13,$bits(bit_cfg_ch1));

`define send_ch2_bit_cnfg send_config_tag(cfg_clk,1'b0,config_data, \
                bit_cfg_ch2,8'd14,$bits(bit_cfg_ch2));

module mesosynctb();

// internal signals
logic clk, cfg_clk, io_clk, reset, reset_r, config_data;
logic [bit_num_p*2-1:0] from_meso, to_meso, 
                        to_meso_delayed, from_meso_delayed,
                        from_meso_fixed;
config_s conf;
int i;
logic [6:0] LA_count;

// shift register for received data
logic [255:0] in_reg_1, in_reg_2;

// signals for generating sending data
logic [1:0] out_selector;
logic valid_to_meso,credit_to_meso;
logic [3:0] count;
logic [bit_num_p*2-1:0] pat_out, loopback_data;
logic [7:0] pattern;

// configuration signals
logic [maxDivisionWidth_p-1:0] input_clk_divider;
logic [maxDivisionWidth_p-1:0] output_clk_divider;
mode_cfg_s mode_cfg;
logic [$clog2(2*bit_num_p)-1:0] la_input_bit_selector;
logic [$clog2(2*bit_num_p)-1:0] la_output_bit_selector;
logic [$clog2(2*bit_num_p)-1:0] v_output_bit_selector;
bit_cfg_s [2*bit_num_p-1:0] bit_cfg;
bit_cfg_s [bit_num_p-1:0] bit_cfg_ch1;
bit_cfg_s [bit_num_p-1:0] bit_cfg_ch2;
logic loopback_en, fifo_en;

// bundling
assign conf = '{cfg_clk: cfg_clk, cfg_bit: config_data};
assign bit_cfg_ch1 = bit_cfg [bit_num_p-1:0];
assign bit_cfg_ch2 = bit_cfg [bit_num_p*2-1:bit_num_p];

// external loopback
logic valid, ready;
logic [(2*bit_num_p)-3:0] data;

// -------------------------------------------------------------//
// ------------------- Module instantiation --------------------//
// -------------------------------------------------------------//

bsg_mesosync_link
           #(  .ch1_width_p(bit_num_p)    
             , .ch2_width_p(bit_num_p)     
             , .LA_els_p(72)         
             , .cfg_tag_base_id_p(10) 
             , .loopback_els_p(16)  
             , .credit_initial_p(8)
             , .credit_max_val_p(10)
             , .decimation_p(4)
            ) DUT
            (  .clk(clk)
             , .reset(reset_r)
             
             , .config_i(conf)

             // Sinals with their acknowledge
             , .pins_i(to_meso_delayed)
             , .pins_o(from_meso)
             
             // connection to core, 2 bits are used for handshake
             , .data_i(data)
             , .v_i(valid)
             , .ready_o(ready)

             , .v_o(valid)
             , .data_o(data)
             , .ready_i(ready)
     
            );

// flow counter to count elements in Logic Analyzer FIFO
bsg_flow_counter #(.els_p(72)           
                 , .count_free_p(0)     
                 , .ready_THEN_valid_p(0)
                 
                  ) cnt      
    
    ( .clk_i(clk)
    , .reset_i(reset_r)

    , .v_i(DUT.mesosync_input.logic_analyzer.narrowed_fifo.v_i)
    , .ready_i(DUT.mesosync_input.logic_analyzer.narrowed_fifo.ready_o)
    , .yumi_i(DUT.mesosync_input.logic_analyzer.narrowed_fifo.yumi)

    , .count_o(LA_count)
    );

// -------------------------------------------------------------//
// ---------------------------- MAIN TEST ----------------------//
// -------------------------------------------------------------//

initial begin
  $timeformat(0, 0, " ns,", 10);
  $display("cycle\t   to_meso  from_meso mode  clk_div");
  $monitor("@%t %b\t %b\t %b\t %h",
            $time,to_meso,from_meso_delayed,
            DUT.mesosync_input.mode_cfg,DUT.mesosync_input.input_clk_divider,
            DUT.mesosync_output.output_clk_divider);
  
  // initial values
  loopback_en                  = 0;
  fifo_en                = 0;
  out_selector           = 0;
  credit_to_meso         = 0;
  valid_to_meso          = 0;
  output_clk_divider     = 4'b0111;
  input_clk_divider      = 4'b0111;
  la_input_bit_selector  = 3'b000;
  la_output_bit_selector = 3'b000;
  v_output_bit_selector  = 3'b001;
  

  mode_cfg = create_cfg (LA_STOP,1'b0,PAT);
  for (i=0 ; i<2*bit_num_p; i= i+1)
    bit_cfg[i]='{clk_edge_selector:1'b0, phase: 4'b0000};

  // reseting the modules and config tag and channel
  reset = 1'b1;
  @ (negedge clk)
  @ (negedge clk)
  reset = 1'b0;
  @ (posedge clk)
  $display("module has been reset");
  `reset_config_tag
  $display("config tag has been reset");
  $display("\n*****************************");
  $display("sending initial configuration");
  $display("*****************************\n");

  // initialize clk divider, disable loop back, ready to be reset
  `send_input(2'b01)
  `send_output(2'b01)
  
  // set mode configuration and select input and output bits 
  // for each channel logic analyzer
  `send_link_config
  
  // set bit configuration for channel 1 
  `send_ch1_bit_cnfg
  
  // set bit configuration for channel 2
  `send_ch2_bit_cnfg
  
  $display("\n*****************************");
  $display("     reseting the channel");
  $display("*****************************\n");

  // reset the mesosync 
  `send_input(2'b10)
  `send_output(2'b10)
  $display("mesosync IO has been reset");
  
  #500
  
  $display("\n*****************************");
  $display("    Going to SYNC1 mode");
  $display("*****************************\n");
  
  // change mode to Sync1
  mode_cfg = create_cfg (LA_STOP,1'b0,SYNC1);
  `send_link_config
  #1500
  $display("\n*****************************");
  $display("bit line allignment performed");
  $display("*****************************\n");
  $display("\n\ncycle\t   to_meso  from_meso");
  $monitor("@%t\t %b\t %b",$time,to_meso,from_meso_fixed);

  #500
  
  $display("\n*****************************");
  $display("    Going to SYNC2 mode");
  $display("*****************************\n");
  
  // change mode to Sync2
  mode_cfg = create_cfg (LA_STOP,1'b0,SYNC2);
  `send_link_config
  #1500
  #1000
  $display("monitor is off");
  $monitoroff;
  #2100000
  
  // (if output sync fails we must lower the io frequency)
  $display("\n*****************************");
  $display("    output sync finished      ");
  $display("*****************************\n");
  $display("\n");

  $display("\n*****************************");
  $display("sending patterns to Logic analyzers");
  $display("  line zero is the valid line  ");
  $display("*****************************\n");
  $monitor("@%t %b\t %b",$time,to_meso,from_meso_fixed);
  
  // For checking LA saving all the data
  // 72 values are saved in the LA fifo using fifo with free counter, during
  // sending data out each 2 cycles one data is removed, so 142 cycles are 
  // between free and full
  
  // sending patterns out
  out_selector = 1;
  v_output_bit_selector = 0;
  
  // reading Logic analyzer data from each line
  for (i=1 ; i<2*bit_num_p; i= i+1) begin

    $display("\n*****************************");
    $display("        testing line %d        ",i);
    $display("*****************************\n");
    
    // stoping the channel and selecting line to be tested
    la_input_bit_selector = i;
    la_output_bit_selector = i;
    mode_cfg = create_cfg (LA_STOP,1'b0,STOP);
    `send_input(2'b10)
    `send_output(2'b10)
    `send_link_config
    
    // starting logic analyzer without any output
    mode_cfg = create_cfg (LA_STOP,1'b1,STOP);
    `send_link_config
    #1000
    // stopping logic anlyzer (which has stopped by itself, just not to gather 
    // data after data is sent out) and starting sending its data out
    mode_cfg = create_cfg (LA_STOP,1'b0,LA);
    `send_link_config
    
    #45000
    $display("\nvalues: %h",in_reg_1);
    $display("valid : %h\n",in_reg_2);
  end
 
    // we have to change the valid line from 0 for testing line 0 itself
    $display("\n*****************************");
    $display("        testing line  0        ");
    $display("*****************************\n");
  
    // stoping the channel and selecting line to be tested
    v_output_bit_selector = 1;
    la_input_bit_selector = 0;
    la_output_bit_selector = 0;
    mode_cfg = create_cfg (LA_STOP,1'b0,STOP);
    `send_input(2'b10)
    `send_output(2'b10)
    `send_link_config
    
    // starting logic analyzer without any output
    mode_cfg = create_cfg (LA_STOP,1'b1,STOP);
    `send_link_config
    #1000
    // stopping logic anlyzer (which has stopped by itself, just not to gather 
    // data after data is sent out) and starting sending its data out
    mode_cfg = create_cfg (LA_STOP,1'b0,LA);
    `send_link_config
    
    #45000
    $display("\nvalues: %h",in_reg_1);
    $display("valid : %h\n",in_reg_2);
 
  $monitoron;
 
  $display("\n*****************************");
  $display("update phases based on the logic analyzer data");
  $display("*****************************\n");
 
  // select cycle and edge to read the data based on the logic analyzers' data
  for (i=0 ; i<2*bit_num_p; i= i+1)
    bit_cfg[i]='{clk_edge_selector:1'b0, phase: 4'b0100};
  
  
  @ (negedge clk)
  // set bit configuration for channel 1 
  `send_ch1_bit_cnfg
  
  // set bit configuration for channel 2
  `send_ch2_bit_cnfg
  
  $display("\n*****************************");
  $display("active loopback_mode");
  $display("*****************************\n\n");
  $display("cycle\t to_chip\t  from_chip from_meso,v   to_meso,rdy crdt_counter");
  $monitor("@%t %b\t  %b    %b, %b\t %b, %b\t %d",$time,to_meso
        ,from_meso_fixed,DUT.from_meso_input,DUT.valid,DUT.to_meso_output,DUT.ready,
        DUT.mesosync_core.output_credit_counter.credit_cnt);
  
  // sending loop back data 
  out_selector = 2;
  
  // making input channel active to send data to loopback module
  mode_cfg = create_cfg (NORMAL,1'b0,STOP);
  `send_link_config
  
  // enabling loopback module 
  loopback_en = 1;
  fifo_en = 1;
  `send_link_config
  
  // based on valid-credit protocol, sending some data which are valid
  valid_to_meso = 1'b1;
  #500 

  // activing the output, after some time to make sure some valid data is 
  // stored in the loop back module
  mode_cfg = create_cfg (NORMAL,1'b0,NORM);
  `send_link_config
  #300
  // no more data to be sent, not exceeding size of FIFO (credit protocol
  // would take care of this)
  valid_to_meso  = 1'b0;
  #200

  credit_to_meso = 1'b1;
  // sending some credits so it would send more data
  #500
  credit_to_meso = 1'b0;

  // some time for the internal loopback simulation to finish
  #5000
  
  $display("\n*****************************");
  $display("Normal I/O mode");
  $display("*****************************\n\n");
  // Outer loop simulation same as internal one, with loopback disabled
  mode_cfg = create_cfg (NORMAL,1'b0,STOP);
  `send_link_config
  
  loopback_en = 0;
  `send_link_config
  
  valid_to_meso = 1'b1;
  #500 
  
  mode_cfg = create_cfg (NORMAL,1'b0,NORM);
  `send_link_config
  #300

  valid_to_meso  = 1'b0;
  #200

  credit_to_meso = 1'b1;
  // sending some credits so it would send more data
  #500
  credit_to_meso = 1'b0;

  // some time for the internal loopback simulation to finish
  #5000
  
  $finish;
end


//-----------------------------------------//
//----- Generating different clocks--------//
//-----------------------------------------//

always begin
  #`half_period clk = 1'b0;
  #`half_period clk = 1'b1;
end

always begin
  #(3*`half_period) cfg_clk = 1'b0;
  #(3*`half_period) cfg_clk = 1'b1;
end

always begin
  #(8*`half_period) io_clk = 1'b0;
  #(8*`half_period) io_clk = 1'b1;
end

// -------------------------------------------------------------//
// ------------------------ Generating delays ------------------//
// -------------------------------------------------------------//

// Generating delays on input and output lines and the fixed delay
// line from the channel
genvar ii;
generate
  for (ii=0; ii< 2*bit_num_p; ii = ii + 1) begin: delay_block
    assign #(ii*18+20) to_meso_delayed[ii]   = to_meso[ii];
    assign #(8-ii)     from_meso_delayed[ii] = from_meso[ii];
    assign #(24+ii)    from_meso_fixed[ii]   = from_meso_delayed[ii];
  end
endgenerate


// -------------------------------------------------------------//
// ------------------- Generating output pattern ---------------//
// -------------------------------------------------------------//
assign pat_out       = (pattern[0] << la_output_bit_selector);
assign loopback_data = {count, credit_to_meso, valid_to_meso};

assign to_meso = (out_selector == 2) ? loopback_data : 
                ((out_selector == 1) ? pat_out : 0);

 
//------------------------------------------------------------------------//
//-- generating output pattern and collecting input data using io clock --//
//------------------------------------------------------------------------//

always_ff @ (posedge io_clk or posedge reset) begin
  if (reset) begin
    pattern  <= 8'b10100101;
    in_reg_1 <= 0;
    in_reg_2 <= 0;
    count    <= 0;
  end else begin
    pattern  <= {pattern[6:0],pattern[7]};
    in_reg_1 <= {in_reg_1[254:0],from_meso_fixed[la_output_bit_selector]};
    in_reg_2 <= {in_reg_2[254:0],from_meso_fixed[v_output_bit_selector]};
    count    <= count + 4'd1;
  end
end

//-----------------------------------------//
//-- function for generating config data --//
//-----------------------------------------//
function mode_cfg_s create_cfg(input input_mode_e in_mode,
                               input LA_enque, output_mode_e out_mode);
    create_cfg = 
           '{input_mode:  in_mode
            ,LA_enque:    LA_enque
            ,output_mode: out_mode
            };
endfunction

endmodule
