`include "bsg_dmc.svh"

module bsg_dmc_controller
  import bsg_dmc_pkg::*;
 #(parameter `BSG_INV_PARAM( ui_addr_width_p      )
  ,parameter `BSG_INV_PARAM( ui_data_width_p      )
  ,parameter `BSG_INV_PARAM( burst_data_width_p   )
  ,parameter `BSG_INV_PARAM( dfi_data_width_p     )
  ,parameter `BSG_INV_PARAM( cmd_afifo_depth_p    )
  ,parameter `BSG_INV_PARAM( cmd_sfifo_depth_p    )
  ,parameter  ui_burst_length_lp   = burst_data_width_p / ui_data_width_p
  ,localparam ui_mask_width_lp     = ui_data_width_p >> 3
  ,localparam dfi_mask_width_lp    = dfi_data_width_p >> 3
  ,localparam dfi_burst_length_lp  = burst_data_width_p / dfi_data_width_p)
  // User interface clock and reset
  (input                                ui_clk_i
  ,input                                ui_clk_sync_rst_i

  ,input								dfi_stall_transactions_i
  ,output logic							dfi_refresh_in_progress_o
  ,output logic                         ui_transaction_in_progress_o
  // User interface signals
  ,input          [ui_addr_width_p-1:0] app_addr_i
  ,input app_cmd_e                      app_cmd_i
  ,input                                app_en_i
  ,output                               app_rdy_o
  ,input                                app_wdf_wren_i
  ,input          [ui_data_width_p-1:0] app_wdf_data_i
  ,input         [ui_mask_width_lp-1:0] app_wdf_mask_i
  ,input                                app_wdf_end_i
  ,output                               app_wdf_rdy_o
  ,output                               app_rd_data_valid_o
  ,output         [ui_data_width_p-1:0] app_rd_data_o
  ,output logic                         app_rd_data_end_o
  ,input                                app_ref_req_i
  ,output                               app_ref_ack_o
  ,input                                app_zq_req_i
  ,output                               app_zq_ack_o
  ,input                                app_sr_req_i
  ,output                               app_sr_active_o
  // Status signal
  ,output logic                         dfi_init_calib_complete_o
  // DDR PHY interface clock and reset
  ,input                                dfi_clk_i
  ,input                                dfi_clk_sync_rst_i
  // DDR PHY interface signals
  ,output logic                   [2:0] dfi_bank_o
  ,output logic                  [15:0] dfi_address_o
  ,output logic                         dfi_cke_o
  ,output logic                         dfi_cs_n_o
  ,output logic                         dfi_ras_n_o
  ,output logic                         dfi_cas_n_o
  ,output logic                         dfi_we_n_o
  ,output logic                         dfi_reset_n_o
  ,output logic                         dfi_odt_o
  ,output logic                         dfi_wrdata_en_o
  ,output logic  [dfi_data_width_p-1:0] dfi_wrdata_o
  ,output logic [dfi_mask_width_lp-1:0] dfi_wrdata_mask_o
  ,output logic                         dfi_rddata_en_o
  ,input         [dfi_data_width_p-1:0] dfi_rddata_i
  ,input                                dfi_rddata_valid_i
  // Control and Status Registers
  ,input bsg_dmc_s                      dfi_dmc_p_i);

  typedef enum logic [2:0] {IDLE, INIT, CALR, REFR, LDST} state;

  integer i;
  genvar k;

  logic                                                                cmd_afifo_wclk,     cmd_afifo_rclk;
  logic                                                                cmd_afifo_wrst,     cmd_afifo_rrst;
  logic                                                                cmd_afifo_winc,     cmd_afifo_rinc;
  logic                                                                cmd_afifo_wfull,    cmd_afifo_rvalid;
  `declare_app_cmd_afifo_entry_s(ui_addr_width_p);
  app_cmd_afifo_entry_s                                                cmd_afifo_wdata,    cmd_afifo_rdata;

  logic                                                                cmd_sfifo_winc,     cmd_sfifo_rinc;
  logic                                                                cmd_sfifo_ready,    cmd_sfifo_valid;
  dfi_cmd_sfifo_entry_s                                                cmd_sfifo_wdata,    cmd_sfifo_rdata;

  logic                                                                wrdata_afifo_wclk,  wrdata_afifo_rclk;
  logic                                                                wrdata_afifo_wrst,  wrdata_afifo_rrst;
  logic                                                                wrdata_afifo_winc,  wrdata_afifo_rinc;
  logic                                                                wrdata_afifo_wfull, wrdata_afifo_rvalid;
  logic                         [ui_data_width_p+ui_mask_width_lp-1:0] wrdata_afifo_wdata, wrdata_afifo_rdata;

  logic                                                                rddata_afifo_wclk,  rddata_afifo_rclk;
  logic                                                                rddata_afifo_wrst,  rddata_afifo_rrst;
  logic                                                                rddata_afifo_winc,  rddata_afifo_rinc;
  logic                                                                rddata_afifo_wfull, rddata_afifo_rvalid;
  logic                                         [dfi_data_width_p-1:0] rddata_afifo_wdata, rddata_afifo_rdata;

  logic                                                                tx_sipo_valid_li;
  logic                         [ui_mask_width_lp+ui_data_width_p-1:0] tx_sipo_data_li;
  logic                                                                tx_sipo_ready_and_lo;
  logic                                                                tx_sipo_valid_lo;
  logic [ui_burst_length_lp-1:0][ui_mask_width_lp+ui_data_width_p-1:0] tx_sipo_data_lo;
  logic                                                                tx_sipo_yumi_li;

  logic                                                                tx_data_piso_valid_li;
  logic                [dfi_burst_length_lp-1:0][dfi_data_width_p-1:0] tx_data_piso_data_li;
  logic                                                                tx_data_piso_ready_lo;
  logic                                                                tx_data_piso_valid_lo;
  logic                                         [dfi_data_width_p-1:0] tx_data_piso_data_lo;
  logic                                                                tx_data_piso_yumi_li;

  logic                                                                tx_mask_piso_valid_li;
  logic               [dfi_burst_length_lp-1:0][dfi_mask_width_lp-1:0] tx_mask_piso_data_li;
  logic                                                                tx_mask_piso_ready_lo;
  logic                                                                tx_mask_piso_valid_lo;
  logic                                        [dfi_mask_width_lp-1:0] tx_mask_piso_data_lo;
  logic                                                                tx_mask_piso_yumi_li;

  logic [(dfi_data_width_p+dfi_mask_width_lp)*dfi_burst_length_lp-1:0] tx_data_mask;
  logic                     [dfi_data_width_p*dfi_burst_length_lp-1:0] tx_data;
  logic                    [dfi_mask_width_lp*dfi_burst_length_lp-1:0] tx_mask;

  logic                                                                rx_piso_valid_li;
  logic                  [ui_burst_length_lp-1:0][ui_data_width_p-1:0] rx_piso_data_li;
  logic                                                                rx_piso_ready_lo;
  logic                                                                rx_piso_valid_lo;
  logic                                          [ui_data_width_p-1:0] rx_piso_data_lo;
  logic                                                                rx_piso_yumi_li;

  logic                                                                rx_sipo_valid_li;
  logic                                         [dfi_data_width_p-1:0] rx_sipo_data_li;
  logic                                                                rx_sipo_ready_and_lo;
  logic                                                                rx_sipo_valid_lo;
  logic                [dfi_burst_length_lp-1:0][dfi_data_width_p-1:0] rx_sipo_data_lo;
  logic                                                                rx_sipo_yumi_li;

  logic                     [dfi_data_width_p*dfi_burst_length_lp-1:0] rx_data;

  logic                                  [$clog2(cmd_afifo_depth_p):0] rd_credit;
  logic                      [`BSG_SAFE_CLOG2(ui_burst_length_lp)-1:0] rd_cnt;

  logic [31:0] row_col_addr;
  logic [15:0] row_addr, col_addr;
  logic  [2:0] bank_addr;
  logic        ap;

  logic  [7:0] cmd_tick;
  logic  [7:0] cmd_act_tick;
  logic  [7:0] cmd_wr_tick, cmd_rd_tick;

  logic        cwd_valid;
  logic  [7:0] cwd_tick;
  logic        wburst_valid;

  logic        cas_valid;
  logic  [7:0] cas_tick;
  logic  [7:0] rburst_tick;

  state        cstate, nstate;

  dfi_cmd_e    c_cmd, n_cmd;

  logic        shoot;
  logic  [7:0] open_bank;
  logic [15:0] open_row [0:7];

  logic        push;

  logic [15:0] init_tick;
  logic        init_done;

  logic [15:0] calr_tick;
  // number of calibration reads completed. ie. response has been received by DDR and forwarded to DMC by DFI
  logic [15:0] calr_cnt;

  logic [15:0] ref_tick;
  logic  [1:0] refr_tick;
  logic        refr_req;
  logic        refr_ack;

  logic [15:0] rd_calib_tick;    
  logic        rd_calib_req;
  logic        rd_calib_ack;

  logic  [1:0] ldst_tick;

  logic [15:0] tick_refi;
  logic  [3:0] tick_mrd;
  logic  [3:0] tick_rfc;
  logic  [3:0] tick_rc;
  logic  [3:0] tick_rp;
  logic  [3:0] tick_ras;
  logic  [3:0] tick_rrd;
  logic  [3:0] tick_rcd;
  logic  [3:0] tick_wr;
  logic  [3:0] tick_wtr;
  logic  [3:0] tick_rtp;
  logic  [3:0] tick_cas;

  assign app_ref_ack_o = app_ref_req_i & ~app_wdf_end_i;
  assign app_zq_ack_o = app_zq_req_i;
  assign app_sr_active_o = app_sr_req_i;

  always_ff @(posedge ui_clk_i) begin
    if(ui_clk_sync_rst_i)
      rd_credit <= cmd_afifo_depth_p;
    else if(app_en_i && (app_cmd_i == RD || app_cmd_i == RP) && app_rdy_o) begin
      if(!(app_rd_data_valid_o && app_rd_data_end_o))
        rd_credit <= rd_credit - 1;
    end
    else if(app_rd_data_valid_o && app_rd_data_end_o)
      rd_credit <= rd_credit + 1;
  end

  assign app_rdy_o = ~cmd_afifo_wfull & |rd_credit;

  assign cmd_afifo_wclk  = ui_clk_i;
  assign cmd_afifo_wrst  = ui_clk_sync_rst_i;
  assign cmd_afifo_winc  = app_en_i & app_rdy_o;
  assign cmd_afifo_wdata.cmd = app_cmd_i;
  assign cmd_afifo_wdata.addr = app_addr_i;

  assign cmd_afifo_rclk  = dfi_clk_i;
  assign cmd_afifo_rrst  = dfi_clk_sync_rst_i;
  assign cmd_afifo_rinc  = cmd_afifo_rvalid & cmd_sfifo_ready & (cstate == LDST && ldst_tick == 0) ;

  bsg_async_fifo #
    (.width_p   ( $bits(cmd_afifo_wdata)    )
    ,.lg_size_p ( $clog2(cmd_afifo_depth_p) )
    ,.and_data_with_valid_p(1))
  cmd_afifo
    (.r_data_o  ( cmd_afifo_rdata   )
    ,.w_full_o  ( cmd_afifo_wfull   )
    ,.r_valid_o ( cmd_afifo_rvalid  )
    ,.w_data_i  ( cmd_afifo_wdata   )
    ,.w_enq_i   ( cmd_afifo_winc    )
    ,.w_clk_i   ( cmd_afifo_wclk    )
    ,.w_reset_i ( cmd_afifo_wrst    )
    ,.r_deq_i   ( cmd_afifo_rinc    )
    ,.r_clk_i   ( cmd_afifo_rclk    )
    ,.r_reset_i ( cmd_afifo_rrst    ));

  assign wrdata_afifo_wclk  = ui_clk_i;
  assign wrdata_afifo_wrst  = ui_clk_sync_rst_i;
  assign wrdata_afifo_winc  = app_wdf_wren_i & ~wrdata_afifo_wfull;
  assign wrdata_afifo_wdata = {app_wdf_mask_i,app_wdf_data_i};
  assign wrdata_afifo_rclk  = dfi_clk_i;
  assign wrdata_afifo_rrst  = dfi_clk_sync_rst_i;
  assign wrdata_afifo_rinc  = tx_sipo_ready_and_lo & wrdata_afifo_rvalid;

  assign app_wdf_rdy_o = ~wrdata_afifo_wfull;

  bsg_async_fifo #
    (.width_p   ( ui_data_width_p+ui_mask_width_lp             )
    ,.lg_size_p ( $clog2(cmd_afifo_depth_p*ui_burst_length_lp) ))
  wrdata_afifo
    (.r_data_o  ( wrdata_afifo_rdata               )
    ,.w_full_o  ( wrdata_afifo_wfull               )
    ,.r_valid_o ( wrdata_afifo_rvalid              )
    ,.w_data_i  ( wrdata_afifo_wdata               )
    ,.w_enq_i   ( wrdata_afifo_winc                )
    ,.w_clk_i   ( wrdata_afifo_wclk                )
    ,.w_reset_i ( wrdata_afifo_wrst                )
    ,.r_deq_i   ( wrdata_afifo_rinc                )
    ,.r_clk_i   ( wrdata_afifo_rclk                )
    ,.r_reset_i ( wrdata_afifo_rrst                ));

  assign tx_sipo_valid_li = wrdata_afifo_rvalid;
  assign tx_sipo_data_li = wrdata_afifo_rdata;
  assign tx_sipo_yumi_li = shoot && cmd_sfifo_rdata[23:20]==WRITE;

  bsg_serial_in_parallel_out_full #
    (.width_p    ( ui_data_width_p+ui_mask_width_lp )
    ,.els_p      ( ui_burst_length_lp               ))
  tx_sipo
    (.clk_i      ( dfi_clk_i                        )
    ,.reset_i    ( dfi_clk_sync_rst_i               )
    ,.v_i        ( tx_sipo_valid_li                 )
    ,.data_i     ( tx_sipo_data_li                  )
    ,.ready_and_o( tx_sipo_ready_and_lo             ) 
    ,.v_o        ( tx_sipo_valid_lo                 )
    ,.data_o     ( tx_sipo_data_lo                  )
    ,.yumi_i     ( tx_sipo_yumi_li                  ));

  assign row_col_addr = ((cmd_afifo_rdata.addr >> (dfi_dmc_p_i.bank_pos + dfi_dmc_p_i.bank_width)) << dfi_dmc_p_i.bank_pos) | (((1 << dfi_dmc_p_i.bank_pos) - 1) & cmd_afifo_rdata.addr);
  assign col_addr     = 16'(((1 << dfi_dmc_p_i.col_width) - 1) & row_col_addr[ui_addr_width_p-1:0]);
  assign row_addr     = 16'(((1 << dfi_dmc_p_i.row_width) - 1) & (row_col_addr >> dfi_dmc_p_i.col_width));
  assign bank_addr    = 3'(((1 << dfi_dmc_p_i.bank_width) - 1) & (cmd_afifo_rdata.addr >> dfi_dmc_p_i.bank_pos));
  // AP comes from UI command when necessary. Internal commands such as calibration reads do not
  //   generate AP
  assign ap           = (cstate == LDST) && cmd_afifo_rdata.cmd[1];

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      dfi_init_calib_complete_o <= 0;
    else if(init_done)
      dfi_init_calib_complete_o <= 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      init_tick <= 0;
    else if(cstate == IDLE && nstate == INIT)
      init_tick <= dfi_dmc_p_i.init_cycles ;
    else if(cstate == INIT && init_tick != 0 && push)
      init_tick <= init_tick - 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      calr_tick <= 0;
    else if(rd_calib_ack && calr_tick == dfi_dmc_p_i.calib_num_reads)
      calr_tick <= 0;
    else if(cstate == IDLE && nstate == CALR)
      calr_tick <= calr_tick +  1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      init_done <= 0;
    else if(cstate == INIT && nstate == IDLE)
      init_done <= 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      ref_tick <= 0;
    else if(init_done) begin
      if(ref_tick == dfi_dmc_p_i.trefi)
        ref_tick <= 0;
      else if(!refr_req)
        ref_tick <= ref_tick + 1;
    end
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      rd_calib_tick <= 0;
    else if(init_done) begin
      // reset rd_calib_tick counter when we transition to calr or when a read command is issued through the UI.
      if((cstate == IDLE && nstate == CALR) ||  (cmd_afifo_rdata.cmd[0]))
        rd_calib_tick <= 0;
      else if(rd_calib_tick < dfi_dmc_p_i.tcalr)
        rd_calib_tick <= rd_calib_tick + 1;
    end
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      refr_req <= 0;
    else if(init_done) begin
      if(refr_ack)
        refr_req <= 0;
      else if(ref_tick == dfi_dmc_p_i.trefi)
        refr_req <= 1;
    end
  end

  assign refr_ack = (cstate == REFR) & push & (refr_tick == 0);

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      rd_calib_req <= 0;
    // reset rd_calib_req to 0 when we are done issuing dfi_dmc_p_i.calib_num_reads number of read commands.
    else if (rd_calib_ack && (calr_tick == dfi_dmc_p_i.calib_num_reads))
      rd_calib_req <= 0;
    else if(rd_calib_tick == dfi_dmc_p_i.tcalr & calr_cnt == 0)
      rd_calib_req <= 1;
  end

  // acknowledgement for every calib read command pushed to cmd_sfifo. 
  assign rd_calib_ack = (cstate == CALR) & push & (ldst_tick==0);

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      refr_tick <= 0;
    else if(cstate == IDLE && nstate == REFR) begin
      if(|open_bank)
        refr_tick <= 2;
      else
        refr_tick <= 1;
    end
    else if(cstate == REFR && refr_tick != 0 && push)
      refr_tick <= refr_tick - 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      ldst_tick <= 0;
    else if(cstate == IDLE && (nstate == LDST || nstate == CALR)) begin
      if(open_bank[bank_addr] && open_row[bank_addr] == row_addr)
        ldst_tick <= 1;
      else if(open_bank[bank_addr])
        ldst_tick <= 3;
      else
        ldst_tick <= 2;
    end
    else if((cstate == LDST || cstate == CALR)  && ldst_tick != 0 && push)
      ldst_tick <= ldst_tick - 1;
  end

  always_comb begin
    push = 1'b0;
    cmd_sfifo_wdata = {$bits(cmd_sfifo_wdata){1'b1}};
    case(cstate)
      INIT: begin
        push = cmd_sfifo_ready;
        case(init_tick)
          dfi_dmc_p_i.init_calib_reads + 'd7  : begin cmd_sfifo_wdata.cmd = PRE; cmd_sfifo_wdata.addr = 16'h400; end
          dfi_dmc_p_i.init_calib_reads + 'd6  : begin cmd_sfifo_wdata.cmd = REF; cmd_sfifo_wdata.addr = 16'h0; end
          dfi_dmc_p_i.init_calib_reads + 'd5  : begin cmd_sfifo_wdata.cmd = REF; cmd_sfifo_wdata.addr = 16'h0; end
          dfi_dmc_p_i.init_calib_reads + 'd4  : begin cmd_sfifo_wdata.cmd = LMR; cmd_sfifo_wdata.addr = {8'h0, dfi_dmc_p_i.tcas, 4'($clog2(dfi_burst_length_lp << 1))}; cmd_sfifo_wdata.ba = 4'h0; end
          dfi_dmc_p_i.init_calib_reads + 'd3  : begin cmd_sfifo_wdata.cmd = LMR; cmd_sfifo_wdata.addr = 16'h0; cmd_sfifo_wdata.ba = 4'h2; end
          dfi_dmc_p_i.init_calib_reads + 'd2  : begin cmd_sfifo_wdata.cmd = NOP; end
          dfi_dmc_p_i.init_calib_reads + 'd1  : begin cmd_sfifo_wdata.cmd = ACT; cmd_sfifo_wdata.addr = '0; cmd_sfifo_wdata.ba = '0; end
          '0                              : begin cmd_sfifo_wdata.cmd = NOP; end
          // Tools like genus have a problem with case inside syntax with non-constants
          // Replace when tool support becomes better
          // NOTE: LSB to MSB
          //[1:dfi_dmc_p_i.init_calib_reads]    : begin cmd_sfifo_wdata.cmd = READ; cmd_sfifo_wdata.ba = '0; end
          default : begin
            if (init_tick <= dfi_dmc_p_i.init_calib_reads && init_tick >= 1) begin
              cmd_sfifo_wdata.cmd = READ; cmd_sfifo_wdata.addr = '0; cmd_sfifo_wdata.ba = '0;
            end else begin
              cmd_sfifo_wdata.cmd = DESELECT;
            end
          end
        endcase
      end
      //    NOTE: We will be cycling between IDLE and CALR for dfi_dmc_p_i.calib_num_reads number of times. For example, the transition for dfi_dmc_p_i.calib_num_reads = 2 would be LDST -> IDLE -> CALR (first calibration read) -> IDLE -> CALR(second calib read) -> IDLE -> CALR (pending calib reads) -> IDLE (pending calib reads done, can move to normal operation)
      CALR: begin
        push = cmd_sfifo_ready;
        cmd_sfifo_wdata.addr = '0; cmd_sfifo_wdata.ba = '0;
        // Periodic calibration reads
        case(ldst_tick)
          'd3: begin cmd_sfifo_wdata.cmd = PRE; end
          'd2: begin cmd_sfifo_wdata.cmd = ACT; end
          'd1: begin cmd_sfifo_wdata.cmd = READ; end
          'd0: begin cmd_sfifo_wdata.cmd = NOP; end
        endcase
      end          
      REFR: begin
        push = cmd_sfifo_ready;
        case(refr_tick)
          'd2: begin cmd_sfifo_wdata.cmd = PRE; cmd_sfifo_wdata.addr = 16'h400; end
          'd1: begin cmd_sfifo_wdata.cmd = REF; end
          'd0: begin cmd_sfifo_wdata.cmd = NOP; end
        endcase
      end
      LDST: begin
        push = cmd_sfifo_ready;
        case(ldst_tick)
          'd3: begin cmd_sfifo_wdata.cmd = PRE; cmd_sfifo_wdata.ba = bank_addr; cmd_sfifo_wdata.addr = open_row[bank_addr]; end
          'd2: begin cmd_sfifo_wdata.cmd = ACT; cmd_sfifo_wdata.ba = bank_addr; cmd_sfifo_wdata.addr = row_addr; end
          'd1: begin
                 cmd_sfifo_wdata.ba = bank_addr;
                 cmd_sfifo_wdata.addr = {col_addr[14:10], ap, col_addr[9:0]};
                 if(cmd_afifo_rdata.cmd[0])
                     cmd_sfifo_wdata.cmd = READ;
                 else
                     cmd_sfifo_wdata.cmd = WRITE;
               end
          'd0: begin 
                    cmd_sfifo_wdata.cmd = NOP; 
               end
        endcase
      end
    endcase
  end

  always_comb begin
    nstate = IDLE;
    case(cstate)
      IDLE: if(!init_done)                                                          nstate = INIT;
            else if(refr_req)                                                       nstate = REFR;
            // for periodic read calibrations that happen in between normal operation
            else if(rd_calib_req)                                                   nstate = CALR;
            else if(cmd_afifo_rvalid)                                               nstate = LDST;
            else                                                                    nstate = cstate;
      INIT: if(calr_cnt == 0)                                                       nstate = IDLE;
            else                                                                    nstate = cstate;
      CALR: if(ldst_tick == 0 && push)                                              nstate = IDLE;
            else                                                                    nstate = cstate;
      REFR: if(refr_tick == 0 && push)                                              nstate = IDLE;
            else                                                                    nstate = cstate;
      LDST: if(ldst_tick == 0 && push)                                              nstate = IDLE;
            else                                                                    nstate = cstate;
      default:                                                                      nstate = IDLE;
    endcase
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i) begin
      cstate <= IDLE;
    end
    else begin
      cstate <= nstate;
    end
  end

  assign cmd_sfifo_winc  = push;
  assign cmd_sfifo_rinc  = shoot;

  bsg_fifo_1r1w_small #
    (.width_p            ( $bits(cmd_sfifo_wdata) )
    ,.els_p              ( cmd_sfifo_depth_p      )
    ,.ready_THEN_valid_p ( 1                      ))
  cmd_sfifo
    (.clk_i              ( dfi_clk_i          )
    ,.reset_i            ( dfi_clk_sync_rst_i )
    ,.v_i                ( cmd_sfifo_winc     )
    ,.ready_param_o      ( cmd_sfifo_ready    )
    ,.data_i             ( cmd_sfifo_wdata    )
    ,.v_o                ( cmd_sfifo_valid    )
    ,.data_o             ( cmd_sfifo_rdata    )
    ,.yumi_i             ( cmd_sfifo_rinc     ));

  always_comb begin
    if(cmd_sfifo_valid && !dfi_stall_transactions_i)
      case(c_cmd)
	LMR:   shoot = cmd_tick >= dfi_dmc_p_i.tmrd;
	REF:   shoot = cmd_tick >= dfi_dmc_p_i.trfc;
	PRE:   shoot = (n_cmd==ACT)? (cmd_tick >= dfi_dmc_p_i.trp && cmd_act_tick >= dfi_dmc_p_i.tras): cmd_tick >= dfi_dmc_p_i.trp;
	ACT:   case(n_cmd)
                 PRE:     shoot = cmd_tick >= dfi_dmc_p_i.tras;
                 ACT:     shoot = cmd_tick >= dfi_dmc_p_i.trrd;
                 WRITE:   shoot = (cmd_tick >= dfi_dmc_p_i.trcd) & (cmd_rd_tick >= dfi_dmc_p_i.tcas+dfi_burst_length_lp-1) & (cmd_act_tick >= dfi_dmc_p_i.tras) & tx_sipo_valid_lo;
                 READ:    shoot = (cmd_tick >= dfi_dmc_p_i.trcd) & (cmd_wr_tick >= dfi_dmc_p_i.twtr) & (cmd_act_tick >= dfi_dmc_p_i.tras);
	         	 default: shoot = 1'b1;
             endcase
    WRITE: case(n_cmd)
                 PRE:     shoot = (cmd_tick >= dfi_dmc_p_i.twr) & (cmd_act_tick >= dfi_dmc_p_i.tras);
				 // if write is followed by refresh, it means we are writing with auto precharge. But we still have to wait for tras after activate and (twr + trp) for internal precharge to have completed. So timing condition below applies for either n_cmd = precharge or refresh			
                 REF:     shoot = (cmd_tick >= dfi_dmc_p_i.twr + dfi_dmc_p_i.trp) & (cmd_act_tick >= dfi_dmc_p_i.tras) ;			
                 WRITE:   shoot = (ap) ? ((cmd_tick >= dfi_burst_length_lp-1) & tx_sipo_valid_lo && cmd_tick >= dfi_dmc_p_i.trp) : ((cmd_tick >= dfi_burst_length_lp-1) & tx_sipo_valid_lo) ;
                 READ:    shoot = (ap) ? (cmd_tick >= dfi_dmc_p_i.twtr && cmd_tick >= dfi_dmc_p_i.trp) : cmd_tick >= dfi_dmc_p_i.twtr ;
                 ACT:     shoot = (cmd_act_tick >= dfi_dmc_p_i.trc) & (cmd_tick >= dfi_dmc_p_i.twr + dfi_dmc_p_i.trp) & (cmd_tick >= dfi_dmc_p_i.trrd);
	             default: shoot = 1'b1;
               endcase
    READ:  case(n_cmd)
                 PRE:     shoot = (cmd_tick >= dfi_dmc_p_i.trtp) & (cmd_act_tick >= dfi_dmc_p_i.tras);
				 // if read is followed by refresh, it means we are reading with auto precharge. But we still have to wait for trtp after read and tras after activate. So timing condition below applies for either n_cmd = precharge or refresh			
                 REF:     shoot = (cmd_tick >= dfi_dmc_p_i.trtp + dfi_dmc_p_i.trp) & (cmd_act_tick >= dfi_dmc_p_i.tras);			
                 WRITE:   shoot = (ap) ?  ( (cmd_tick >= dfi_dmc_p_i.tcas + dfi_dmc_p_i.trp + dfi_burst_length_lp-1) & tx_sipo_valid_lo ): ((cmd_tick >= dfi_dmc_p_i.tcas + dfi_burst_length_lp-1) & tx_sipo_valid_lo);
                 READ:    shoot = cmd_tick >= dfi_burst_length_lp-1;
                 ACT:     shoot = (cmd_act_tick >= dfi_dmc_p_i.trc) & (cmd_tick >= dfi_dmc_p_i.trtp + dfi_dmc_p_i.trp) & (cmd_tick >= dfi_dmc_p_i.trrd) & (cmd_tick >= dfi_dmc_p_i.trrd);
	             default: shoot = 1'b1;
               endcase
	default: shoot = 1'b1;
      endcase
    else
      shoot = 1'b0;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      cmd_tick <= 0;
    else if(shoot)
      cmd_tick <= 0;
    else if(cmd_tick != 8'hf)
      cmd_tick <= cmd_tick + 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      cmd_act_tick <= 0;
    else if(shoot && n_cmd == ACT)
      cmd_act_tick <= 0;
    else if(cmd_act_tick != 8'hf)
      cmd_act_tick <= cmd_act_tick + 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      cmd_wr_tick <= 0;
    else if(shoot && n_cmd == WRITE)
      cmd_wr_tick <= 0;
    else if(cmd_wr_tick != 8'hf)
      cmd_wr_tick <= cmd_wr_tick + 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      cmd_rd_tick <= 0;
    else if(shoot && n_cmd == READ)
      cmd_rd_tick <= 0;
    else if(cmd_rd_tick != 8'hf)
      cmd_rd_tick <= cmd_rd_tick + 1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      c_cmd <= NOP;
    else if(shoot && n_cmd != NOP)
      c_cmd <= n_cmd;
  end

  assign n_cmd = cmd_sfifo_rdata.cmd;

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i) begin
      wburst_valid <= 0;
    end
    else if((shoot && cmd_sfifo_rdata[23:20] == WRITE) ) begin
      wburst_valid <= 1;
    end
    else begin 
          wburst_valid <= 0;
    end
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i) begin
      cas_tick <= 0;
      cas_valid <= 0;
    end
    else if(shoot && cmd_sfifo_rdata[23:20] == READ) begin
      cas_tick <= dfi_dmc_p_i.tcas - 1;
      cas_valid <= 1;
    end
    else if(cas_valid) begin
      cas_tick <= cas_tick - 1;
      if(cas_tick == 0) cas_valid <= 0;
    end
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i) begin
      rburst_tick <= 0;
      dfi_rddata_en_o <= 0;
    end
    else if(cas_valid && cas_tick == 0) begin
      rburst_tick <= dfi_burst_length_lp-1;
      dfi_rddata_en_o <= 1;
    end
    else if(dfi_rddata_en_o) begin
      rburst_tick <= rburst_tick - 1;
      if(rburst_tick == 0) dfi_rddata_en_o <= 0;
    end
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i) begin
      dfi_bank_o <= 3'b000;
      dfi_address_o <= 16'h0000;
      {dfi_cs_n_o, dfi_ras_n_o, dfi_cas_n_o, dfi_we_n_o} <= 4'b1111;
      dfi_reset_n_o <= 1'b1;
      dfi_odt_o <= 1'b1;
    end
    else if(shoot)begin
      dfi_bank_o <= cmd_sfifo_rdata[18:16];
      dfi_address_o <= cmd_sfifo_rdata[15:0];
      {dfi_cs_n_o, dfi_ras_n_o, dfi_cas_n_o, dfi_we_n_o} <= n_cmd;
    end
    else begin
      {dfi_cs_n_o, dfi_ras_n_o, dfi_cas_n_o, dfi_we_n_o} <= 4'b1111;
      dfi_reset_n_o <= 1'b1;
      dfi_odt_o <= 1'b1;
    end
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      dfi_cke_o <= 1'b0;
    else
      dfi_cke_o <= 1'b1;
  end

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i) begin
      open_bank <= 0;
    end
    else if(cmd_sfifo_winc) begin
      case(cmd_sfifo_wdata[23:20])
        ACT: begin
               open_bank[cmd_sfifo_wdata[18:16]] <= 1'b1;
               open_row[cmd_sfifo_wdata[18:16]] <= cmd_sfifo_wdata[15:0];
             end
        WRITE,
        READ: open_bank[cmd_sfifo_wdata[18:16]] <= ~ap;
        PRE: begin
               if(cmd_sfifo_wdata[10])
                 open_bank <= 0;
               else
                 open_bank[cmd_sfifo_wdata[18:16]] <= 1'b0;
             end
      endcase
    end
  end

  for(k=0;k<ui_burst_length_lp;k++) begin: tx_flatten
    assign tx_data[k*ui_data_width_p+:ui_data_width_p]   = tx_sipo_data_lo[k][0+:ui_data_width_p];
    assign tx_mask[k*ui_mask_width_lp+:ui_mask_width_lp] = tx_sipo_data_lo[k][ui_data_width_p+:ui_mask_width_lp];
  end
  for(k=0;k<dfi_burst_length_lp;k++) begin: tx_make
    always_ff @(posedge dfi_clk_i) begin
      tx_data_piso_data_li[k] <= tx_data[k*dfi_data_width_p+:dfi_data_width_p];
      tx_mask_piso_data_li[k] <= tx_mask[k*dfi_mask_width_lp+:dfi_mask_width_lp];
    end
  end

  assign tx_data_piso_valid_li = wburst_valid;
  assign tx_data_piso_yumi_li  = tx_data_piso_valid_lo;

  assign tx_mask_piso_valid_li = wburst_valid;
  assign tx_mask_piso_yumi_li  = tx_mask_piso_valid_lo;

  bsg_parallel_in_serial_out #
    (.width_p ( dfi_data_width_p      )
    ,.els_p   ( dfi_burst_length_lp   ))
  tx_data_piso
    (.clk_i   ( dfi_clk_i             )
    ,.reset_i ( dfi_clk_sync_rst_i    )
    ,.valid_i ( tx_data_piso_valid_li )
    ,.data_i  ( tx_data_piso_data_li  )
    ,.ready_and_o ( tx_data_piso_ready_lo ) 
    ,.valid_o ( tx_data_piso_valid_lo )
    ,.data_o  ( tx_data_piso_data_lo  )
    ,.yumi_i  ( tx_data_piso_yumi_li  ));

  bsg_parallel_in_serial_out #
    (.width_p ( dfi_mask_width_lp     )
    ,.els_p   ( dfi_burst_length_lp   ))
  tx_mask_piso
    (.clk_i   ( dfi_clk_i             )
    ,.reset_i ( dfi_clk_sync_rst_i    )
    ,.valid_i ( tx_mask_piso_valid_li )
    ,.data_i  ( tx_mask_piso_data_li  )
    ,.ready_and_o ( tx_mask_piso_ready_lo ) 
    ,.valid_o ( tx_mask_piso_valid_lo )
    ,.data_o  ( tx_mask_piso_data_lo  )
    ,.yumi_i  ( tx_mask_piso_yumi_li  ));

  assign dfi_wrdata_o      = tx_data_piso_data_lo;
  assign dfi_wrdata_en_o   = tx_data_piso_valid_lo;
  assign dfi_wrdata_mask_o = tx_mask_piso_data_lo;

  assign rddata_afifo_wclk  = dfi_clk_i;
  assign rddata_afifo_wrst  = dfi_clk_sync_rst_i;
  assign rddata_afifo_winc  = (calr_cnt >0) ? '0 : dfi_rddata_valid_i;
  assign rddata_afifo_wdata = dfi_rddata_i;

  assign rddata_afifo_rclk  = ui_clk_i;
  assign rddata_afifo_rrst  = ui_clk_sync_rst_i;
  assign rddata_afifo_rinc  = rx_sipo_ready_and_lo && rddata_afifo_rvalid;

  bsg_async_fifo #
    (.width_p   ( dfi_data_width_p                             )
    ,.lg_size_p ( $clog2(cmd_afifo_depth_p*dfi_burst_length_lp) ))
  rddata_afifo
    (.r_data_o  ( rddata_afifo_rdata  )
    ,.w_full_o  ( rddata_afifo_wfull  )
    ,.r_valid_o ( rddata_afifo_rvalid )
    ,.w_data_i  ( rddata_afifo_wdata  )
    ,.w_enq_i   ( rddata_afifo_winc   )
    ,.w_clk_i   ( rddata_afifo_wclk   )
    ,.w_reset_i ( rddata_afifo_wrst   )
    ,.r_deq_i   ( rddata_afifo_rinc   )
    ,.r_clk_i   ( rddata_afifo_rclk   )
    ,.r_reset_i ( rddata_afifo_rrst   ));

  always_ff @(posedge dfi_clk_i) begin
    if(dfi_clk_sync_rst_i)
      calr_cnt <= '0;
    else if(cstate == IDLE && nstate == INIT && calr_cnt == 0)
      calr_cnt <= dfi_dmc_p_i.init_calib_reads * dfi_burst_length_lp;
    else if(cstate == IDLE && nstate == CALR && calr_cnt == 0)
      calr_cnt <= dfi_dmc_p_i.calib_num_reads * dfi_burst_length_lp;
    else if(calr_cnt > 0 && dfi_rddata_valid_i) begin
      calr_cnt <= calr_cnt - 1'b1;
    end
  end

  assign rx_sipo_valid_li = rddata_afifo_rvalid;
  assign rx_sipo_data_li = rddata_afifo_rdata;
  assign rx_sipo_yumi_li = rx_sipo_valid_lo & rx_piso_ready_lo;

  bsg_serial_in_parallel_out_full #
    (.width_p    ( dfi_data_width_p    )
    ,.els_p      ( dfi_burst_length_lp ))
  rx_sipo
    (.clk_i      ( ui_clk_i            )
    ,.reset_i    ( ui_clk_sync_rst_i   )
    ,.v_i        ( rx_sipo_valid_li    )
    ,.data_i     ( rx_sipo_data_li     )
    ,.ready_and_o( rx_sipo_ready_and_lo) 
    ,.v_o        ( rx_sipo_valid_lo    )
    ,.data_o     ( rx_sipo_data_lo     )
    ,.yumi_i     ( rx_sipo_yumi_li     ));

  for(k=0;k<dfi_burst_length_lp;k++) begin: rx_flatten
    assign rx_data[k*dfi_data_width_p+:dfi_data_width_p] = rx_sipo_data_lo[k];
  end
  for(k=0;k<ui_burst_length_lp;k++) begin: rx_make
    assign rx_piso_data_li[k] = rx_data[k*ui_data_width_p+:ui_data_width_p];
  end

  // We don't want to return the data from the calibration reads
  assign rx_piso_valid_li =  rx_sipo_valid_lo;
  assign rx_piso_yumi_li = rx_piso_valid_lo;

  bsg_parallel_in_serial_out #
    (.width_p ( ui_data_width_p    )
    ,.els_p   ( ui_burst_length_lp ))
  rx_piso
    (.clk_i   ( ui_clk_i           )
    ,.reset_i ( ui_clk_sync_rst_i  )
    ,.valid_i ( rx_piso_valid_li   )
    ,.data_i  ( rx_piso_data_li    )
    ,.ready_and_o ( rx_piso_ready_lo   ) 
    ,.valid_o ( rx_piso_valid_lo   )
    ,.data_o  ( rx_piso_data_lo    )
    ,.yumi_i  ( rx_piso_yumi_li    ));

  always_ff @(posedge ui_clk_i) begin
    if(ui_clk_sync_rst_i)
      rd_cnt <= 0;
    else if(rx_piso_yumi_li) begin
      if(rd_cnt == ui_burst_length_lp - 1)
        rd_cnt <= '0;
      else
        rd_cnt <= rd_cnt + 1;
    end
  end

  logic [`BSG_WIDTH(2*cmd_sfifo_depth_p)-1:0] txn_cnt;
  bsg_counter_up_down #
    (.max_val_p(2*cmd_sfifo_depth_p)
    ,.init_val_p(cmd_sfifo_depth_p)
    ,.max_step_p(1))
  txn_counter
    (.clk_i(ui_clk_i)
     ,.reset_i(ui_clk_sync_rst_i)
     ,.up_i((app_rdy_o & app_en_i))
     ,.down_i((app_wdf_end_i & app_wdf_rdy_o) || (app_rd_data_end_o))
     ,.count_o(txn_cnt)
     );
  assign ui_transaction_in_progress_o = (txn_cnt != cmd_sfifo_depth_p);

  assign dfi_refresh_in_progress_o = (c_cmd == REF);

  assign app_rd_data_valid_o =  rx_piso_valid_lo ;
  assign app_rd_data_o       =  rx_piso_data_lo;
  assign app_rd_data_end_o   =  (rx_piso_valid_lo && (rd_cnt == ui_burst_length_lp - 1));
endmodule

`BSG_ABSTRACT_MODULE(bsg_dmc_controller)
