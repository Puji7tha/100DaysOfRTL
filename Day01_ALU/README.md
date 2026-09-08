# Day 1 — 8-bit ALU

A combinational arithmetic logic unit supporting 16 operations, with four status flags.

## Interface

| Port | Width | Dir | Description |
|------|-------|-----|-------------|
| `d0` | 8 | in | first operand |
| `d1` | 8 | in | second operand |
| `sel` | 4 | in | operation select |
| `result` | 9 | out | result (bit 8 holds carry) |
| `zero` | 1 | out | result[7:0] == 0 |
| `carry` | 1 | out | unsigned carry/borrow out |
| `negative` | 1 | out | MSB of the 8-bit result |
| `overflow` | 1 | out | signed overflow on ADD/SUB |

## Operations

| sel | Operation | sel | Operation |
|-----|-----------|-----|-----------|
| 0000 | ADD | 1000 | d0 << 1 |
| 0001 | SUB | 1001 | d1 << 1 |
| 0010 | MUL | 1010 | d0 >> 1 |
| 0011 | DIV (guarded) | 1011 | d1 >> 1 |
| 0100 | AND | 1100 | NOT d0 |
| 0101 | OR | 1101 | ASR d0 |
| 0110 | NAND | 1110 | 2's complement d0 |
| 0111 | NOR | 1111 | XOR |

## Design notes

**9-bit result.** Two 8-bit operands can sum to 510, which needs 9 bits. An 8-bit
result would silently wrap: `255 + 1` would read as 0.

**Context-determined width.** Verilog sizes the entire right-hand expression to the
width of the left-hand side *before* evaluating it. So `result = ~(d0 & d1)` widens
both operands to 9 bits, ANDs, then inverts all nine — corrupting bit 8. Wrapping the
operation as `{1'b0, ~(d0 & d1)}` forces 8-bit evaluation, then prepends the zero.
Applied to every operation that cannot overflow past 8 bits.

**Arithmetic right shift.** `>>>` only sign-extends on a signed operand. Since `d0` is
declared unsigned, plain `d0 >>> 1` behaves identically to `>>`. Fixed with
`$signed(d0) >>> 1`.

**Divide-by-zero.** Unguarded, `a / 0` produces all X's which propagate through the
design. Guarded with a ternary returning 0.

**Carry vs overflow.** The same bits mean different things depending on interpretation.
`127 + 1` produces `10000000`: valid as unsigned 128 (no carry), invalid as signed
(two positives yielding a negative → overflow). Both flags are reported; the consuming
logic decides which matters.

**Known limitation — multiply truncates.** 8x8 needs 16 bits; `result` is 9. `200 * 100`
returns 32 rather than 20000. This is architectural, not a coding error — fixing it
requires either a wider result bus, a separate hi/lo output, or removing MUL from the ALU.

## Verification

Three testbenches, all self-contained:

| File | Strategy | Purpose |
|------|----------|---------|
| `tb_ALU_directed.v` | directed | opcode sweep, adversarial vectors, flag checks |
| `tb_ALU_random.v` | random | 10,000 vectors against a golden reference model |
| `tb_constrained_random.v` | constrained-random | weighted stimulus + hand-rolled coverage bins |

The directed sweep with benign inputs (`d0=12, d1=5`) passed all 16 operations while
three separate bugs remained undetected — the arithmetic shift fix, for instance, is
untestable with a positive operand. Adversarial vectors were required to expose them.

Constraints force `d0` to a boundary value (0/127/128/255) 30% of the time and `d1=0`
20% of the time. Effect on corner coverage over 10,000 vectors:

| Bin | Plain random (expected) | Constrained (measured) |
|-----|------------------------|------------------------|
| `d0 == 255` | ~39 | 777 |
| `d0 == 127` | ~39 | 763 |
| `d1 == 0` | ~39 | 2020 |
| `overflow == 1` | rare | 249 |

## Synthesis

Yosys 0.52, generic gate mapping. Total: **1160 cells, 0 flip-flops** (purely combinational).

| Cell | Count |
|------|-------|
| `$_AND_` | 492 |
| `$_OR_` | 327 |
| `$_XOR_` | 191 |
| `$_NOT_` | 84 |
| `$_MUX_` | 66 |

