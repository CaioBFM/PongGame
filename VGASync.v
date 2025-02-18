module VGASync(
	input wire clk, rstn,
	output wire hsync, vsync, video_on, p_tick,
	output wire [9:0] pixel_x, pixel_y
);

	// Declaração de constantes
	// Parâmetros de sincronização VGA 640x480
	localparam HD = 640; // área de exibição horizontal
	localparam HF = 48;  // borda frontal horizontal (esquerda)
	localparam HB = 16;  // borda traseira horizontal (direita)
	localparam HR = 96;  // retrace horizontal
	localparam VD = 480; // área de exibição vertical
	localparam VF = 10;  // borda frontal vertical (topo)
	localparam VB = 33;  // borda traseira vertical (fundo)
	localparam VR = 2;   // retrace vertical

	// Contador mod-2
	reg mod2_reg;
	wire mod2_next;
	// Contadores de sincronização
	reg [9:0] h_count_reg, h_count_next;
	reg [9:0] v_count_reg, v_count_next;
	// Buffer de saída
	reg v_sync_reg, h_sync_reg;
	wire v_sync_next, h_sync_next;
	// Sinal de status
	wire h_end, v_end, pixel_tick;
	
	// Corpo
	// Registros
	always@(posedge clk, negedge rstn)
		if(rstn == 0)
		begin
			mod2_reg <= 1'b0;
			v_count_reg <= 0;
			h_count_reg <= 0;
			v_sync_reg <= 1'b0;
			h_sync_reg <= 1'b0;
		end
		else
		begin
			mod2_reg <= mod2_next;
			v_count_reg <= v_count_next;
			h_count_reg <= h_count_next;
			v_sync_reg <= v_sync_next;
			h_sync_reg <= h_sync_next;
		end
		
	// Circuito mod-2 para gerar o sinal de enable de 25 MHz
	assign mod2_next = ~mod2_reg;
	assign pixel_tick = mod2_reg;
	
	// Sinais de status
	// Fim do contador horizontal (799)
	assign h_end = (h_count_reg == (HD+HF+HB+HR-1));
	// Fim do contador vertical (524)
	assign v_end = (v_count_reg == (VD+VF+VB+VR-1));
	
	// Lógica do próximo estado do contador horizontal mod-800
	always@*
		if(pixel_tick) // Pulso de 25 MHz
			if(h_end)
				h_count_next = 0;
			else
				h_count_next = h_count_reg + 1;
		else
			h_count_next = h_count_reg;
			
	// Lógica do próximo estado do contador vertical mod-525
	always@*
		if(pixel_tick & h_end) // Pulso de 25 MHz
			if(v_end)
				v_count_next = 0;
			else
				v_count_next = v_count_reg + 1;
		else
			v_count_next = v_count_reg;
			
	// Sincronização horizontal e vertical, com buffer para evitar glitch
	// h_sync_next é ativado entre 656 e 751
	assign h_sync_next = (h_count_reg >= (HD+HB) &&
								 h_count_reg <= (HD+HB+HR-1));
	
	// v_sync_next é ativado entre 490 e 491
	assign v_sync_next = (v_count_reg >= (VD+VB) &&
								 v_count_reg <= (VD+VB+VR-1));

	// Vídeo ativado/desativado
	assign video_on = (h_count_reg<HD) && (v_count_reg<VD);
	
	// Saídas
	assign hsync = h_sync_reg;
	assign vsync = v_sync_reg;
	assign pixel_x = h_count_reg;
	assign pixel_y = v_count_reg;
	assign p_tick = pixel_tick;
	
endmodule
