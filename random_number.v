`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.12.2024 15:10:24
// Design Name: 
// Module Name: random_number
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

// Generates a pseudo random 8 bit number

module random_number (
    input  wire         clk,
    input  wire         rst,
    output reg  [11:0]  lfsr,    // 12-bit LFSR
    input wire [11:0] seed
);
    wire  feedback;

    assign feedback = lfsr[11] ^ lfsr[10] ^ lfsr[9] ^ lfsr[3];

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Load the seed during reset
            lfsr <= seed;
        end else begin
            // Shift left and insert feedback in the LSB
            lfsr <= {lfsr[10:0], feedback};
        end
    end
endmodule
