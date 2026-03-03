module pi_controller (
    input [9:0] sensor_i; // 10 bit input, unsigned
    input [9:0] setpoint_i; // 10 bit setpoint, unsigned

    input [0:-5] Kp_i; // multiply error by this fixed point value, LSB is 2^-5 = 0.03125, max value is 1.96875
    input [0:-5] Ki_i; // multiply integrated error by this fixed point value

    input [0:0] reset_i;
    input [0:0] clk_i;
    
    input [0:0] process_data_i; // should pulse once per operation.
    // 2 bytes per operation, so 2 UART frames
    // uart bitrate is 115200
    // 115200 / (2 uart frames) / (1 start bit + 8 data bits + 0 parity bits + 1 stop bit) = 5760 operations per second
    // 5760Hz is desired rate that this should pulse

    input [0:0] enable_i;

    output signed [11:0] result_o; // 12 bit output, signed

);

wire signed [11:0] error_w;

assign error_w = setpoint_i - sensor_i;

logic signed [11:0] accumulated_error_l; // should not be more than 2^11-1 = 2047 or less than -2^11 = -2048

always_ff @(posedge clk_i) begin
    if (reset_i) begin
        accumulated_error_l <= 16'h0;
    end else begin
        if (enable_i & process_data_i) begin
            if (accumulated_error_l + error_w > 2047) begin
                accumulated_error_l <= 2047;
            end else if (accumulated_error_l + error_w < -2048) begin
                accumulated_error_l <= -2048;
            end else begin
                accumulated_error_l <= accumulated_error_l + error_w;
            end
        end else begin

        end
    end
end

logic signed [11:-7] p_l;
logic signed [11:-7] i_l;

logic signed [12:]

always_comb begin
    p_l = 0;
    i_l = 0;
    if (enable_i) begin // gates expensive multiplication logic with the enable input (for power?)
        p_l = (error_w * Kp_i);
        i_l = (accumulated_error_l * Ki_i);

        result_o = {p_l + i_l}[12:0];
    end
end



endmodule