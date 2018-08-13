module mock_dram_ctrl
  import bsg_dram_ctrl_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter burst_len_p="inv"
    ,parameter mem_size_p="inv"
    ,parameter lg_mem_size_lp=`BSG_SAFE_CLOG2(mem_size_p)
    ,parameter lg_burst_len_lp=`BSG_SAFE_CLOG2(burst_len_p)
    ,parameter mask_width_lp=data_width_p/8)
(
  input clock_i
  ,input reset_i
  ,bsg_dram_ctrl_if.slave dram_ctrl_if
);

  typedef enum logic {
    IDLE = 1'b0
    ,BUSY = 1'b1
  } ch_state_e;

  logic [mem_size_p-1:0][data_width_p-1:0] mem;  

  logic wr_state_r, wr_state_n;
  logic [lg_mem_size_lp-1:0] wr_addr_r, wr_addr_n;
  logic [lg_burst_len_lp-1:0] wr_cnt_r, wr_cnt_n;

  logic rd_state_r, rd_state_n;
  logic [lg_mem_size_lp-1:0] rd_addr_r, rd_addr_n;
  logic [lg_burst_len_lp-1:0] rd_cnt_r, rd_cnt_n;

  logic wr_req_valid;
  logic rd_req_valid;
  assign wr_req_valid = dram_ctrl_if.app_en & (dram_ctrl_if.app_cmd == eAppWrite);
  assign rd_req_valid = dram_ctrl_if.app_en & (dram_ctrl_if.app_cmd == eAppRead);

  assign dram_ctrl_if.app_rdy = dram_ctrl_if.app_en & (
    ((dram_ctrl_if.app_cmd == eAppWrite) & (wr_state_r == IDLE))
    | ((dram_ctrl_if.app_cmd == eAppRead) & (rd_state_r == IDLE))
  );

  assign dram_ctrl_if.app_rd_data = mem[rd_addr_r];

  assign dram_ctrl_if.app_zq_ack = 1'b0;
  assign dram_ctrl_if.app_ref_ack = 1'b0;
  assign dram_ctrl_if.init_calib_complete = 1'b0;
  assign dram_ctrl_if.app_sr_ack = 1'b0;

  always_comb begin
    case (wr_state_r)
      IDLE: begin
        dram_ctrl_if.app_wdf_rdy = 1'b0;
        wr_state_n = wr_req_valid ? BUSY : IDLE;
        wr_addr_n = wr_req_valid
          ? dram_ctrl_if.app_addr[`BSG_SAFE_CLOG2(data_width_p/8)+:lg_mem_size_lp]
          : wr_addr_r;
        wr_cnt_n = wr_req_valid ? '0 : wr_cnt_r;
        
      end

      BUSY: begin
        dram_ctrl_if.app_wdf_rdy = 1'b1;
        wr_state_n = dram_ctrl_if.app_wdf_wren & dram_ctrl_if.app_wdf_end
          ? IDLE : BUSY;
        wr_addr_n = dram_ctrl_if.app_wdf_wren
          ? wr_addr_r + 1
          : wr_addr_r;
        wr_cnt_n = dram_ctrl_if.app_wdf_wren
          ? wr_cnt_r + 1
          : wr_cnt_n;
      end
    endcase

    case (rd_state_r)
      IDLE: begin
        dram_ctrl_if.app_rd_data_valid = 1'b0;
        dram_ctrl_if.app_rd_data_end = 1'b0;
        rd_state_n = rd_req_valid ? BUSY : IDLE;
        rd_addr_n = rd_req_valid 
          ? dram_ctrl_if.app_addr[`BSG_SAFE_CLOG2(data_width_p/8)+:lg_mem_size_lp]
          : rd_addr_r;
        rd_cnt_n = rd_req_valid ? 0 : wr_cnt_r;
      end
      
      BUSY: begin
        dram_ctrl_if.app_rd_data_valid = 1'b1;
        dram_ctrl_if.app_rd_data_end = (rd_cnt_r == (burst_len_p-1));
        rd_state_n = (rd_cnt_r == (burst_len_p-1)) ? IDLE : BUSY;
        rd_addr_n = rd_addr_r + 1;
        rd_cnt_n = rd_cnt_r + 1;
      end
    endcase
  end

  always_ff @ (posedge clock_i) begin
    if (reset_i) begin
      wr_state_r <= IDLE;
      wr_addr_r <= '0;
      wr_cnt_r <= '0;

      rd_state_r <= IDLE;
      rd_addr_r <= '0;
      rd_cnt_r <= '0;

      for (int i = 0; i < mem_size_p; i++) begin
        mem[i] <= 0;
      end

    end
    else begin
      wr_state_r <= wr_state_n;
      wr_addr_r <= wr_addr_n;
      wr_cnt_r <= wr_cnt_n;
  
      rd_state_r <= rd_state_n;
      rd_addr_r <= rd_addr_n;
      rd_cnt_r <= rd_cnt_n;

      if ((wr_state_r == BUSY) & dram_ctrl_if.app_wdf_wren) begin
        for (int i = 0; i < mask_width_lp; i++) begin
          if (~dram_ctrl_if.app_wdf_mask[i]) begin /* WARNING: ACTIVE LOW!!!!! */
            mem[wr_addr_r][8*i+:8] <= dram_ctrl_if.app_wdf_data[8*i+:8];
          end
        end
      end
    end
  end

endmodule
