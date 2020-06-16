#
#   gather_stat.py
# 

import sys
import json



class GatherStat:

  simv_int_stat = ["num_cache_group_p", "num_subcache_p", "block_size_in_words_p", "dma_data_width_p"]
  simv_float_stat = ["bandwidth", "peak_bandwidth_pct"]
  dramsim3_stat = ["num_act_cmds", "num_pre_cmds", "num_ref_cmds",
    "num_reads_done", "num_read_row_hits",
    "num_writes_done", "num_write_row_hits"]
  calculated_stat = ["read_row_hit_pct", "write_row_hit_pct"]

  # default constructor
  def __init__(self):
    self.stat = {}

  # parse simv.log
  def parse_simv_log(self, filepath):
    with open(filepath, "r") as f:
      lines = f.readlines()
      for line in lines:
        for stat in self.simv_int_stat:
          if line.startswith(stat):
            words = line.split("=")
            self.stat[stat] = int(words[1])
        for stat in self.simv_float_stat:
          if line.startswith(stat):
            words = line.split("=")
            self.stat[stat] = float(words[1])

  # parse dramsim3.json
  def parse_dramsim3_json(self, filepath):
    with open(filepath, "r") as f:
      j = json.load(f)
      for stat in self.dramsim3_stat:
        self.stat[stat] = j["0"][stat]

  # calculate generated stat
  def calculate_stat(self):
    if self.stat["num_reads_done"] == 0:
      self.stat["read_row_hit_pct"] = 0.0
    else:
      self.stat["read_row_hit_pct"] = self.stat["num_read_row_hits"] / self.stat["num_reads_done"] * 100.0

    if self.stat["num_writes_done"] == 0:
      self.stat["write_row_hit_pct"] = 0.0
    else:
      self.stat["write_row_hit_pct"] = self.stat["num_write_row_hits"] / self.stat["num_writes_done"] * 100.0

  # return stat object.
  def get_stat(self):
    return self.stat

  # get all stat
  def get_all_stats(self):
    return ["trace"] + self.simv_int_stat + self.simv_float_stat + self.dramsim3_stat + self.calculated_stat

  # set trace
  def set_trace(self, trace):
    self.stat["trace"] = trace
  

  # print csv header
  def print_csv_header(self):
    print(",".join(self.get_all_stats()))
 
  # print csv data
  def print_csv_data(self):
    all_data = map(lambda x: str(self.stat[x]), self.get_all_stats())
    print(",".join(all_data))

if __name__ == "__main__":
  gs = GatherStat()

  # 0 = header
  # 1 = parse and data
  if sys.argv[1] == "0":
    gs.print_csv_header()
  else:
    gs.set_trace(sys.argv[2])
    gs.parse_simv_log(sys.argv[3])
    gs.parse_dramsim3_json(sys.argv[4])
    gs.calculate_stat()
    gs.print_csv_data()

