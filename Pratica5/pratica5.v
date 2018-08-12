module pratica5(SW, LEDR, HEX0, HEX1, HEX2);
  input [17:0]SW;
  output [17:0]LEDR;
  output [6:0]HEX0, HEX1, HEX2;
  wire [2:0]saida0, saida1, saida2;

  //diretorio_talk Falando(SW[16], SW[17], SW[2:0], saida0, saida1, saida2);
  diretorio_listen Escutando(SW[16], SW[17], SW[2:0], saida0, saida1, saida2);

  display7Segmentos Exibe0(saida0, HEX0); // STATE
  display7Segmentos Exibe1(saida1, HEX1); // BUS
  display7Segmentos Exibe2(saida2, HEX2); // SIGNAL

  assign LEDR = SW; // associa o led às chaves
endmodule

//saida0 = state  HEX0
//saida1 = bus    HEX1
//saida2 = signal HEX2

module display7Segmentos(Entrada, SaidaDisplay);
	input [2:0]Entrada;
	output reg [0:6]SaidaDisplay;

	always begin
		case(Entrada)
			0:SaidaDisplay = 7'b1000000;       // 0
			1:SaidaDisplay = 7'b1111001;       // 1
			2:SaidaDisplay = 7'b0100100;       // 2
			3:SaidaDisplay = 7'b0110000;       // 3
			4:SaidaDisplay = 7'b0011001;       // 4
			5:SaidaDisplay = 7'b0010010;       // 5
			6:SaidaDisplay = 7'b0000010;       // 6
			7:SaidaDisplay = 7'b1111000;       // 7
			default:SaidaDisplay = 7'b0000000; // F
		endcase
	end
endmodule

module diretorio_talk(clock, reset, bus, saida0, saida1, saida2);
  input clock, reset;
  input [2:0]bus;
  output [2:0]saida0;
  output [2:0]saida1;
  output [2:0]saida2;
  reg [2:0]state;
  reg [2:0]signal;

  /* ESTADO
   * 0 = Shared
   * 1 = Invalid
   * 2 = modified
   *
   * BUS
   * 0 = DEFAULT
   * 1 = read miss
   * 2 = write miss
   * 3 = read hit
   * 4 = write hit
   * 5 = Fetch
   * 6 = Fetch invalidate
   * 7 = Invalidate
   *
   * SIGNAL
   * 0 = DEFAULT
   * 1 = Data write-back / write miss
   * 2 = Send write miss message
   * 3 = Send read miss message
   * 4 = Data write-back; read miss
   * 5 = Fetch Data write-back
   * 6 = Send Invalidate message
   * 7 = Read miss
   */

  assign saida0 = state;
  assign saida1 = bus;
  assign saida2 = signal;

  always @ (posedge clock) begin
  	if(reset)begin
		signal = 3'b000; // DEFAULT
      case(state)
        /** S H A R E D **/
        0:begin
          case(bus)
            1:begin // read miss
            // mantem o estado
  					signal = 3'b111; // Read miss
  				  end
          2:begin // write miss
            state = 3'b010;  // estado modified
            signal = 3'b010; // send write miss message
            end
          3:begin // read hit
            // mantem o estado
            // não envia mensagem
            end
          4:begin // write hit
              state = 3'b010;   // estado modificado
              signal = 3'b110;  // send invalid mensagen
            end
          7:begin // Invalidate
            state = 3'b001; // estado Invalid
            // não envia mensagem
            end
          endcase
        end

        /** I N V A L I D **/
        1:begin
          case(bus)
            1:begin // read miss
            state = 3'b000;   // estado shared
            signal = 3'b111;  // Read miss
            end
          2:begin // write miss
            state = 3'b010;  // estado modified
            signal = 3'b010; // send write miss message
            end
          endcase
        end

        /** M O D I F I E D **/
        2:begin
          case(bus)
            1:begin // read miss
            state = 3'b000;   // estado shared
            signal = 3'b100;  // Data write-back; read miss
            end
          2:begin // write miss
            // mantem o estado
            signal = 3'b001; // Data write-back / Write miss
            end
          5:begin
            state = 3'b000;   // estado Shared
            signal = 3'b101;  // Data write-back
            end
          6:begin // Fetch Invalidate
            state = 3'b001;   // estado Invalid
            signal = 3'b101;  // Data write-back
            end
			endcase
		end // end if
	 endcase
	 end
    else begin // reset
  		state = 3'b000;
  		signal = 3'b000;
  	 end // end else
  end // end always
endmodule


module diretorio_listen(clock, reset, bus, saida0, saida1, saida2);
  input clock, reset;
  input [2:0]bus;
  output [2:0]saida0;
  output [2:0]saida1;
  output [2:0]saida2;
  reg [2:0]state;
  reg [2:0]signal;


  /* ESTADO
   * 0 = Shared
   * 1 = Uncached
   * 2 = Exclusive
   *
   * BUS
   * 0 = DEFAULT
   * 1 = read miss
   * 2 = write miss
   * 3 = Data write-back
   *
   * SIGNAL
   * 0 = Data value reply / Sharers = Sharers + {P}
   * 1 = Fetch; data value reply; Sharers = Sharers + {P}
   * 2 = Invalidate; Sharers = {P}; date valeu reply
   * 3 = Sharers = {}
   * 4 = Data value reply; / Sharers = {P}
   * 5 = Fetch / Invalidate Date value reply Sharers = {P}
   */

  assign saida0 = state;
  assign saida1 = bus;
  assign saida2 = signal;

  always @ (posedge clock) begin
  	if(reset)begin
	signal = 3'b000; // DEFAULT
      case(state)
        /** S H A R E D **/
        0:begin
          case(bus)
            1:begin // read miss
            // mantem o estado
  					signal = 3'b000; // Data value reply / Sharers = Sharers + {P}
  				end
          2:begin // write miss
            state = 3'b010;  // estado modified
            signal = 3'b010; // Invalidate; Sharers = {P}; data value reply
          end
          endcase
        end

        /** U N C A C H E D **/
        1:begin
          case(bus)
            1:begin // read miss
            state = 3'b000;   // estado Shared
            signal = 3'b100;  // Data value reply; Sharers = {P}
          end
          2:begin // write miss
            state = 3'b010;  // estado Exclusive
            signal = 3'b100; // Data value reply; Sharers = {P}
          end
          endcase
        end

        /** E X C L U S I V E **/
        2:begin
          case(bus)
            1:begin // read miss
            state = 3'b000;   // estado Shared
            signal = 3'b001;  // Fetch; data value reply; Sharers = Sharers + {P}
          end
          2:begin // write miss
            // mantem o estado
            signal = 3'b101; // Fetch/Invalidate / Data value reply / Sharers = {P}
          end
          3:begin // Data write-back
            state = 3'b001;   // estado Uncached
            signal = 3'b011;  // Sharers = {}
				end
          endcase
		   end
		endcase
  	 end // end if

    else begin // reset
  		state = 3'b000;
  		signal = 3'b000;
  	end // end else
  end // end always
endmodule
