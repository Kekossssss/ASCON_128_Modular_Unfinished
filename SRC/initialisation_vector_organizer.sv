//Author : Guilloux
//Module : Organize the IV input, according to the size of the key for the desired configuration
//Last modified : 11/08/2024

`timescale 1ns / 1ps

import ascon_pack::*;


module initialisation_vector_organizer(
    input logic clk_i,
    input logic [7:0] key_lenght_k_i,
    input logic [191:0] initialisation_vector_i,
    output logic [191:0] initialisation_vector_o
    );
    //Internal nets declaration
    logic [191:0] initialisation_vector_mask_s;
    logic [191:0] initialisation_vector_final_s;
    int k;
    //Logic
    always_comb begin
        k = int'(key_lenght_k_i);
        for (int i=0;i<192;i++) begin
            if (i<192-k) initialisation_vector_mask_s[i] <= initialisation_vector_i[i] & 1;
            else initialisation_vector_mask_s[i] <= initialisation_vector_i[i] & 0;
        end
    end
    assign initialisation_vector_final_s = initialisation_vector_mask_s << k;
    //Outputs assignation
    assign initialisation_vector_o = initialisation_vector_final_s;
endmodule : initialisation_vector_organizer
