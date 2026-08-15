`timescale 1ns/1ps

module tb_directed;

    reg  [7:0] d0, d1;
    reg  [3:0] sel;
    wire [8:0] result;
    wire zero, carry, negative, overflow;

    integer i;

    ALU dut (
        .d0(d0),
        .d1(d1),
        .sel(sel),
        .result(result),
        .zero(zero),
        .carry(carry),
        .negative(negative),
        .overflow(overflow)
    );

    initial begin
        $dumpfile("sim/alu_directed.vcd");
        $dumpvars(0, tb_directed);

        // ---- sweep all 16 operations with benign inputs ----
        $display("--- operation sweep (d0=12, d1=5) ---");
        d0 = 8'd12; d1 = 8'd5;
        for (i = 0; i < 16; i = i + 1) begin
            sel = i[3:0];
            #10;
            $display("sel=%2d  d0=%3d d1=%3d  result=%3d (%b)",
                     sel, d0, d1, result, result);
        end

        // ---- adversarial vectors ----
        $display("--- adversarial vectors ---");

        d0 = 8'b10000010; d1 = 8'd0;   sel = 4'b1101; #10;
        $display("ASR  of %b     = %b", d0, result);

        d0 = 8'd200;      d1 = 8'd100; sel = 4'b0010; #10;
        $display("MUL  200 * 100 = %0d  (true answer 20000)", result);

        d0 = 8'd50;       d1 = 8'd0;   sel = 4'b0011; #10;
        $display("DIV  50 / 0    = %0d", result);

        d0 = 8'd255;      d1 = 8'd1;   sel = 4'b0000; #10;
        $display("ADD  255 + 1   = %0d", result);

        // ---- flag behaviour ----
        $display("--- flags ---");

        d0 = 8'd5;   d1 = 8'd5; sel = 4'b0001; #10;
        $display("5-5:     res=%3d Z=%b C=%b N=%b V=%b",
                 result, zero, carry, negative, overflow);

        d0 = 8'd255; d1 = 8'd1; sel = 4'b0000; #10;
        $display("255+1:   res=%3d Z=%b C=%b N=%b V=%b",
                 result, zero, carry, negative, overflow);

        d0 = 8'd127; d1 = 8'd1; sel = 4'b0000; #10;
        $display("127+1:   res=%3d Z=%b C=%b N=%b V=%b",
                 result, zero, carry, negative, overflow);

        d0 = 8'd3;   d1 = 8'd5; sel = 4'b0001; #10;
        $display("3-5:     res=%3d Z=%b C=%b N=%b V=%b",
                 result, zero, carry, negative, overflow);

        $finish;
    end

endmodule