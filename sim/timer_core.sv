module timer_core (
    input logic axi_clk,
    input logic rst_n,

    input logic enable,
    input logic reset_counter,
    input logic [31:0] prescaler,

    output logic [31:0] counter
);
    logic [31:0] prescaler_count;

    always_ff @(posedge axi_clk or negedge rst_n) begin : timer_block
        if(!rst_n || reset_counter) begin
            counter <= '0;
            prescaler_count <= '0;
        end else if (enable) begin
            if(prescaler_count >= prescaler) begin
                counter <= counter + 1;
                prescaler_count <= '0;
            end else begin
                prescaler_count <= prescaler_count + 1;
            end
        end
    end
endmodule