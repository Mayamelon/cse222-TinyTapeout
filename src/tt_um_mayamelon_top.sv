/*
 * Copyright (c) 2026 Cole Lewis
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none


// this is the top module!
module tt_um_mayamelon_top (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    wire [0:0] soft_reset_w;
    wire [0:0] reset_w;
    assign reset_w = (~rst_n) | soft_reset_w;

    wire [0:0] uart_pulse_w;

    slower_clks slower_clks_inst (
        .clk_i(clk),
        .reset_i(reset_w),
        .uart_pulse_o(uart_pulse_w)
    );

    wire [15:0] tx_data_w;
    wire [0:0] tx_data_valid_w;
    
    wire [7:0] rx_data_w;
    wire [0:0] rx_data_valid_w;

    uart uart_inst (
        .rx_i(ui_in[3]),
        .tx_o(uo_out[4]),
        
        .clk_i(clk),
        .reset_i(reset_w),
        
        .uart_pulse_i(uart_pulse_w),
        
        .tx_data_i(tx_data_w),
        .tx_data_valid_i(tx_data_valid_w),
        
        .rx_data_o(rx_data_w),
        .rx_data_valid_o(rx_data_valid_w)
    );

    wire [11:0] sensor_w;
    wire [11:0] setpoint_w;

    wire [0:0] process_data_w;

    wire [3:0] Kp_w;
    wire [3:0] Ki_w;

    wire [11:0] result_w;
    wire [0:0] result_valid_w;

    wire [0:0] reset_accumulated_error_o;


    uart_interface uart_interface (
        .rx_data_i(rx_data_w),
        .rx_data_valid_i(rx_data_valid_w),

        .tx_data_o(tx_data_w),
        .tx_data_valid_o(tx_data_valid_w),

        .clk_i(clk),
        .reset_i(reset_w),

        .sensor_o(sensor_w),
        .setpoint_o(setpoint_w),

        .process_data_o(process_data_w),

        .reset_accumulated_error_o(reset_accumulated_error_o),

        .Kp_o(Kp_w),
        .Ki_o(Ki_w),

        .soft_reset_o(soft_reset_w),
        
        .result_i(result_w),
        .result_valid_i(result_valid_w)
    );


    pi_controller pi_controller_inst (
        .sensor_i(sensor_w),
        .setpoint_i(setpoint_w),
        
        .Kp_i(Kp_w),
        .Ki_i(Ki_w),
        
        .clk_i(clk),
        .reset_i(reset_w),
        
        .process_data_i(process_data_w),
        
        .reset_accumulated_error_i(reset_accumulated_error_o),
        
        .result_o(result_w),
        .result_valid_o(result_valid_w)
    );







    // \/ DEFAULT \/

    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out[7:5] = 0;
    assign uo_out[3:0] = 0;
    assign uio_out = 0;
    assign uio_oe  = 0; // assign all uio bits to be inputs

    // List all unused inputs to prevent warnings
    wire _unused = &{1'b0, ena, ui_in[7:4], ui_in[2:0], uio_in};

endmodule
