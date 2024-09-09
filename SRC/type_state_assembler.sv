//Author : Guilloux
//Module : Allows to assemble the type_state S of 320bits from the IV,K,N vectors
//Last modified : 11/08/2024

`timescale 1ns / 1ps

import ascon_pack::*;


module type_state_assembler(
    input logic clk_i,
    input logic start_i,
    input logic rst_i,
    input logic end_i,
    input logic [191:0] initialisation_vector_i,
    input logic [159:0] key_i,
    input logic [127:0] nonce_i,
    output type_state registerS_o
    );
    //Internal nets description
    type_state registerS_s;
    //Register assignation
    always_ff @(posedge clk_i) begin
	   if (~rst_i || end_i) begin
	       registerS_s <= 320'h00000000000000000000000000000000000000000000000000000000000000000000000000000000;
	   end
	   else if (start_i) begin
	       registerS_s[0][63:32] <= registerS_s[0][63:32] ^ initialisation_vector_i[191:160];
	       registerS_s[0][31:0] <= registerS_s[0][31:0] ^ initialisation_vector_i[159:128] ^ key_i[159:128];
	       registerS_s[1] <= registerS_s[1] ^ initialisation_vector_i[127:64] ^ key_i[127:64];
	       registerS_s[2] <= registerS_s[2] ^ initialisation_vector_i[63:0] ^ key_i[63:0];
	       registerS_s[3] <= nonce_i[127:64];
	       registerS_s[4] <= nonce_i[63:0];
	   end
	end
	//Outputs assignation
	assign registerS_o = registerS_s;
endmodule : type_state_assembler
