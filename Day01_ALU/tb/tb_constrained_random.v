`timescale 1ns/1ps

module tb_constrained_random;

    reg  [7:0] d0, d1;
    reg  [3:0] sel;
    wire [8:0] result;
    wire zero, carry, negative, overflow;

    integer i, j, covered;
    integer errors = 0;
    reg [8:0] expected;

    // ---- coverage bins ----
    integer sel_hit    [0:15];
    integer zero_hit   [0:1];
    integer carry_hit  [0:1];
    integer neg_hit    [0:1];
    integer ovf_hit    [0:1];
    integer corner_hit [0:3];   // d1==0, d0==0, d0==255, d0==127

    integer pick;

    ALU dut (
        .d0(d0), .d1(d1), .sel(sel), .result(result),
        .zero(zero), .carry(carry),
        .negative(negative), .overflow(overflow)
    );

    // ---- golden reference model ----
    function [8:0] model;
        input [7:0] a, b;
        input [3:0] s;
        begin
            case (s)
                4'b0000 : model = a + b;
                4'b0001 : model = a - b;
                4'b0010 : model = (a * b) & 9'h1FF;
                4'b0011 : model = (b == 0) ? 9'b0 : a / b;
                4'b0100 : model = {1'b0, a & b};
                4'b0101 : model = {1'b0, a | b};
                4'b0110 : model = {1'b0, ~(a & b)};
                4'b0111 : model = {1'b0, ~(a | b)};
                4'b1000 : model = a << 1;
                4'b1001 : model = b << 1;
                4'b1010 : model = {1'b0, a >> 1};
                4'b1011 : model = {1'b0, b >> 1};
                4'b1100 : model = {1'b0, ~a};
                4'b1101 : model = {1'b0, $signed(a) >>> 1};
                4'b1110 : model = {1'b0, (~a + 8'd1)};
                4'b1111 : model = {1'b0, a ^ b};
                default : model = 9'b0;
            endcase
        end
    endfunction

    initial begin
        // zero the bins
        for (j = 0; j < 16; j = j + 1) sel_hit[j]    = 0;
        for (j = 0; j < 2;  j = j + 1) zero_hit[j]   = 0;
        for (j = 0; j < 2;  j = j + 1) carry_hit[j]  = 0;
        for (j = 0; j < 2;  j = j + 1) neg_hit[j]    = 0;
        for (j = 0; j < 2;  j = j + 1) ovf_hit[j]    = 0;
        for (j = 0; j < 4;  j = j + 1) corner_hit[j] = 0;

        for (i = 0; i < 10000; i = i + 1) begin

            // ---- constrained stimulus ----
            // 30% of the time force d0 to a boundary value
            pick = {$random} % 10;
            if (pick < 3) begin
                case ({$random} % 4)
                    0 : d0 = 8'd255;
                    1 : d0 = 8'd127;
                    2 : d0 = 8'd128;
                    3 : d0 = 8'd0;
                endcase
            end else
                d0 = $random;

            // 20% of the time force d1 = 0 (exercises divide guard)
            d1  = ({$random} % 10 < 2) ? 8'd0 : $random;
            sel = $random;

            #1;

            // ---- check ----
            expected = model(d0, d1, sel);
            if (result !== expected) begin
                errors = errors + 1;
                $display("FAIL: d0=%0d d1=%0d sel=%0d  got=%0d exp=%0d",
                         d0, d1, sel, result, expected);
            end

            // ---- sample coverage ----
            sel_hit[sel]      = sel_hit[sel]      + 1;
            zero_hit[zero]    = zero_hit[zero]    + 1;
            carry_hit[carry]  = carry_hit[carry]  + 1;
            neg_hit[negative] = neg_hit[negative] + 1;
            ovf_hit[overflow] = ovf_hit[overflow] + 1;

            if (d1 == 8'd0)   corner_hit[0] = corner_hit[0] + 1;
            if (d0 == 8'd0)   corner_hit[1] = corner_hit[1] + 1;
            if (d0 == 8'd255) corner_hit[2] = corner_hit[2] + 1;
            if (d0 == 8'd127) corner_hit[3] = corner_hit[3] + 1;
        end

        // ---- results ----
        $display("=====================================");
        $display("Ran 10000 constrained-random tests, %0d failures", errors);
        $display("%s", (errors == 0) ? "PASS" : "FAIL");

        $display("--- opcode coverage ---");
        covered = 0;
        for (j = 0; j < 16; j = j + 1) begin
            if (sel_hit[j] > 0) covered = covered + 1;
            else $display("  sel=%2d : UNCOVERED", j);
        end
        $display("  %0d/16 opcodes hit (%0d%%)", covered, covered*100/16);

        $display("--- flag coverage (0-hits / 1-hits) ---");
        $display("  zero     : %6d / %6d", zero_hit[0],  zero_hit[1]);
        $display("  carry    : %6d / %6d", carry_hit[0], carry_hit[1]);
        $display("  negative : %6d / %6d", neg_hit[0],   neg_hit[1]);
        $display("  overflow : %6d / %6d", ovf_hit[0],   ovf_hit[1]);

        $display("--- corner values ---");
        $display("  d1==0   : %0d", corner_hit[0]);
        $display("  d0==0   : %0d", corner_hit[1]);
        $display("  d0==255 : %0d", corner_hit[2]);
        $display("  d0==127 : %0d", corner_hit[3]);
        $display("=====================================");

        $finish;
    end

endmodule