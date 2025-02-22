#!/usr/bin/env python2
"""
profile_analyzer.py

Post-processes the output of bsg_nonsynth_profiler.sv

A Python 2.7 script that:
  1) Parses a schema file (profile.schema) to define category groups.
  2) Reads profile.names, which has lines of <counter_number> <hierarchical_path>.
     Ensures counter_number increments by 1 from 0 up to N-1 with no skips.
  3) Reads binary data from profile.dat (unsigned 32-bit little-endian),
     organized in frames of N counters (one integer per counter).
  4) Accumulates sums for each category (based on regex matches) per frame.
  5) Plots one stacked-bar subplot per category group, titled by the group name
     following each "@" line in the schema, with categories stacked in the order
     they appear in the schema.
  6) Optionally saves the plot to an png/pdf file via --output=filename
     or shows the interactive plot window if --output is not provided.

Usage example:
  python2 profile_analyzer.py \
      --schema=profile.schema \
      --names=profile.names \
      --data=profile.dat \
      [--debug_mapping] \
      [--debug_data] \
      [--output=plot.pdf] [--output=plot.png]

Requires:
  - matplotlib (install via pip)
  - re (standard library)
  - struct (standard library)
  - argparse (bundled in Python 2.7+)


* Generated via ChatGPT o1 using the following prompt:

Generate a python 2.7 program as follows:

The python program takes in three files, profile.dat, profile.names, and profile.schema. profile.names is a series of lines, where each line has an event counter number and a systemverilog hierarchical path, which are separated by a space.  profile.dat is a series of raw 32-bit integers. it is organized as frames, which contain one 32-bit integer for each event counter number. Each integer corresponds to how many times that event happened during a certain time range. Each frame corresponds one cycle count for each event counter that is in the profile.names file. The profile.schema file contains a number of lines. Each line contains a category name,  a color, and a list of regular expressions. Occasionally a line will consist solely of an "@" sign which designates the end of a category group that will be used for a single graph plot. The python program will perform the following processing:

Parse the profile.schema file.  Iterate through the profile.names file line by line, and build a list for each category in the profile.schema file of the event counter numbers of the hierarchical paths that match one of the regexps in the profile.schema file. If an optional flag is set, print out each category and the list of event counters and systemverilog hierarchical paths that correspond to the category. Then, read in the profile.dat file, and for each category, generate an array, indexed by frame, of counts for each category of event counter numbers, each count summing across the matching event counters for that category within that frame. If an optional flag is set, print out these arrays.  Then, using a plotting library available via pip, in standard python 2.7, generate a series of vertically aligned stacked bar graphs. Each bar graph will plot the data from the categories that belong to a category group. The order of the stacking of categories will match the order in the profile.schema. The category name will be used to label the category, and the label and the plotted data will use the color specified in the profile.schema file. The bar graphs will be aligned so that you can easily compare across the category groups data that is in the same frame. There should be no horizontal gap between different frames in the graph. Feel free to ask any clarifying questions before outputting the final code.

* Then it asked a set of questions to which the response was:

1. unsigned, little endian
2. correct
3.  white space separated
4. entire path
5a. in order, unsigned int, but output an error if it is not in order, or if a counter number was skipped
5b.  I would rely on the integer label when reading from profile.dat, to simplify the code
6a. legend on each subplot
6b. tick labels are okay
Please revise the above specification that after the @ sign terminates a category group is the name of the category group which is used to a title for the category group in the graph

* Then I said:

Great, go ahead and generate the code.

* I further asked it to create an example profile.schema with this prompt:

In my profile.name file, I have strings that look like testbench.ctr[44].ctr.u_bind_suff or testbench.ctr[0].ctr.u_bind_suff . I want to define a profile.schema file that has a categories of 10 counters, and category groups of every sets of 3 categories. There are 100 counters. How would I write that schema file? 

* Then I said:

modify so that it outputs either pdf or an image file, based on the command line parameter.


* See testing/bsg_test/bsg_nonsynth_profiler for an example of a complete test that uses this infrastructure

"""

import sys
import os
import argparse
import re
import struct
import matplotlib
import matplotlib.pyplot as plt

