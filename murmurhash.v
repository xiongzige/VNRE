module murmurhash(
clk,
reset,
chipselect,
address,
read,
write,
writedata,
byteenable,
readdata
);

input clk;
input reset;
input chipselect;
input[3:0] address;
input read;
input write;
input[63:0] writedata;
input[7:0] byteenable;

output[63:0] readdata;

reg[63:0] readdata;

reg[63:0] raw_data_reg;
reg[15:0] len_reg;
reg[15:0] acc_status_reg;
reg[7:0] control_reg;
reg[31:0] seed_reg;
reg[63:0] fp_data_reg;
reg[7:0] loop_status_reg;
reg[15:0] offcut_mod8_reg; //(len/8)
reg[63:0] tail_reg;//tail of the string
reg[15:0] status_reg;

reg raw_data_reg_select;
reg len_reg_select;
reg acc_status_reg_select;
reg control_reg_select;
reg seed_reg_select;
reg fp_data_reg_select;
reg loop_status_reg_select;
reg offcut_mod8_reg_select;
reg tail_reg_select;
reg status_reg_select;

//reg[63:0] hash_reg;
//reg[63:0] k_reg;
//reg[63:0] j_reg;
reg[127:0] hash_reg;
reg[127:0] k_reg;
reg[127:0] j_reg;
reg[15:0] i_reg; //offcut_reg

parameter m = 64'hc6a4a7935bd1e995;
parameter r = 47;

parameter MS0=4'b0000,
		  MS1=4'b0001,
		  MS2=4'b0010,
		  MS3=4'b0011,
		  MS4=4'b0100,
		  MS5=4'b0101,
		  MS6=4'b0110,
		  MS7=4'b0111,
		  MS8=4'b1000,
		  MS9=4'b1001,
		  MS10=4'b1010,
		  MS30=4'b1011;

parameter SS0=4'b0000,
		  SS1=4'b0001,
		  SS2=4'b0010,
		  SS3=4'b0011,
		  SS4=4'b0100,
		  SS5=4'b0101,
		  SS6=4'b0110,
		  SS7=4'b0111,
		  SS8=4'b1000;

parameter SS_oc_0=4'b0000,
		  SS_oc_1=4'b0001,
		  SS_oc_2=4'b0010,
		  SS_oc_3=4'b0011,
		  SS_oc_4=4'b0100,
		  SS_oc_5=4'b0101,
		  SS_oc_6=4'b0110,
		  SS_oc_7=4'b0111,
		  SS_oc_8=4'b1000,
		  SS_oc_9=4'b1001;

reg[3:0] cur_state;
reg[3:0] nxt_state;

reg[3:0] sub_cur_state;
reg[3:0] sub_nxt_state;

reg[3:0] sub_cur_state_offcut;
reg[3:0] sub_nxt_state_offcut;