Per-operator cost, synthesized in isolation:

| Operation | Gates | Relative |
|-----------|-------|----------|
| AND | 8 | 1x |
| ADD | 49 | 6x |
| MUL | 184 | 23x |
| **DIV** | **494** | **62x** |

Divide alone is ~43% of the design. MUL and DIV together are ~58% of the area for 2 of
16 operations. Division resists parallelisation — each compare-and-subtract stage depends
on the previous stage's remainder — so it is both the largest block and the critical path.
This is why production cores implement divide as a multi-cycle iterative unit, or omit it
entirely (ARM Cortex-M0 has no divide instruction).

Notably, `carry` and `negative` cost **zero gates** — Yosys recognised them as aliases for
`result[8]` and `result[7]` and simply renamed the wires. Only `overflow` required real logic.

## Reproducing

```bash
# simulate
iverilog -g2012 -o sim/directed.out    rtl/ALU.v tb/tb_ALU_directed.v    && vvp sim/directed.out
iverilog -g2012 -o sim/random.out      rtl/ALU.v tb/tb_ALU_random.v      && vvp sim/random.out
iverilog -g2012 -o sim/constrained.out rtl/ALU.v tb/tb_constrained_random.v && vvp sim/constrained.out

# waveform
gtkwave sim/alu_directed.vcd &

# synthesize
yosys -s synth/synth.ys
```

## Next steps

- Wrap in input/output registers to enable static timing analysis
- Run OpenSTA to measure the critical path and confirm the divider dominates
- Resolve the multiply truncation

## Critical path analysis

`yosys -p "read_verilog -sv rtl/ALU.v; hierarchy -top ALU; proc; opt; techmap; opt; ltp"`

Longest topological path: **129 gate levels**, starting at `d0[5]` and ending at `zero`.

### Path breakdown

| Segment | Levels | Share |
|---------|--------|-------|
| Divider (9 stages) | ~117 | 91% |
| 16-way `case` multiplexer | ~6 | 5% |
| Zero-flag reduction | ~4 | 3% |

### Why the divider dominates

Steps 2-118 of the path are nine near-identical blocks, each producing one
quotient bit from MSB to LSB:

| Stage | Path step | Output |
|-------|-----------|--------|
| 1 | 11 | `$div.Y[8]` |
| 2 | 24 | `$div.Y[7]` |
| 3 | 38 | `$div.Y[6]` |
| ... | ... | ... |
| 9 | 118 | `$div.Y[0]` |

Each stage is a compare (`$ge`), a Brent-Kung lookahead carry unit (`lcu`), and
logic to select the quotient bit — roughly 13 gate levels. Stages are linked by
`div_mod_u.chaindata`, the running remainder, visible at path steps 12, 25, 39,
53, 66, 79, 92 and 105.

This is textbook long division implemented in gates: compare, conditionally
subtract, record a quotient bit, pass the remainder onward. The stages are
strictly sequential — stage N cannot start until stage N-1's remainder exists.

**Depth scales linearly with operand width.** 8-bit operands give 9 stages
(~129 levels); 16-bit would give ~17 stages (~230 levels). Multiplication does
not have this problem: its partial products resolve in parallel, so it is wide
but shallow.

### Logic depth by operator

Synthesized in isolation:

| Operation | Cells | Depth |
|-----------|-------|-------|
| AND | 8 | ~1 |
| XOR | 8 | ~1 |
| ADD | 49 | ~1 |
| MUL | 184 | ~1 |
| **DIV** | **498** | **17** |

### Consequence

Combinational logic must settle within one clock period regardless of which
operation `sel` selects. A cycle performing a single AND still waits for a clock
period sized by the 129-level divider path. At a nominal ~50 ps per gate level
that is roughly 6.5 ns, or ~155 MHz; without the divider the deepest remaining
path is on the order of 25 levels.

This is why production designs either implement division as a multi-cycle
iterative unit, pipeline it across several stages, or omit it entirely — the
ARM Cortex-M0 has no divide instruction at all.

### Secondary observation

The zero flag adds ~4 levels *after* `result` is computed, because
`(result[7:0] == 8'b0)` requires OR-reducing eight bits. Negligible next to the
divider, but it would become a meaningful fraction of a divider-free design.
