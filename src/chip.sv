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
    reg[31:0] temp_mag;
    logic keep_output;
    logic fft_start;

    fft fft1(
        .clk(clock),
        .start(fft_start),
        .done(fft_done),
        .din(buffer),
        .real_n(real_num),
        .imag(imag)
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

endmodule

    // STEP 2: FFT --> used ChatGPT to understand basic FFT and necessary components
    // Outputs values in the real and imaginary bins, used for magnitude computation
module fft(
    input logic clk,
    input logic start,
    input wire [15:0] din [0:15],
    output logic done,
    output wire [15:0] real_n [0:15],
    output wire [15:0] imag [0:15]
    );
     
    always @(posedge clk) begin

        done <= start;
        real_n <= din;
        imag <= din;
    end

endmodule