.option brief=1       $ stops printbak of data file until .END
.option ingold=1      $ specifies the printout data format
.option post=1        $ save sim results: 0=none, 1=binary, 2=ascii, 3="new wave"
.option accurate=1    $ increases the accuracy of RUNLVL to be at least 5
.option nomod=1       $ suppresses device model printout
.option measform=0    $ measurement file format: 0=normal, 1=ssv, 2=hsim, 3=csv
.option autostop      $ stop once all meas statements finish

.lib '/gro/cad/pdk/gf_14/gf/pdk-12LP-V1.0_1.0_Models_HSPICE/Models/HSPICE/models/12LP_Hspice.lib' TT
.include '/gro/cad/pdk/gf_14/bsg/spf/include_IN14LPP_SC7P5T_84CPP_BASE_SSC14SL_FDK_RELV02R00.sp'
.option pre_layout_sw=1 $ Adds parasitic RC estimations for nets

.temp 25C
.param supply=0.8

.global vdd
.global vss

v1 vdd    0 supply
v0 vss    0 0
