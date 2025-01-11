`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.12.2024 13:53:37
// Design Name: 
// Module Name: clk_conv
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Clock conversion module to generate `sprtclk`
//              based on counters from the input clock `clk`.
//
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Generates a sprtclk for processing sprite animations

module clk_conv(
    input clk,           // Input clock signal
    input rst,           // Active-low reset signal
    output reg sprtclk,  // Output clock for sprite logic
    output reg new_clk
    );
    
    reg [26:0] counterclk; // Counter for clock division
    reg [3:0] sprtclk_counter;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            counterclk <= 27'd0; // Reset counter to 0
            sprtclk <= 1'b0;     // Reset `sprtclk`
            sprtclk_counter <= 4'd0;
            new_clk <= 1'b0;
        end else begin
            // Increment the counter
            counterclk <= counterclk + 1;

            // Generate sprtclk every 5 million cycles and reset the counter
            if (counterclk >= 27'd5000000) begin
                sprtclk <= ~sprtclk;
                counterclk <= 27'd0; // Reset the counter
            end
            
            sprtclk_counter <= sprtclk_counter + 1;
            if(sprtclk_counter == 4'd9) begin
                new_clk <= ~new_clk;
                sprtclk_counter <= 4'd0;
            end
        end
    end

endmodule
