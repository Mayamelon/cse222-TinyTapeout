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

    wire [0:0] uart_pulse_w;

    slower_clks slower_clks_inst
        (.clk_i(clk_i)
        ,.reset_n(rst_n)

        ,.enable_i(1'b1)

        ,.uart_pulse_o(uart_pulse_w));


    uart uart_inst
        (.rx_i(ui_in[3])
        ,.tx_o(uo_out[4])

        ,.clk_i(clk)
        ,.reset_n(rst_n)

        ,.uart_pulse_i(uart_pulse_w)

        ,.tx_data_i()
        ,.tx_data_valid_i()

        ,.rx_data_o()
        ,.rx_data_valid_o());


    pi_controller pi_controller_inst
        (.sensor_i()
        ,.setpoint_i()

        ,.Kp_i()
        ,.Ki_i()

        ,.reset_n()
        ,.clk_i()
        
        ,.process_data_i()

       ,.result_o());







    // \/ DEFAULT \/

    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
    assign uio_out = 0;
    assign uio_oe  = 0; // assign all uio bits to be inputs

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
