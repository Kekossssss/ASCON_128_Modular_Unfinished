//Author : Guilloux
//Module : Module regroupant les différents composants (Module finale du projet)
//Last modified : 09/08/2024

`timescale 1ns/1ps

import ascon_pack::*;


module ASCON_Top #(
    parameter nb_bits_A = 64,
    parameter nb_bits_data = 184
)(
	//Clock et reset du module
	input logic clk_i,
	input logic rst_i,
	//Entrees logiques
	input logic start_i,
	input logic decrypt_enable_i,
	input logic associated_data_valid_i,
	input logic data_valid_i,
	input logic tag_valid_i,
	//Entrees de valeurs
	input logic [nb_bits_A-1:0] associated_data_i,
	input logic [127:0] tag_i,
	input logic [nb_bits_data-1:0] data_i,
	input logic [191:0] initialisation_vector_i,
	input logic [159:0] key_i,
	input logic [127:0] nonce_i,
	//Sorties logiques
	output logic end_o,
	output logic data_valid_o,
	output logic tag_valid_o,
	//Sorties de valeurs
	output logic [nb_bits_data-1:0] data_o,
	output logic [127:0] tag_o
);
// Description des connexions internes
	//Connectiques de controles internes
	logic sel_mux_perm_s;
	logic sel_muxData_perm_s;
	logic perm_data_mux_select_s;
	logic write_enable_data_s;
	logic write_enable_cipher_s;
	logic write_enable_tag_s;
	logic en_xor_begin_data_s;
	logic en_xor_begin_key_s;
	logic en_xor_end_lsb_s;
	logic en_xor_end_key_s;
	logic en_cpt_round_s;
	logic init_p6_s;
	logic init_p12_s;
	logic en_cpt_bloc_s;
	logic init_bloc_s;
	//Connectiques de valeurs/donnees internes
	logic [3:0] round_s;
	logic [3:0] bloc_s;
	logic [7:0] nb_perm_a_s;
	logic [7:0] nb_perm_b_s;
	logic [7:0] size_treated_data_r_s;
	logic [7:0] key_lenght_k_s;
	type_state registerS_s;       //<----Utile uniquement pour l'initialisation
	logic [159:0] final_key_s;
	logic [191:0] final_IV_s;
	logic [255:0] final_data_s;
	logic [127:0] tag_verif_s;
	logic [127:0] tag_permutation_out_s;
	logic [nb_bits_data-1:0] data_s;
	logic [nb_bits_A-1:0] associated_data_s;
	logic [nb_bits_data-1:0] data_permutation_out_s;
	logic [nb_bits_data-1:0] perm_data_s;
	//Description des entiers
	int r,k,a,b;
//Initialisation des différents blocs
	//Bloc de la Machine d'Etats Finis (FSM)
	FSM_v2 FSM (
		.clk_i(clk_i),
		.rst_i(rst_i),
		.start_i(start_i),
		.data_valid_i(data_valid_i),
		.decrypt_enable_i(decrypt_enable_i),
		.round_i(round_s),
		.bloc_i(bloc_s),
		.nb_perm_a_i(nb_perm_a_s),
		.en_cpt_round_o(en_cpt_round_s),
		.en_cpt_bloc_o(en_cpt_bloc_s),
		.init_p6_o(init_p6_s),
		.init_p12_o(init_p12_s),
		.init_bloc_o(init_bloc_s),
		.sel_mux_perm_o(sel_mux_perm_s),
		.sel_muxData_perm_o(sel_muxData_perm_s),
		.write_enable_data_o(write_enable_data_s),
		.write_enable_cipher_o(write_enable_cipher_s),
		.write_enable_tag_o(write_enable_tag_s),
		.en_xor_begin_data_o(en_xor_begin_data_s),
		.en_xor_begin_key_o(en_xor_begin_key_s),
		.en_xor_end_lsb_o(en_xor_end_lsb_s),
		.en_xor_end_key_o(en_xor_end_key_s),
		.end_o(end_o)
	);
	//Bloc de permutations et XOR
	permutation_xor PermXOR (
		//Entrees de donnees (S,P,K)
		.registerS_i(registerS_s),
		.key_lenght_k_i(key_lenght_k_s),
		.size_treated_data_r_i(size_treated_data_r_s),
		.data_i(final_data_s),
		.key_i(final_key_s),
		//Differentes entrees de selections
		.sel_mux_perm_i(sel_mux_perm_s),
		.sel_muxData_perm_i(sel_muxData_perm_s),
		.round_i(round_s),
		.write_enable_data_i(write_enable_data_s),
		.write_enable_cipher_i(write_enable_cipher_s),
		.write_enable_tag_i(write_enable_tag_s),
		.en_xor_begin_data_i(en_xor_begin_data_s),
		.en_xor_begin_key_i(en_xor_begin_key_s),
		.en_xor_end_lsb_i(en_xor_end_lsb_s),
		.en_xor_end_key_i(en_xor_end_key_s),
		//Clock et reset
		.clk_i(clk_i),
		.rst_i(rst_i),
		//Sorties de donnees (S,C,T)
		.data_o(data_s),
		.tag_o(tag_o)
	);
	//Bloc du compteur de round
	compteur_round CptRound (
		.clock_i(clk_i),
		.resetb_i(rst_i),
		.en_i(en_cpt_round_s),
		.init_p6_i(init_p6_s),
		.init_p12_i(init_p12_s),
		.nb_perm_a_i(nb_perm_a_s),
		.nb_perm_b_i(nb_perm_b_s),
		.round_o(round_s)
	);
	//Bloc du compteur de blocs
	compteur_blocs CptBlocs (
		.clock_i(clk_i),
    	.resetb_i(rst_i),
    	.en_i(en_cpt_bloc_s),
    	.init_bloc_i(init_bloc_s),
    	.bloc_o(bloc_s)
	);
	//Organizer blocs for the inputs
	initialisation_vector_organizer IV_ORGA (
	    .key_lenght_k_i(key_lenght_k_s),
	    .initialisation_vector_i(initialisation_vector_i),
	    .initialisation_vector_o(final_IV_s)
	);
	key_organizer KEY_ORGA (
	    .key_lenght_k_i(key_lenght_k_s),
	    .key_i(key_i),
	    .key_o(final_key_s)
	);
	data_organizer_v2 ASSOCIATED_DATA_ORGA (
	    .size_treated_data_r_i(size_treated_data_r_s),
	    .data_i(data_i),
	    .data_o(final_data_s)
	);
	data_organizer_v2 DATA_ORGA (
	    .size_treated_data_r_i(size_treated_data_r_s),
	    .data_i(data_i),
	    .data_o(final_data_s)
	);
	//Input data registers
	////Associated data input register
	register_w_en #(nb_bits_A) ASSOCIATED_REG (
		clk_i, rst_i, associated_data_valid_i, associated_data_i, associated_data_s
	);
	////Data input register
	register_w_en #(nb_bits_data) DATA_REG (
		clk_i, rst_i, data_valid_i, data_i, data_s
	);
	////Tag input register
	register_w_en #(128) TAG_REG (
		clk_i, rst_i, tag_valid_i, tag_i, tag_verif_s
	);
	//Assembler of the type_state register data
	type_state_assembler S_ASSEMBLER (
	    .clk_i(clk_i),
	    .start_i(start_i),
	    .rst_i(rst_i),
	    .end_i(end_o),
	    .initialisation_vector_i(final_IV_s),
	    .key_i(final_key_s),
	    .nonce_i(nonce_i),
	    .registerS_o(registerS_s)
	);
	//Organizer of the data for the output
	output_data_organizer OUT_DATA_ORGA (
	    .size_treated_data_r_i(size_treated_data_r_s),
	    .data_i(data_s),
	    .data_o(data_o)
	);
	//Mux for switching between the associated data or the data going in the permutation bloc
    configurable_mux #(1,256) PERM_DATA_MUX (
        .data_i({data_s, associated_data_s}),
        .sel_i(perm_data_mux_select_s),
        .data_o(perm_data_s)
    );
//Assignation of permutation parameters a and b at the start of each encryption/decryption
	always_comb begin
	   if (start_i) begin
	       nb_perm_a_s <= initialisation_vector_i[47:40];
	       nb_perm_b_s <= initialisation_vector_i[39:32];
	       size_treated_data_r_s <= initialisation_vector_i[55:48];
	       key_lenght_k_s <= initialisation_vector_i[63:56];
	   end
	   if (decrypt_enable_i) begin
	       if (tag_verif_s^tag_permutation_out_s == 128'h00000000000000000000000000000000) begin
	           tag_valid_o <= end_o;
	           tag_o <= tag_permutation_out_s;
	           data_valid_o <= end_o;
	           data_o <= data_permutation_out_s;
	       end
	       else begin
	           tag_valid_o <= 1'b0;
	           tag_o <= 128'h00000000000000000000000000000000;
	           data_valid_o <= 1'b0;
	           data_o <= 0;
	       end
	   end
	   else begin
	       tag_o <= tag_permutation_out_s;
	       tag_valid_o <= end_o;
	       data_valid_o <= end_o;
	       data_o <= data_permutation_out_s;
	   end
	end
endmodule : ASCON_Top
	
