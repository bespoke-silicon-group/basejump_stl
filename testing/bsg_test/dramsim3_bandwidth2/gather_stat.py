#
#   gather_stat.py
# 

import sys
import json



class GatherStat:

  simv_int_stat = ["num_cache_group_p", "num_subcache_p", "block_size_in_words_p", "dma_data_width_p"]
  simv_float_stat = ["bandwidth", "peak_bandwidth_pct"]
  dramsim3_stat = ["num_act_cmds", "num_pre_cmds", "num_ref_cmds"]

  # default constructor
  def __init__(self):
    self.stat = {}

  # parse simv.log
  def parse_simv_log(self):
    with open("simv.log", "r") as f:
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
  def parse_dramsim3_json(self):
    with open("dramsim3.json", "r") as f:
      j = json.load(f)
      for stat in self.dramsim3_stat:
        self.stat[stat] = j["0"][stat]

  # return stat object.
  def get_stat(self):
    return self.stat

  # print csv header
  def print_csv_header(self):
    all_stats = self.simv_int_stat + self.simv_float_stat + self.dramsim3_stat
    print(",".join(all_stats))
 
  # print csv data
  def print_csv_data(self):
    all_stats = self.simv_int_stat + self.simv_float_stat + self.dramsim3_stat
    all_data = map(lambda x: str(self.stat[x]), all_stats)
    print(",".join(all_data))

if __name__ == "__main__":
  gs = GatherStat()

  # 0 = header
  # 1 = parse and data
  if sys.argv[1] == "0":
    gs.print_csv_header()
  else:
    gs.parse_simv_log()
    gs.parse_dramsim3_json()
    gs.print_csv_data()

