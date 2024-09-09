//Author : Guilloux
//Module : Organize the IV input, according to the size of the key for the desired configuration
//Last modified : 11/08/2024

`timescale 1ns / 1ps

import ascon_pack::*;


module data_organizer(
    input logic [7:0] size_treated_data_r_i,
    input logic [255:0] data_i,
    output logic [255:0] data_o
    );
    //Internal nets declaration
    logic [255:0] data_mask_s;
    logic [255:0] data_final_s;
    int r;
    //Logic
    always_comb begin
        r = int'(size_treated_data_r_i);
        for (int i=0;i<256;i++) begin
            if (i<r) data_mask_s[i] <= data_i[i] & 1;
            else data_mask_s[i] <= data_i[i] & 0;
        end
    end
    assign data_final_s = data_mask_s << 256 - r;
    //Outputs assignation
    assign data_o = data_final_s;
endmodule : data_organizer
