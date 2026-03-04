module slower_clks (
    input [0:0] clk_i,
    input [0:0] reset_i, // reset high

    output [0:0] uart_pulse_o // pulses for 1 clk cycle at 115200 Hz
);

    // input clock generated at 12MHz from https://tinytapeout.com/specs/pcb/#rp2040-on-board-mcu
    // goal clock is 115200 for UART
    // 12000000/115200 = 104.167 times slower

    // allowable clock accuracy is 2% from https://www.analog.com/en/resources/technical-articles/determining-clock-accuracy-requirements-for-uart-communications.html
    // because of that, 104 clock cycles is acceptable: 12000000/104 -> 115384.6 which is only 0.16% off from 115200

    // counter up to 127 (7 bits) that resets and pulses uart_pulse_o on 104th bit (103).

    logic [6:0] counter_r;
    logic [6:0] counter_n;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            counter_r <= 0;
        end else begin
            counter_r <= counter_n;
        end
    end

    logic [0:0] uart_pulse_l;

    logic [7:0] counter_r_plus_1_l = counter_r + 1'b1;

    always_comb begin
        if (counter_r == 7'd103) begin // counts from 0 to 103 -> 104 clock cycles
            counter_n = 0;
            uart_pulse_l = 1;
        end else begin
            counter_n = counter_r_plus_1_l[6:0];
            uart_pulse_l = 0;
        end
    end

    assign uart_pulse_o = uart_pulse_l;




endmodule