def parse_schema(schema_file):
    """
    Parse the profile.schema file.
    Returns a list of 'groups'. Each group is a dict with:
      {
        'title': <string>,
        'categories': [
            {
              'name': <category_name>,
              'color': <color_string>,
              'regexes': [list_of_compiled_regex_objects],
              'counters': []  # to be filled in later
            },
            ...
        ]
      }
    """
    groups = []
    current_group = {
        'title': None,
        'categories': []
    }

    with open(schema_file, 'r') as sf:
        for line in sf:
            line = line.strip()
            if not line:
                continue  # Skip empty lines

            # Check if line starts with '@'
            if line.startswith('@'):
                # Format: "@ <group_title>"
                parts = line.split(None, 1)
                if len(parts) < 2:
                    sys.stderr.write(
                        "Error: Found '@' line with no group title.\n"
                    )
                    sys.exit(1)
                group_title = parts[1].strip()

                # Close out the current group
                current_group['title'] = group_title
                groups.append(current_group)

                # Start a new group structure
                current_group = {
                    'title': None,
                    'categories': []
                }
            else:
                # Normal category line: <category_name> <color> <regex1> <regex2> ...
                parts = line.split()
                if len(parts) < 3:
                    sys.stderr.write(
                        "Error: Invalid category line. Needs at least 3 tokens.\n"
                        "Line was: {}\n".format(line)
                    )
                    sys.exit(1)

                cat_name = parts[0]
                cat_color = parts[1]
                raw_patterns = parts[2:]

                compiled_regexes = []
                for pat in raw_patterns:
                    # Force full-match by wrapping with ^(...)$
                    pattern_full = "^(" + pat + ")$"
                    compiled_regexes.append(re.compile(pattern_full))

                category = {
                    'name': cat_name,
                    'color': cat_color,
                    'regexes': compiled_regexes,
                    'counters': []
                }
                current_group['categories'].append(category)

    # If the schema didn't end with an '@' line, we might have leftover categories
    # with no group title. We'll ignore them (warn).
    if current_group['categories']:
        sys.stderr.write(
            "Warning: The schema file ended without an '@ <group_title>' line.\n"
            "The last set of categories will be ignored.\n"
        )

    return groups


def parse_names(names_file):
    """
    Parse profile.names, returning a list of (counter_number, hierarchical_path).
    The list index must match the counter_number, checking increments from 0..N-1.
    """
    counters = []
    expected_counter = 0

    with open(names_file, 'r') as nf:
        for line in nf:
            line = line.strip()
            if not line:
                continue

            parts = line.split(None, 1)
            if len(parts) != 2:
                sys.stderr.write(
                    "Error: Each line of profile.names must have 2 tokens.\n"
                    "Invalid line: {}\n".format(line)
                )
                sys.exit(1)

            try:
                counter_num = int(parts[0])
            except ValueError:
                sys.stderr.write(
                    "Error: First token in profile.names is not an integer.\n"
                    "Line: {}\n".format(line)
                )
                sys.exit(1)

            hier_path = parts[1]
            # Ensure strictly increasing from 0..N-1
            if counter_num != expected_counter:
                sys.stderr.write(
                    "Error: Expected counter number {}, but got {}.\nLine: {}\n"
                    .format(expected_counter, counter_num, line)
                )
                sys.exit(1)

            counters.append((counter_num, hier_path))
            expected_counter += 1

    return counters


def associate_counters_with_categories(groups, counters, debug_mapping=False):
    """
    For each category in each group, find all counters from 'counters'
    whose hierarchical_path fully matches any regex in that category.
    """
    # Initialize counters list
    for g in groups:
        for cat in g['categories']:
            cat['counters'] = []

    # Check each counter against each category's regex
    for (counter_num, hier_path) in counters:
        for g in groups:
            for cat in g['categories']:
                for regx in cat['regexes']:
                    if regx.match(hier_path):
                        cat['counters'].append(counter_num)
                        # Once matched, no need to check other regexes in this category
                        break

    if debug_mapping:
        print("=== Category to Counters Mapping ===")
        for g in groups:
            print("Group Title: {}".format(g['title']))
            for cat in g['categories']:
                print("  Category: {}".format(cat['name']))
                for cnum in cat['counters']:
                    _, path = counters[cnum]
                    print("    - Counter {} => {}".format(cnum, path))
        print("====================================\n")


def read_profile_dat(data_file, num_counters):
    """
    Reads the profile.dat file (unsigned 32-bit, little-endian).
    Returns a list of frames, each frame a list of num_counters counts.
    """
    frames = []
    record_size = 4 * num_counters

    with open(data_file, 'rb') as df:
        while True:
            chunk = df.read(record_size)
            if not chunk:
                # Reached EOF
                break
            if len(chunk) < record_size:
                sys.stderr.write(
                    "Warning: profile.dat ended in a partial frame. "
                    "Ignoring incomplete data.\n"
                )
                break

            # Unpack into 32-bit unsigned ints (little-endian)
            frame_values = []
            for i in range(num_counters):
                val = struct.unpack_from('<I', chunk, offset=i*4)[0]
                frame_values.append(val)

            frames.append(frame_values)

    return frames


