`timescale 1ns/1ps

module tb_gray;

    localparam W = 8;

    reg  [W-1:0] bin_in;
    wire [W-1:0] gray_mid;
    wire [W-1:0] bin_out;

    integer i, j, bitdiff;
    integer errors_rt = 0, errors_ref = 0, errors_adj = 0;
    reg [W-1:0] prev_gray;
    reg [W-1:0] xr;

    // chain the two converters back to back
    bin2gray #(.W(W)) enc (.bin(bin_in),   .gray(gray_mid));
    gray2bin #(.W(W)) dec (.gray(gray_mid), .bin(bin_out));

    function [W-1:0] model_b2g;
        input [W-1:0] b;
        begin
            model_b2g = b ^ (b >> 1);
        end
    endfunction

    initial begin
        $dumpfile("sim/gray.vcd");
        $dumpvars(0, tb_gray);

        for (i = 0; i < (1<<W); i = i + 1) begin
            bin_in = i[W-1:0];
            #1;

            // check 1: round trip is identity
            if (bin_out !== bin_in) begin
                errors_rt = errors_rt + 1;
                if (errors_rt < 5)
                    $display("RT FAIL: in=%0d gray=%b out=%0d", bin_in, gray_mid, bin_out);
            end

            // check 2: encoder matches reference model
            if (gray_mid !== model_b2g(bin_in))
                errors_ref = errors_ref + 1;

            // check 3: THE defining property - adjacent codes differ in exactly 1 bit
            if (i > 0) begin
                xr = gray_mid ^ prev_gray;
                bitdiff = 0;
                for (j = 0; j < W; j = j + 1)
                    if (xr[j]) bitdiff = bitdiff + 1;
                if (bitdiff !== 1) begin
                    errors_adj = errors_adj + 1;
                    if (errors_adj < 5)
                        $display("ADJ FAIL: %0d->%0d changed %0d bits", i-1, i, bitdiff);
                end
            end
            prev_gray = gray_mid;
        end

        $display("=====================================");
        $display("Exhaustive over %0d values (W=%0d)", 1<<W, W);
        $display("  round-trip  gray2bin(bin2gray(x))==x : %0d failures", errors_rt);
        $display("  encoder vs golden model             : %0d failures", errors_ref);
        $display("  adjacent codes differ by 1 bit      : %0d failures", errors_adj);
        $display("%s", (errors_rt+errors_ref+errors_adj==0) ? "PASS" : "FAIL");
        $display("=====================================");
        $finish;
    end

endmodule