always @(address)
begin
	raw_data_reg_select <= 0;
	len_reg_select <= 0;
	acc_status_reg_select <= 0;
	control_reg_select <= 0;
	seed_reg_select <= 0;
	fp_data_reg_select <= 0;
	loop_status_reg_select <= 0;
	offcut_mod8_reg_select <= 0;
	tail_reg_select <= 0;
	status_reg_select <= 0;
	case(address)
	4'b0000: raw_data_reg_select <= 1;
	4'b0001: len_reg_select <= 1;
	4'b0010: acc_status_reg_select <= 1;
	4'b0011: control_reg_select <= 1;
	4'b0100: seed_reg_select <= 1;
	4'b0101: fp_data_reg_select <= 1;
	4'b0110: loop_status_reg_select <= 1;
	4'b0111: offcut_mod8_reg_select <= 1;
	4'b1000: tail_reg_select <= 1;
	4'b1001: status_reg_select <= 1;
	default:
	begin
		raw_data_reg_select <= 0;
		len_reg_select <= 0;
		acc_status_reg_select <= 0;
		control_reg_select <= 0;
		seed_reg_select <= 0;
		fp_data_reg_select <= 0;
		loop_status_reg_select <= 0;
		offcut_mod8_reg_select <= 0;
		tail_reg_select <= 0;
		status_reg_select <= 0;
	end
	endcase
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		raw_data_reg <= 0;
	else
	begin
		if(chipselect&write&raw_data_reg_select)
		begin
			if(byteenable[0])
				raw_data_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				raw_data_reg[15:8] <= writedata[15:8];
			if(byteenable[2])
				raw_data_reg[23:16] <= writedata[23:16];
			if(byteenable[3])
				raw_data_reg[31:24] <= writedata[31:24];
			if(byteenable[4])
				raw_data_reg[39:32] <= writedata[39:32];
			if(byteenable[5])
				raw_data_reg[47:40] <= writedata[47:40];
			if(byteenable[6])
				raw_data_reg[55:48] <= writedata[55:48];
			if(byteenable[7])
				raw_data_reg[63:56] <= writedata[63:56];
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		len_reg <= 0;
	else
	begin
		if(chipselect&write&len_reg_select)
		begin
			if(byteenable[0])
				len_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				len_reg[15:8] <= writedata[15:8];			
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		acc_status_reg <= 16'h0;
	else
	begin
		if((nxt_state == MS3)&&(sub_nxt_state == SS7))
			acc_status_reg <= acc_status_reg + 1;
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		loop_status_reg <= 8'h0;
	else
	begin
		if((nxt_state == MS3)&&(sub_nxt_state == SS7))
			loop_status_reg <= 8'b1;
		if(chipselect&write&loop_status_reg_select)
		begin
			if(byteenable[0])
				loop_status_reg[7:0] <= writedata[7:0];
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		control_reg <= 0;
	else
	begin
		if(chipselect&write&control_reg_select)
		begin
			if(byteenable[0])
				control_reg[7:0] <= writedata[7:0];
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		seed_reg <= 0;
	else
	begin
		if(chipselect&write&seed_reg_select)
		begin
			if(byteenable[0])
				seed_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				seed_reg[15:8] <= writedata[15:8];
			if(byteenable[2])
				seed_reg[23:16] <= writedata[23:16];
			if(byteenable[3])
				seed_reg[31:24] <= writedata[31:24];
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		offcut_mod8_reg <= 0;
	else
	begin
		if(chipselect&write&offcut_mod8_reg_select)
		begin
			if(byteenable[0])
				offcut_mod8_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				offcut_mod8_reg[15:8] <= writedata[15:8];
		end
		/*if((nxt_state == MS3)&&(sub_nxt_state == SS8)&&(!loop_status_reg[0]))
			offcut_mod8_reg <= 0;*/
	end
end

always @(chipselect or address or read)
//always @(*) 
begin
	if(chipselect&read)
	begin
		case(address)
		4'b0000: readdata <= raw_data_reg;
		4'b0001: readdata <= len_reg;
		4'b0010: readdata <= acc_status_reg;
		4'b0011: readdata <= control_reg;
		4'b0100: readdata <= seed_reg;
		4'b0101: readdata <= fp_data_reg;
		4'b0110: readdata <= loop_status_reg;
		4'b0111: readdata <= offcut_mod8_reg;
		4'b1000: readdata <= tail_reg;
		4'b1001: readdata <= status_reg;
		default: readdata <= 64'haaaa;
		endcase
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
	begin
		cur_state <= 4'b0;
		sub_cur_state <= 4'b0;
		sub_cur_state_offcut <= 4'b0;
	end
	else
	begin
		cur_state <= nxt_state;
		sub_cur_state <= sub_nxt_state;
		sub_cur_state_offcut <= sub_nxt_state_offcut;
	end
end

