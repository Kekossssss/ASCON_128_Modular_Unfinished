//Author : Guilloux
//Module : Module de la FSM, regroupant les transitions de tout l'algorithme de l'ASCON128, pour le decryptage
//Last modified : 17/08/2024


import ascon_pack::*;


`timescale 1ns/1ps


module FSM_v2
(
	//Clock et reset du module
	input logic clk_i,
	input logic rst_i,
	//Entrees logiques
	input logic start_i,
	input logic data_valid_i,
	input logic decrypt_enable_i,
	//Entrees de valeurs
	input logic [3:0] round_i,
	input logic [3:0] bloc_i,
	input logic [7:0] nb_perm_a_i,
	//Sorties logiques
	output logic en_cpt_round_o,
	output logic en_cpt_bloc_o,
	output logic init_p6_o,
	output logic init_p12_o,
	output logic init_bloc_o,
	output logic sel_mux_perm_o,
	output logic sel_muxData_perm_o,
	output logic write_enable_data_o,
	output logic write_enable_cipher_o,
	output logic write_enable_tag_o,
	output logic en_xor_begin_data_o,
	output logic en_xor_begin_key_o,
	output logic en_xor_end_lsb_o,
	output logic en_xor_end_key_o,
	output logic end_o
);
	//Definition des differents etats
	typedef enum {attente, conf_init, init_rd0, init_rd1_to_10, init_rd11, conf_assData, assData_rd6, assData_rd7_to_10, assData_rd11, confBoucle_txt, conf_txt, txt_rd6, txt_rd7_to_10, txt_rd11, conf_final, final_rd0, final_rd1_to_10, final_rd11, fin} state_t;
	state_t current_state, next_state;
	
	//Process sequentiel qui permet de realiser les registres de transition d'etat
	always_ff @(posedge clk_i or negedge rst_i) begin : seq_o
		if (rst_i == 1'b0)
			current_state <= attente;
		else current_state <= next_state;
	end : seq_o
	
	//Logique combinatoire pour la transition entre les différents états
	always_comb begin : comb_next_state
		case (current_state)
			attente : 
				if (start_i == 1'b1) next_state = conf_init;
				else next_state = attente;

			conf_init :  next_state = init_rd0;

			init_rd0 : next_state = init_rd1_to_10;

			init_rd1_to_10 :
				if (round_i == nb_perm_a_i-2) next_state = init_rd11;
				else next_state = init_rd1_to_10;

			init_rd11 : next_state = conf_assData;

			conf_assData : 
				if (data_valid_i == 1'b1) next_state = assData_rd6;
				else next_state = conf_assData;

			assData_rd6 : next_state = assData_rd7_to_10;

			assData_rd7_to_10 :
				if (round_i == nb_perm_a_i-2) next_state = assData_rd11;
				else next_state = assData_rd7_to_10;

			assData_rd11 : next_state = confBoucle_txt;

			confBoucle_txt : next_state = conf_txt;

			conf_txt : 
				if (data_valid_i == 1'b1) next_state = txt_rd6;
				else next_state = conf_txt;

			txt_rd6 : next_state = txt_rd7_to_10;

			txt_rd7_to_10 :
				if (round_i == nb_perm_a_i-2) next_state = txt_rd11;
				else next_state = txt_rd7_to_10;

			txt_rd11 :
				if (bloc_i == 2'h1) next_state = conf_final;
				else next_state = conf_txt;

			conf_final :
				if (data_valid_i == 1'b1) next_state = final_rd0;
				else next_state = conf_final;

			final_rd0 : next_state = final_rd1_to_10;

			final_rd1_to_10 :
				if (round_i == nb_perm_a_i-2) next_state = final_rd11;
				else next_state = final_rd1_to_10;

			final_rd11 : next_state = fin;

			fin : next_state = attente;
			
			default : next_state = attente;
		endcase
	end : comb_next_state

	//Logique combinatoire qui donne les valeurs de sorties en fonction de l'etat
	always_comb begin : comb_outputs
		case (current_state)
			attente : 
				begin
					en_cpt_round_o <= 1'b0;
					en_cpt_bloc_o <= 1'b0;
					init_p6_o <= 1'b0;
					init_p12_o <= 1'b0;
					init_bloc_o <= 1'b0;
					sel_mux_perm_o <= 1'b0;
					sel_muxData_perm_o <= 1'b0;
					write_enable_data_o <= 1'b0;
					write_enable_cipher_o <= 1'b0;
					write_enable_tag_o <= 1'b0;
					en_xor_begin_key_o <= 1'b0;
					en_xor_begin_data_o <= 1'b0;
					en_xor_end_lsb_o <= 1'b0;
					en_xor_end_key_o <= 1'b0;
					end_o <= 1'b0;
				end

			conf_init :
				begin
					en_cpt_round_o <= 1'b1;
					init_p12_o <= 1'b1;
				end

			init_rd0 : 
				begin
					write_enable_data_o <= 1'b1;
					init_p12_o <= 1'b0;
				end

			init_rd1_to_10 :
				sel_mux_perm_o <= 1'b1;

			init_rd11 :
				en_xor_end_key_o <= 1'b1;

			conf_assData : 
				begin
					init_p6_o <= 1'b1;
					write_enable_data_o <= 1'b0;
					en_xor_end_key_o <= 1'b0;
				end

			assData_rd6 :
				begin
					init_p6_o <= 1'b0;
					write_enable_data_o <= 1'b1;
					en_xor_begin_data_o <= 1'b1;
				end
			
			assData_rd7_to_10 :
				en_xor_begin_data_o <= 1'b0;

			assData_rd11 :
				en_xor_end_lsb_o <= 1'b1;

			confBoucle_txt :
				begin
					en_xor_end_lsb_o <= 1'b0;
					en_cpt_bloc_o <= 1'b1;
					init_bloc_o <= 1'b1;
					write_enable_data_o <= 1'b0;
				end

			conf_txt :
				begin
					init_p6_o <= 1'b1;
					write_enable_data_o <= 1'b0;
					en_cpt_bloc_o <= 1'b0;
					init_bloc_o <= 1'b0;
				end
	
			txt_rd6 :
				begin
					init_p6_o <= 1'b0;
					if (decrypt_enable_i) sel_muxData_perm_o <= 1'b1;
					write_enable_data_o <= 1'b1;
					write_enable_cipher_o <= 1'b1;
					en_xor_begin_data_o <= 1'b1;
				end

			txt_rd7_to_10 :
				begin
					write_enable_cipher_o <= 1'b0;
					if (decrypt_enable_i) sel_muxData_perm_o <= 1'b0;
					en_xor_begin_data_o <= 1'b0;
				end

			txt_rd11 :
				en_cpt_bloc_o <= 1'b1;

			conf_final :
				begin
					init_bloc_o <= 1'b1;
					write_enable_data_o <= 1'b0;
					init_p12_o <= 1'b1;
				end

			final_rd0 :
				begin
					en_cpt_bloc_o <= 1'b0;
					init_p12_o <= 1'b0;
					init_bloc_o <= 1'b0;
					if (decrypt_enable_i) sel_muxData_perm_o <= 1'b1;
					en_xor_begin_key_o <= 1'b1;
					en_xor_begin_data_o <= 1'b1;
					write_enable_data_o <= 1'b1;
					write_enable_cipher_o <= 1'b1;
				end

			final_rd1_to_10 :
				begin
					en_xor_begin_key_o <= 1'b0;
					en_xor_begin_data_o <= 1'b0;
					if (decrypt_enable_i) sel_muxData_perm_o <= 1'b0;
					write_enable_cipher_o <= 1'b0;
				end

			final_rd11 :
				begin
					en_xor_end_key_o <= 1'b1;
					write_enable_tag_o <= 1'b1;
				end

			fin : 
				begin
					en_xor_end_key_o <= 1'b0;
					write_enable_tag_o <= 1'b0;
					write_enable_data_o <= 1'b0;
					init_p12_o <= 1'b1;
					end_o <= 1'b1;
				end

			default : 
				begin
					en_cpt_round_o <= 1'b0;
					en_cpt_bloc_o <= 1'b0;
					init_p6_o <= 1'b0;
					init_p12_o <= 1'b0;
					init_bloc_o <= 1'b0;
					sel_mux_perm_o <= 1'b0;
					sel_muxData_perm_o <= 1'b0;
					write_enable_data_o <= 1'b0;
					write_enable_cipher_o <= 1'b0;
					write_enable_tag_o <= 1'b0;
					en_xor_begin_key_o <= 1'b0;
					en_xor_begin_data_o <= 1'b0;
					en_xor_end_lsb_o <= 1'b0;
					en_xor_end_key_o <= 1'b0;
					end_o <= 1'b0;
				end
		endcase
	end : comb_outputs
endmodule : FSM_v2
