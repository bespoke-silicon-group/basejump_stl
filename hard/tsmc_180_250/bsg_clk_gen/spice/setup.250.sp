
.lib '/gro/cad/mosis/pdk/tsmc/cl025g/spice/fp1/hspice/logic025.l' TT
.include '/gro/cad/arm250/pdk/tsmc/cl025g/fb/std_cells/Rev_2008q2v3/aci/sc/lvs_netlist/tsmc25.cdl'
.temp 25C

.malias pch P
.malias nch N

.param supply=2.5

v1 vdd 0 supply
v0 vss 0 0
