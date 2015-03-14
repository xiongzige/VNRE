module rabin_fp(
clk,
reset,
chipselect,
address,
read,
write,
writedata,
byteenable,
readdata,
irq
);

input clk;
input reset;
input chipselect;
input[2:0] address;
input read;
input write;
input[63:0] writedata;
input[7:0] byteenable;

output[63:0] readdata;
output irq;

reg[63:0] readdata;
reg irq; 

reg[63:0] p1_data_reg;
reg[63:0] p2_data_reg;
reg[7:0] m_reg;
reg[7:0] shift_reg;
reg[15:0] control_reg;
reg[63:0] fp_data_reg;
reg[7:0] status_reg;

reg p1_data_reg_select;
reg p2_data_reg_select;
reg m_reg_select;
reg shift_reg_select;
reg control_reg_select;

reg[6:0] counter;
reg[63:0] mem[255:0];
reg[63:0] tab_data_reg;

parameter S0=4'b0000,
		  S1=4'b0001,
		  S2=4'b0010,
		  S3=4'b0011,
		  S4=4'b0100,
		  S5=4'b0101,
		  S6=4'b0110,
		  S7=4'b0111;

reg[3:0] cur_state;
reg[3:0] nxt_state;


always @(address)
begin
	p1_data_reg_select <= 0;
	p2_data_reg_select <= 0;
	m_reg_select <= 0;
	shift_reg_select <= 0;
	control_reg_select <= 0;
	case(address)
	3'b000: p1_data_reg_select <= 1;
	3'b001: p2_data_reg_select <= 1;
	3'b010: m_reg_select <= 1;
	3'b011: shift_reg_select <= 1;
	3'b100: control_reg_select <= 1;
	default:
		begin
		p1_data_reg_select <= 0;
		p2_data_reg_select <= 0;
		m_reg_select <= 0;
		shift_reg_select <= 0;
		control_reg_select <= 0;
		end
	endcase
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		p1_data_reg <= 0;
	else
	begin
		if(chipselect&write&p1_data_reg_select)
		begin
			if(byteenable[0])
				p1_data_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				p1_data_reg[15:8] <= writedata[15:8];
			if(byteenable[2])
				p1_data_reg[23:16] <= writedata[23:16];
			if(byteenable[3])
				p1_data_reg[31:24] <= writedata[31:24];
			if(byteenable[4])
				p1_data_reg[39:32] <= writedata[39:32];
			if(byteenable[5])
				p1_data_reg[47:40] <= writedata[47:40];
			if(byteenable[6])
				p1_data_reg[55:48] <= writedata[55:48];
			if(byteenable[7])
				p1_data_reg[63:56] <= writedata[63:56];
		end
		else
		begin
			if(nxt_state == S1)
				p1_data_reg <= p1_data_reg>>1;
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		p2_data_reg <= 0;
	else
	begin
		if(chipselect&write&p2_data_reg_select)
		begin
			if(byteenable[0])
				p2_data_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				p2_data_reg[15:8] <= writedata[15:8];
			if(byteenable[2])
				p2_data_reg[23:16] <= writedata[23:16];
			if(byteenable[3])
				p2_data_reg[31:24] <= writedata[31:24];
			if(byteenable[4])
				p2_data_reg[39:32] <= writedata[39:32];
			if(byteenable[5])
				p2_data_reg[47:40] <= writedata[47:40];
			if(byteenable[6])
				p2_data_reg[55:48] <= writedata[55:48];
			if(byteenable[7])
				p2_data_reg[63:56] <= writedata[63:56];
			else
			if(nxt_state == S3)
				p2_data_reg <= p2_data_reg<<8;
			if(nxt_state == S4)
				p2_data_reg <= p2_data_reg | m_reg; //	
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		m_reg <= 0;
	else
	begin
		if(chipselect&write&m_reg_select)
		begin
			if(byteenable[0])
				m_reg[7:0] <= writedata[7:0];
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		shift_reg <= 0;
	else
	begin
		if(chipselect&write&shift_reg_select)
		begin
			if(byteenable[0])
				shift_reg[7:0] <= writedata[7:0];
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
	begin
		control_reg <= 0;
	end
	else
	begin
		if(chipselect&write&control_reg_select)
		begin
			if(byteenable[0])
				control_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				control_reg[15:8] <= writedata[15:8];
		end
		else
			if(nxt_state==S7)
				control_reg <= 0;
	end
end

