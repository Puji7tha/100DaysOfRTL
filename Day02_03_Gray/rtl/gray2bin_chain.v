module gray2bin_chain #(parameter W = 8) (
    input  wire [W-1:0] gray,
    output wire [W-1:0] bin
);
    genvar i;
    assign bin[W-1] = gray[W-1];
    generate
        for (i = W-2; i >= 0; i = i - 1) begin : c
            assign bin[i] = bin[i+1] ^ gray[i];
        end
    endgenerate
endmodule