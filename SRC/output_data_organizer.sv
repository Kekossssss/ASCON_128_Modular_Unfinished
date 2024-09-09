//Author : Guilloux
//Module : Organize the data output, according to the size of the rate for the desired configuration
//Last modified : 12/08/2024

`timescale 1ns / 1ps

import ascon_pack::*;


module output_data_organizer(
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
        for (int i=255;i>=0;i--) begin
            if (i>255-r) data_mask_s[i] <= data_i[i] & 1;
            else data_mask_s[i] <= data_i[i] & 0;
        end
    end
    assign data_final_s = data_mask_s >> 256 - r;
    //Outputs assignation
    assign data_o = data_final_s;
endmodule
