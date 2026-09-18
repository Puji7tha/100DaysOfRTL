# 100 Days of RTL

One digital design a day, each taken the whole way: **RTL → simulation → verification
→ synthesis → static timing analysis**, entirely in open-source EDA.

Most RTL-a-day repos stop at "it simulates." That's the least interesting question.
This one asks what each design actually costs — in gates, in silicon area, in
nanoseconds — and what stops it running faster.

## Progress

| Day | Project | Cells | Area | Fmax | Finding |
|-----|---------|-------|------|------|---------|
| 01 | [8-bit ALU](Day01_ALU/) | 1193 | 877 µm² | 110 MHz | `/` is 43% of combinational area and sets the critical path for all 16 operations |

*Area and Fmax measured on Nangate45 (slow corner) via Yosys `abc -liberty` and OpenSTA.*

## Toolchain

| Stage | Tool |
|-------|------|
| RTL authoring | VS Code (WSL2 / Ubuntu) |
| Simulation | Icarus Verilog, Verilator |
| Waveforms | GTKWave |
| Synthesis | Yosys + ABC |
| Static timing | OpenSTA |
| Physical design | OpenROAD |
| Libraries | Nangate45, Sky130 |

## Method

Each project follows the same structure:

    DayNN_Name/
    ├── rtl/      design under test
    ├── tb/       testbenches — directed, random, constrained-random
    ├── sim/      simulation outputs (gitignored)
    ├── synth/    Yosys scripts and reports
    ├── sta/      SDC constraints and OpenSTA scripts
    └── README.md findings, measurements, and how to reproduce them

Three things I try to do on every design:

**Predict before measuring.** Writing down the wrong guess is more useful than
recording only the right answer. On Day 1 I expected multiplication to dominate the
area — it was division, by nearly 3x.

**Test adversarially.** A directed sweep of the Day 1 ALU with `d0=12, d1=5` passed
all sixteen operations while three real bugs sat undetected. Benign inputs prove
nothing.

**Make every number reproducible.** Commands are in each project README. Run them and
check me.

## Reproducing

    sudo apt install -y iverilog gtkwave yosys verilator opensta

A Liberty file is needed for area and timing. These projects use
`nangate45_slow.lib` from the OpenSTA examples. Paths in the synthesis and STA
scripts are absolute and will need adjusting.

---