always @(chipselect or address or read) //
begin
	if(chipselect&read)
	begin
		case(address)
		3'b000: readdata <= p1_data_reg;
		3'b001: readdata <= p2_data_reg;
		3'b010: readdata <= m_reg;
		3'b011: readdata <= shift_reg;
		3'b100: readdata <= control_reg;
		3'b101: readdata <= fp_data_reg;
		3'b110: readdata <= status_reg;
		default:readdata <= 64'hcccc;
		endcase
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
	begin
		counter <= 0;
	end
	else
	begin
		if(control_reg[0])
		begin
			counter <= counter + 1;
		end
		else
		begin
			counter <= 0;
		end		
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		cur_state <= 4'b0;
	else
		cur_state <= nxt_state;
end

always @(cur_state or control_reg) //
begin
	nxt_state = 'bx;
	case(cur_state)
		S0:
			if(control_reg[0])
				nxt_state = S1;
			else
				nxt_state = S0;
		S1:
			if(control_reg[0]&(counter<shift_reg)) //
			begin
				nxt_state = S1;
			end
			else
				nxt_state = S2;	
		S2:
			if(control_reg[0])
				nxt_state = S3;
		S3:
			if(control_reg[0])
				nxt_state = S4;
		S4:
			if(control_reg[0])
				nxt_state = S5;
		S5:
			if(control_reg[0])
				nxt_state = S6;
		S6:
			if(control_reg[0])
				nxt_state = S7;
		S7:
			nxt_state = S0;
		default: nxt_state = S0;
	endcase
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		tab_data_reg <= 64'b0;
	else
	begin
		if(nxt_state == S2)
			tab_data_reg <= mem[p1_data_reg[7:0]];
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		fp_data_reg <= 64'b0;
	else
	begin
		if(nxt_state == S5)
			fp_data_reg <= tab_data_reg^p2_data_reg;
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		status_reg <= 8'b0;
	else
	begin
		if(nxt_state == S6)
			status_reg <= 8'b1;
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		irq <= 1'b0;
	else
	begin
		if(nxt_state == S6)
			irq <= 1'b1;
	end
end

