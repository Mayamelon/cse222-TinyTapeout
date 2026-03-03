module uart_clk (
    input [0:0] clk_i;
    input [0:0] reset_i;

    input [0:0] enable_i;

    output [0:0] uart_clk_o;
);

    // input clock generated at 12MHz from https://tinytapeout.com/specs/pcb/#rp2040-on-board-mcu
    // goal clock is 115200 for UART
    // 12000000/115200 = 104.167

    // allowable clock accuracy is 2% from https://www.analog.com/en/resources/technical-articles/determining-clock-accuracy-requirements-for-uart-communications.html

    // counter up to 127 (7 bits) that resets on bit 104

    logic [6:0] counter_r;
    logic [6:0] counter_n;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            counter_r <= 0;
        end else begin
            counter_r <= counter_n;
        end
    end

    logic [0:0] clk_r;
    logic [0:0] clk_n;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            clk_r <= 0;
        end else begin
            clk_r <= clk_n;
        end
    end

    always_comb begin
        if (counter_r == 103) begin // counts from 0 to 103
            counter_n = 0;
            clk_n = ~clk_r;
        end else begin
            counter_n = counter_r + 1;
            clk_n = clk_r;
        end
    end




endmodule