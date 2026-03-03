module pi_controller (
    input [10:0] sensor_i; // 11 bit input, unsigned
    input [10:0] setpoint_i; // 11 bit setpoint, unsigned

    input [0:-7] Kp_i; // multiply error by this fixed point value, LSB is 2^-6 = 0.015625, max value is 3.3.984375
    input [0:-7] Ki_i; // multiply integrated error by this fixed point value

    input [0:0] reset_i;
    input [0:0] clk_i; // should be slower than uart clock. 4 bytes in per operation
    // uart bitrate is 115200
    // 115200 / (4 uart frames) / (1 start bit + 8 data bits + 0 parity bits + 1 stop bit) = 2880 operations per second
    // 2880 is desired clock rate

    input [0:0] enable_i;

    output signed [15:0] result_o; // 16 bit output, signed (first bit is sign bit)

);

wire signed [11:0] error_w;

assign error_w = setpoint_i - sensor_i;

logic signed [11:0] accumulated_error_l; // should not be more than 2^11-1 = 2047 or less than -2^11 = -2048

always_ff @(posedge clk_i) begin
    if (reset_i) begin
        accumulated_error_l <= 16'h0;
    end else begin
        if (enable_i) begin
            if (accumulated_error_l + error_w > 2047) begin
                accumulated_error_l <= 2047;
            end else if (accumulated_error_l + error_w < -2048) begin
                accumulated_error_l <= -2048;
            end else begin
                accumulated_error_l <= accumulated_error_l + error_w;
            end
        end
    end
end

logic signed [11:-7] p_l;
logic signed [11:-7] i_l;

always_comb begin
    p_l = 0;
    i_l = 0;
    if (enable_i) begin // gates expensive multiplication logic with the enable input (for power?)
        p_l = (error_w * Kp_i);
        i_l = (accumulated_error_l * Ki_i);
    end
end



endmodule