always @(negedge reset)
begin
	if(reset == 1'b0)
		mem[0] <= 64'h0;
		mem[1] <= 64'hbfe6b8a5bf378d83;
		mem[2] <= 64'h7fcd714b7e6f1b06;
		mem[3] <= 64'hc02bc9eec1589685;
		mem[4] <= 64'h407c5a3343e9bb8f;
		mem[5] <= 64'hff9ae296fcde360c;
		mem[6] <= 64'h3fb12b783d86a089;
		mem[7] <= 64'h805793dd82b12d0a;
		mem[8] <= 64'h3f1e0cc338e4fa9d;
		mem[9] <= 64'h80f8b46687d3771e;
		mem[10] <= 64'h40d37d88468be19b;
		mem[11] <= 64'hff35c52df9bc6c18;
		mem[12] <= 64'h7f6256f07b0d4112;
		mem[13] <= 64'hc084ee55c43acc91;
		mem[14] <= 64'haf27bb05625a14;
		mem[15] <= 64'hbf499f1eba55d797;
		mem[16] <= 64'h7e3c198671c9f53a;
		mem[17] <= 64'hc1daa123cefe78b9;
		mem[18] <= 64'h1f168cd0fa6ee3c;
		mem[19] <= 64'hbe17d068b09163bf;
		mem[20] <= 64'h3e4043b532204eb5;
		mem[21] <= 64'h81a6fb108d17c336;
		mem[22] <= 64'h418d32fe4c4f55b3;
		mem[23] <= 64'hfe6b8a5bf378d830;
		mem[24] <= 64'h41221545492d0fa7;
		mem[25] <= 64'hfec4ade0f61a8224;
		mem[26] <= 64'h3eef640e374214a1;
		mem[27] <= 64'h8109dcab88759922;
		mem[28] <= 64'h15e4f760ac4b428;
		mem[29] <= 64'hbeb8f7d3b5f339ab;
		mem[30] <= 64'h7e933e3d74abaf2e;
		mem[31] <= 64'hc1758698cb9c22ad;
		mem[32] <= 64'h439e8ba95ca467f7;
		mem[33] <= 64'hfc78330ce393ea74;
		mem[34] <= 64'h3c53fae222cb7cf1;
		mem[35] <= 64'h83b542479dfcf172;
		mem[36] <= 64'h3e2d19a1f4ddc78;
		mem[37] <= 64'hbc04693fa07a51fb;
		mem[38] <= 64'h7c2fa0d16122c77e;
		mem[39] <= 64'hc3c91874de154afd;
		mem[40] <= 64'h7c80876a64409d6a;
		mem[41] <= 64'hc3663fcfdb7710e9;
		mem[42] <= 64'h34df6211a2f866c;
		mem[43] <= 64'hbcab4e84a5180bef;
		mem[44] <= 64'h3cfcdd5927a926e5;
		mem[45] <= 64'h831a65fc989eab66;
		mem[46] <= 64'h4331ac1259c63de3;
		mem[47] <= 64'hfcd714b7e6f1b060;
		mem[48] <= 64'h3da2922f2d6d92cd;
		mem[49] <= 64'h82442a8a925a1f4e;
		mem[50] <= 64'h426fe364530289cb;
		mem[51] <= 64'hfd895bc1ec350448;
		mem[52] <= 64'h7ddec81c6e842942;
		mem[53] <= 64'hc23870b9d1b3a4c1;
		mem[54] <= 64'h213b95710eb3244;
		mem[55] <= 64'hbdf501f2afdcbfc7;
		mem[56] <= 64'h2bc9eec15896850;
		mem[57] <= 64'hbd5a2649aabee5d3;
		mem[58] <= 64'h7d71efa76be67356;
		mem[59] <= 64'hc2975702d4d1fed5;
		mem[60] <= 64'h42c0c4df5660d3df;
		mem[61] <= 64'hfd267c7ae9575e5c;
		mem[62] <= 64'h3d0db594280fc8d9;
		mem[63] <= 64'h82eb0d319738455a;
		mem[64] <= 64'h38dbaff7067f426d;
		mem[65] <= 64'h873d1752b948cfee;
		mem[66] <= 64'h4716debc7810596b;
		mem[67] <= 64'hf8f06619c727d4e8;
		mem[68] <= 64'h78a7f5c44596f9e2;
		mem[69] <= 64'hc7414d61faa17461;
		mem[70] <= 64'h76a848f3bf9e2e4;
		mem[71] <= 64'hb88c3c2a84ce6f67;
		mem[72] <= 64'h7c5a3343e9bb8f0;
		mem[73] <= 64'hb8231b9181ac3573;
		mem[74] <= 64'h7808d27f40f4a3f6;
		mem[75] <= 64'hc7ee6adaffc32e75;
		mem[76] <= 64'h47b9f9077d72037f;
		mem[77] <= 64'hf85f41a2c2458efc;
		mem[78] <= 64'h3874884c031d1879;
		mem[79] <= 64'h879230e9bc2a95fa;
		mem[80] <= 64'h46e7b67177b6b757;
		mem[81] <= 64'hf9010ed4c8813ad4;
		mem[82] <= 64'h392ac73a09d9ac51;
		mem[83] <= 64'h86cc7f9fb6ee21d2;
		mem[84] <= 64'h69bec42345f0cd8;
		mem[85] <= 64'hb97d54e78b68815b;
		mem[86] <= 64'h79569d094a3017de;
		mem[87] <= 64'hc6b025acf5079a5d;
		mem[88] <= 64'h79f9bab24f524dca;
		mem[89] <= 64'hc61f0217f065c049;
		mem[90] <= 64'h634cbf9313d56cc;
		mem[91] <= 64'hb9d2735c8e0adb4f;
		mem[92] <= 64'h3985e0810cbbf645;
		mem[93] <= 64'h86635824b38c7bc6;
		mem[94] <= 64'h464891ca72d4ed43;
		mem[95] <= 64'hf9ae296fcde360c0;
		mem[96] <= 64'h7b45245e5adb259a;
		mem[97] <= 64'hc4a39cfbe5eca819;
		mem[98] <= 64'h488551524b43e9c;
		mem[99] <= 64'hbb6eedb09b83b31f;
		mem[100] <= 64'h3b397e6d19329e15;
		mem[101] <= 64'h84dfc6c8a6051396;
		mem[102] <= 64'h44f40f26675d8513;
		mem[103] <= 64'hfb12b783d86a0890;
		mem[104] <= 64'h445b289d623fdf07;
		mem[105] <= 64'hfbbd9038dd085284;
		mem[106] <= 64'h3b9659d61c50c401;
		mem[107] <= 64'h8470e173a3674982;
		mem[108] <= 64'h42772ae21d66488;
		mem[109] <= 64'hbbc1ca0b9ee1e90b;
		mem[110] <= 64'h7bea03e55fb97f8e;
		mem[111] <= 64'hc40cbb40e08ef20d;
		mem[112] <= 64'h5793dd82b12d0a0;
		mem[113] <= 64'hba9f857d94255d23;
		mem[114] <= 64'h7ab44c93557dcba6;
		mem[115] <= 64'hc552f436ea4a4625;
		mem[116] <= 64'h450567eb68fb6b2f;
		mem[117] <= 64'hfae3df4ed7cce6ac;
		mem[118] <= 64'h3ac816a016947029;
		mem[119] <= 64'h852eae05a9a3fdaa;
		mem[120] <= 64'h3a67311b13f62a3d;
		mem[121] <= 64'h858189beacc1a7be;
		mem[122] <= 64'h45aa40506d99313b;
		mem[123] <= 64'hfa4cf8f5d2aebcb8;
		mem[124] <= 64'h7a1b6b28501f91b2;
		mem[125] <= 64'hc5fdd38def281c31;
		mem[126] <= 64'h5d61a632e708ab4;
		mem[127] <= 64'hba30a2c691470737;
		mem[128] <= 64'h71b75fee0cfe84da;
		mem[129] <= 64'hce51e74bb3c90959;
		mem[130] <= 64'he7a2ea572919fdc;
		mem[131] <= 64'hb19c9600cda6125f;
		mem[132] <= 64'h31cb05dd4f173f55;
		mem[133] <= 64'h8e2dbd78f020b2d6;
		mem[134] <= 64'h4e06749631782453;
		mem[135] <= 64'hf1e0cc338e4fa9d0;
		mem[136] <= 64'h4ea9532d341a7e47;
		mem[137] <= 64'hf14feb888b2df3c4;
		mem[138] <= 64'h316422664a756541;
		mem[139] <= 64'h8e829ac3f542e8c2;
		mem[140] <= 64'hed5091e77f3c5c8;
		mem[141] <= 64'hb133b1bbc8c4484b;
		mem[142] <= 64'h71187855099cdece;
		mem[143] <= 64'hcefec0f0b6ab534d;
		mem[144] <= 64'hf8b46687d3771e0;
		mem[145] <= 64'hb06dfecdc200fc63;
		mem[146] <= 64'h7046372303586ae6;
		mem[147] <= 64'hcfa08f86bc6fe765;
		mem[148] <= 64'h4ff71c5b3edeca6f;
		mem[149] <= 64'hf011a4fe81e947ec;
		mem[150] <= 64'h303a6d1040b1d169;
		mem[151] <= 64'h8fdcd5b5ff865cea;
		mem[152] <= 64'h30954aab45d38b7d;
		mem[153] <= 64'h8f73f20efae406fe;
		mem[154] <= 64'h4f583be03bbc907b;
		mem[155] <= 64'hf0be8345848b1df8;
		mem[156] <= 64'h70e91098063a30f2;
		mem[157] <= 64'hcf0fa83db90dbd71;
		mem[158] <= 64'hf2461d378552bf4;
		mem[159] <= 64'hb0c2d976c762a677;
		mem[160] <= 64'h3229d447505ae32d;
		mem[161] <= 64'h8dcf6ce2ef6d6eae;
		mem[162] <= 64'h4de4a50c2e35f82b;
		mem[163] <= 64'hf2021da9910275a8;
		mem[164] <= 64'h72558e7413b358a2;
		mem[165] <= 64'hcdb336d1ac84d521;
		mem[166] <= 64'hd98ff3f6ddc43a4;
		mem[167] <= 64'hb27e479ad2ebce27;
		mem[168] <= 64'hd37d88468be19b0;
		mem[169] <= 64'hb2d16021d7899433;
		mem[170] <= 64'h72faa9cf16d102b6;
		mem[171] <= 64'hcd1c116aa9e68f35;
		mem[172] <= 64'h4d4b82b72b57a23f;
		mem[173] <= 64'hf2ad3a1294602fbc;
		mem[174] <= 64'h3286f3fc5538b939;
		mem[175] <= 64'h8d604b59ea0f34ba;
		mem[176] <= 64'h4c15cdc121931617;
		mem[177] <= 64'hf3f375649ea49b94;
		mem[178] <= 64'h33d8bc8a5ffc0d11;
		mem[179] <= 64'h8c3e042fe0cb8092;
		mem[180] <= 64'hc6997f2627aad98;
		mem[181] <= 64'hb38f2f57dd4d201b;
		mem[182] <= 64'h73a4e6b91c15b69e;
		mem[183] <= 64'hcc425e1ca3223b1d;
		mem[184] <= 64'h730bc1021977ec8a;
		mem[185] <= 64'hcced79a7a6406109;
		mem[186] <= 64'hcc6b0496718f78c;
		mem[187] <= 64'hb32008ecd82f7a0f;
		mem[188] <= 64'h33779b315a9e5705;
		mem[189] <= 64'h8c912394e5a9da86;
		mem[190] <= 64'h4cbaea7a24f14c03;
		mem[191] <= 64'hf35c52df9bc6c180;
		mem[192] <= 64'h496cf0190a81c6b7;
		mem[193] <= 64'hf68a48bcb5b64b34;
		mem[194] <= 64'h36a1815274eeddb1;
		mem[195] <= 64'h894739f7cbd95032;
		mem[196] <= 64'h910aa2a49687d38;
		mem[197] <= 64'hb6f6128ff65ff0bb;
		mem[198] <= 64'h76dddb613707663e;
		mem[199] <= 64'hc93b63c48830ebbd;
		mem[200] <= 64'h7672fcda32653c2a;
		mem[201] <= 64'hc994447f8d52b1a9;
		mem[202] <= 64'h9bf8d914c0a272c;
		mem[203] <= 64'hb6593534f33daaaf;
		mem[204] <= 64'h360ea6e9718c87a5;
		mem[205] <= 64'h89e81e4ccebb0a26;
		mem[206] <= 64'h49c3d7a20fe39ca3;
		mem[207] <= 64'hf6256f07b0d41120;
		mem[208] <= 64'h3750e99f7b48338d;
		mem[209] <= 64'h88b6513ac47fbe0e;
		mem[210] <= 64'h489d98d40527288b;
		mem[211] <= 64'hf77b2071ba10a508;
		mem[212] <= 64'h772cb3ac38a18802;
		mem[213] <= 64'hc8ca0b0987960581;
		mem[214] <= 64'h8e1c2e746ce9304;
		mem[215] <= 64'hb7077a42f9f91e87;
		mem[216] <= 64'h84ee55c43acc910;
		mem[217] <= 64'hb7a85df9fc9b4493;
		mem[218] <= 64'h778394173dc3d216;
		mem[219] <= 64'hc8652cb282f45f95;
		mem[220] <= 64'h4832bf6f0045729f;
		mem[221] <= 64'hf7d407cabf72ff1c;
		mem[222] <= 64'h37ffce247e2a6999;
		mem[223] <= 64'h88197681c11de41a;
		mem[224] <= 64'haf27bb05625a140;
		mem[225] <= 64'hb514c315e9122cc3;
		mem[226] <= 64'h753f0afb284aba46;
		mem[227] <= 64'hcad9b25e977d37c5;
		mem[228] <= 64'h4a8e218315cc1acf;
		mem[229] <= 64'hf5689926aafb974c;
		mem[230] <= 64'h354350c86ba301c9;
		mem[231] <= 64'h8aa5e86dd4948c4a;
		mem[232] <= 64'h35ec77736ec15bdd;
		mem[233] <= 64'h8a0acfd6d1f6d65e;
		mem[234] <= 64'h4a21063810ae40db;
		mem[235] <= 64'hf5c7be9daf99cd58;
		mem[236] <= 64'h75902d402d28e052;
		mem[237] <= 64'hca7695e5921f6dd1;
		mem[238] <= 64'ha5d5c0b5347fb54;
		mem[239] <= 64'hb5bbe4aeec7076d7;
		mem[240] <= 64'h74ce623627ec547a;
		mem[241] <= 64'hcb28da9398dbd9f9;
		mem[242] <= 64'hb03137d59834f7c;
		mem[243] <= 64'hb4e5abd8e6b4c2ff;
		mem[244] <= 64'h34b238056405eff5;
		mem[245] <= 64'h8b5480a0db326276;
		mem[246] <= 64'h4b7f494e1a6af4f3;
		mem[247] <= 64'hf499f1eba55d7970;
		mem[248] <= 64'h4bd06ef51f08aee7;
		mem[249] <= 64'hf436d650a03f2364;
		mem[250] <= 64'h341d1fbe6167b5e1;
		mem[251] <= 64'h8bfba71bde503862;
		mem[252] <= 64'hbac34c65ce11568;
		mem[253] <= 64'hb44a8c63e3d698eb;
		mem[254] <= 64'h7461458d228e0e6e;
		mem[255] <= 64'hcb87fd289db983ed;
end

endmodule