def accumulate_category_data(groups, frames, debug_data=False):
    """
    For each category in each group, compute sum of counters for each frame,
    storing an array in cat['data'].
    """
    num_frames = len(frames)
    # Initialize cat['data']
    for g in groups:
        for cat in g['categories']:
            cat['data'] = [0] * num_frames

    for f_idx, frame_vals in enumerate(frames):
        for g in groups:
            for cat in g['categories']:
                # sum up relevant counters
                total = 0
                for cnum in cat['counters']:
                    total += frame_vals[cnum]
                cat['data'][f_idx] = total

    if debug_data:
        print("=== Per-Frame Category Sums ===")
        for g in groups:
            print("Group Title: {}".format(g['title']))
            for cat in g['categories']:
                print("  Category: {}".format(cat['name']))
                print("    Data: {}".format(cat['data']))
        print("================================\n")


def plot_stacked_bars(groups):
    """
    Generate stacked bar charts in one figure.
    One subplot per group (vertical stack), with group['title'] as subplot title.
    """
    num_groups = len(groups)

    # Create subplots
    fig, axes = plt.subplots(num_groups, 1, sharex=True, figsize=(10, 3 * num_groups))
    # If there's only one group, axes is not a list
    if num_groups == 1:
        axes = [axes]

    for g_idx, group in enumerate(groups):
        ax = axes[g_idx]
        if not group['categories']:
            # If the group has no categories (possibly an empty group), skip
            ax.set_title(group['title'] + " (No Categories)")
            continue

        # We'll stack bars for each frame
        num_frames = len(group['categories'][0]['data'])
        x_indices = range(num_frames)
        bottoms = [0] * num_frames

        for cat in group['categories']:
            cat_data = cat['data']
            ax.bar(
                x_indices,
                cat_data,
                bottom=bottoms,
                color=cat['color'],
                label=cat['name'],
                linewidth=0
            )
            # Update bottoms
            for i in range(num_frames):
                bottoms[i] += cat_data[i]

        ax.set_title(group['title'])
        ax.legend(loc='upper right')
        ax.set_ylabel("Counts")
        ax.set_xticks(x_indices)
        ax.set_xlabel("Frame Index")

    plt.tight_layout()
    # Removed plt.show() here. We'll either save or show in main().


def main():
    parser = argparse.ArgumentParser(description="Profile Data Analyzer for Python 2.7")
    parser.add_argument("--schema", required=True, help="Path to profile.schema")
    parser.add_argument("--names", required=True, help="Path to profile.names")
    parser.add_argument("--data", required=True, help="Path to profile.dat")
    parser.add_argument("--debug_mapping", action="store_true",
                        help="Print debug info about which counters match which categories.")
    parser.add_argument("--debug_data", action="store_true",
                        help="Print debug info about accumulated data arrays.")
    parser.add_argument("--output", default=None,
                        help="Output filename (e.g. 'plot.pdf' or 'plot.png'). "
                             "If not set, an interactive window will be shown.")

    args = parser.parse_args()

    # 1) Parse schema
    groups = parse_schema(args.schema)
    if not groups:
        sys.stderr.write("Error: No valid category groups found in schema. Exiting.\n")
        sys.exit(1)

    # 2) Parse names
    counters = parse_names(args.names)
    if not counters:
        sys.stderr.write("Error: No counters found in profile.names. Exiting.\n")
        sys.exit(1)

    # 3) Associate counters with categories
    associate_counters_with_categories(groups, counters, debug_mapping=args.debug_mapping)

    # 4) Read profile.dat
    frames = read_profile_dat(args.data, num_counters=len(counters))
    if not frames:
        sys.stderr.write("Warning: No frames read from profile.dat. The resulting plot will be empty.\n")

    # 5) Accumulate data
    accumulate_category_data(groups, frames, debug_data=args.debug_data)

    print("Generating plot..");

    # 6) Plot
    plot_stacked_bars(groups)

    print("Saving plot..");

    # 7) Either save or show
    if args.output:
        plt.savefig(args.output, bbox_inches='tight')
        print("Plot saved to '{}'".format(args.output))
    else:
        plt.show()


if __name__ == "__main__":
    main()
