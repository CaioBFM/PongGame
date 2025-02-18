module AsyncInputSynchronizer (
    input  wire clk,    // clock do sistema
    input  wire asyncn, // reset ou sinal assíncrono (ativo-baixo)
    output wire syncn   // saída sincronizada
);
    reg ff1, ff2;

    // Sincroniza o sinal assíncrono com o clock do sistema
    always @(posedge clk or negedge asyncn) begin
        if (!asyncn) begin
            ff1 <= 1'b0;  // Se o sinal assíncrono for baixo (reset), reseta os flip-flops
            ff2 <= 1'b0;
        end else begin
            ff1 <= 1'b1;   // Se o sinal assíncrono for alto, carrega 1 nos flip-flops
            ff2 <= ff1;    // O segundo flip-flop captura o valor do primeiro
        end
    end

    assign syncn = ff2;  // A saída sincronizada é o valor do segundo flip-flop

endmodule
