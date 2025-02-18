module PixelGen(
    input  wire clk,
    input  wire rstn,
    input  wire video_on, 
    input  wire p_tick,

    // Entradas de controle do paddle
    input  wire left_up,      // Move o paddle esquerdo para cima (sw 1)
    input  wire left_down,    // Move o paddle esquerdo para baixo (sw 2)
    input  wire right_up,     // Move o paddle direito para cima (key 0)
    input  wire right_down,   // Move o paddle direito para baixo (key 1)

    input  wire [9:0] pixel_x,
    input  wire [9:0] pixel_y,

    // Saída de cor RGB de 12 bits (4 bits por canal)
    output reg [3:0] r,
    output reg [3:0] g,
    output reg [3:0] b
);

    //=========================================================
    // 1) Parâmetros da Tela e Objetos
    //=========================================================
    localparam SCREEN_W     = 640;  // Largura da tela em pixels
    localparam SCREEN_H     = 480;  // Altura da tela em pixels

    localparam PADDLE_W     = 10;   // Largura do paddle em pixels
    localparam PADDLE_H     = 70;   // Altura do paddle em pixels
    localparam BALL_SIZE    = 13;   // Tamanho da bola (largura e altura em pixels)

    localparam LEFT_PADDLE_X  = 30;  // Coordenada X do paddle esquerdo
    localparam RIGHT_PADDLE_X = SCREEN_W - 30 - PADDLE_W;  // Coordenada X do paddle direito

    // Definições de cor (formato RGB de 12 bits)
    localparam COLOR_BLACK = 12'h000;  // Cor preta
    localparam COLOR_WHITE = 12'hFFF;  // Cor branca
    localparam COLOR_RED   = 12'hF00;  // Cor vermelha
    localparam COLOR_DARK_BLUE = 12'h008;  // Cor azul escuro
	 localparam COLOR_YELLOW = 12'hFF0; // Cor amarelo
	 localparam COLOR_ORANGE = 12'hF80; // Cor laranja

    //=========================================================
    // 2) Sinal de Atualização da Tela (~60 Hz)
    //=========================================================
    wire refr_tick;
    assign refr_tick = (pixel_y == SCREEN_H) && (pixel_x == 0);

    //=========================================================
    // 3) Variáveis de Estado dos Paddles, da bola e do placar
    //=========================================================
    reg [9:0] left_paddle_y, right_paddle_y;  // Posições verticais dos paddles
    reg [9:0] ball_x, ball_y;  // Posição da bola (coordenadas X e Y)
    reg       ball_dir_x, ball_dir_y;  // Direção do movimento da bola (1 = direita/baixo, 0 = esquerda/cima)
	 reg [3:0] left_score, right_score;

    //=========================================================
    // 4) Lógica de Inicialização e Movimento dos Objetos
    //=========================================================
    always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        // Reset: centraliza os paddles e a bola no meio da tela
        left_paddle_y  <= (SCREEN_H - PADDLE_H) / 2;
        right_paddle_y <= (SCREEN_H - PADDLE_H) / 2;
        ball_x         <= (SCREEN_W - BALL_SIZE) / 2;
        ball_y         <= (SCREEN_H - BALL_SIZE) / 2;
        ball_dir_x     <= 1'b1;  // Direção inicial da bola: direita
        ball_dir_y     <= 1'b1;  // Direção inicial da bola: baixo
        left_score     <= 0;
        right_score    <= 0;
    end
    else if (refr_tick) begin
        // Lógica de movimento do paddle (limitada pelas bordas da tela)
        if (left_up && (left_paddle_y >= 4))
            left_paddle_y <= left_paddle_y - 4;
        else if (left_down && ((left_paddle_y + PADDLE_H + 4) <= SCREEN_H))
            left_paddle_y <= left_paddle_y + 4;

        if (right_up && (right_paddle_y >= 4))
            right_paddle_y <= right_paddle_y - 4;
        else if (right_down && ((right_paddle_y + PADDLE_H + 4) <= SCREEN_H))
            right_paddle_y <= right_paddle_y + 4;

        // Lógica de movimento da bola (baseada na direção)
        ball_x <= ball_dir_x ? ball_x + 2 : ball_x - 2;
        ball_y <= ball_dir_y ? ball_y + 2 : ball_y - 2;

        // Colisão da bola com as paredes superior e inferior
        if (ball_y <= BALL_SIZE)
            ball_dir_y <= 1'b1;  // Rebote para baixo
        else if (ball_y + BALL_SIZE >= SCREEN_H)
            ball_dir_y <= 1'b0;  // Rebote para cima

        // Colisão da bola com o paddle esquerdo
        if (ball_x <= (LEFT_PADDLE_X + PADDLE_W)) begin
            if ((ball_y + BALL_SIZE >= left_paddle_y) && (ball_y <= left_paddle_y + PADDLE_H))
                ball_dir_x <= 1'b1;  // Rebote para a direita
            else begin
                // Jogador da esquerda errou: reseta a bola e incrementa o score do jogador da direita
                ball_x     <= (SCREEN_W - BALL_SIZE) / 2;
                ball_y     <= (SCREEN_H - BALL_SIZE) / 2;
                ball_dir_x <= 1'b1;
                right_score <= right_score + 1;
            end
        end

        // Colisão da bola com o paddle direito
        if ((ball_x + BALL_SIZE) >= RIGHT_PADDLE_X) begin
            if ((ball_y + BALL_SIZE >= right_paddle_y) && (ball_y <= right_paddle_y + PADDLE_H))
                ball_dir_x <= 1'b0;  // Rebote para a esquerda
            else begin
                // Jogador da direita errou: reseta a bola e incrementa o score do jogador da esquerda
                ball_x     <= (SCREEN_W - BALL_SIZE) / 2;
                ball_y     <= (SCREEN_H - BALL_SIZE) / 2;
                ball_dir_x <= 1'b0;
                left_score <= left_score + 1;
            end
         end
      end
		end

    //=========================================================
    // 5) Lógica de Renderização dos Objetos (Detecção por Pixel)
    //=========================================================
    wire left_paddle_on = (pixel_x >= LEFT_PADDLE_X) && (pixel_x < LEFT_PADDLE_X + PADDLE_W) && (pixel_y >= left_paddle_y) && (pixel_y < left_paddle_y + PADDLE_H);
    wire right_paddle_on = (pixel_x >= RIGHT_PADDLE_X) && (pixel_x < RIGHT_PADDLE_X + PADDLE_W) && (pixel_y >= right_paddle_y) && (pixel_y < right_paddle_y + PADDLE_H);
    wire ball_on = (pixel_x >= ball_x) && (pixel_x < ball_x + BALL_SIZE) && (pixel_y >= ball_y) && (pixel_y < ball_y + BALL_SIZE);
    wire middle_line_on = (pixel_x >= (SCREEN_W / 2 - 1)) && (pixel_x <= (SCREEN_W / 2 + 1));

    //=========================================================
    // 6) Lógica de Seleção de Cor
    //=========================================================
    reg [11:0] rgb_next;
    always @* begin
    if (!video_on)
        rgb_next = COLOR_BLACK;  // Cor de fundo quando o vídeo está desligado
    else begin
        rgb_next = COLOR_DARK_BLUE;  // Cor de fundo padrão
        if (middle_line_on)
            rgb_next = COLOR_WHITE;  // Linha central em branco
        if (left_paddle_on || right_paddle_on)
            rgb_next = COLOR_RED;  // Paddles em branco
        if (ball_on)
            rgb_next = COLOR_ORANGE;  // Bola em laranja
		  if (score_on) 
            rgb_next = COLOR_YELLOW; // Placar em amarelo
			end
     end
		
		//=========================================================
		//  7) Lógica de Exibição do Placar
		//=========================================================

		wire [3:0] tens_digit_left = (left_score >= 10) ? 4'd1 : 4'd0;  // Dígito das dezenas para o placar esquerdo
		wire [3:0] units_digit_left = left_score - (tens_digit_left * 10);  // Dígito das unidades para o placar esquerdo

		wire [3:0] tens_digit_right = (right_score >= 10) ? 4'd1 : 4'd0;  // Dígito das dezenas para o placar direito
		wire [3:0] units_digit_right = right_score - (tens_digit_right * 10);  // Dígito das unidades para o placar direito

		// Novas regiões ajustadas para os dígitos das dezenas e unidades (tamanho estreito)
		wire left_tens_on = (pixel_x >= 16) && (pixel_x < 32) && (pixel_y >= 16) && (pixel_y < 32);  // Nova região para as dezenas do placar esquerdo
		wire left_units_on = (pixel_x >= 32) && (pixel_x < 48) && (pixel_y >= 16) && (pixel_y < 32);  // Nova região para as unidades do placar esquerdo
		wire right_tens_on = (pixel_x >= 600) && (pixel_x < 616) && (pixel_y >= 16) && (pixel_y < 32);  // Nova região para as dezenas do placar direito
		wire right_units_on = (pixel_x >= 616) && (pixel_x < 632) && (pixel_y >= 16) && (pixel_y < 32);  // Nova região para as unidades do placar direito

		// Função para calcular se um pixel está iluminado no display de 7 segmentos
		function automatic pixel_on;
			 input [3:0] digit;  // Dígito que será exibido
			 input [4:0] x_rel;  // Coordenada relativa no eixo X
			 input [4:0] y_rel;  // Coordenada relativa no eixo Y
			 reg [6:0] seg;  // Valor dos segmentos iluminados para o dígito
			 reg in_a, in_b, in_c, in_d, in_e, in_f, in_g;  // Definição de cada segmento
		begin
			 // Mapeamento dos segmentos para cada dígito (0 a 9)
			 case (digit)
				  4'd0: seg = 7'b1111110; // a b c d e f g
				  4'd1: seg = 7'b0110000; // Digit 1 (fixing the issue for this number)
				  4'd2: seg = 7'b1101101; // Digit 2 (adjustments made for better readability)
				  4'd3: seg = 7'b1111001;
				  4'd4: seg = 7'b0110011;
				  4'd5: seg = 7'b1011011;
				  4'd6: seg = 7'b1011111; // Digit 6 (adjustments made for better readability)
				  4'd7: seg = 7'b1110000;
				  4'd8: seg = 7'b1111111;
				  4'd9: seg = 7'b1111011;
				  default: seg = 7'b0000000;
			 endcase

			 // Lógica dos segmentos para o display de 7 segmentos em uma grade maior (estreita e alta)
			 // Ajuste para garantir que os segmentos estejam corretamente alinhados em um display estreito
			 in_a = (y_rel == 0) && (x_rel >= 1) && (x_rel <= 5);  // Segmento horizontal superior
			 in_b = (x_rel == 6) && (y_rel >= 1) && (y_rel <= 3);  // Segmento vertical superior-direito
			 in_c = (x_rel == 6) && (y_rel >= 4) && (y_rel <= 6);  // Segmento vertical inferior-direito
			 in_d = (y_rel == 7) && (x_rel >= 1) && (x_rel <= 5);  // Segmento horizontal inferior
			 in_e = (x_rel == 0) && (y_rel >= 4) && (y_rel <= 6);  // Segmento vertical inferior-esquerdo
			 in_f = (x_rel == 0) && (y_rel >= 1) && (y_rel <= 3);  // Segmento vertical superior-esquerdo
			 in_g = (y_rel == 3) && (x_rel >= 1) && (x_rel <= 5);  // Segmento horizontal do meio

			 // Determina se o pixel está aceso com base nos segmentos e no dígito
			 pixel_on = (in_a & seg[6]) | (in_b & seg[5]) | (in_c & seg[4]) |
							(in_d & seg[3]) | (in_e & seg[2]) | (in_f & seg[1]) |
							(in_g & seg[0]);
		end
		endfunction

		// Cálculo das coordenadas relativas para cada dígito (com novo tamanho estreito)
		wire [4:0] left_tens_x = pixel_x - 16;  // Coordenada relativa X para as dezenas do placar esquerdo
		wire [4:0] left_tens_y = pixel_y - 16;  // Coordenada relativa Y para as dezenas do placar esquerdo
		wire left_tens_pixel = pixel_on(tens_digit_left, left_tens_x, left_tens_y);  // Pixel aceso para as dezenas do placar esquerdo

		wire [4:0] left_units_x = pixel_x - 32;  // Coordenada relativa X para as unidades do placar esquerdo
		wire [4:0] left_units_y = pixel_y - 16;  // Coordenada relativa Y para as unidades do placar esquerdo
		wire left_units_pixel = pixel_on(units_digit_left, left_units_x, left_units_y);  // Pixel aceso para as unidades do placar esquerdo

		wire [4:0] right_tens_x = pixel_x - 600;  // Coordenada relativa X para as dezenas do placar direito
		wire [4:0] right_tens_y = pixel_y - 16;  // Coordenada relativa Y para as dezenas do placar direito
		wire right_tens_pixel = pixel_on(tens_digit_right, right_tens_x, right_tens_y);  // Pixel aceso para as dezenas do placar direito

		wire [4:0] right_units_x = pixel_x - 616;  // Coordenada relativa X para as unidades do placar direito
		wire [4:0] right_units_y = pixel_y - 16;  // Coordenada relativa Y para as unidades do placar direito
		wire right_units_pixel = pixel_on(units_digit_right, right_units_x, right_units_y);  // Pixel aceso para as unidades do placar direito

		// Combinação de todos os sinais de exibição do placar
		wire score_on = (left_tens_on && left_tens_pixel) ||
							 (left_units_on && left_units_pixel) ||
							 (right_tens_on && right_tens_pixel) ||
							 (right_units_on && right_units_pixel);  // Exibição final do placar


    //=========================================================
    // 8) Latch de Cor de Saída (Sincronizado com p_tick)
    //=========================================================
    always @(posedge clk) begin
        if (p_tick)
            {r, g, b} <= rgb_next;
    end

endmodule