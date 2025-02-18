module Pratica10(
    //////////// CLOCK //////////
    input           MAX10_CLK1_50, // 50 MHz

    //////////// KEY //////////
    input     [1:0] KEY,          // KEY0, KEY1 (botões de pressão, ativo-baixo)

    //////////// SW //////////
    input     [9:0] SW,           // usar SW[0] para reset, SW[1], SW[2] para o paddle direito

    //////////// VGA //////////
    output    [3:0] VGA_B,
    output    [3:0] VGA_G,
    output          VGA_HS,
    output    [3:0] VGA_R,
    output          VGA_VS
);
    //------------------------------------------------
    // 1) Clock & Reset
    //------------------------------------------------
    wire clk        = MAX10_CLK1_50;       // Atribui o sinal de clock de 50 MHz
    wire async_rstn = ~SW[0];              // SW[0] é o reset ativo-baixo
    wire sync_rstn;

    // Sincroniza o reset externo no domínio do clock
    AsyncInputSynchronizer u_rst_sync (
        .clk   (clk),
        .asyncn(async_rstn),
        .syncn (sync_rstn)
    );

    //------------------------------------------------
    // 2) Mapeamento de Entradas
    //------------------------------------------------
    wire left_up     = ~KEY[0];  // Aciona o movimento para cima do paddle esquerdo (KEY0)
    wire left_down   = ~KEY[1];  // Aciona o movimento para baixo do paddle esquerdo (KEY1)
    wire right_up    =  SW[1];   // Aciona o movimento para cima do paddle direito (SW[1])
    wire right_down  =  SW[2];   // Aciona o movimento para baixo do paddle direito (SW[2])
    //------------------------------------------------
    // 3) Sinais de Sincronização VGA
    //------------------------------------------------
    wire video_on, pixel_tick;
    wire [9:0] pixel_x, pixel_y;

    // Unidade de sincronização VGA
    VGASync vsync_unit (
        .clk       (clk),
        .rstn      (sync_rstn),
        .hsync     (VGA_HS),      // Sinal de sincronização horizontal (HS)
        .vsync     (VGA_VS),      // Sinal de sincronização vertical (VS)
        .video_on  (video_on),    // Sinal que indica se o vídeo está ativo
        .p_tick    (pixel_tick), // Sinal de tick do pixel
        .pixel_x   (pixel_x),    // Posição horizontal do pixel
        .pixel_y   (pixel_y)     // Posição vertical do pixel
    );

    //------------------------------------------------
    // 4) Geração de Pixel (Lógica do Pong)
    //------------------------------------------------
    wire [11:0] rgb_next;   // Cor do próximo pixel
    reg  [11:0] rgb_reg;    // Cor registrada do pixel

    // Unidade de Geração de Pixels (Pong)
    PixelGen px_gen (
        .clk        (clk),
        .rstn       (sync_rstn),
        .video_on   (video_on),
        .p_tick     (pixel_tick),   // Sinal de tick do pixel

        // Paddles:
        .left_up    (left_up),     // Movimento do paddle esquerdo para cima
        .left_down  (left_down),   // Movimento do paddle esquerdo para baixo
        .right_up   (right_up),    // Movimento do paddle direito para cima
        .right_down (right_down),  // Movimento do paddle direito para baixo

        .pixel_x    (pixel_x),     // Posição horizontal do pixel
        .pixel_y    (pixel_y),     // Posição vertical do pixel

        // Saídas de 4 bits para R, G, B
        .r          (rgb_next[11:8]),
        .g          (rgb_next[7:4]),
        .b          (rgb_next[3:0])
    );

    // Armazena a cor do próximo pixel a cada ciclo de tick
    always @(posedge clk) begin
        if (pixel_tick)
            rgb_reg <= rgb_next;  // Atribui a cor próxima ao registro
    end

    // Atribui a cor final aos sinais de saída VGA
    assign VGA_R = rgb_reg[11:8];  // Cor vermelha (R)
    assign VGA_G = rgb_reg[7:4];   // Cor verde (G)
    assign VGA_B = rgb_reg[3:0];   // Cor azul (B)

endmodule
