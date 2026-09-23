# Days 2-3 — Gray Code Converters

Binary-to-Gray and Gray-to-binary, parameterised by width. Two designs that look
equally trivial in RTL and behave completely differently in hardware.

## Why Gray code exists

In binary, incrementing 3 -> 4 flips every bit: `011` -> `100`. Bits do not arrive
simultaneously in real hardware — wires differ in length and delay — so a reader in
another clock domain sampling mid-transition may see `111` (7) or `000` (0). Values
the counter was never at.

Gray code guarantees **exactly one bit changes per increment**, so a mid-transition
sample yields either the old value or the new one. Never garbage. This is why
asynchronous FIFO pointers are Gray-coded.

## Designs

**bin2gray** — each output bit needs two adjacent input bits:

```verilog
assign gray = bin ^ (bin >> 1);
```

**gray2bin (tree)** — each output bit is the parity of all higher input bits:

```verilog
assign bin[i] = ^(gray >> i);
```

**gray2bin (chain)** — mathematically identical, structurally opposite:

```verilog
assign bin[i] = bin[i+1] ^ gray[i];
```

The chained form takes the answer one position up and XORs in one more bit, which
creates a dependency: `bin[0]` waits on `bin[1]`, which waits on `bin[2]`.

## Measurements

Yosys 0.52, generic gate mapping (`proc; opt; techmap; opt`). Every cell in every
configuration is `$_XOR_`.

### bin2gray — width is free

| W | cells | depth |
|----|-------|-------|
| 4 | 3 | 1 |
| 8 | 7 | 1 |
| 16 | 15 | 1 |
| 32 | 31 | 1 |
| 64 | 63 | 1 |

**Depth stays at 1 regardless of width.** Each output bit needs only `bin[i]` and
`bin[i+1]`, so all W-1 XORs evaluate in parallel. A 1024-bit converter would still be
depth 1.

### gray2bin — tree vs chain

| W | tree cells | tree depth | chain cells | chain depth |
|----|-----------|-----------|------------|------------|
| 4 | 5 | 2 | 3 | 3 |
| 8 | 17 | 3 | 7 | 7 |
| 16 | 49 | 4 | 15 | 15 |
| 32 | 129 | 5 | 31 | 31 |
| 64 | **321** | **6** | **63** | **63** |

Tree depth is exactly **log2(W)**. Chain depth is exactly **W-1**.

At W=64 the tree costs **5.1x the area** to achieve **10.5x the speed**. At W=4 the
tree is worse on both counts — more cells for barely less depth. The crossover is
around W=8.

### What Yosys did with the tree version

`bin[0]` is the XOR of all 64 Gray bits, and an XOR gate takes two inputs. So the
reduction becomes a balanced tree: 64 -> 32 -> 16 -> 8 -> 4 -> 2 -> 1, six levels.

A separate tree per output bit would cost roughly 2016 cells. Yosys produced **321**,
because `bin[0]` XORs bits 0-63, `bin[1]` XORs bits 1-63, and so on — the trees share
almost all their structure, and `opt` computed the common subtrees once.

That is a **parallel prefix** network, structurally the same idea as a Kogge-Stone or
Brent-Kung adder. Yosys derived it from a reduction operator without being told to.

## Verification

Exhaustive over all 256 values at W=8, three independent checks:

| Check | What it catches |
|-------|-----------------|
| `gray2bin(bin2gray(x)) == x` | round-trip identity |
| encoder vs golden model | encoder-specific errors |
| adjacent codes differ by exactly 1 bit | **the property that makes Gray code useful** |

The first two are weaker than they appear. Round-trip passes for *any* bijection
composed with its inverse — two consistently-wrong modules would both pass. The golden
model is written with the same operators as the RTL, so a shared misunderstanding
would go undetected.

The adjacency check is the real one: it tests the property the design exists to
provide, independent of how either module is implemented. For an async FIFO pointer
this is the only check that matters — get it wrong and you have a metastability bug
that surfaces once every few hours in silicon.

## Takeaway

Two one-line designs, both "just XORs." One has a critical path that never grows with
width. The other's grows as log2(W), and costs 5x the area to stay that short — or W-1
if you write it the other way.

None of this is visible in the source. `^(gray >> i)` and `bin[i+1] ^ gray[i]` are the
same function and a 10x difference in critical path.

## Reproducing

```bash
iverilog -g2012 -o sim/gray.out rtl/bin2gray.v rtl/gray2bin.v tb/tb_gray.v && vvp sim/gray.out
./synth/sweep.sh
```
