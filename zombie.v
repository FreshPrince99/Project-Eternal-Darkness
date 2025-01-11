`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.12.2024 13:52:09
// Design Name: 
// Module Name: zombie
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Logic to handle zombie movement and attacks
//
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module zombie(
        input rst,
        input game_clk,
        input [5:0] player_loc_simple_x,
        input [4:0] player_loc_simple_y,
        output reg detected,
        input [10:0] curr_x,
        input [10:0] curr_y,
        input [109:0] bullet_x, // Checking collision of bullets with the zombie
        input [99:0] bullet_y,
        output reg [12:0] zombie_computed_reg,
        input sprtclk,
        input [2:0] sound_state,
        output reg [3:0] hit_timer,
        output reg zombie_attack,
        input [2:0] display_wave,
        input wire [11:0] seed,
        input [3:0] wave_counter,
        output reg dead
    );
    
    reg [1:0] dir;
    reg [5:0] current_loc_x;
    reg [4:0] current_loc_y;
    reg [5:0] abs_diff_x;
    reg [4:0] abs_diff_y;
    reg [5:0] counter; // game_clk to 1 cps
    reg counter_true;
    reg movetrue; 
    reg [10:0] zom_x; // stores the position of the zombies
    reg [9:0] zom_y;
    reg [4:0] hit_count; // Counts the number of times the zombie has been hit by a bullet
    reg hit_count_detection; // Checks whether the zombie has been defeated
    reg z_move_animation_true; // Signal that controls the zombie's movement
    
    wire [11:0] randomiser; // Randomizes the direction they face during respawn and when 
    
    reg [4:0] circle_radius; 
    reg [8:0] circle_radius_sq;
    reg [12:0] distance_squared; 
    reg [3:0] sprite_counter;
    reg [2:0] sprite_animation_stage; // For displaying the sprite animations
    
    reg [7:0] shot_by_player_counter;
    
    
    parameter [10:0] START_X = 750;
    parameter [9:0] START_Y = 90;
    

    
    integer i; // Loop variable for bullet collision with zombie
    parameter BULLET_RADIUS = 8; // Bullet hitbox size
    parameter BLK_SIZE_X = 24;
    parameter BLK_SIZE_Y = 24;
    parameter PIXEL_SCALE = 1;
    parameter AREA = BLK_SIZE_X * BLK_SIZE_Y;
    parameter ATTACK_RANGE = 1;
    
    // Player tracker, chooses direction and detects if it can attack the player
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            detected <= 0;
            counter <= 0;
            counter_true <= 0;
            zombie_attack <= 0;
          
        end else begin
            if (!dead) begin
                if (counter == 30) begin
                    counter <= 0;
                    counter_true <= 1;
                end else begin
                    counter <= counter + 1;
                    counter_true <= 0;
                end
                // Zombie tracking logic is on a half second clock to make them feel more sluggish, turning on a dime is unrealistic for a zombie and would lead to clustering
                if (counter_true) begin
                    // Compute the absolute differences
                    abs_diff_x = (player_loc_simple_x > current_loc_x) ? 
                                 (player_loc_simple_x - current_loc_x) : 
                                 (current_loc_x - player_loc_simple_x); // was zom_x before (zom_x represents the pixelated position
                                 
                    abs_diff_y = (player_loc_simple_y > current_loc_y) ? 
                                 (player_loc_simple_y - current_loc_y) : 
                                 (current_loc_y - player_loc_simple_y);
                                 
                    // Compute the distance squared
                    distance_squared = abs_diff_x * abs_diff_x + abs_diff_y * abs_diff_y;
                    
                     
                    // Check if the player is within the circle
                    if (distance_squared <= circle_radius_sq || shot_by_player_counter) begin
                        detected <= 1;
                        movetrue <= 1;
                    end else begin
                        detected <= 0;
                        movetrue <= 0;
                    end
                    
                    if (distance_squared <= ATTACK_RANGE && !dead) begin // Switches zombie_attack to 1 when the zombie is within close proximity
                        zombie_attack <= 1;
                    end else begin
                        zombie_attack <= 0;
                    end
                    
                    if (!detected) begin
                        if (randomiser[0]) begin
                            movetrue <= 1;
                            dir <= randomiser[2:1];
                        end else begin
                            movetrue <= 0;
                        end
                    end else begin
                        // Decide direction based on which axis is further from the player
                        if (abs_diff_x >= abs_diff_y && !dead) begin
                            if (player_loc_simple_x > current_loc_x) begin
                                dir <= 2'b01; // Move right
                            end else begin
                                dir <= 2'b11; // Move left
                            end
                        end else if (!dead) begin
                            if (player_loc_simple_y > current_loc_y) begin
                                dir <= 2'b10; // Move down
                            end else begin
                                dir <= 2'b00; // Move up
                            end
                        end
                    
                    end
                end
            end
        end
    end
    
    
    // Zombie movement 
    // Zombie movement is synced to gameclk
    
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            zom_x <= START_X + (randomiser % 100); 
            zom_y <= START_Y + (randomiser % 25);
            z_move_animation_true <= 0;
        end else if (display_wave) begin 
            // Has to be repreated since these are reset between waves, repeat prevents ambiguos clock error
            z_move_animation_true <= 0;
        end else begin
            if (!dead) begin
                // Zombies would initialise to 
                if (zom_x == 0 || zom_y == 0 || zom_x < 180 || zom_y < 32) begin
                    zom_x <= START_X + (randomiser % 100); 
                    zom_y <= START_Y + (randomiser % 25); 
                end
                if (movetrue) begin
                    case(dir)            
                        2'b00: begin // up
                            if (zom_y > 11'd48 && !(zom_x > 830 && zom_y < 450) && !(zom_x > 1050 && zom_y < 680) && !(zom_x > 1200 && zom_y < 850)) begin
                               zom_y <= zom_y -2;
                               z_move_animation_true <= 1;
                            end
                        end
                        2'b10: begin // down
                            if (zom_y < (11'd900 - 11'd80)) begin
                               zom_y <= zom_y + 2;
                               z_move_animation_true <= 1;
                            end
                        end
                        2'b01: begin // right
                            if (zom_x < 11'd1420 && !(zom_x > 830 && zom_y < 450) && !(zom_x > 1050 && zom_y < 680) && !(zom_x > 1200 && zom_y < 850)) begin
                               zom_x <= zom_x + 2;
                               z_move_animation_true <= 1;
                            end
                        end
                        2'b11: begin // left
                            if (zom_x > 192) begin
                               zom_x <= zom_x - 2;
                               z_move_animation_true <= 1;
                            end
                        end
                        default: begin
                            z_move_animation_true <= 0;
                        end
                    endcase
                end else begin
                    z_move_animation_true <= 0;
                end
             end else begin
                z_move_animation_true <= 0;
             end 
        end
    end
    
    // Bullet detection logic    
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            hit_count <= 0;
            hit_count_detection <= 0;
            hit_timer <= 0;
            dead <= 0;
        end else if (display_wave) begin
            dead <= 0; 
            hit_count <= 0;
        end else begin
            if (hit_timer > 0) begin
                hit_timer <= hit_timer - 1;
            end
            if (shot_by_player_counter) begin
                hit_count_detection <= 0;
            end
            // Check for bullet collisions
            for (i = 0; i < 10; i = i + 1) begin
                if ((bullet_x[11*i +: 11] >= zom_x - BULLET_RADIUS) && 
                    (bullet_x[11*i +: 11] <= zom_x + BLK_SIZE_X + BULLET_RADIUS) &&
                    (bullet_y[10*i +: 10] >= zom_y - BULLET_RADIUS) && 
                    (bullet_y[10*i +: 10] <= zom_y + BLK_SIZE_Y + BULLET_RADIUS)) begin
                    hit_count <= (dead) ? hit_count:hit_count + 1; // Increment hit count
                    hit_count_detection <= 1;
                    hit_timer <= 5'd15; // Highlight the zombie for 15 frames 
                    dead <= (hit_count > 3 + wave_counter/2); // Freezes the zombie if hit
                end
            end
        end
    end
    
    // Zombie tracker updater
    // This allows the zombies to travel parallel to the player, making them more difficult to shoot
    // This sometimes results in the zombies pacing next to the player, however they still damage the player so the player should be too distracted to notice
    // Having them stop next to the player didn't feel right
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            current_loc_x <= zom_x / 32;
            current_loc_y <= zom_y / 32;
        end else begin
            current_loc_x <= zom_x / 32;
            current_loc_y <= zom_y / 32;
        end
    end
    
    // Zombie address calculator (with rotation)
    always @* begin
        zombie_computed_reg = 0;
        // Determine address based on sprite direction and position
        if (dir == 2'd0 || dir == 2'd2) begin
            if (zom_x <= curr_x && curr_x <= zom_x + BLK_SIZE_X * PIXEL_SCALE - 1 &&
                zom_y <= curr_y && curr_y <= zom_y + BLK_SIZE_Y * PIXEL_SCALE - 1) begin
                    
                case (dir)
                    2'd2: // Down
                        zombie_computed_reg = sprite_animation_stage * AREA 
                                        + ((curr_y - zom_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - zom_x)/PIXEL_SCALE);
                    2'd0: // Up
                        zombie_computed_reg = sprite_animation_stage * AREA 
                                        + (AREA - 1) 
                                        - (((curr_y - zom_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - zom_x)/PIXEL_SCALE));
                endcase
            end
        end else if (dir == 2'd1 || dir == 2'd3) begin
            if (zom_x <= curr_x && curr_x <= zom_x + BLK_SIZE_Y * PIXEL_SCALE - 1 &&
                zom_y <= curr_y && curr_y <= zom_y + BLK_SIZE_X * PIXEL_SCALE - 1) begin
                    
                case (dir)
                    2'd3: // Left
                        zombie_computed_reg = sprite_animation_stage * AREA + (AREA - 1)
                                        - ((curr_x - zom_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((curr_y - zom_y)/PIXEL_SCALE);
                    2'd1: // Right
                        zombie_computed_reg = sprite_animation_stage * AREA
                                        + ((curr_x - zom_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((BLK_SIZE_X - 1 - (curr_y - zom_y)/PIXEL_SCALE));
                endcase
            end
        end
    end
    
    
    // Zombie animation calculator
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            sprite_counter <= 0; 
        end
        else begin
            if (!z_move_animation_true) begin
                sprite_counter <= 0;  // Reset the sprite counter on reset or no movement
            end else if (sprite_counter == 4'd11) begin
                sprite_counter <= 0;
            end else begin
                sprite_counter <= sprite_counter + 1;  // Increment the counter
            end
        end
    end
    
    // Zombie animation assigner (12 frames in 1 cycle, 7 frames stored)
    always @* begin
        if (z_move_animation_true) begin 
            case (sprite_counter)
                4'd0: sprite_animation_stage = 0;
                4'd1: sprite_animation_stage = 1;
                4'd2: sprite_animation_stage = 2;
                4'd3: sprite_animation_stage = 3;
                4'd4: sprite_animation_stage = 2;
                4'd5: sprite_animation_stage = 1;
                4'd6: sprite_animation_stage = 0;
                4'd7: sprite_animation_stage = 4;
                4'd8: sprite_animation_stage = 5;
                4'd9: sprite_animation_stage = 6;
                4'd10: sprite_animation_stage = 5;
                4'd11: sprite_animation_stage = 4;
                default: sprite_animation_stage = 0;
            endcase

        end else begin
            sprite_animation_stage = 0;
        end
    end
    
    // Detection rate assignments    
    always @* begin
        circle_radius = (sound_state + 1) * 4;
        circle_radius_sq = circle_radius * circle_radius;
    end
    
    
    // Creates a timer that waits ~4 seconds, this is used to have the zombie chase the player after being shot
    always @(posedge game_clk or negedge rst) begin
        if (!rst || display_wave) begin
            shot_by_player_counter <= 0;
        end else if (hit_count_detection) begin
            shot_by_player_counter <= 255;
        end else if (shot_by_player_counter != 0) begin
            shot_by_player_counter <= shot_by_player_counter - 1;
        end
    end

    



    random_number random_number_bullet_inst(
        .clk(game_clk),
        .rst(rst),
        .lfsr(randomiser),
        .seed(seed)
    );


endmodule
