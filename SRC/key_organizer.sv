//Author : Guilloux
//Module : Organize the IV input, according to the size of the key for the desired configuration
//Last modified : 11/08/2024

`timescale 1ns / 1ps

import ascon_pack::*;


module key_organizer(
    input logic [7:0] key_lenght_k_i,
    input logic [159:0] key_i,
    output logic [159:0] key_o
    );
    //Internal nets declaration
    logic [159:0] key_mask_s;
    int k;
    //Logic
    always_comb begin
        k = int'(key_lenght_k_i);
        for (int i=0;i<160;i++) begin
            if (i<k) key_mask_s[i] <= key_i[i] & 1;
            else key_mask_s[i] <= key_i[i] & 0;
        end
    end
    //Outputs assignation
    assign key_o = key_mask_s;
endmodule : key_organizer
