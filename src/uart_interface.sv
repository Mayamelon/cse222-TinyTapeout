module uart_interface (
    input [7:0] rx_data_i,
    input [0:0] rx_data_valid_i,

    output [15:0] tx_data_o,
    output [0:0] tx_data_valid_o,

    input [0:0] clk_i,
    input [0:0] reset_i, // reset high


    output [11:0] sensor_o,
    output [11:0] setpoint_o,

    output [0:0] process_data_o,

    output [0:0] reset_accumulated_error_o,

    output [3:0] Kp_o,
    output [3:0] Ki_o,

    output [0:0] soft_reset_o,
    
    input [11:0] result_i,
    input [0:0] result_valid_i
);


    // Receive:
    logic [11:0] sensor_r;
    logic [11:0] sensor_n;
    
    logic [11:0] setpoint_r;
    logic [11:0] setpoint_n;

    logic [3:0] Kp_r;
    logic [3:0] Kp_n;
    
    logic [3:0] Ki_r;
    logic [3:0] Ki_n;

    logic [0:0] process_data_r;
    logic [0:0] process_data_n;

    logic [0:0] soft_reset_r;
    logic [0:0] soft_reset_n;

    logic [0:0] reset_accumulated_error_r;
    logic [0:0] reset_accumulated_error_n;

    always_ff @(posedge clk_i) begin


        if (reset_i) begin
            sensor_r <= 0;
            setpoint_r <= 0;

            Kp_r <= 0;
            Ki_r <= 0;

            process_data_r <= 0;
            soft_reset_r <= 0;
            reset_accumulated_error_r <= 0;
        end else begin
            sensor_r <= sensor_n;
            setpoint_r <= setpoint_n;

            Kp_r <= Kp_n;
            Ki_r <= Ki_n;

            process_data_r <= process_data_n;
            soft_reset_r <= soft_reset_n;
            reset_accumulated_error_r <= reset_accumulated_error_n;
        end
    end

    assign sensor_o = sensor_r;
    assign setpoint_o = setpoint_r;

    assign Kp_o = Kp_r;
    assign Ki_o = Ki_r;

    assign process_data_o = process_data_r;
    assign soft_reset_o = soft_reset_r;
    assign reset_accumulated_error_o = reset_accumulated_error_r;


    // Transmit:
    logic [15:0] tx_data_r;
    logic [15:0] tx_data_n;

    logic [0:0] tx_data_valid_r;
    logic [0:0] tx_data_valid_n;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            tx_data_r <= 0;
            tx_data_valid_r <= 0;
        end else begin
            tx_data_r <= tx_data_n;
            tx_data_valid_r <= tx_data_valid_n;
        end
    end

    assign tx_data_o = tx_data_r;
    assign tx_data_valid_o = tx_data_valid_r;

    always_comb begin

        // Recieve:
        sensor_n = sensor_r;
        setpoint_n = setpoint_r;

        Kp_n = Kp_r;
        Ki_n = Ki_r;

        process_data_n = 1'b0;
        soft_reset_n = 1'b0;
        reset_accumulated_error_n = 1'b0;
    
        if (rx_data_valid_i) begin
            case (rx_data_i[7:7])
                1'b0: begin // read sensor in
                    case (rx_data_i[6:6])
                        1'b0: begin // upper 6 bits
                            sensor_n[11:6] = rx_data_i[5:0];
                        end
                        1'b1: begin // lower 6 bits
                            sensor_n[5:0] = rx_data_i[5:0];
                            process_data_n = 1;
                        end
                    endcase
                end
                1'b1: begin // configure controller
                    case (rx_data_i[6:4])
                        3'b000: begin
                            case (rx_data_i[0:0])
                                0: soft_reset_n = 1'b1;
                                1: reset_accumulated_error_n = 1'b1;
                            endcase
                        end
                        3'b001: setpoint_n[11:8] = rx_data_i[3:0];
                        3'b010: setpoint_n[7:4] = rx_data_i[3:0];
                        3'b011: setpoint_n[3:0] = rx_data_i[3:0];
                        3'b100: Kp_n = rx_data_i[3:0];
                        3'b101: Ki_n = rx_data_i[3:0];
                        3'b110, 3'b111: begin
                            // do nothing
                        end
                    endcase
                end
            endcase
        end else begin
            // do nothing
        end


        // Transmit:

        if (result_valid_i) begin
            tx_data_n = {2'b00, result_i[11:6], 2'b01, result_i[5:0]};
            tx_data_valid_n = 1;
        end else begin
            tx_data_n = 0;
            tx_data_valid_n = 0;
        end


    end


endmodule
