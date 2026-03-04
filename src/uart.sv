module uart (
    input [0:0] rx_i,
    output [0:0] tx_o,

    input [0:0] clk_i,
    input [0:0] uart_pulse_i, // should pulse for one clock period at 115200Hz
    input [0:0] reset_i, // reset high

    input [15:0] tx_data_i,
    input [0:0] tx_data_valid_i,
    
    output [7:0] rx_data_o,
    output [0:0] rx_data_valid_o
);


    localparam IDLE = 4'h1;
    localparam START = 4'h2;
    localparam DATA = 4'h4;
    localparam STOP = 4'h8;



    // transmit
    logic [3:0] tx_state_r;
    logic [3:0] tx_state_n;
    
    logic [3:0] tx_data_pos_r;
    logic [3:0] tx_data_pos_n;

    logic [0:0] tx_l;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            tx_state_r <= IDLE;
            tx_data_pos_r <= 0;
        end else begin
            tx_state_r <= tx_state_n;
            tx_data_pos_r <= tx_data_pos_n;
        end
    end

    logic [4:0] tx_data_pos_r_plus_1_l = tx_data_pos_r + 1'b1;

    always_comb begin

        // state outputs:
        tx_state_n = tx_state_r;
        tx_l = 1;
        case (tx_state_r)
            IDLE: begin
                tx_l = 1;
            end
            START: begin
                tx_l = 0;
            end
            DATA: begin
                tx_l = tx_data_i[tx_data_pos_r];
            end
            STOP: begin
                tx_l = 1;
            end
            default: begin
                tx_l = 1;
            end
        endcase

        // state transitions:
        tx_data_pos_n = tx_data_pos_r;
        if (uart_pulse_i) begin

            case (tx_state_r)
                IDLE: begin
                    if (tx_data_valid_i) begin
                        tx_state_n = START;
                    end else begin
                        tx_state_n = IDLE;
                    end
                end
                START: begin
                    tx_state_n = DATA;
                end
                DATA: begin
                    tx_data_pos_n = tx_data_pos_r_plus_1_l[3:0];
                    if (tx_data_pos_r == 4'h7) begin
                        tx_state_n = STOP;
                    end else if (tx_data_pos_r == 4'hF) begin
                        tx_state_n = IDLE;
                    end else begin
                        tx_state_n = DATA;
                    end
                end
                STOP: begin
                    tx_state_n = START;
                end
                default: begin
                    tx_state_n = IDLE;
                end
            endcase
        end
    end

    assign tx_o = tx_l;



    // receive
    logic [2:0] rx_state_r;
    logic [2:0] rx_state_n;
    
    logic [7:0] rx_data_buffer_r;
    logic [7:0] rx_data_buffer_n;
    
    logic [2:0] rx_data_pos_r;
    logic [2:0] rx_data_pos_n;

    logic [7:0] rx_data_l;
    logic [0:0] rx_data_valid_l;


    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            rx_state_r <= IDLE[2:0];
            rx_data_buffer_r <= 0;
            rx_data_pos_r <= 0;
        end else begin
            rx_state_r <= rx_state_n;
            rx_data_buffer_r <= rx_data_buffer_n;
            rx_data_pos_r <= rx_data_pos_n;
        end
    end

    logic [3:0] rx_data_pos_r_plus_1_l;
    assign rx_data_pos_r_plus_1_l = rx_data_pos_r + 3'b1;
    
    always_comb begin
        
        // state transitions:
        rx_data_buffer_n = rx_data_buffer_r;
        if (uart_pulse_i) begin

            rx_data_pos_n = 0;
            case (rx_state_r)
                IDLE[2:0]: begin
                    if (~rx_i) begin
                        rx_state_n = START[2:0];
                    end else begin
                        rx_state_n = IDLE[2:0];
                    end
                end
                START[2:0]: begin
                    rx_state_n = DATA[2:0];
                    // rx_data_pos_n = rx_data_pos_r_plus_1_l[2:0];
                    rx_data_buffer_n = {rx_data_buffer_r[6:0], rx_i};
                end
                DATA[2:0]: begin
                    rx_data_pos_n = rx_data_pos_r_plus_1_l[2:0];
                    rx_data_buffer_n = {rx_data_buffer_r[6:0], rx_i};
                    if (rx_data_pos_r == 3'h7) begin
                        rx_state_n = IDLE[2:0];
                    end else begin
                        rx_state_n = DATA[2:0];
                    end
                end
                default: begin
                    rx_state_n = IDLE[2:0];
                end

            endcase
        end else begin
            rx_state_n = rx_state_r;
            rx_data_pos_n = rx_data_pos_r;
        end

        // state outputs:
        case ({rx_state_r, rx_data_pos_r, uart_pulse_i})
            {DATA[2:0], 3'h7, 1'b1}: begin // in data state AND all 8 data bits recieved AND on a uart pulse
                // oops UART is little endian so I had to swap the bits
                rx_data_l = {rx_data_buffer_r[0], rx_data_buffer_r[1], rx_data_buffer_r[2], rx_data_buffer_r[3], rx_data_buffer_r[4], rx_data_buffer_r[5], rx_data_buffer_r[6], rx_data_buffer_r[7]};
                rx_data_valid_l = 1;
            end
            default: begin
                rx_data_l = 0;
                rx_data_valid_l = 0;
            end
        endcase

    end

    assign rx_data_o = rx_data_l;
    assign rx_data_valid_o = rx_data_valid_l;


    

endmodule
