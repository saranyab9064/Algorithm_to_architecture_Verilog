`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Algorithms to architecture(Assignment 2) 
// Engineer: saranya006@e.ntu.edu.sg
// 
// Create Date:    18:56:46 01/05/2017 
// Design Name:    MD5 Hashing Algorithm
// Module Name:    Md5Hash 
// Project Name:   Md5Hashing
// Target Devices: Sparten 6
// Tool versions:  14.3
// Description:    Md5 Algorithm, and state machine to receive the data through serial, calculate the digest and transmit the result via serial.
//
// Dependencies:   Sparton 6 kit, Uart Module, Serial terminl program
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// terminal data will be ended with "CTRL+D" signal which will be detected by the program for end of the chunk data.
//////////////////////////////////////////////////////////////////////////////////
module Md5Hash(
    input clk,
    input reset,
    input [7:0] rx_byte,
    input received,
    input is_transmitting,
    output reg transmit,
    output reg [7:0] tx_byte
    );

parameter IDLE = 2'b00;
parameter PADDING = 2'b01;
parameter TRANSFORM = 2'b10;
parameter TRANSMIT_RESULT = 2'b11;

reg [511:0]InputChunk;
reg [1:0] hash_state = IDLE;
reg [8:0]top = 9'b000000000; 
reg [8:0]top_process= 9'b000000000;
reg [1:0]flag = 2'b00;
// This length will be required for padding
reg[63:0]TotalLegth = 64'h0000000000000000;
// This length will be required for padding
reg[63:0]TotalLegth_process = 64'h0000000000000000;

reg [511:0] InputWb;
reg [511:0] paddWb;
reg [511:0] temp;
reg [3:0] TxByteCount;
reg [7:0] HashResult[15:0];
reg [31:0] Input0 [15:0];
// All variables are unsigned 32 bit 
reg [31:0] a0 = 'h67452301; //A
reg [31:0] b0 = 'hefcdab89; //B
reg [31:0] c0 = 'h98badcfe; //C
reg [31:0] d0 = 'h10325476; //D

reg [31:0] A,B,C,D,F,g,dTemp;

reg [6:0]i;
reg lastchunk = 1'b0;
`define rotate(x, c)                  \
((x) << c) | ((x) >> (32-c));         \


