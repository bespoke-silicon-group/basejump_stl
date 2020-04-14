#
#   miss_latency.py
#
import matplotlib.mlab as mlab
import matplotlib.pyplot as plt
from statistics import mode

with open("miss_latency.txt", "r") as f:
  lines = f.readlines()
  bucket = {}
  latencies = []
  for line in lines:
    stripped = line.strip();
    words = stripped.split(",")
    latency = int(words[1])
    latencies.append(latency)
    if latency in bucket:
      bucket[latency] += 1
    else:
      bucket[latency] = 1


  print("mode    = {}".format(mode(latencies)))
  print("average = {}".format(sum(latencies) / float(len(latencies))))
  print("max     = {}".format(max(latencies)))
  print("min     = {}".format(min(latencies)))


  num_bins = 50
  n, bins, patches = plt.hist(latencies, num_bins)
  plt.title("Cache Miss Latency Histogram")
  plt.xlabel("latency")
  plt.ylabel("frequency")
  plt.grid(True)
  plt.show()


  #keys = bucket.keys()
  #keys.sort()

  #for k in keys:
  #  print("".format)
