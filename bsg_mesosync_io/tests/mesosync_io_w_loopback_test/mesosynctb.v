//`include "definitions.v"
`define half_period 16
parameter bit_num_p = 3;

module mesosynctb();

// internal signals
logic clk, cfg_clk, io_clk, reset, reset_r, config_data;
logic [bit_num_p*2-1:0] from_meso, to_meso, 
                        to_meso_delayed, from_meso_delayed,
                        from_meso_fixed;
config_s conf;
integer cycle_counter,cycle_counter_slow;
int i;

// shift register for received data
logic [255:0] in_reg_1, in_reg_2;

// signals for generating sending data
logic [1:0] out_selector;
logic valid_to_meso,credit_to_meso;
logic [3:0] count;
logic [bit_num_p*2-1:0] pat_out, lp_data;
logic [7:0] pattern_1, pattern_2;

assign conf = '{cfg_clk: cfg_clk, cfg_bit: config_data};

bsg_mesosync_link
           #(  .ch1_width_p(bit_num_p)    
             , .ch2_width_p(bit_num_p)     
             , .LA_els_p(72)         
             , .cfg_tag_base_id_p(10) 
             , .loopback_els_p(16)  
             , .credit_initial_p(8)
             , .credit_max_val_p(10)
            ) DUT
            (  .clk(clk)
             , .reset(reset_r)
             
             , .config_i(conf)

             // Sinals with their acknowledge
             , .pins_i(to_meso_delayed)
             , .pins_o(from_meso)
             
             // connection to chip, 2 bits are used for handshake
             , .chip_data_i()
             , .chip_v_i(1'b0)
             , .chip_ready_o()

             , .chip_v_o()
             , .chip_data_o()
             , .chip_yumi_i(1'b0)
     
            );

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

// configuration signals
clk_divider_s clk_divider;
mode_cfg_s mode_cfg;
logic [$clog2(2*bit_num_p)-1:0] input_bit_selector_ch1;
logic [$clog2(2*bit_num_p)-1:0] output_bit_selector_ch1;
logic [$clog2(2*bit_num_p)-1:0] input_bit_selector_ch2;
logic [$clog2(2*bit_num_p)-1:0] output_bit_selector_ch2;
logic [$clog2(2*bit_num_p)*4-1:0] ch_bit_selector;
bit_cfg_s [2*bit_num_p-1:0] bit_cfg;
bit_cfg_s [bit_num_p-1:0] bit_cfg_ch1;
bit_cfg_s [bit_num_p-1:0] bit_cfg_ch2;
logic en_lb, fifo_en;

assign ch_bit_selector =  {input_bit_selector_ch1,output_bit_selector_ch1,
                           input_bit_selector_ch2,output_bit_selector_ch2};
assign bit_cfg_ch1 = bit_cfg [bit_num_p-1:0];
assign bit_cfg_ch2 = bit_cfg [bit_num_p*2-1:bit_num_p];

// pattern for sending to channel
assign pat_out = (pattern_1[0] << output_bit_selector_ch1)| 
                 (pattern_2[0] << output_bit_selector_ch2);

assign to_meso = (out_selector == 2) ? lp_data : 
                ((out_selector == 1) ? pat_out : 0);
assign lp_data = {count, credit_to_meso, valid_to_meso};

initial begin

  $display("cycle\t to_meso  from_meso mode  clk_div");
  $monitor("@%g\t %b\t %b\t %b\t %h",
            cycle_counter,to_meso,from_meso_delayed,
            DUT.mode_cfg,DUT.clk_divider);
  
  // initial values
  clk_divider.output_clk_divider = 4'b0111;
  clk_divider.input_clk_divider  = 4'b0111;
  for (i=0 ; i<2*bit_num_p; i= i+1)
    bit_cfg[i]='{clk_edge_selector:1'b0, phase: 4'b0000};
  input_bit_selector_ch1  = 3'b000;
  output_bit_selector_ch1 = 3'b000;
  input_bit_selector_ch2  = 3'b001;
  output_bit_selector_ch2 = 3'b001;
  mode_cfg = create_cfg (LA_STOP,1'b0,PAT);
  en_lb = 0;
  fifo_en = 0;
  out_selector = 0;
  credit_to_meso = 0;
  valid_to_meso = 0;

  // reseting the modules and config tag and channel
  reset = 1'b1;
  @ (negedge clk)
  @ (negedge clk)
  reset = 1'b0;
  @ (posedge clk)
  $display("module has been reset");
  send_config_tag(cfg_clk,1'b1,config_data);
  $display("config tag has been reset");
  $display("\n*****************************");
  $display("sending initial configuration");
  $display("*****************************\n");

  // initialize clk divider, disable loop back, ready to be reset
  send_config_tag(cfg_clk,1'b0,config_data,
                  {2'b01,clk_divider},8'd10,2+$bits(clk_divider));
  
  // set mode configuration and select input and output bits 
  // for each channel logic analyzer
  send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                          8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
  
  // set bit configuration for channel 1 
  send_config_tag(cfg_clk,1'b0,config_data,bit_cfg_ch1,8'd12,$bits(bit_cfg_ch1));
  
  // set bit configuration for channel 2
  send_config_tag(cfg_clk,1'b0,config_data,bit_cfg_ch2,8'd13,$bits(bit_cfg_ch2));
  
  $display("\n*****************************");
  $display("     reseting the channel");
  $display("*****************************\n");

  // reset the mesosync 
  send_config_tag(cfg_clk,1'b0,config_data,
                  {2'b10,clk_divider},8'd10,2+$bits(clk_divider));
  $display("mesosync IO has been reset");
  
  #500
  
  $display("\n*****************************");
  $display("    Going to SYNC1 mode");
  $display("*****************************\n");
  
  // change mode to Sync1
  mode_cfg = create_cfg (LA_STOP,1'b0,SYNC1);
  send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                          8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
  #1500
  $display("\n*****************************");
  $display("bit line allignment performed");
  $display("*****************************\n");
  $monitor("@%g\t %b\t %b",cycle_counter,to_meso,from_meso_fixed);

  #500
  
  $display("\n*****************************");
  $display("    Going to SYNC2 mode");
  $display("*****************************\n");
  
  // change mode to Sync2
  mode_cfg = create_cfg (LA_STOP,1'b0,SYNC2);
  send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                          8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
  #1500
  $monitor("@%g %b\t %b",cycle_counter,to_meso,from_meso_fixed);
  //$monitor("@%g(s) %b\t %b",cycle_counter_slow,to_meso,from_meso_fixed);
  #1000
  $display("monitor is off");
  $monitoroff;
  #2090000
  $monitoron;
  #10000
  // (if output sync fails we must lower the io frequency)
  $display("\n*****************************");
  $display("    output sync finished      ");
  $display("*****************************\n");
  $display("\n");
  $display("\n*****************************");
  $display("sending patterns to Logic analyzers");
  $display("  line zero is the reference line  ");
  $display("*****************************\n");
  $monitor("@%g(s)\t %b\t %b\t %b\t %b",cycle_counter_slow,to_meso,
           from_meso_fixed,DUT.mesosync_channel.mesosync_input.LA_valid,
           DUT.mesosync_channel.mesosync_input.logic_analyzer_1.ready_o);
  
  // 72 values are saved in the LA fifo using fifo with free counter, during
  // sending data out each 2 cycles one data is removed, so 142 cycles are 
  // between free and full
  
  // sending patterns out
  out_selector = 1;
  
  // reading Logic analyzer data from each line
  // line 0 is the reference line
  for (i=1 ; i<2*bit_num_p; i= i+1) begin

    $display("\n*****************************");
    $display("        testing line %d        ",i);
    $display("*****************************\n");
    
    // stoping the channel and selecting line to be tested
    input_bit_selector_ch2  = i;
    output_bit_selector_ch2 = i;
    mode_cfg = create_cfg (LA_STOP,1'b0,STOP);
    send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                            8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
    
    // starting logic analyzer without any output
    mode_cfg = create_cfg (LA_STOP,1'b1,STOP);
    send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                            8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
    #1000
    // stopping logic anlyzer (which has stopped by itself, just not to gather 
    // data after data is sent out) and starting sending its data out
    mode_cfg = create_cfg (LA_STOP,1'b0,LA);
    send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                           8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
    
    #45000
    $display("\nin_reg_1 = %h",in_reg_1);
    $display("in_reg_2 = %h\n",in_reg_2);
  end
  
  $display("\n*****************************");
  $display("update phases based on the logic analyzer data");
  $display("*****************************\n");
 
  // select cycle and edge to read the data based on the logic analyzers' data
  for (i=0 ; i<2*bit_num_p; i= i+1)
    bit_cfg[i]='{clk_edge_selector:1'b0, phase: 4'b0100};
  
  @ (negedge clk)
  // set bit configuration for channel 1 
  send_config_tag(cfg_clk,1'b0,config_data,bit_cfg_ch1,8'd12,$bits(bit_cfg_ch1));
  
  // set bit configuration for channel 2
  send_config_tag(cfg_clk,1'b0,config_data,bit_cfg_ch2,8'd13,$bits(bit_cfg_ch2));
  
  $display("\n*****************************");
  $display("active loopback_mode");
  $display("*****************************\n");
  $monitor("@%g\t %b\t %b\t %b\t %b\t %b\t %b\t %b\t %d",cycle_counter,to_meso
           ,from_meso_fixed,DUT.valid,DUT.to_loopback,DUT.from_loopback,DUT.ready, 
           DUT.loopback.valid, DUT.loopback.output_credit_counter.credit_cnt);
  
  // sending loop back data 
  out_selector = 2;
  
  // making input channel active to send data to loopback module
  mode_cfg = create_cfg (NORMAL,1'b0,STOP);
  send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                         8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
  
  // enabling loopback module 
  en_lb = 1;
  fifo_en = 1;
  send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                         8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
  
  // based on valid-credit protocol, sending some data which are valid
  valid_to_meso = 1'b1;
  #100 

  // activing the output, after some time to make sure some valid data is 
  // stored in the loop back module
  mode_cfg = create_cfg (NORMAL,1'b0,NORM);
  send_config_tag(cfg_clk,1'b0,config_data,{fifo_en,en_lb,mode_cfg,ch_bit_selector},
                         8'd11,$bits(mode_cfg)+$bits(ch_bit_selector)+2);
  #200
  // no more data to be sent, not exceeding size of FIFO (credit protocol
  // would take care of this)
  valid_to_meso = 1'b0;
  #200

  credit_to_meso = 1'b1;
  // sending some credits so it would send more data
  #500
  credit_to_meso = 1'b0;

  // some time for the simulation to finish
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
        
//-----------------------------------------//
//----- slow and normal cycle counters-----//
//-----------------------------------------//

always_ff @ (posedge clk) begin
  reset_r <= reset;
  if (reset)
    cycle_counter <= 0;
  else
    cycle_counter <= cycle_counter + 1'b1;
end

always_ff @ (posedge io_clk or posedge reset) begin
  if (reset)
    cycle_counter_slow <= 0;
  else
    cycle_counter_slow <= cycle_counter_slow + 1'b1;
end

//------------------------------------------------------------------------//
//-- generating output pattern and collecting input data using io clock --//
//------------------------------------------------------------------------//

always_ff @ (posedge io_clk or posedge reset) begin
  if (reset) begin
    pattern_1 <= 8'b10000000;
    pattern_2 <= 8'b10100101;
    in_reg_1  <= 0;
    in_reg_2  <= 0;
    count     <= 0;
  end else begin
    pattern_1 <= {pattern_1[6:0],pattern_1[7]};
    pattern_2 <= {pattern_2[6:0],pattern_2[7]};
    in_reg_1  <= {in_reg_1[254:0],from_meso_fixed[output_bit_selector_ch1]};
    in_reg_2  <= {in_reg_2[254:0],from_meso_fixed[output_bit_selector_ch2]};
    count     <= count + 4'd1;
  end
end

//-----------------------------------------//
//-- function for generating config data --//
//-----------------------------------------//
function mode_cfg_s create_cfg(input input_mode_e in_mode,
                               input LA_enque, output_mode_e out_mode);
    create_cfg = 
           '{input_mode:   in_mode
            ,LA_enque:    LA_enque
            ,output_mode: out_mode
            };
endfunction

endmodule
