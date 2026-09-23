#!/bin/bash
# Compare tree-based vs chained gray2bin across widths
cells() { yosys -p "read_verilog $1; chparam -set W $3 $2; hierarchy -top $2; proc; opt; techmap; opt; stat" 2>/dev/null | grep -m1 "Number of cells" | awk '{print $NF}'; }
depth() { yosys -p "read_verilog $1; chparam -set W $3 $2; hierarchy -top $2; proc; opt; techmap; opt; ltp" 2>/dev/null | grep -oP 'length=\K[0-9]+'; }

echo "| W  | tree cells | tree depth | chain cells | chain depth |"
echo "|----|-----------|-----------|------------|------------|"
for W in 4 8 16 32 64; do
  tc=$(cells rtl/gray2bin.v       gray2bin       $W)
  td=$(depth rtl/gray2bin.v       gray2bin       $W)
  cc=$(cells rtl/gray2bin_chain.v gray2bin_chain $W)
  cd=$(depth rtl/gray2bin_chain.v gray2bin_chain $W)
  printf "| %-2s | %9s | %9s | %10s | %10s |\n" $W $tc $td $cc $cd
done
