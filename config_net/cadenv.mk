# Set up environment
export SYNOPSYS=/gro/cad/synopsys
export LM_LICENSE_FILE=27000@bbfs-00.calit2.net
export SNPSLMD_LICENSE_FILE=27000@bbfs-00.calit2.net
export VCS_RELEASE=vcs/F-2011.12
export DC_RELEASE=syn/F-2011.09-SP5
export MW_RELEASE=mw/F-2011.09-SP5
export ICC_RELEASE=icc/F-2011.09-SP5
export PTS_RELEASE=pts/F-2011.12-SP3

export VCS_BIN=$(SYNOPSYS)/$(VCS_RELEASE)/bin
export DC_BIN=$(SYNOPSYS)/$(DC_RELEASE)/bin
export MW_BIN=$(SYNOPSYS)/$(MW_RELEASE)/bin/AMD.64
export ICC_BIN=$(SYNOPSYS)/$(ICC_RELEASE)/bin
export PTS_BIN=$(SYNOPSYS)/$(PTS_RELEASE)/bin
export PATH:=$(DC_BIN):$(VCS_BIN):$(PATH)

export VCS_HOME=$(SYNOPSYS)/$(VCS_RELEASE)
export VCS=$(VCS_BIN)/vcs
export DC=$(DC_BIN)/dc_shell
export MW=$(MW_BIN)/Milkyway
export ICC=$(ICC_BIN)/icc_shell
export PTS=$(PTS_BIN)/pt_shell

# Disable warning about CentOS
export VCS_ARCH_OVERRIDE=linux

# VCS FLAGS
# +vcs+lic+wait                          - Wait for a license rather than exit immediately
# -sverilog                              - Allow SystemVerilog code
# +v2k                                   - Allow features from IEEE 1364-2001 standard
# +lint=all                              - Print warning messages
# -v filename                            - Specify a library file
# -y dirname                             - Specify a library directory
# +libext+<ext>+                         - Specify file extensions (separated by + characters) for libary directory search
# -timescale=<unit>/<precision>          - Time values specified are in terms of <unit>, and delays are rounded to <precision>
# -override_timescale=<unit>/<precision> - Overrides the timescale specified in any source file (be careful)
# +evalorder                             - Change the way in which VCS evaluates the combinational and behavioral event queues
# -race                                  - Might be used to find race conditions (undocumented); also see "raced"
# -timopt+<clock_period>                 - Unclear; supposed to help speed up simulation time
# -full64                                - Run in 64-bit mode
# -gui                                   - Start Discovery Visual Environment (DVE)
# -parallel                              - Enable multicore compilation
# -debug_pp, -debug, -debug_all          - Various debugging modes

