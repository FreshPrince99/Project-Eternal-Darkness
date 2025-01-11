`timescale 1ns / 1ps

module game_top(
    input clk,
    input rst,
    input [1:0] sw,
    input [4:0] btn,
    output [3:0] pix_r,
    output [3:0] pix_g,
    output [3:0] pix_b,
    output hsync,
    output vsync,
    output M_CLK,
    output M_LRSEL,
    input M_DATA,
    output a, b, c, d, e ,f, g 
);

wire [6:0] seg;
assign {a, b, c, d, e, f, g} = seg; // Used for displaying the seven segment display for detecting sound

// Internal wires
wire pixclk;
wire [3:0] draw_r;
wire [3:0] draw_g;
wire [3:0] draw_b;
wire [10:0] curr_x;
wire [10:0] curr_y;

reg [20:0] clk_div;
reg game_clk;
reg game_clk_three;

// Player position and direction
reg [10:0] blkpos_x; 
reg [9:0] blkpos_y;
reg [1:0] dir;
reg move_animation_true;
reg shoot_true;
wire [2:0] display_wave; // Signals other ui components whenever the wave is changed

// Player simplified coordinates
reg [5:0] player_loc_simple_x; 
reg [4:0] player_loc_simple_y;

// Collision detection
reg [3:0] collision;
reg [10:0] collision_addr;
wire collision_vision;

// Player health counter
wire [2:0] player_health;

reg sample_en;
wire [1:0] pdm_output; // Contains the output of the mic which detects sound

// State machine for pipelined collision checking
reg [2:0] state;
localparam STATE_ADDR = 3'd0;
localparam STATE_WAIT = 3'd1;
localparam STATE_WAIT2 = 3'd2;
localparam STATE_READ = 3'd3;
localparam STATE_UPDATE = 3'd4; 

// Direction attempt storage
reg [3:0] direction_input;


//clock generator for pixel clock
clk_wiz inst
(
    .clk_out1(pixclk),
    .clk_in1(clk)
);


// Creates 60fps clock
always @(posedge pixclk or negedge rst) begin
    if(!rst) begin
        clk_div <= 0;
        game_clk <= 0;
        game_clk_three <= 0;
    end else begin
        if (clk_div == 21'd591494 || clk_div == (21'd591494 * 2) || clk_div == (21'd591494 * 3)) begin
            game_clk_three <= !game_clk_three;
        end
        if ((clk_div == 21'd1774483)) begin
            clk_div <= 0;
            game_clk <= !game_clk;
        end else begin
            clk_div <= clk_div + 1;
        end
    end
end

// Movement and collision checking state machine
always @(posedge game_clk_three or negedge rst) begin
    if(!rst || display_wave) begin
        blkpos_x <= 48;
        blkpos_y <= 560;
        move_animation_true <= 0;
        shoot_true <= 0;
        collision <= 4'b0000;
        direction_input <= 4'b0000;
        state <= STATE_ADDR;
    end else begin
        shoot_true <= btn[0] ? 1'b1 : 1'b0;
        
        case (state)
            STATE_ADDR: begin
                // We set the collision_addr here but do NOT immediately read collision_vision
                // Reset collision flags for this new check
                            
                collision <= 4'b0000;

                case(btn[4:1]) // was btn before
                    4'b0010: begin // Left
                        direction_input <= 4'b0010;
                        if (player_loc_simple_x > 0)
                            collision_addr <= player_loc_simple_y * 45 + (player_loc_simple_x - 1);
                        else
                            collision_addr <= player_loc_simple_y * 45 + player_loc_simple_x; 
                    end
                    4'b0100: begin // Right
                        direction_input <= 4'b0100;
                        if (player_loc_simple_x < 44)
                            collision_addr <= player_loc_simple_y * 45 + (player_loc_simple_x + 1);
                        else
                            collision_addr <= player_loc_simple_y * 45 + player_loc_simple_x;
                    end
                    4'b1000: begin // Up
                        direction_input <= 4'b1000;
                        if (player_loc_simple_y > 0)
                            collision_addr <= (player_loc_simple_y + 1) * 45 + player_loc_simple_x; 
                        else
                            collision_addr <= player_loc_simple_y * 45 + player_loc_simple_x;
                    end
                    4'b0001: begin // Down
                        direction_input <= 4'b0001;
                        if (player_loc_simple_y < 27) 
                            collision_addr <= (player_loc_simple_y - 1) * 45 + player_loc_simple_x; 
                        else
                            collision_addr <= player_loc_simple_y * 45 + player_loc_simple_x;
                    end
                    default: begin
                        direction_input <= 4'b0000;
                        collision_addr <= player_loc_simple_y * 45 + player_loc_simple_x;
                    end
                endcase
                
                state <= STATE_WAIT;
            end

            STATE_WAIT: begin
                // Just wait one game_clk cycle here. 
                // The collision memory is synchronous with 'clk', 
                // by the time we hit next state (READ), collision_vision should be stable.
                state <= STATE_READ;
            end
            
            // Reads from the collision data
            STATE_READ: begin
                if (collision_vision == 1'b1) begin
                    case(direction_input)
                        4'b0010: collision[3] <= 1; // Left
                        4'b0100: collision[1] <= 1; // Right
                        4'b1000: collision[2] <= 1; // Up
                        4'b0001: collision[0] <= 1; // Down
                        default: collision <= 4'b0000;
                    endcase
                end
                state <= STATE_UPDATE;
            end
                
            // Checks for collision and updates player movement
            STATE_UPDATE: begin 
            // Attempt movement if no collision occured
                if (direction_input != 4'b0000) begin
                    case (direction_input)
                        4'b0010: begin // Left
                            dir <= 2'd3;
                            if (blkpos_x > 11'd10 && !collision[3]) begin
                                $display("Moving Left: New X = %d", blkpos_x - 2 - 2 * (shoot_true + 1));
                                blkpos_x <= blkpos_x - 2 - 2 * (shoot_true + 1);
                                
                                move_animation_true <= 1;
                            end else begin
                                move_animation_true <= 0;
                            end
                        end
                        4'b0100: begin // Right
                            dir <= 2'd1;
                            if (blkpos_x < (11'd1430 - 11'd50) && !collision[1]) begin
                                $display("Moving Right: New X = %d", blkpos_x + 2 + 2 * (shoot_true + 1));
                                blkpos_x <= blkpos_x + 2 + 2 * (shoot_true + 1);
                                
                                move_animation_true <= 1;
                            end else begin
                                move_animation_true <= 0;
                            end
                        end
                        4'b1000: begin // Up
                            dir <= 2'd0;
                            if (blkpos_y < (11'd890 - 11'd50) && !collision[2]) begin
                                $display("Moving Up: New Y = %d", blkpos_y + 2 + 2 * (shoot_true + 1));
                                blkpos_y <= blkpos_y + 2 + 2 * (shoot_true + 1);
                                
                                move_animation_true <= 1;
                            end else begin
                                move_animation_true <= 0;
                            end
                        end
                        4'b0001: begin // Down
                            dir <= 2'd2;
                            if (blkpos_y > 11'd10 && !collision[0]) begin
                                $display("Moving Down: New Y = %d", blkpos_y - 2 - 2 * (shoot_true + 1));
                                blkpos_y <= blkpos_y - 2 - 2 * (shoot_true + 1);
                                
                                move_animation_true <= 1;
                            end else begin
                                move_animation_true <= 0;
                            end
                        end
                        default: move_animation_true <= 0;
                    endcase
                end else begin
                    move_animation_true <= 0;
                end

                // Go back to STATE_ADDR to handle next input
                state <= STATE_ADDR;
            end
        endcase
    end
end

 // Creates a player loc simple for zombie tracking
always @(posedge game_clk_three or negedge rst) begin
    if(!rst || display_wave) begin
        player_loc_simple_x <= 6'd0;
        player_loc_simple_y <= 2'd0;
    end else begin
        player_loc_simple_x <= blkpos_x / 32; 
        if (blkpos_y > 16) begin
            player_loc_simple_y <= (blkpos_y-16) / 32;
        end else begin
            player_loc_simple_y <= 0;
        end
    end
end

assign M_LRSEL = 1;

pdm_mic_interface pdm_mic_interface_inst(
    .clk(clk),
    .rst(rst),
    .pdm_data(M_DATA),
    .pdm_clk(M_CLK),
    .pdm_output(pdm_output),
    .seg(seg),
    .game_clk_three(game_clk_three)
);



drawcon drawcon_inst(
    .clk(pixclk),
    .rst(rst),
    .sw(sw),
    .blkpos_x(blkpos_x),
    .blkpos_y(blkpos_y),
    .draw_r(draw_r),
    .draw_g(draw_g),
    .draw_b(draw_b),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .dir(dir),
    .move_animation_true(move_animation_true),
    .shoot_true(shoot_true),
    .game_clk(game_clk),
    .player_loc_simple_x(player_loc_simple_x),
    .player_loc_simple_y(player_loc_simple_y),
    .display_wave(display_wave),
    .pdm_output(pdm_output)

);

vga vga_inst(
    .clk(pixclk),
    .rst(rst),
    .draw_r(draw_r),
    .draw_g(draw_g),
    .draw_b(draw_b),
    .pix_r(pix_r),
    .pix_g(pix_g),
    .pix_b(pix_b),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .hsync(hsync),
    .vsync(vsync)
);

blk_mem_gen_8 Collision_data_player
(
    .clka(pixclk),
    .addra(collision_addr),
    .douta(collision_vision)
);

endmodule
