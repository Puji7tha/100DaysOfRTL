read_liberty /home/pujitha/pdk/nangate45_slow.lib
read_verilog synth/ALU_top_mapped.v
link_design ALU_top
read_sdc sta/constraints.sdc
puts "\n===== WORST SETUP PATH ====="
report_checks -path_delay max -digits 3
puts "\n===== SUMMARY ====="
report_wns
report_tns
exit
