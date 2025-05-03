`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    logic buffer_full;
    reg [15:0] buffer [0:15]; // array of 16 samples that are 16 bits wide
    logic [3:0] buffer_index;
    logic top_half, fft_done;
    reg [15:0] real_num [0:15];
    reg [15:0] imag [0:15];
    reg [3:0] peak_bin;
    reg [31:0] best;
    reg [3:0] best_bin;
    reg [31:0] temp_mag;
    logic keep_output;
    logic fft_start;

    // Expansion of buffer, and real_num/imag syntax error fixed via AI
    fft fft1(
        .clk(clock),
        .start(fft_start),
        .done(fft_done),
        .din_0(buffer[0]),
        .din_1(buffer[1]),
        .din_2(buffer[2]),
        .din_3(buffer[3]),
        .din_4(buffer[4]),
        .din_5(buffer[5]),
        .din_6(buffer[6]),
        .din_7(buffer[7]),
        .din_8(buffer[8]),
        .din_9(buffer[9]),
        .din_10(buffer[10]),
        .din_11(buffer[11]),
        .din_12(buffer[12]),
        .din_13(buffer[13]),
        .din_14(buffer[14]),
        .din_15(buffer[15]),
        .real_0(real_num[0]),
        .real_1(real_num[1]),
        .real_2(real_num[2]),
        .real_3(real_num[3]),
        .real_4(real_num[4]),
        .real_5(real_num[5]),
        .real_6(real_num[6]),
        .real_7(real_num[7]),
        .real_8(real_num[8]),
        .real_9(real_num[9]),
        .real_10(real_num[10]),
        .real_11(real_num[11]),
        .real_12(real_num[12]),
        .real_13(real_num[13]),
        .real_14(real_num[14]),
        .real_15(real_num[15]),
        .imag_0(imag[0]),
        .imag_1(imag[1]),
        .imag_2(imag[2]),
        .imag_3(imag[3]),
        .imag_4(imag[4]),
        .imag_5(imag[5]),
        .imag_6(imag[6]),
        .imag_7(imag[7]),
        .imag_8(imag[8]),
        .imag_9(imag[9]),
        .imag_10(imag[10]),
        .imag_11(imag[11]),
        .imag_12(imag[12]),
        .imag_13(imag[13]),
        .imag_14(imag[14]),
        .imag_15(imag[15])
    );

    // INPUT: microcontroller sends samples from mic
    // OUTPUT: output is the frequency bin --> calculation of peak frequency + MIDI note done on microcontroller
    always @(posedge clock, posedge reset) begin
        // if reset, set counter to 0
        if (reset) begin
            buffer_index <= 0;
            buffer_full <= 0;
            top_half <= 1;
            for (integer i = 0; i < 16; i = i + 1) begin
                buffer[i] <= 16'd0;
            end
        end else begin
            // STEP 1: Buffer to collect samples from microcontroller
            if (!buffer_full) begin
                if (!top_half) begin
                    buffer[buffer_index] <= (buffer[buffer_index] << 8) | io_in[7:0];
                    buffer_index <= buffer_index + 1;
                end
                else buffer[buffer_index] <= io_in[7:0];
                if (buffer_index == 15) buffer_full <= 1;
                top_half <= ~top_half;
            end
            if (buffer_full) begin
                fft_start <= 1;
                if (fft_done) begin
                    // MAGNITUDE COMPUTATION
                    // STEP 3: Magnitude of bins
                    // Calculate magnitudes of each bin
                    best = 0;
                    best_bin = 0;
                    temp_mag = 0;
                    for (integer i = 0; i < 16; i = i + 1) begin
                        temp_mag = real_num[i]*real_num[i] + imag[i]*imag[i];
                        if (temp_mag > best) begin
                            best = temp_mag;
                            best_bin = i;
                        end
                    end
                    peak_bin <= best_bin;
                    buffer_index <= 0;
                    buffer_full <= 0;
                    top_half <= 1;
                    for (integer i = 0; i < 16; i = i + 1) begin
                        buffer[i] <= 16'd0;
                    end
                    fft_start <= 0;
                    keep_output <= 1;
                end
                else begin
                    keep_output <= 0;
                end
            end
        end
    end

    assign io_out[3:0] = (keep_output) ? peak_bin : 0;

endmodule : my_chip

    // STEP 2: FFT --> used ChatGPT to understand basic FFT and necessary components
    // Outputs values in the real and imaginary bins, used for magnitude computation
    // Quick convo with AI to figure out separation of wires for the buffer for fft
module fft(
    input logic clk,
    input logic start,
    // Use individual ports instead of arrays
    input wire [15:0] din_0,
    input wire [15:0] din_1,
    input wire [15:0] din_2,
    input wire [15:0] din_3,
    input wire [15:0] din_4,
    input wire [15:0] din_5,
    input wire [15:0] din_6,
    input wire [15:0] din_7,
    input wire [15:0] din_8,
    input wire [15:0] din_9,
    input wire [15:0] din_10,
    input wire [15:0] din_11,
    input wire [15:0] din_12,
    input wire [15:0] din_13,
    input wire [15:0] din_14,
    input wire [15:0] din_15,
    output logic done,
    // Output individual real and imaginary ports
    output reg [15:0] real_0,
    output reg [15:0] real_1,
    output reg [15:0] real_2,
    output reg [15:0] real_3,
    output reg [15:0] real_4,
    output reg [15:0] real_5,
    output reg [15:0] real_6,
    output reg [15:0] real_7,
    output reg [15:0] real_8,
    output reg [15:0] real_9,
    output reg [15:0] real_10,
    output reg [15:0] real_11,
    output reg [15:0] real_12,
    output reg [15:0] real_13,
    output reg [15:0] real_14,
    output reg [15:0] real_15,
    output reg [15:0] imag_0,
    output reg [15:0] imag_1,
    output reg [15:0] imag_2,
    output reg [15:0] imag_3,
    output reg [15:0] imag_4,
    output reg [15:0] imag_5,
    output reg [15:0] imag_6,
    output reg [15:0] imag_7,
    output reg [15:0] imag_8,
    output reg [15:0] imag_9,
    output reg [15:0] imag_10,
    output reg [15:0] imag_11,
    output reg [15:0] imag_12,
    output reg [15:0] imag_13,
    output reg [15:0] imag_14,
    output reg [15:0] imag_15
);
     
    always @(posedge clk) begin
        if (start) begin
            done <= 1;
            // Copy inputs to real outputs, set imaginary to zero
            real_0 <= din_0;
            real_1 <= din_1;
            real_2 <= din_2;
            real_3 <= din_3;
            real_4 <= din_4;
            real_5 <= din_5;
            real_6 <= din_6;
            real_7 <= din_7;
            real_8 <= din_8;
            real_9 <= din_9;
            real_10 <= din_10;
            real_11 <= din_11;
            real_12 <= din_12;
            real_13 <= din_13;
            real_14 <= din_14;
            real_15 <= din_15;
            
            imag_0 <= 16'd0;
            imag_1 <= 16'd0;
            imag_2 <= 16'd0;
            imag_3 <= 16'd0;
            imag_4 <= 16'd0;
            imag_5 <= 16'd0;
            imag_6 <= 16'd0;
            imag_7 <= 16'd0;
            imag_8 <= 16'd0;
            imag_9 <= 16'd0;
            imag_10 <= 16'd0;
            imag_11 <= 16'd0;
            imag_12 <= 16'd0;
            imag_13 <= 16'd0;
            imag_14 <= 16'd0;
            imag_15 <= 16'd0;
        end else begin
            done <= 0;
        end
    end

endmodule : fft