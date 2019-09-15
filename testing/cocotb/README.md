# Basejump STL Cocotb Testing

This directory contains unit tests using the cocotb testing infrastructure.
**Note**: this is currently just a sample as we evaluate various testing
infrastructures and strategies. Inside this directory are unit tests for some
of the basejump_stl modules which mirror the repository's root directory
structure. There is also a `common/` directory that contains some code to
simplify the makefile infrastructure used to drive the cocotb testbenches.

## Tempalte Files

Inside `common/template/` exists some files that can be used as a starting
point for creating a branch new cocotb testbench. Simply create the directory
for your new testbench and copy all of the files inside `common/template/` to
  your new testbench and modify as needed. The files inside `common/template/`
  include the following:

1. `Makefile` - Main makefile framework. Inside this file are a few empty
   variables that need to be filled in. Once completed, that should be it for
   the infrastructure, the user just needs to implement the actual testbench
   python script.
2. `test_bsg.py` - Sample cocotb testbench script. Has an "always pass" and
   "always fail" test case to make sure that everything is working. Should be
   modified to get rid of those two test cases and add real tests that actually
   test the design.
3. `README.md` - A generic readme that explains how to add and run tests using
   the generic infrastructure. This includes target names and some features
   used to control which tests get executed. This is inteneded to live in every
   testing directory as a reminder for how to actually execute tests.

## Useful Links

1. [Cocotb Documentation](https://cocotb.readthedocs.io/en/latest/introduction.html)
2. [Cocotb Github](https://github.com/cocotb/cocotb)
