`timescale 1ns/1ps

module tb_random;

    reg  [7:0] d0, d1;
    reg  [3:0] sel;
    wire [8:0] result;
    wire zero, carry, negative, overflow;

    integer i;
    integer errors = 0;
    reg [8:0] expected;

    ALU dut (
        .d0(d0), .d1(d1), .sel(sel), .result(result),
        .zero(zero), .carry(carry),
        .negative(negative), .overflow(overflow)
    );

    // golden reference model — written independently of the RTL
    function [8:0] model;
        input [7:0] a, b;
        input [3:0] s;
        begin
            case (s)
                4'b0000 : model = a + b;
                4'b0001 : model = a - b;
                4'b0010 : model = (a * b) & 9'h1FF;   // acknowledge truncation
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
        for (i = 0; i < 10000; i = i + 1) begin
            d0  = $random;
            d1  = $random;
            sel = $random;
            #1;
            expected = model(d0, d1, sel);
            if (result !== expected) begin
                errors = errors + 1;
                $display("FAIL: d0=%0d d1=%0d sel=%0d  got=%0d exp=%0d",
                         d0, d1, sel, result, expected);
            end
        end

        $display("=====================================");
        $display("Ran 10000 random tests, %0d failures", errors);
        if (errors == 0) $display("PASS");
        else             $display("FAIL");
        $display("=====================================");
        $finish;
    end

endmodule