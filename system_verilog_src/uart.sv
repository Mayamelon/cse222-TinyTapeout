module uart (
    input [0:0] rx_i;
    output [0:0] tx_o;

    input [0:0] clk_i;
    input [0:0] uart_pulse_i; // should pulse for one clock period at 115200Hz
    input [0:0] reset_i;

    input [7:0] tx_data_i;
    input [0:0] tx_data_valid_i;
    
    output [7:0] rx_data_o;
    output [0:0] rx_data_valid_o;
);

    typedef enum {IDLE=3'h1, START=3'h2, DATA=3'h4} states_t; // one hot



    // transmit
    logic [2:0] tx_state_r;
    logic [2:0] tx_state_n;
    
    logic [2:0] tx_data_pos_r
    logic [2:0] tx_data_pos_n;

    logic [0:0] tx_l;

    always_ff (@posedge clk_i) begin
        if (reset_i) begin
            tx_state_r <= IDLE;
            tx_data_pos_r <= 0;
        end else begin
            tx_state_r <= tx_state_n;
            tx_data_pos_r <= tx_data_pos_n;
        end
    end

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
                tx_l = tx_data_i[tx_data_pos_r:tx_data_pos_r];
            end
        endcase

        // state transitions:
        if (uart_pulse_i) begin

            tx_data_pos_n = 0;
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
                    tx_data_pos_n = {tx_data_pos_r + 1}[2:0];
                    if (tx_data_pos_r == 3'h7) begin
                        tx_state_n = IDLE;
                    end else begin
                        tx_state_n = DATA;
                    end
                end
            endcase
        end
    end

    assign tx_o = tx_l;



    // receive
    logic [2:0] rx_state_r;
    logic [2:0] rx_state_n;
    
    logic [7:0] rx_data_buffer_r
    logic [7:0] rx_data_buffer_n;
    
    logic [2:0] rx_data_pos_r
    logic [2:0] rx_data_pos_n;

    logic [7:0] rx_data_l;
    logic [0:0] rx_data_valid_l;


    always_ff (@posedge clk_i) begin
        if (reset_i) begin
            rx_state_r <= IDLE;
            rx_data_buffer_r <= 0;
            rx_data_pos_r <= 0;
        end else begin
            rx_state_r <= rx_state_n;
            rx_data_buffer_r <= rx_data_buffer_n;
            rx_data_pos_r <= rx_data_pos_n;
        end
    end
    
    always_comb begin
        
        // state transitions:
        if (uart_pulse_i) begin

            rx_data_pos_n = 0;
            case (rx_state_r)
                IDLE: begin
                    if (~rx_i) begin
                        rx_state_n = START;
                    end
                end
                START: begin
                    rx_state_n = DATA;
                end
                DATA: begin
                    rx_data_pos_n = {rx_data_pos_r + 1}[2:0];
                    if (rx_data_pos_r == 3'h7) begin
                        rx_state_n = IDLE;
                    end else begin
                        rx_state_n = DATA;
                    end
                end

            endcase

            rx_data_buffer_n = {rx_data_buffer_r[6:0], rx_i}
        end else begin
            rx_state_n = rx_state_r;
            rx_data_buffer_n = rx_data_buffer_r;
        end

        // state outputs:
        case ({rx_state_r, rx_data_pos_r, uart_pulse_i})
            {DATA, 3'h7, 1}: begin // in data state AND all 8 data bits recieved AND on a uart pulse
                rx_data_l = rx_data_buffer_r;
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