# BSG Generic Cocotb User Instructions

This testing directory has test cases builting using the BSG generic cocotb
testing infrastructure. This testing infrastructure is built on top of cocotb
and is intended to make it easy to setup and run a cocotb testbench across
multiple parameterizations of the design under test.

The best way to start using this infrastructure is to go into a test that
already exists and start poking around! A good starting place is
`testing/cocotb/bsg_misc/bsg_and` which tests a simple AND gate modules.

## Configuration File

Each test case has a JSON configuration file. This configuration file sets up
the design for testing.

### JSON Configuration Fields

`toplevel` - Name of the toplevel module to test.

`test_modules` - List of python modules to run the test suite.

`filelist` - List of RTL files for the design.

`include` - List of directories to search for include files.

`psweep` - List of parameterizations. Each parameterization has an optional
'name' key as well as a collection of key:value pairs to override parameters.

### Example Configuration File

```
{
    # Name of the toplevel module to test.
    "toplevel": "bsg_and",

    # List of python test modules.
    "test_modules": [ "test_bsg" ],

    # List of RTL files.
    "filelist": [ "bsg_misc/bsg_and.v" ],

    # List of directories to search for include files.
    "include": [ "bsg_misc" ],

    # Parameter sweeps. Each element in the psweep list is a new test run with
    # a different parameterization. The optional key "name" can be used to set
    # the name of the test run with the given parameterization. 
    "psweep": [
        { "name": "w1", "width_p": "1" },
        { "name": "w5", "width_p": "5" },
        { "name": "w8", "width_p": "8" }
    ]
}
```

## Running The Makefile

To run all of the test, simply run:

```
$ make
```

This will go through all parameterizations of the design under test and run all
test cases for each parameterization. You can also specify the `-j#` (where `#`
is a number) when executing the makefile (e.g. `$ make -j4`). This will run the
testbench on `#` parameterizations in parallel.

To clean up the testing directory, simply run:

```
$ make clean
```

This will clean the current directory but will not delete your test runs. To
truly delete everything, run:

```
$ make clean_all
```

### Running a specific parameterization

To run the testbench on a single parameterization, use the following:

```
$ make test.<name>
```

The name comes from the optional 'name' field in the psweep parameterizations.
If no name is specified, a name is created based on the rest of the parameter
value pairs.

The target `$ make test.all` is an alias that is used to run on every
parameterization (what the makefile defaults to).

You can cleanup an individual test as well by using the following:

```
$ make clean.test.<name>
```

There is also a target `$ make clean.test.all` which will clean all
parameterizations (used by `$ make clean_all`).

### Running specific test case(s)

To run a specific set of test cases, use the following:

```
$ make TESTCASE=<cases>
```

Here cases is a comma separated list of all the test cases that you want to
execute. All other test cases will be skipped.

Inside the cocotb testbench python script, you can (and probably will) define
multiple test cases. These are functions that have the `@cocotb.test()`
annotation applied to them. Each of these functions is a test case with the
name of the test case being the name of the function. For example, say you have
the following test cases:

```
@cocotb.test()
def test_one (dut):
    ...

@cocotb.test()
def test_two (dut):
    ...

@cocotb.test()
def test_three (dut):
    ...
```

We can run just `test_one()` by using `$ make TESTCASE=test_one`. If we also
wanted to run `test_three()` we could modify our make command to `$ make
TESTCASE=test_one,test_three`.

### Building and Cleaning External Tools

The makefile should automatically build the external tools required to run a
testbench if they don't exist when you first try and run a testbench; however,
you can still use `$ make build_tools` and `$ make clean_tools` to manually
build or clean (delete) them. All of the testbenches use the same set of
external tools that only need to be built once. These exists in the cocotb
testing `common/` directory.

## Setting up the simulator (VCS)

If you would like to run simulations with VCS, you will need to do a small
amount of setup first. If you have access to `bsg_cadenv` and are running on a
machine that is compatible with `bsg_cadenv` then you can simply put the
`bsg_cadenv` repo in the `testing/cocotb` direcotry and you are good to go!
Otherwise, you can manually set the variable `LM_LICENSE_FILE` to point to the
available license server and the variable `VCS_HOME` to the VCS home directory
(the one with `bin/` in it).

## Creating New Test Cases

Inside `testing/cocotb/common/template/` exists some files that can be used as
a starting point for creating a branch new cocotb testbench. Simply create the
directory for your new testbench and copy all of the files inside
`testing/cocotb/common/template/` to your new testbench and modify as needed.

To write actual testbenches, checkout the [cocotb
documentation](https://cocotb.readthedocs.io/en/latest/introduction.html), it
is really good!

## Useful Links

1. [Cocotb Documentation](https://cocotb.readthedocs.io/en/latest/introduction.html)
2. [Cocotb Source Code](https://github.com/cocotb/cocotb)

## Useful Links

1. [Cocotb Documentation](https://cocotb.readthedocs.io/en/latest/introduction.html)
2. [Cocotb Github](https://github.com/cocotb/cocotb)

