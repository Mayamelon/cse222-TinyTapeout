module pi_controller (
    input [11:0] sensor_i, // 12 bit input, unsigned
    input [11:0] setpoint_i, // 12 bit setpoint, unsigned

    input [3:0] Kp_i, // determines how much to shift P term by - shifts right by any values 0x0-0x7. 0x8 shifts left by 1 and 0x9-0xF disables the P term
    input [3:0] Ki_i, // determines how much to shift I term by - shifts right by any values 0x0-0x7. 0x8 shifts left by 1 and 0x9-0xF disables the I term

    input [0:0] clk_i,
    input [0:0] reset_i, // reset high
    
    input [0:0] process_data_i, // should pulse once per operation. Can be disabled entirely

    input [0:0] reset_accumulated_error_i,

    // 2 bytes per operation, so 2 UART frames
    // uart bitrate is 115200
    // 115200 / (2 uart frames) / (1 start bit + 8 data bits + 0 parity bits + 1 stop bit) = 5760 operations per second
    // 5760Hz is desired rate that this should pulse

    output signed [11:0] result_o, // 12 bit output, signed
    output [0:0] result_valid_o

);

wire signed [11:0] error_w;

assign error_w = setpoint_i - sensor_i;

logic signed [15:0] accumulated_error_l; // signed. Should not be more than 2^15-1 = 32767 or less than -2^15 = -32768

always_ff @(posedge clk_i) begin
    if (reset_i | reset_accumulated_error_i) begin
        accumulated_error_l <= 16'h0;
    end else begin
        if (process_data_i) begin
            if ((accumulated_error_l + {4'b0, error_w}) > 17'd32767) begin
                accumulated_error_l <= 32767;
            end else if ((accumulated_error_l + {4'b0, error_w}) < -17'd32768) begin
                accumulated_error_l <= -32768;
            end else begin
                accumulated_error_l <= (accumulated_error_l + {4'b0, error_w});
            end
        end else begin
            // do nothing
        end
    end
end

logic signed [12:0] p_l;
logic signed [16:0] i_l;

logic signed [16:0] sum_l;

logic signed [11:0] result_l; // ranges from 2,047 to -2,048

logic [0:0] result_valid_l;

always_comb begin
    p_l = 0;
    i_l = 0;
    sum_l = 0;
    result_l = 0;
    result_valid_l = 0;
    if (process_data_i) begin
        if (Kp_i <= 4'h7) begin
            p_l = ({{1'b0, error_w} >>> Kp_i}[12:0]); // arithmetic right shift preserves sign
        end else if (Kp_i == 4'h8) begin
            p_l = ({{1'b0, error_w} <<< 1}[12:0]); // arithmetic left shift preserves sign
        end else begin // disable p term
            p_l = 0;
        end
        
        if (Ki_i <= 4'h7) begin
            i_l = ({{1'b0, accumulated_error_l} >>> Ki_i}[16:0]); // arithmetic right shift preserves sign
        end else if (Ki_i == 4'h8) begin
            i_l = ({{1'b0, accumulated_error_l} <<< 1}[16:0]); // arithmetic left shift preserves sign
        end else begin // disable i term
            i_l = 0;
        end

        sum_l = {{4'b0, p_l} + i_l};

        if (sum_l > 2047) begin
            result_l = 2047;
        end else if (sum_l < -2048) begin
            result_l = -2048;
        end else begin
            result_l = {sum_l[16:16], sum_l[10:0]};
        end
        result_valid_l = 1;
    end
end

assign result_o = result_l;
assign result_valid_o = result_valid_l;


endmodule
