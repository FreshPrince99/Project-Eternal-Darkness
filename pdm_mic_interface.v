    `timescale 1ns / 1ps
    //////////////////////////////////////////////////////////////////////////////////
    // Company: 
    // Engineer: 
    // 
    // Create Date: 05.01.2025 19:37:54
    // Design Name: 
    // Module Name: pdm_mic_interface
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
    
    
    module pdm_mic_interface(
        input wire clk,        // System clock (e.g., 100 MHz)
        input wire rst,        // Reset signal
        input wire pdm_data,   // PDM data input
        output wire pdm_clk,    // PDM clock output
        output reg [1:0] pdm_output, //Output for sound level classification
        output reg [6:0] seg, // 7 segment display
        input wire game_clk_three
        );
    
        // Parameters
        parameter PDM_CLK_DIV = 40; // Divider for PDM clock (e.g., 100 MHz / 40 = 2.5 MHz)
        parameter DECIMATION_FACTOR = 64; // Number of PDM samples per PCM sample
        
        parameter AMBIENT = 2; 
        parameter CONVERSATIONAL = 3;
        parameter LOUD = 4;
    
        // Clock divider for PDM clock
        reg [5:0] clk_div_counter = 0;
        reg pdm_clk_reg = 0;
        reg [15:0] pcm_data; // Decimated PCM output
        reg [3:0] game_clk_three_div;
        reg second_clk;
        reg [15:0] max_value;
        reg [1:0] max_rst_count;
        
        // Generates a slower clock signal second_clk which runs at ~ 3Hz
        always @(posedge game_clk_three or negedge rst) begin
            if (!rst) begin
                game_clk_three_div <= 0;
                second_clk <= 0;
            end else begin
                if (game_clk_three_div >= 10) begin
                    second_clk <= ~second_clk;
                    game_clk_three_div <= 0;
                end else begin
                    game_clk_three_div <= game_clk_three_div + 1;
                end
            end
        end
        
        // Updates pcm_data with the current max_value
        always @(posedge second_clk or negedge rst) begin
            if (!rst) begin
                pcm_data <= 0;
                max_rst_count <= 0;
            end else begin
                if (max_value > 0) begin
                    pcm_data <= max_value;
                end
                if (max_rst_count >= 3) begin
                    max_rst_count <= 0;
                end else begin
                    max_rst_count <= max_rst_count + 1;
                end
            end
        end
        
        // Generates a PDM clock signal for decimating PDM data 
        always @(posedge clk or negedge rst) begin
            if (!rst) begin
                clk_div_counter <= 0;
                pdm_clk_reg <= 0;
            end else begin
                if (clk_div_counter == (PDM_CLK_DIV - 1)) begin
                    clk_div_counter <= 0;
                    pdm_clk_reg <= ~pdm_clk_reg;
                end else begin
                    clk_div_counter <= clk_div_counter + 1;
                end
            end
        end
    
        assign pdm_clk = pdm_clk_reg;
    
        // Decimation counter and accumulator
        reg [5:0] decimation_counter = 0;
        reg [15:0] accumulator = 0;
        
     
        // Performs decimation of PDM data to produce PCM data and tracks maximum PCM value
        always @(posedge pdm_clk_reg or negedge rst) begin
            if (!rst) begin
                decimation_counter <= 0;
                accumulator <= 0;
                max_value <= 0;
            end else 
                if (max_rst_count >= 3) begin // every 3 seconds
                    max_value <= 0;
                end else begin
                    if (decimation_counter == (DECIMATION_FACTOR - 1)) begin
                        decimation_counter <= 0;
                        if (max_value < accumulator) begin
                            max_value <= accumulator;
                        end
                        accumulator <= 0;
                    end else begin
                        decimation_counter <= decimation_counter + 1;
                        accumulator <= accumulator + pdm_data;
                    end
            end
        end
        
         // 7-Segment Decoder
        always @(pcm_data) begin
            case (pcm_data[3:0]) // Display lower nibble of pcm_data
                4'h0: seg = 7'b0000001; // 0
                4'h1: seg = 7'b1001111; // 1
                4'h2: seg = 7'b0010010; // 2
                4'h3: seg = 7'b0000110; // 3
                4'h4: seg = 7'b1001100; // 4
                4'h5: seg = 7'b0100100; // 5
                4'h6: seg = 7'b0100000; // 6
                4'h7: seg = 7'b0001111; // 7
                4'h8: seg = 7'b0000000; // 8
                4'h9: seg = 7'b0000100; // 9
                4'hA: seg = 7'b0000100; // A
                4'hB: seg = 7'b1100000; // B
                4'hC: seg = 7'b0110001; // C
                4'hD: seg = 7'b1000010; // D
                4'hE: seg = 7'b0010000; // E
                4'hF: seg = 7'b0111000; // F
                default: seg = 7'b0000000; // Blank
            endcase
        end

        // Assigning different variations in sound of pcm_data to pdm_output
        always@(pcm_data) begin
            if (pcm_data[3:0] > LOUD) pdm_output <= 2'b11;
            else if (pcm_data[3:0] > CONVERSATIONAL) pdm_output <= 2'b10;
            else if (pcm_data[3:0] > AMBIENT) pdm_output <= 2'b01;
            else pdm_output <= 2'b00;
        end

    endmodule
