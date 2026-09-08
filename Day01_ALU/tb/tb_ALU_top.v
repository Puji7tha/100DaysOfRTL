`timescale 1ns/1ps

module tb_ALU_top;

    // ---- signals ----
    reg        clk = 0;
    reg        rst_n;
    reg  [7:0] d0_in, d1_in;
    reg  [3:0] sel_in;

    wire [8:0] result_out;
    wire       zero_out, carry_out, negative_out, overflow_out;

    // ---- DUT ----
    ALU_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .d0_in(d0_in),
        .d1_in(d1_in),
        .sel_in(sel_in),
        .result_out(result_out),
        .zero_out(zero_out),
        .carry_out(carry_out),
        .negative_out(negative_out),
        .overflow_out(overflow_out)
    );

    // ---- clock: 10ns period, 100 MHz ----
    always #5 clk = ~clk;

    // ---- stimulus ----
    initial begin
        $dumpfile("sim/alu_top.vcd");
        $dumpvars(0, tb_ALU_top);

        // hold reset
        rst_n  = 0;
        d0_in  = 8'd0;
        d1_in  = 8'd0;
        sel_in = 4'd0;

        repeat (2) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // apply one vector per clock edge
        d0_in = 8'd10;  d1_in = 8'd3;  sel_in = 4'b0000;  // ADD
        @(posedge clk);

        d0_in = 8'd20;  d1_in = 8'd4;  sel_in = 4'b0001;  // SUB
        @(posedge clk);

        d0_in = 8'd255; d1_in = 8'd1;  sel_in = 4'b0000;  // ADD -> carry
        @(posedge clk);

        d0_in = 8'd12;  d1_in = 8'd5;  sel_in = 4'b1111;  // XOR
        @(posedge clk);

        d0_in = 8'd7;   d1_in = 8'd7;  sel_in = 4'b0001;  // SUB -> zero
        @(posedge clk);

        // idle, let the pipeline drain
        d0_in = 8'd0;   d1_in = 8'd0;  sel_in = 4'd0;
        repeat (4) @(posedge clk);

        $finish;
    end

    // ---- monitor ----
    initial begin
        $monitor("t=%5t rst=%b | in: d0=%3d d1=%3d sel=%2d | out: res=%3d Z=%b C=%b N=%b V=%b",
                 $time, rst_n, d0_in, d1_in, sel_in,
                 result_out, zero_out, carry_out, negative_out, overflow_out);
    end

endmodule