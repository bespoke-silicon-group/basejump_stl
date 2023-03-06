import os
import json
import time, datetime
import argparse
import subprocess
import sys
import re


def main ():
  cwd = os.getcwd()
  pattern = re.compile("^\s*\"[\w]*_p\s*=\s*\d+")
  size_pattern = re.compile("^\s*\"design_size\"\s*:\s*\w*\s*$")
  if size_pattern.match("            \"design_size\":\"medium\","):
    print ("Matched!")
  current_size_description = ""
  for directory in os.listdir("./"):
    if not os.path.isfile(os.path.join(cwd, directory)):
      os.chdir(os.path.join(cwd, directory))
      for file in os.listdir("./"):
        if "micro" not in file and "daily" not in file and os.path.isfile(os.path.join(cwd,directory,file)):
          with open (os.path.join(cwd, directory, file)) as json_file:
            for line in json_file:
              if "design_size" in line:
                current_size_description = re.sub(",", "", re.sub("\"", "", line.split(":")[1]).strip())
              if pattern.match(line) and current_size_description == "medium":
                if int(re.sub("[^0-9]", "", line.split("=")[1].strip())) > 100:
                  print(directory + "/" + file + " uses parameter " + line.split("=")[0].strip() +  " with value " + line.split("=")[1].strip())

if __name__ == '__main__':
  main()