always @(posedge clk) begin
	if (reset) begin
		top = 9'b000000000;  
		TotalLegth = 64'h0000000000000000;
		top_process = 9'b000000000;  
		TotalLegth_process = 64'h0000000000000000;
		flag = 2'b00;
	end
	else if (received) begin
      temp = {{504{1'b0}},rx_byte};
		InputWb =  temp << top;
		top = top + 9'b000001000; 
		TotalLegth = TotalLegth + 64'h0000000000001000;
		// 
		if(top == 9'h200) begin    
			top = 9'b000000000;
			flag = 2'b01; // 01 for Received chunk, // trigger statemachine to process
		end
		else if(rx_byte == 'h03) begin
		   // Use top for Padding and reset it there
			// Last chunk, and not if top == 1 means only CTRL+D received in that case no need of peform HASHING just move to TRANSMIT
			flag = 2'b10; 
			top_process = top;
			TotalLegth_process = TotalLegth; // minus the CTRL+D length
			TotalLegth = 64'h0000000000000000;
			top = 9'b000000000;
		end
		else begin
			flag = 2'b00; 
		end
	end
end

always @(posedge clk) begin
	if (reset) begin
		TxByteCount = 4'b0000;
		transmit = 1'b0;
		hash_state = IDLE;
		tx_byte = 0;
	   //Initialize variables:				
		a0 = 'h67452301;   //A
		b0 = 'hefcdab89;   //B
		c0 = 'h98badcfe;   //C
		d0 = 'h10325476;   //D
	end
	else begin
		// Hash state machine
		case (hash_state) 
			IDLE: begin
				if(flag == 2'b01) begin					
					transmit = 1'b0;
					tx_byte = 0;
					paddWb = InputWb;
					hash_state = TRANSFORM;
				end
				else if(flag == 2'b10) begin
					// its last chunk enable a flag here
					lastchunk = 1'b1;			
					transmit = 1'b0;
					tx_byte = 0;
					paddWb = InputWb;
					hash_state = PADDING;
				end
				else begin
					lastchunk = 1'b0;
					hash_state = IDLE;
					TxByteCount = 4'b0000;
					transmit = 1'b0;
					tx_byte = 0;
					// initialize all the hardcoded default value here which will be used in transform		
					{HashResult[3],HashResult[2],HashResult[1],HashResult[0]}     <= 'h00000000;
					{HashResult[7],HashResult[6],HashResult[5],HashResult[4]}     <= 'h00000000;
					{HashResult[11],HashResult[10],HashResult[9],HashResult[8]}   <= 'h00000000;
					{HashResult[15],HashResult[14],HashResult[13],HashResult[12]} <= 'h00000000;
				end
			end			
			PADDING: begin	
			   // perform padding here
				paddWb[top_process- 9'b000001000] = 1'b1;					// padd 1 at the end of msg
				//top_process = top_process + 9'b000000001; 
				paddWb = paddWb & ({512{1'b1}}>>(512-(top_process+'b000000001)));            // Padd zero to the rest of the length
				paddWb = paddWb | {{448{1'b0}},(TotalLegth_process - 64'h0000000000001000)};    // Padd the mod (2^64) length of the complete msg	
				// go to transform state
				hash_state = TRANSFORM;
			end
			
			TRANSFORM: begin	
			   // copy input buffer to process after padding
			   Input0[0]  = paddWb[31:0];
				Input0[1]  = paddWb[63:32];
				Input0[2]  = paddWb[95:64];
				Input0[3]  = paddWb[127:96];
				Input0[4]  = paddWb[159:128];
				Input0[5]  = paddWb[191:160];
				Input0[6]  = paddWb[223:192];
				Input0[7]  = paddWb[255:224];
				Input0[8]  = paddWb[287:256];
				Input0[9]  = paddWb[319:288];
				Input0[10] = paddWb[351:320];
				Input0[11] = paddWb[383:352];
				Input0[12] = paddWb[415:384];
				Input0[13] = paddWb[447:416];
				Input0[14] = paddWb[479:448];
				Input0[15] = paddWb[511:480];
				
			   // Initialize the values for this chunk of data
				A = a0;
				B = b0;
				C = c0;
				D = d0;
				//Main loop:
// First function, 16 iteration
						F = (B & C) | ((~ B) & D);
						g = 0;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hd76aa478 + Input0[g]), 'd7);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 1;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'he8c7b756 + Input0[g]), 'd12);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 2;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h242070db + Input0[g]), 'd17);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 3;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hc1bdceee + Input0[g]), 'd22);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 4;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hf57c0faf + Input0[g]), 'd7);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 5;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h4787c62a + Input0[g]), 'd7);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 6;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'ha8304613 + Input0[g]), 'd17);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 7;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hfd469501 + Input0[g]), 'd22);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 8;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h698098d8 + Input0[g]), 'd7);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 9;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h8b44f7af + Input0[g]), 'd12);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 10;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hffff5bb1 + Input0[g]), 'd17);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 11;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h895cd7be + Input0[g]), 'd22);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 12;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h6b901122 + Input0[g]), 'd7);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 13;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hfd987193 + Input0[g]), 'd12);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 14;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'ha679438e + Input0[g]), 'd17);
						A = dTemp;
						
						F = (B & C) | ((~ B) & D);
						g = 15;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h49b40821 + Input0[g]), 'd22);
						A = dTemp;
						
// Second function, 16 iteration
						F = (D & B) | ((~ D) & C);
						g = (5*16 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hf61e2562  + Input0[g]), 'd5);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*17 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hc040b340 + Input0[g]), 'd9);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*18 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h265e5a51 + Input0[g]), 'd14);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*19 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'he9b6c7aa + Input0[g]), 'd20);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*20 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hd62f105d + Input0[g]), 'd5);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*21 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h02441453 + Input0[g]), 'd9);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*22 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hd8a1e681 + Input0[g]), 'd14);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*23 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'he7d3fbc8 + Input0[g]), 'd20);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*24 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h21e1cde6 + Input0[g]), 'd5);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*25 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hc33707d6 + Input0[g]), 'd9);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*26 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hf4d50d87 + Input0[g]), 'd14);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*27 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h455a14ed + Input0[g]), 'd20);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*28 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'ha9e3e905 + Input0[g]), 'd5);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*29 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hfcefa3f8 + Input0[g]), 'd9);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*30 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h676f02d9 + Input0[g]), 'd14);
						A = dTemp;
						
						F = (D & B) | ((~ D) & C);
						g = (5*31 + 1) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h8d2a4c8a + Input0[g]), 'd20);
						A = dTemp;			