always @(control_reg or cur_state or sub_cur_state or sub_cur_state_offcut or acc_status_reg or offcut_mod8_reg or loop_status_reg or i_reg) 
//always @(control_reg or cur_state or sub_cur_state or sub_cur_state_offcut or loop_status_reg) 
begin
	//nxt_state = 'bx;
	//sub_nxt_state = 'bx;
	//sub_nxt_state_offcut = 'bx;
	case(cur_state)
		MS0:
			if(control_reg[0])
				nxt_state = MS1;
			else
				nxt_state = MS0;
		MS1:
			if(control_reg[0]) 
			begin
				nxt_state = MS2;
			end
		MS2:
			if(control_reg[0])
				nxt_state = MS3;
		MS3:
			//if(control_reg[0]&&(acc_status_reg<offcut_mod8_reg))
			if(control_reg[0])
			begin
				//nxt_state = MS3;
				case(sub_cur_state)
				SS0:
					//if(!loop_status_reg[0])
					begin
						nxt_state = MS3;
						sub_nxt_state = SS1;
					end
					//else
						//sub_nxt_state = SS0;
				SS1:
					begin
						nxt_state = MS3;
						sub_nxt_state = SS2;
					end
				SS2:
					begin
						nxt_state = MS3;
						sub_nxt_state = SS3;
					end
				SS3:
					begin
						nxt_state = MS3;
						sub_nxt_state = SS4;
					end
				SS4:
					begin
						nxt_state = MS3;
						sub_nxt_state = SS5;
					end
				SS5:
					begin
						nxt_state = MS3;
						sub_nxt_state = SS6;
					end
				SS6:
					begin
						nxt_state = MS3;
						sub_nxt_state = SS7;
					end
				SS7:
					begin
						nxt_state = MS3;
						sub_nxt_state = SS8;
					end
				SS8:
					begin
						if(acc_status_reg<offcut_mod8_reg)
						begin
							if(loop_status_reg == 0)
							begin
								nxt_state = MS3;
								sub_nxt_state = SS0;
								//$display("acc = %h", acc_status_reg);
								//$display("hash = %h", hash_reg);
							end
							else
							begin
								nxt_state = MS3;
								sub_nxt_state = SS8;
							end
						end
						else
						begin
							nxt_state = MS30;
							sub_nxt_state = SS0;
							//$display("hash = %h", hash_reg);
						end
					end											
				default: sub_nxt_state = SS0;
				endcase
			end
		MS30:
			begin
				if(i_reg!=16'h0)
				begin
					case(sub_cur_state_offcut)
					SS_oc_0:
					begin
						sub_nxt_state_offcut = SS_oc_1;
						nxt_state = MS30;
					end
					SS_oc_1:
					begin
						sub_nxt_state_offcut = SS_oc_2;
						nxt_state = MS30;
					end
					SS_oc_2:
					begin
						sub_nxt_state_offcut = SS_oc_3;
						nxt_state = MS30;
					end
					SS_oc_3:
					begin
						sub_nxt_state_offcut = SS_oc_4;
						nxt_state = MS30;
					end
					SS_oc_4:
					begin
						sub_nxt_state_offcut = SS_oc_5;
						nxt_state = MS30;
					end
					SS_oc_5:
					begin
						sub_nxt_state_offcut = SS_oc_6;
						nxt_state = MS30;
					end
					SS_oc_6:
					begin
						sub_nxt_state_offcut = SS_oc_7;
						nxt_state = MS30;
					end
					SS_oc_7:
					begin
						sub_nxt_state_offcut = SS_oc_8;
						nxt_state = MS30;
					end
					SS_oc_8:
					begin
						sub_nxt_state_offcut = SS_oc_9;
						nxt_state = MS30;
					end
					SS_oc_9:
					begin
						sub_nxt_state_offcut = SS_oc_9;
						nxt_state = MS4;
					end	
					default: sub_nxt_state_offcut = SS_oc_0;
					endcase
				end
				else
					nxt_state = MS4;
			end	
		MS4:
			if(control_reg[0])
				nxt_state = MS5;
		MS5:
			if(control_reg[0])
				nxt_state = MS6;
		MS6:
			if(control_reg[0])
				nxt_state = MS7;
		MS7:
			if(control_reg[0])
				nxt_state = MS8;
		MS8:
			if(control_reg[0])
				nxt_state = MS9;
		MS9:
			if(control_reg[0])
				nxt_state = MS10;
		MS10:
			if(control_reg[0])
				nxt_state = MS10;
			else
				nxt_state = MS0;
		default: nxt_state = MS0;
	endcase
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		hash_reg <= 64'b0;
	else
	begin
		if(nxt_state == MS1)
			hash_reg <= len_reg*m;
		if(nxt_state == MS2)
			hash_reg <= hash_reg[63:0]^seed_reg;
		if((nxt_state == MS3)&&(sub_nxt_state == SS6))
			hash_reg <= hash_reg^k_reg[63:0];
		if((nxt_state == MS3)&&(sub_nxt_state == SS7))
			hash_reg <= hash_reg[63:0]*m;
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_1))
		begin
			if(i_reg[2:0]==3'b111)
				hash_reg <= hash_reg[63:0]^{8'b0,tail_reg[55:48],48'b0};
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_2))
		begin
			if(i_reg[2:0]==3'b110)
				hash_reg <= hash_reg[63:0]^{16'b0,tail_reg[47:40],40'b0};
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_3))
		begin
			if(i_reg[2:0]==3'b101)
				hash_reg <= hash_reg[63:0]^{24'b0,tail_reg[39:32],32'b0};
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_4))
		begin
			if(i_reg[2:0]==3'b100)
				hash_reg <= hash_reg[63:0]^{32'b0,tail_reg[31:24],24'b0};
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_5))
		begin
			if(i_reg[2:0]==3'b011)
				hash_reg <= hash_reg[63:0]^{40'b0,tail_reg[23:16],16'b0};
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_6))
		begin
			if(i_reg[2:0]==3'b010)
				hash_reg <= hash_reg[63:0]^{48'b0,tail_reg[15:8],8'b0};
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_7))
		begin
			if(i_reg[2:0]==3'b001)
				hash_reg <= hash_reg[63:0]^{56'b0,tail_reg[7:0]};
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_8))
		begin
			hash_reg <= hash_reg[63:0]*m;
		end
		if(nxt_state == MS5)
			hash_reg <= hash_reg^j_reg[16:0];
		if(nxt_state == MS6)
			hash_reg <= hash_reg[63:0]*m;
		if(nxt_state == MS8)
			hash_reg <= hash_reg^j_reg[16:0];
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		k_reg <= 64'b0;
	else
	begin
		if(nxt_state == MS1)
			k_reg <= raw_data_reg;
		if((nxt_state == MS3)&&(sub_nxt_state == SS0))
			k_reg <= raw_data_reg;
		if((nxt_state == MS3)&&(sub_nxt_state == SS2))
			k_reg <= k_reg[63:0]*m;
		if((nxt_state == MS3)&&(sub_nxt_state == SS4))
			k_reg <= {64'b0,k_reg[63:0]}^j_reg[16:0];
		if((nxt_state == MS3)&&(sub_nxt_state == SS5))
			k_reg <= k_reg[63:0]*m;
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		j_reg <= 64'b0;
	else
	begin
		if((nxt_state == MS3)&&(sub_nxt_state == SS3))
			j_reg <= k_reg>>r;
		if(nxt_state == MS4)
			j_reg <= hash_reg>>r;
		if(nxt_state == MS7)
			j_reg <= hash_reg>>r;
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		fp_data_reg <= 64'b0;
	else
	begin
		if(nxt_state == MS9)
			fp_data_reg <= hash_reg[63:0];
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		i_reg <= 16'b0;
	else
	begin
		if(nxt_state == MS1)
			i_reg <= len_reg&16'h7;
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_1))
		begin
			if(i_reg[2:0]==3'b111)
				i_reg <= i_reg - 1;
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_2))
		begin
			if(i_reg[2:0]==3'b110)
				i_reg <= i_reg - 1;
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_3))
		begin
			if(i_reg[2:0]==3'b101)
				i_reg <= i_reg - 1;
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_4))
		begin
			if(i_reg[2:0]==3'b100)
				i_reg <= i_reg - 1;
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_5))
		begin
			if(i_reg[2:0]==3'b011)
				i_reg <= i_reg - 1;
		end
		if((nxt_state == MS30)&&(sub_nxt_state_offcut == SS_oc_6))
		begin
			if(i_reg[2:0]==3'b010)
				i_reg <= i_reg - 1;
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		tail_reg <= 0;
	else
	begin
		if(chipselect&write&tail_reg_select)
		begin
			if(byteenable[0])
				tail_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				tail_reg[15:8] <= writedata[15:8];
			if(byteenable[2])
				tail_reg[23:16] <= writedata[23:16];
			if(byteenable[3])
				tail_reg[31:24] <= writedata[31:24];
			if(byteenable[4])
				tail_reg[39:32] <= writedata[39:32];
			if(byteenable[5])
				tail_reg[47:40] <= writedata[47:40];
			if(byteenable[6])
				tail_reg[55:48] <= writedata[55:48];
			if(byteenable[7])
				tail_reg[63:56] <= writedata[63:56];
		end
	end
end

always @(posedge clk or negedge reset)
begin
	if(reset == 1'b0)
		status_reg <= 0;
	else
	begin
		if(chipselect&write&status_reg_select)
		begin
			if(byteenable[0])
				status_reg[7:0] <= writedata[7:0];
			if(byteenable[1])
				status_reg[15:8] <= writedata[15:8];			
		end
		if(nxt_state == MS9)
			status_reg <= 16'h1;
	end
end

endmodule