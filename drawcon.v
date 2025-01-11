`timescale 1ns / 1ps

module drawcon(
    input clk,
    input rst,
    input [1:0] sw,
    input [10:0] blkpos_x,
    input [9:0] blkpos_y,
    output [3:0] draw_r,
    output [3:0] draw_g,
    output [3:0] draw_b,
    input [10:0] curr_x,
    input [10:0] curr_y,
    
    input [1:0] dir,
    input move_animation_true,
    input shoot_true,
    input game_clk,
    input [5:0] player_loc_simple_x, // map divided into 16 * 16 squares 26*46
    input [4:0] player_loc_simple_y,
    output reg [2:0] display_wave,
    input [1:0] pdm_output
//    input [2:0] player_health
    
    );   

    reg [3:0] bg_r;
    reg [3:0] bg_g;
    reg [3:0] bg_b;
    
    reg [3:0] sprite_counter;
    reg [1:0] sprite_direction;
    reg [2:0] sprite_animation_stage;
    
    reg [3:0] blt_r;
    reg [3:0] blt_g;
    reg [3:0] blt_b;
    
    reg [3:0] print_r;
    reg [3:0] print_g;
    reg [3:0] print_b;
    
    parameter BLK_SIZE_X = 33, BLK_SIZE_Y = 20;
    parameter AREA = 660;
    parameter PIXEL_SCALE = 1; 
    parameter BULLET_SIZE = 4;
    parameter NUM_ZOMBIES = 8;
    
    parameter GAME_OVER_SIZE_X = 36; 
    parameter GAME_OVER_SIZE_Y = 22;
    parameter GAME_OVER_PIXEL_SCALE = 10; // Scale factor
    parameter GAME_OVER_X_START = (1440 - GAME_OVER_SIZE_X * GAME_OVER_PIXEL_SCALE) / 2; // 540
    parameter GAME_OVER_Y_START = (900 - GAME_OVER_SIZE_Y * GAME_OVER_PIXEL_SCALE) / 2 - 15; // 340
    parameter GAME_OVER_AREA = GAME_OVER_SIZE_X * GAME_OVER_SIZE_Y;
    
    parameter WAVE_SIZE_X = 16; 
    parameter WAVE_SIZE_Y = 16; 
    parameter WAVE_PIXEL_SCALE = 10; 
    parameter WAVE_X_START = (1440 - WAVE_SIZE_X * WAVE_PIXEL_SCALE) / 2;
    parameter WAVE_Y_START = (900 - WAVE_SIZE_Y * WAVE_PIXEL_SCALE) / 2;
    parameter WAVE_AREA = WAVE_SIZE_X * WAVE_SIZE_Y;
    
    parameter TITLE_SIZE_X = 48; 
    parameter TITLE_SIZE_Y = 20; // 1 Less than in the files since the bottom is a black row
    parameter TITLE_PIXEL_SCALE = 2; 
    parameter TITLE_X_START = (1440 - TITLE_SIZE_X * TITLE_PIXEL_SCALE)/2 ; // [672 768]
    parameter TITLE_Y_START = (900 - TITLE_SIZE_Y * TITLE_PIXEL_SCALE); // [853 895]
    parameter TITLE_AREA = TITLE_SIZE_X * TITLE_SIZE_Y;
    
    parameter SKULL_SIZE_X = 15; 
    parameter SKULL_SIZE_Y = 14; 
    parameter SKULL_PIXEL_SCALE = 2; 
    parameter SKULL_X_START = (1440 - SKULL_SIZE_X * SKULL_PIXEL_SCALE) - 56 ; // [1310 1340]
    parameter SKULL_Y_START = (900 - SKULL_SIZE_Y * SKULL_PIXEL_SCALE) - 5; // [867 895]
    parameter SKULL_AREA = SKULL_SIZE_X * SKULL_SIZE_Y;
    
    parameter ID_SIZE_X = 40; 
    parameter ID_SIZE_Y = 14; 
    parameter ID_PIXEL_SCALE = 2;
    parameter ID_X_START = (1440 - ID_SIZE_X * ID_PIXEL_SCALE)/2 + 300 ; // [778 858]
    parameter ID_Y_START = (900 - ID_SIZE_Y * ID_PIXEL_SCALE) - 4; // [867 895]
    parameter ID_AREA = ID_SIZE_X * ID_SIZE_Y;
    
    parameter OUTPUT_SIZE_X = 7; 
    parameter OUTPUT_SIZE_Y = 11; 
    parameter OUTPUT_PIXEL_SCALE = 2; 
    parameter OUTPUT_X_START = (1440 - OUTPUT_SIZE_X * OUTPUT_PIXEL_SCALE) - 20 ; // [1344 1440]
    parameter OUTPUT_Y_START = (900 - OUTPUT_SIZE_Y * OUTPUT_PIXEL_SCALE) - 10; // [853 895]
    parameter OUTPUT_X_START_2 = (1440 - OUTPUT_SIZE_X * OUTPUT_PIXEL_SCALE) - 20 - OUTPUT_SIZE_X * OUTPUT_PIXEL_SCALE - 4; // 4 Pixel gap
    parameter OUTPUT_Y_START_2 = (900 - OUTPUT_SIZE_Y * OUTPUT_PIXEL_SCALE) - 10; 
    parameter OUTPUT_AREA = OUTPUT_SIZE_X * OUTPUT_SIZE_Y;

    wire zombie_attack [0:NUM_ZOMBIES-1]; // array containing the zombie_attack value for each zombie
    reg zombie_attack_total; // 1 if the zombie attacks or 0 otherwise
    reg [3:0] active_zombies; // maximum number of zombies in a wave
    
    
    wire detected [0:NUM_ZOMBIES-1]; // Passed through the zombie instance if the player is within the detection raius

    wire [3:0] hit_timer [0:NUM_ZOMBIES-1]; // produces a delay between zombie attacks
    
    wire [11:0] rom_pixel;
    reg [11:0] rom_pixel_reg;
    
    reg [10:0] bullet_x_arr [0:9];
    reg [9:0] bullet_y_arr [0:9];
    wire [109:0] bullet_x;
    wire [99:0] bullet_y;
    
    reg [3:0] score; // contains the number of zombies defeated every wave
    parameter SCORE = 9;
    
    wire [11:0] rom_pixel_background;
    reg [11:0] rom_pixel_background_reg;
    
    // Weapons UI reg
    reg [11:0] ui_addr_reg;
    reg [11:0] rom_pixel_ui_reg;
    wire [11:0] rom_pixel_ui;
    
    // Health UI reg
    reg [12:0] health_ui_addr_reg;
    reg [11:0] rom_pixel_health_ui_reg;
    wire [11:0] rom_pixel_health_ui;
    reg [2:0] health_state; // For switching between different health levels of the health bar
    reg [6:0] health_timer; // Makes the health bar wait for 2.5 seconds before updating
    reg game_over; // Prevents player input when this flag is raised
    reg game_win; // 1 if the player wins the game
    
    // Sound UI reg
    reg [12:0] sound_ui_addr_reg;
    reg [11:0] rom_pixel_sound_ui_reg;
    wire [11:0] rom_pixel_sound_ui;
    reg [2:0] sound_state;
    reg [2:0] sound_state_buffer;
    reg [2:0] sound_state_buffer_gun;
    
    reg injure_player; // 1 if the player has been injured by the zombie

    parameter STATE_CALCULATE = 0;
    parameter STATE_UPDATE = 1;
    
    // Zombie UI reg
    reg [11:0] rom_pixel_zombie_ui_reg [0:NUM_ZOMBIES-1]; 
    wire [12:0] zombie_computed_reg [0:NUM_ZOMBIES-1]; // Outputs from zombies
    wire [11:0] rom_pixel_zombie_ui [0:NUM_ZOMBIES-1];
    wire [12:0] zombie_computed_addr;
    
    wire shoot_flag; // Indicates the player is shooting
    
    // Wave UI reg
    reg [11:0] wave_ui_addr_reg;
    reg [11:0] rom_pixel_wave_ui_reg;
    wire [11:0] rom_pixel_wave_ui;
    reg [3:0] wave_state;
    reg [3:0] wave_counter; // Keeps track of the current wave
    reg [3:0] wave_end_state;
    reg [31:0] wave_timer; // Timer to count clock cyles
    
    // Title animation
    reg [9:0] title_ui_addr_reg;
    reg [11:0] rom_pixel_title_ui_reg;
    wire [11:0] rom_pixel_title_ui;
    
    // Skull animation
    reg [7:0] skull_ui_addr_reg;
    reg [11:0] rom_pixel_skull_ui_reg;
    wire [11:0] rom_pixel_skull_ui;
    
//     Student id animation
    reg [9:0] id_ui_addr_reg;
    reg [11:0] rom_pixel_id_ui_reg;
    wire [11:0] rom_pixel_id_ui;

    
//     Output animation
    reg [9:0] output_ui_addr_reg;
    reg [11:0] rom_pixel_output_ui_reg;
    wire [11:0] rom_pixel_output_ui;
    reg [9:0] output_ui_addr_reg_2;
    reg [11:0] rom_pixel_output_ui_reg_2;
    wire [11:0] rom_pixel_output_ui_2;
    
    parameter SPRTCLK_FREQ = 11; // Approximate frequency of sprtclk in Hz
    parameter ONE_MINUTE_CYCLES = 60 * SPRTCLK_FREQ; // Number of sprtclk cycles for 1 minute
    
    // End screen UI 
    reg [12:0] end_screen_ui_addr_reg;
    reg [11:0] rom_pixel_end_screen_ui_reg;
    wire [11:0] rom_pixel_end_screen_ui;
    reg [3:0] end_screen_state;
    
    reg [12:0] animation_counter; // Counter for slowing down updates
    parameter ANIMATION_DELAY = 10; // Adjust this value for desired delay on wave
    
    // 10fps clk   
    wire sprtclk;
    wire new_clk;
    
    reg [2:0] game_over_counter;
        
    integer i;
    genvar j;
    genvar k;
    genvar m;
    
    reg [5:0] kill_count; // Keeps track of the total number of zombies killed
    
    wire dead [0:NUM_ZOMBIES-1]; // Contains 1 or 0 which determine if the zombie is alive or not

    // Compute sprite address combinationally
    reg [12:0] computed_addr;
    
    reg [3:0] score_buffer;
    reg [3:0] score_buffer_squared;
    
    reg [1:0] end_screen_stage;   
    // ADDRESS CALULATIONS
    
    
    // Soldier sprite address calulator (with rotation)
    always @* begin
        computed_addr = 0;
        // Determine address based on sprite direction and position
        if (sprite_direction == 2'd1 || sprite_direction == 2'd3) begin
            if (blkpos_x <= curr_x && curr_x <= blkpos_x + BLK_SIZE_X * PIXEL_SCALE - 1 &&
                blkpos_y <= curr_y && curr_y <= blkpos_y + BLK_SIZE_Y * PIXEL_SCALE - 1) begin
                    
                case (sprite_direction)
                    2'd1: 
                        computed_addr = sprite_animation_stage * AREA 
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE);
                    2'd3: 
                        computed_addr = sprite_animation_stage * AREA 
                                        + (AREA - 1) 
                                        - (((curr_y - blkpos_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE));
                    default:
                        computed_addr = sprite_animation_stage * AREA 
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE);
                endcase
            end
        end else if (sprite_direction == 2'd0 || sprite_direction == 2'd2) begin
            if (blkpos_x <= curr_x && curr_x <= blkpos_x + BLK_SIZE_Y * PIXEL_SCALE - 1 &&
                blkpos_y <= curr_y && curr_y <= blkpos_y + BLK_SIZE_X * PIXEL_SCALE - 1) begin
                    
                case (sprite_direction)
                    2'd0: 
                        computed_addr = sprite_animation_stage * AREA
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE);
                    2'd2: 
                        computed_addr = sprite_animation_stage * AREA
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((BLK_SIZE_X - 1 - (curr_y - blkpos_y)/PIXEL_SCALE));
                    default:
                        computed_addr = sprite_animation_stage * AREA
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE);
                endcase
            end
        end
    end

    // Checks if zombies are attacking
    always @* begin
        zombie_attack_total = 0;
        for (i = 0; i < active_zombies; i = i + 1) begin
            if(zombie_attack[i] == 1 && zombie_attack_total == 0 && !dead[i]) begin
                zombie_attack_total = 1;
            end 
        end 
    end
    
    // Weapons ui (first ui so has a default name)
    always @* begin
        if (curr_x >= 8 && curr_x < 40 && curr_y >= 873 && curr_y < 895) begin
            // Calculate the offset within the 32x22 UI
            ui_addr_reg = 704 * sw + ((curr_y - 873) * 32) + (curr_x - 8); // Adjust x-coordinate to start at 0
        end else begin
            ui_addr_reg = 0;  // Outside the UI area
        end
    end
    
    // Health UI
    always @* begin
        if (curr_x >= 48 && curr_x < 48 + 64 && curr_y >= 879 && curr_y < 879 + 16) begin
            // Calculate the offset within the 64x16 UI
            health_ui_addr_reg = 1024 * health_state + ((curr_y - 879) * 64) + (curr_x - 48); // Adjust x and y coordinates accordingly
        end else begin
            health_ui_addr_reg = 0;  // Outside the UI area 
            // This lets other sprites overwrite this file when it's null
        end
    end
    
    // Sound UI
    always @* begin
        if (curr_x >= 128 && curr_x < 128 + 64 && curr_y >= 879 && curr_y < 879 + 16) begin
            // Calculate the offset within the 64x16 UI
            sound_ui_addr_reg = 1024 * sound_state + ((curr_y - 879) * 64) + (curr_x - 128); // Adjust x and y coordinates accordingly
        end else begin
            sound_ui_addr_reg = 0;  // Outside the UI area 
            // This lets other sprites overwrite this file when it's null
        end
    end
    
    // Wave UI
    always @* begin
       if (curr_x >= WAVE_X_START && curr_x < WAVE_X_START + WAVE_SIZE_X * WAVE_PIXEL_SCALE 
            && curr_y >= WAVE_Y_START && curr_y < WAVE_Y_START + WAVE_SIZE_Y * WAVE_PIXEL_SCALE) begin     
            // Calculate the offset within the 64x16 UI
            wave_ui_addr_reg = wave_state * WAVE_AREA
                                 + ((curr_y - WAVE_Y_START) / WAVE_PIXEL_SCALE) * WAVE_SIZE_X
                                 + ((curr_x - WAVE_X_START) / WAVE_PIXEL_SCALE);
        end else begin
            wave_ui_addr_reg = 0;  // Outside the UI area 
            // This lets other sprites overwrite this file when it's null
        end
    end
    

    // End screen UI
    always @* begin
        if (curr_x >= GAME_OVER_X_START && curr_x < GAME_OVER_X_START + GAME_OVER_SIZE_X * GAME_OVER_PIXEL_SCALE 
        && curr_y >= GAME_OVER_Y_START && curr_y < GAME_OVER_Y_START + GAME_OVER_SIZE_Y * GAME_OVER_PIXEL_SCALE
        && end_screen_state < 6) begin // end_screen_state == 7
            end_screen_ui_addr_reg = end_screen_state * GAME_OVER_AREA
                                 + ((curr_y - GAME_OVER_Y_START) / GAME_OVER_PIXEL_SCALE) * GAME_OVER_SIZE_X
                                 + ((curr_x - GAME_OVER_X_START) / GAME_OVER_PIXEL_SCALE);
        end else begin
            end_screen_ui_addr_reg = 0;  // Outside the UI area 
        end
    end
    
    // Title UI
    always @* begin
        if (curr_x >= TITLE_X_START && curr_x < TITLE_X_START + 48 * TITLE_PIXEL_SCALE 
        && curr_y >= TITLE_Y_START && curr_y < TITLE_Y_START + 20 * TITLE_PIXEL_SCALE) begin
            title_ui_addr_reg = ((curr_y - TITLE_Y_START) / TITLE_PIXEL_SCALE) * TITLE_SIZE_X
                                 + ((curr_x - TITLE_X_START) / TITLE_PIXEL_SCALE);
        end else begin
            title_ui_addr_reg = 0;  // Outside the UI area 
        end
    end
    
    // Skull UI
    always @* begin
        if (curr_x >= SKULL_X_START && curr_x < SKULL_X_START + 15 * SKULL_PIXEL_SCALE 
        && curr_y >= SKULL_Y_START && curr_y < SKULL_Y_START + 14 * SKULL_PIXEL_SCALE) begin
            skull_ui_addr_reg = ((curr_y - SKULL_Y_START) / SKULL_PIXEL_SCALE) * SKULL_SIZE_X
                                 + ((curr_x - SKULL_X_START) / SKULL_PIXEL_SCALE);
        end else begin
            skull_ui_addr_reg = 0;  // Outside the UI area 
        end
    end
    
//   Student ID UI
    always @* begin
        if (curr_x >= ID_X_START && curr_x < ID_X_START + 40 * ID_PIXEL_SCALE 
        && curr_y >= ID_Y_START && curr_y < ID_Y_START + 14 * ID_PIXEL_SCALE) begin
            id_ui_addr_reg =       ((curr_y - ID_Y_START) / ID_PIXEL_SCALE) * ID_SIZE_X
                                 + ((curr_x - ID_X_START) / ID_PIXEL_SCALE);
            if (!id_ui_addr_reg) begin
                id_ui_addr_reg = 40; // Prints a silver pixel in the top left since top left is 000 in memory
            end
        end else begin
            id_ui_addr_reg = 0;  // Outside the UI area 
            // This is one of the only ui's with a non black addr 0 pixel
        end
    end

    // Score display right 0-9
    always @* begin
        if (curr_x >= OUTPUT_X_START && curr_x < OUTPUT_X_START + 7 * OUTPUT_PIXEL_SCALE 
        && curr_y >= OUTPUT_Y_START && curr_y < OUTPUT_Y_START + 11 * OUTPUT_PIXEL_SCALE) begin
            output_ui_addr_reg = ((kill_count + score) % 10) * OUTPUT_AREA + ((curr_y - OUTPUT_Y_START) / OUTPUT_PIXEL_SCALE) * OUTPUT_SIZE_X
                                 + ((curr_x - OUTPUT_X_START) / OUTPUT_PIXEL_SCALE);
        end else begin
            output_ui_addr_reg = 0;  // Outside the UI area 
        end
    end
    
    // Score display left 00 - 90
    always @* begin
        if (curr_x >= OUTPUT_X_START_2 && curr_x < OUTPUT_X_START_2 + 7 * OUTPUT_PIXEL_SCALE 
        && curr_y >= OUTPUT_Y_START_2 && curr_y < OUTPUT_Y_START_2 + 11 * OUTPUT_PIXEL_SCALE) begin
            output_ui_addr_reg_2 = ((kill_count + score) / 10) % 10 * OUTPUT_AREA + ((curr_y - OUTPUT_Y_START_2) / OUTPUT_PIXEL_SCALE) * OUTPUT_SIZE_X
                                 + ((curr_x - OUTPUT_X_START_2) / OUTPUT_PIXEL_SCALE);
        end else begin
            output_ui_addr_reg_2 = 0;  // Outside the UI area 
        end
    end

    reg [18:0] computed_bg_addr;
    // Computes the background address
    always @* begin
        if (curr_x < 1440 && curr_y < 890 && curr_y >= 10) begin
            computed_bg_addr = (((curr_y / 2) > 4) ? (curr_y / 2 - 5) : 0) * 720 + (curr_x / 2);
        end else begin
            computed_bg_addr = 0;
        end
    end
    
    // END ADDRESS CALCULATIONS
    
    // CLOCK DRIVEN LOGIC
    
    // Background and bullet logic
    // Kept seperate from the other printing logic as this is more complicated than a reset and massive if statement
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            bg_r <= 4'b0000;
            bg_g <= 4'b0000;
            bg_b <= 4'b0000;
            
            rom_pixel_background_reg <= 0;
        end else begin
            
            rom_pixel_background_reg <= rom_pixel_background;
      
            // Bullets
            blt_r = 4'b0000;
            blt_g = 4'b0000;
            blt_b = 4'b0000;
            
            // Asigns bullet/knife colour
            for (i = 0; i < 10; i = i + 1) begin
                if(bullet_x_arr[i] != 0) begin
                    if (bullet_x_arr[i] <= curr_x && curr_x < bullet_x_arr[i] + BULLET_SIZE &&
                        bullet_y_arr[i] <= curr_y && curr_y < bullet_y_arr[i] + BULLET_SIZE) begin
                        if (sw == 2'd3) begin
                            blt_r = 4'b1001; // Knife color 
                            blt_g = 4'b1001 ;
                            blt_b = 4'b1001;
                        end else begin
                            blt_r = 4'b1111; // Bullet color 
                            blt_g = 4'b1101 ;
                            blt_b = 4'b0001;
                        end
                    end 
                end
            end
            
            if(game_over || display_wave || game_win) begin 
                bg_r <= rom_pixel_background_reg[11:8] >> 2;
                bg_g <= rom_pixel_background_reg[7:4] >> 2;
                bg_b <= rom_pixel_background_reg[3:0] >> 2;
            end else begin
                // Background from rom_pixel_background_reg
                bg_r <= rom_pixel_background_reg[11:8];
                bg_g <= rom_pixel_background_reg[7:4];
                bg_b <= rom_pixel_background_reg[3:0];
            end
        end
    end
    
    // Assigns values rom_pixel values from the animations to the registers
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            // Reset other values
            rom_pixel_reg <= 12'b0;
            rom_pixel_ui_reg <= 12'b0;
            rom_pixel_health_ui_reg <= 12'b0;
            rom_pixel_sound_ui_reg <= 12'b0;
            rom_pixel_wave_ui_reg <= 12'b0;
            rom_pixel_end_screen_ui_reg <= 12'b0;
            rom_pixel_skull_ui_reg <= 12'b0;
            rom_pixel_id_ui_reg <= 12'b0;
            rom_pixel_output_ui_reg <= 12'b0;
            rom_pixel_output_ui_reg_2 <= 12'b0;
            rom_pixel_title_ui_reg <= 12'b0;
            
            for (i = 0; i < NUM_ZOMBIES; i = i + 1) begin
                rom_pixel_zombie_ui_reg[i] <= 12'b0;
            end
        end else begin
            // Update UI pixel data
            rom_pixel_reg <= rom_pixel;
            rom_pixel_ui_reg <= rom_pixel_ui;
            rom_pixel_health_ui_reg <= rom_pixel_health_ui;
            rom_pixel_sound_ui_reg <= rom_pixel_sound_ui;
            rom_pixel_wave_ui_reg <= rom_pixel_wave_ui;
            rom_pixel_end_screen_ui_reg <= rom_pixel_end_screen_ui;
            rom_pixel_skull_ui_reg <= rom_pixel_skull_ui;
            rom_pixel_id_ui_reg <= rom_pixel_id_ui;
            rom_pixel_output_ui_reg <= rom_pixel_output_ui;
            rom_pixel_output_ui_reg_2 <= rom_pixel_output_ui_2;
            rom_pixel_title_ui_reg <= rom_pixel_title_ui;
            for (i = 0; i < active_zombies; i = i + 1) begin
                if (i < active_zombies && rom_pixel_zombie_ui[i] != 0 && dead[i]) begin
                        rom_pixel_zombie_ui_reg[i][11:8] <= 6; // 2 shades darker than injured
                        rom_pixel_zombie_ui_reg[i][7:4] <= rom_pixel_zombie_ui[i][7:4];
                        rom_pixel_zombie_ui_reg[i][3:0] <= rom_pixel_zombie_ui[i][3:0];
                end else begin
                    rom_pixel_zombie_ui_reg[i] <= rom_pixel_zombie_ui[i];
                end
            end         
        end
    end

    // Final pixel selection
    always @* begin
        if (blt_r != 0) begin // red is the colour to show bullets exist
            print_r = blt_r;
            print_g = blt_g;
            print_b = blt_b;  
        end else if (rom_pixel_reg != 0 && !display_wave) begin // might be here
            print_r = (zombie_attack_total) ? (rom_pixel_reg[11:8] + 4'b0011) & 4'b1111 : rom_pixel_reg[11:8];
            print_g = rom_pixel_reg[7:4];
            print_b = rom_pixel_reg[3:0];         
        end else if (rom_pixel_end_screen_ui_reg != 0 && (game_over || game_win)) begin 
            print_r = rom_pixel_end_screen_ui_reg[11:8];
            print_g = rom_pixel_end_screen_ui_reg[7:4];
            print_b = rom_pixel_end_screen_ui_reg[3:0];
        end else if (rom_pixel_wave_ui_reg != 0 && display_wave && !(game_over || game_win)) begin
            print_r = rom_pixel_wave_ui_reg[11:8];
            print_g = rom_pixel_wave_ui_reg[7:4];
            print_b = rom_pixel_wave_ui_reg[3:0];
        end else if (rom_pixel_ui_reg != 0 && !(game_over || game_win) && !display_wave) begin // Doesn't matter if black is overidden as background colour is black
            print_r = rom_pixel_ui_reg[11:8];
            print_g = rom_pixel_ui_reg[7:4];
            print_b = rom_pixel_ui_reg[3:0];
        end else if (rom_pixel_health_ui_reg != 0 && !(game_over || game_win) && !display_wave) begin
            print_r = rom_pixel_health_ui_reg[11:8];
            print_g = rom_pixel_health_ui_reg[7:4];
            print_b = rom_pixel_health_ui_reg[3:0];
        end else if (rom_pixel_sound_ui_reg != 0 && !(game_over || game_win) && !display_wave) begin
            print_r = rom_pixel_sound_ui_reg[11:8];
            print_g = rom_pixel_sound_ui_reg[7:4];
            print_b = rom_pixel_sound_ui_reg[3:0];
        end else if (rom_pixel_title_ui_reg != 0 && !(game_over || game_win) && !display_wave) begin
            print_r = rom_pixel_title_ui_reg[11:8];
            print_g = rom_pixel_title_ui_reg[7:4];
            print_b = rom_pixel_title_ui_reg[3:0];
        end else if (rom_pixel_skull_ui_reg != 0 && !(game_over || game_win) && !display_wave) begin
            print_r = rom_pixel_skull_ui_reg[11:8];
            print_g = rom_pixel_skull_ui_reg[7:4];
            print_b = rom_pixel_skull_ui_reg[3:0];
        end else if (rom_pixel_id_ui_reg != 0 && !(game_over || game_win) && !display_wave) begin
            print_r = rom_pixel_id_ui_reg[11:8];
            print_g = rom_pixel_id_ui_reg[7:4];
            print_b = rom_pixel_id_ui_reg[3:0];
        end else if (rom_pixel_output_ui_reg != 0 && !(game_over || game_win) && !display_wave) begin
            print_r = rom_pixel_output_ui_reg[11:8];
            print_g = rom_pixel_output_ui_reg[7:4];
            print_b = rom_pixel_output_ui_reg[3:0];          
        end else if (rom_pixel_output_ui_reg_2 != 0 && !(game_over || game_win) && !display_wave) begin
            print_r = rom_pixel_output_ui_reg_2[11:8];
            print_g = rom_pixel_output_ui_reg_2[7:4];
            print_b = rom_pixel_output_ui_reg_2[3:0];       
        end else begin
            print_r = 0;
            print_g = 0;
            print_b = 0;

            for (i = 0; i < active_zombies; i = i + 1) begin
                if (rom_pixel_zombie_ui_reg[i] != 0 && !display_wave) begin
                    print_r <= (hit_timer[i] > 0 && !dead[i]) ? 4'h8 : rom_pixel_zombie_ui_reg[i][11:8];
                    print_g <= rom_pixel_zombie_ui_reg[i][7:4];
                    print_b <= rom_pixel_zombie_ui_reg[i][3:0];
                end
            end   

        end 
        
    end
    
    // END CLOCK DRIVEN LOGIC
    
    // SPRTCLK DRIVEN LOGIC
    // Slower to save processing power
    
    // Noise animation calculations
    
    
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            sound_state <= 0;
        end else begin
            if (move_animation_true && shoot_true) begin
                sound_state_buffer <= 2; // Sprinting adds 2
            end else if (move_animation_true) begin
                sound_state_buffer <= 1; // Moving adds 1
            end else begin
                sound_state_buffer <= 0;
            end
    
            if (shoot_true) begin
                case (sw)
                    2'd0: sound_state_buffer_gun <= 2; // Assault rifle adds 2
                    2'd1: sound_state_buffer_gun <= 1; // Pistol adds 1
                    2'd2: sound_state_buffer_gun <= 3; // Shotgun adds 3
                    2'd3: sound_state_buffer_gun <= 0; // Knife adds no noise
                endcase
            end else begin
                sound_state_buffer_gun <= 0;
            end
    
            if (sound_state + sound_state_buffer_gun + pdm_output > 5) begin
                sound_state <= 5; // Cap the value at 5
            end else begin
                sound_state <= sound_state_buffer + sound_state_buffer_gun + pdm_output;
            end
        end
    end
    
    
    
    // Wave calculations
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            wave_counter <= 0; // Start with the first wave
            wave_state <= 0;
            wave_end_state <= 4;
            display_wave <= 1; 
            
            animation_counter <= 0;
            score <= 0;
            
            kill_count <= 0;
            
        end else begin
            score <= score_buffer;
            
            if (score >= active_zombies && !game_win && active_zombies != 8) begin
                kill_count <= kill_count + score;
                score <= 0;
                if (wave_counter <= 4) begin
                    wave_counter <= (game_over || game_win) ? wave_counter : wave_counter + 1; // Move to the next wave
                    display_wave <= (game_over || game_win) ? 0:1;
                end
            end

            // Contains the final frame the wave animation should display
            case(wave_counter)
                0: wave_end_state = 0;
                1: wave_end_state = 3;
                2: wave_end_state = 6;
                3: wave_end_state = 9;
                4: wave_end_state = 12;
                default: wave_end_state = 0;
            endcase
            
            // Wave changing logic
            if (display_wave) begin                
                if (wave_state >= wave_end_state) begin
                    if (wave_end_state > 1) begin 
                        // Updates wave state for the next wave
                        wave_state <= wave_end_state; // -3
                    end else begin 
                        wave_state <= 0; 
                    end
                    display_wave <= 0;
                end else begin
                    if(animation_counter >= ANIMATION_DELAY) begin
                        animation_counter <= 0;
                        wave_state <= wave_state + 1;
                    end else begin
                        animation_counter <= animation_counter + 1;
                    end
                end
            end 
            
            
        end
    end
    
    // Game Win/Lose
    // Would have been easier to displace by a variable instead of storing a seperate coe file for each animation
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            end_screen_state <= 7;
            game_over <= 0;
            game_win <= 0;
            game_over_counter <= 0;
            end_screen_stage <= 0;
        end else begin

            // Causes the final screen to dis
            if (game_over_counter > 4) begin
                if (end_screen_stage != 3) begin
                    end_screen_stage <= end_screen_stage + 1;
                end else begin
                    end_screen_stage <= 0;
                end
                if (kill_count + score == 30) begin
                    end_screen_state <= 1;
                    game_win <= 1;
                end
                // For displaying game_over or game_win
                if (game_over) begin
                    case (end_screen_stage)
                        0: end_screen_state <= 3;
                        1: end_screen_state <= 4;
                        2: end_screen_state <= 5;
                        3: end_screen_state <= 4;
                    endcase                    
                end else if (game_win) begin
                    case (end_screen_stage)
                        0: end_screen_state <= 0;
                        1: end_screen_state <= 1;
                        2: end_screen_state <= 2;
                        3: end_screen_state <= 1;
                    endcase 
                end
                game_over_counter <= 0; 
            end else begin
                game_over_counter <= game_over_counter + 1; 
            end

            if (health_state == 5) begin
                game_over <= (game_win) ? 0:1;
            end
        end
    end
    
    // Health logic
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            injure_player <= 0;
            health_timer <= 0;
            health_state <= 0;
        end else begin
            if (zombie_attack_total) begin
                    injure_player <= 1;
                    if(health_timer == 0) begin
                        health_state <= health_state + 1;
                        health_timer <= 30; // Reset timer for 2.5 seconds
                    end    
            end else begin
                injure_player <= 0;
            end
            
            if (display_wave) begin
                health_state <= 0;
            end

            if (health_timer > 0) begin
                health_timer <= health_timer - 1;
            end 
        end
    end
    
    
    // Soldier sprite counter
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
        sprite_direction <= 0;
        sprite_counter <= 0;
        end else begin
            sprite_direction <= dir;
            if (!move_animation_true || game_over || display_wave || game_win) begin
                sprite_counter <= 0;  // Reset the sprite counter on reset or no movement
            end else if (sprite_counter == 4'd11) begin
                sprite_counter <= 0;
            end else begin
                sprite_counter <= sprite_counter + 1;  // Increment the counter
            end
        end
    end
    
    // END SPRTCLK DRIVEN LOGIC
    
    // GENERAL CALCULATIONS
    
    // Bullet wire to reg
    always @* begin
        for (i = 0; i < 10; i = i + 1) begin
            bullet_x_arr[i] = bullet_x[11*i +: 11];
            bullet_y_arr[i] = bullet_y[10*i +: 10];
        end
    end
    
    // Creates new zombies each wave, here to allow configuration and clarity
    always @* begin
        case (wave_counter)
            0: active_zombies = 4; // Wave 1
            1: active_zombies = 5; // Wave 2
            2: active_zombies = 6; // Wave 3
            3: active_zombies = 7; // Wave 4
            4: active_zombies = 8; // Wave 5
            default: active_zombies = 8; // Safety default
        endcase
    end

    // Score buffer
    always @* begin
        score_buffer_squared = 0;
        for (i = 0; i < active_zombies; i=i+1) begin
            score_buffer_squared = score_buffer_squared + dead[i];
        end
        score_buffer = score_buffer_squared;
       
    end      
    
    // Soldier animation assigner (12 frames in 1 cycle, 9 frames stored)
    always @* begin
        if (injure_player && health_timer[1]) begin
            sprite_animation_stage = 8;
        end else if (injure_player && !health_timer[1]) begin
            sprite_animation_stage = 9;
        end 
        if (move_animation_true) begin // 
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
        if (shoot_true && shoot_flag && !move_animation_true) begin
            sprite_animation_stage = 7;
        end else if (shoot_true) begin
            sprite_animation_stage = 0;
        end
    end
    
    // END GENERAL CALCULATIONS
         
    assign draw_r = (print_r != 4'b0000 && (rom_pixel_background!=12'h321 || rom_pixel_wave_ui!=0 || rom_pixel_end_screen_ui!=0)) ? print_r : bg_r;
    assign draw_g = (print_g != 4'b0000 && (rom_pixel_background!=12'h321 || rom_pixel_wave_ui!=0 || rom_pixel_end_screen_ui!=0)) ? print_g : bg_g;
    assign draw_b = (print_b != 4'b0000 && (rom_pixel_background!=12'h321 || rom_pixel_wave_ui!=0 || rom_pixel_end_screen_ui!=0)) ? print_b : bg_b;
    
    // CALLING ANIMATION INSTANCES

    bullet_logic bullet_logic_inst
    (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .blkpos_x(blkpos_x),
        .blkpos_y(blkpos_y),
        .game_clk(game_clk),
        .shoot_true(shoot_true),
        .sprite_direction(sprite_direction),
        .bullet_x(bullet_x),
        .bullet_y(bullet_y),
        .shoot_flag(shoot_flag),
        .move_animation_true(move_animation_true)
    );
    
    clk_conv clk_conv_inst
    (
        .clk(clk),
        .rst(rst),
        .sprtclk(sprtclk),
        .new_clk(new_clk)
    );
    
    Background_Final Background (
        .clka(clk),
        .addra(computed_bg_addr),
        .douta(rom_pixel_background)
    );
    
    Soldier_Frames Soldier_Frames (
        .clka(clk),
        .addra(computed_addr),
        .douta(rom_pixel)
    );
    
    Weapons_UI Weapons_UI (
        .clka(clk),
        .addra(ui_addr_reg),
        .douta(rom_pixel_ui)
    );
    
    Health_UI Health_UI (
        .clka(clk),
        .addra(health_ui_addr_reg),
        .douta(rom_pixel_health_ui)
    );
    
    Sound_UI Sound_UI (
        .clka(clk),
        .addra(sound_ui_addr_reg),
        .douta(rom_pixel_sound_ui)
    );
    
    Wave_UI Wave_UI (
        .clka(clk),
        .addra(wave_ui_addr_reg),
        .douta(rom_pixel_wave_ui)
    );
    
    Title Title (
        .clka(clk),
        .addra(title_ui_addr_reg),
        .douta(rom_pixel_title_ui)
    );
    
    studentid studentid (
        .clka(clk),
        .addra(id_ui_addr_reg),
        .douta(rom_pixel_id_ui)
    );
    
    skull skull (
        .clka(clk),
        .addra(skull_ui_addr_reg),
        .douta(rom_pixel_skull_ui)
    );
    
    output_1 output_1 (
        .clka(clk),
        .addra(output_ui_addr_reg),
        .douta(rom_pixel_output_ui),
        .clkb(clk),
        .addrb(output_ui_addr_reg_2),
        .doutb(rom_pixel_output_ui_2)
    );
    
    
    
    YOUWIN_plus_GAMEOVER YOUWIN_plus_GAMEOVER (
        .clka(clk),
        .addra(end_screen_ui_addr_reg),
        .douta(rom_pixel_end_screen_ui)
    );
    

    generate
        for (k = 0; k < NUM_ZOMBIES; k = k + 1) begin : zombie_instances
            zombie zombie_inst (
                .rst(rst),
                .game_clk(game_clk),
                .bullet_x(bullet_x),
                .bullet_y(bullet_y),
                .player_loc_simple_x(player_loc_simple_x),
                .player_loc_simple_y(player_loc_simple_y),
                .detected(detected[k]),
                .curr_x(curr_x),
                .curr_y(curr_y),
                .zombie_computed_reg(zombie_computed_reg[k]),
                .sprtclk(sprtclk),
                .sound_state(sound_state),
                .hit_timer(hit_timer[k]),
                .zombie_attack(zombie_attack[k]),
                .display_wave(display_wave),
                .seed(12'b110101100000 + k),
                .wave_counter(wave_counter),
                .dead(dead[k])
            );
        end
    endgenerate
    
    generate
        for (j = 0; j < NUM_ZOMBIES; j = j + 2) begin : zombie_render
            Zombie_Animations Zombie_Animations_inst (
                .clka(clk),
                .addra(zombie_computed_reg[j]),
                .douta(rom_pixel_zombie_ui[j]),  // Store ROM output for each zombie
                .clkb(clk),
                .addrb(zombie_computed_reg[j+1]),
                .doutb(rom_pixel_zombie_ui[j+1])
            );
         end
    endgenerate
    


endmodule
