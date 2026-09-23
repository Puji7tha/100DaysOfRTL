module gray2bin #(parameter W = 8) (
    input  wire [W-1:0] gray,
    output wire [W-1:0] bin
);
    genvar i;
    generate
        for (i = 0; i < W; i = i + 1) begin : g
            assign bin[i] = ^(gray >> i);
        end
    endgenerate
endmodule