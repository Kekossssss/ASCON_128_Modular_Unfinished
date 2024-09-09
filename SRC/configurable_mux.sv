//Author : Kevin GUILLOUX
//Last modified : 10/05/2024
//Comment : Multiplexer configurable in order to be used in every configurations

`timescale 1ns/1ps

module configurable_mux #(
	parameter nb_bits_select = 1,
	parameter nb_bits_taille_donnes = 1
)(
	//Input is made under a table form
	input logic [2**(nb_bits_select)-1:0][nb_bits_taille_donnes-1:0] data_i,
	//Selection input, to select which input to redirect on the output
	input logic [nb_bits_select-1:0] sel_i,
	//Output in the form of a single data signal
	output logic [nb_bits_taille_donnes-1:0] data_o
);
	assign data_o = data_i[sel_i];
endmodule : configurable_mux