// Third function, 16 iteration	
					   F = B ^ C ^ D;
						g = (3*32 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hfffa3942 + Input0[g]), 'd4);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*33 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h8771f681 + Input0[g]), 'd11);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*34 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h6d9d6122 + Input0[g]), 'd16);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*35 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hfde5380c + Input0[g]), 'd23);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*36 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'ha4beea44 + Input0[g]), 'd4);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*37 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h4bdecfa9 + Input0[g]), 'd11);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*38 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hf6bb4b60 + Input0[g]), 'd16);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*39 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hbebfbc70 + Input0[g]), 'd23);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*40 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h289b7ec6 + Input0[g]), 'd4);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*41 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'heaa127fa + Input0[g]), 'd11);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*42 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hd4ef3085 + Input0[g]), 'd16);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*43 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h04881d05 + Input0[g]), 'd23);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*44 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hd9d4d039 + Input0[g]), 'd4);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*45 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'he6db99e5 + Input0[g]), 'd11);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*46 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h1fa27cf8 + Input0[g]), 'd16);
						A = dTemp;
						
						F = B ^ C ^ D;
						g = (3*47 + 5) % 16;			
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hc4ac5665 + Input0[g]), 'd23);
						A = dTemp;

// Fourth function, 16 iteration	
						F = C ^ (B | (~ D));
						g = (7*48) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hf4292244 + Input0[g]), 'd6);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*49) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h432aff97 + Input0[g]), 'd10);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*50) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hab9423a7 + Input0[g]), 'd15);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*51) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hfc93a039 + Input0[g]), 'd21);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*52) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h655b59c3 + Input0[g]), 'd6);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*53) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h8f0ccc92 + Input0[g]), 'd10);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*54) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hffeff47d + Input0[g]), 'd15);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*55) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h85845dd1 + Input0[g]), 'd21);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*56) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h6fa87e4f + Input0[g]), 'd6);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*57) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hfe2ce6e0 + Input0[g]), 'd10);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*58) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'ha3014314 + Input0[g]), 'd15);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*59) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h4e0811a1 + Input0[g]), 'd21);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*60) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hf7537e82 + Input0[g]), 'd6);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*61) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'hbd3af235 + Input0[g]), 'd10);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*62) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'h2ad7d2bb + Input0[g]), 'd15);
						A = dTemp;
						
						F = C ^ (B | (~ D));
						g = (7*63) % 16;		
						//definitions of a,b,c,d
						dTemp = D;
						D = C;
						C = B;
						B = B + `rotate((A + F + 'heb86d391 + Input0[g]), 'd21);
						A = dTemp;
			
				//Add this chunk's hash to result so far:
				a0 = a0 + A;
				b0 = b0 + B;
				c0 = c0 + C;
				d0 = d0 + D;
				// if this is last chunk move to TRANSMIT_RESULT
				if(lastchunk == 1'b1)begin
					lastchunk = 1'b0;
					{HashResult[3],HashResult[2],HashResult[1],HashResult[0]}     <= a0;
					{HashResult[7],HashResult[6],HashResult[5],HashResult[4]}     <= b0;
					{HashResult[11],HashResult[10],HashResult[9],HashResult[8]}   <= c0;
					{HashResult[15],HashResult[14],HashResult[13],HashResult[12]} <= d0;
					hash_state = TRANSMIT_RESULT;
				end
				// ELSE move to IDLE
				else begin
					hash_state = IDLE;
				end
			end		
			
			TRANSMIT_RESULT: begin	
			// disable last chunk flag and move to idle after transmitting
			// Have to transmit 16 bytes(128 bits)
			   transmit = 1'b0;
				if(!is_transmitting)begin
					tx_byte =  HashResult[TxByteCount];
					transmit = 1'b1;
					TxByteCount = TxByteCount+4'b0001;
					if (TxByteCount == 4'b1111)begin
						TxByteCount = 4'b0000;
						hash_state = IDLE;
					end
					else begin
						hash_state = TRANSMIT_RESULT;
					end
				end	
				else begin
					transmit = 1'b0;
					hash_state = TRANSMIT_RESULT;
				end
			end
			
			default: 
				hash_state = IDLE;
		endcase
	end
end
endmodule



