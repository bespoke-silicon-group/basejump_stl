/**
 *  mock_dram_ctrl.v
 */

module mock_dram_ctrl
  import bsg_dram_ctrl_pkg::*;
  #(parameter addr_width_p="inv"
    ,parameter data_width_p="inv"
    ,parameter burst_len_p="inv"
    ,parameter mem_size_p="inv"
    ,parameter lg_mem_size_lp=`BSG_SAFE_CLOG2(mem_size_p)
    ,parameter lg_burst_len_lp=`BSG_SAFE_CLOG2(burst_len_p)
    ,parameter mask_width_lp=data_width_p>>3)
(
  input clk_i
  ,input reset_i

  ,input app_en_i
  ,output logic app_rdy_o
  ,input app_hi_pri_i
  ,input eAppCmd app_cmd_i
  ,input [addr_width_p-1:0] app_addr_i

  ,input app_wdf_wren_i
  ,output logic app_wdf_rdy_o
  ,input [data_width_p-1:0] app_wdf_data_i
  ,input [(data_width_p>>3)-1:0] app_wdf_mask_i
  ,input app_wdf_end_i

  ,output logic app_rd_data_valid_o
  ,output logic [data_width_p-1:0] app_rd_data_o
  ,output logic app_rd_data_end_o

  ,input app_ref_req_i
  ,output logic app_ref_ack_o

  ,input app_zq_req_i
  ,output logic app_zq_ack_o
  ,output logic init_calib_complete_o

  ,input app_sr_req_i
  ,output logic app_sr_ack_o
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
  assign wr_req_valid = app_en_i & (app_cmd_i == eAppWrite);
  assign rd_req_valid = app_en_i & (app_cmd_i == eAppRead);

  assign app_rdy_o = app_en_i & (
    ((app_cmd_i == eAppWrite) & (wr_state_r == IDLE))
    | ((app_cmd_i == eAppRead) & (rd_state_r == IDLE))
  );

  assign app_rd_data_o = mem[rd_addr_r];

  assign app_zq_ack_o = 1'b0;
  assign app_ref_ack_o = 1'b0;
  assign init_calib_complete_o = 1'b0;
  assign app_sr_ack_o = 1'b0;

  always_comb begin
    case (wr_state_r)
      IDLE: begin
        app_wdf_rdy_o = 1'b0;
        wr_state_n = wr_req_valid ? BUSY : IDLE;
        wr_addr_n = wr_req_valid
          ? app_addr_i[`BSG_SAFE_CLOG2(data_width_p/8)+:lg_mem_size_lp]
          : wr_addr_r;
        wr_cnt_n = wr_req_valid ? '0 : wr_cnt_r;
        
      end

      BUSY: begin
        app_wdf_rdy_o = 1'b1;
        wr_state_n = app_wdf_wren_i & app_wdf_end_i
          ? IDLE : BUSY;
        wr_addr_n = app_wdf_wren_i
          ? wr_addr_r + 1
          : wr_addr_r;
        wr_cnt_n = app_wdf_wren_i
          ? wr_cnt_r + 1
          : wr_cnt_n;
      end
    endcase

    case (rd_state_r)
      IDLE: begin
        app_rd_data_valid_o = 1'b0;
        app_rd_data_end_o = 1'b0;
        rd_state_n = rd_req_valid ? BUSY : IDLE;
        rd_addr_n = rd_req_valid 
          ? app_addr_i[`BSG_SAFE_CLOG2(data_width_p/8)+:lg_mem_size_lp]
          : rd_addr_r;
        rd_cnt_n = rd_req_valid ? 0 : wr_cnt_r;
      end
      
      BUSY: begin
        app_rd_data_valid_o = 1'b1;
        app_rd_data_end_o = (rd_cnt_r == (burst_len_p-1));
        rd_state_n = (rd_cnt_r == (burst_len_p-1)) ? IDLE : BUSY;
        rd_addr_n = rd_addr_r + 1;
        rd_cnt_n = rd_cnt_r + 1;
      end
    endcase
  end

  always_ff @ (posedge clk_i) begin
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

      if ((wr_state_r == BUSY) & app_wdf_wren_i) begin
        for (int i = 0; i < mask_width_lp; i++) begin
          if (~app_wdf_mask_i[i]) begin /* WARNING: ACTIVE LOW!!!!! */
            mem[wr_addr_r][8*i+:8] <= app_wdf_data_i[8*i+:8];
          end
        end
      end
    end
  end

endmodule
