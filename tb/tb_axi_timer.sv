`timescale 1ns / 1ps

module tb_axi_timer;

    parameter AXI_DATA_WIDTH = 32;
    
    //timer register addresses to access    
    localparam ADDR_CONTROL = 32'h0000_0000;
    localparam ADDR_PRESCALER = 32'h0000_0004;
    localparam ADDR_COUNTER = 32'h0000_0008; 

    logic axi_clk;
    logic rst_n;
    
    //all axi interface signals

    logic [31:0] AWADDR;
    logic AWVALID;
    logic AWREADY;

    logic [31:0] WDDATA;
    logic [3:0] WDSTRB;
    logic WDVALID;
    logic WDREADY;

    logic [1:0] BRESP;
    logic BVALID;
    logic BREADY;

    logic [31:0] ARADDR;
    logic ARVALID;
    logic ARREADY;

    logic [31:0] RDATA;
    logic [1:0] RRESP;
    logic RVALID;
    logic RREADY;
    logic [31:0] read_data; //internal signal (reading data)

    axi_timer_top dut (
        .* //use wildcard connection as all ports identical
    );

    //generate a clock
    always #5 axi_clk = ~axi_clk;

    //AXI Write task logic

    task axi_write(input [31:0] addr, input [31:0] data);
        @(posedge axi_clk);
        AWADDR <= addr;
        AWVALID <= 1'b1;
        WDDATA <= data;
        WDSTRB <= 4'hF; //enable all byte lanes for strobe
        WDVALID <= 1'b1;

        wait(AWREADY); //wait until AWREADY is asserted (slave)
        @(posedge axi_clk);
        AWVALID <= 1'b0; //disassert awvalid

        wait(WDREADY);
        @(posedge axi_clk);
        WDVALID <= 1'b0;

        BREADY <= 1'b1;
        wait(BVALID);
        @(posedge axi_clk);
        BREADY <= 1'b0;
    endtask

    //AXI Read task logic

    task axi_read(input [31:0] addr, output [31:0] data);
        @(posedge axi_clk);
        ARADDR <= addr;
        ARVALID <= 1'b1;
        
        wait (ARREADY);
        @(posedge axi_clk)
        ARVALID <= 1'b0;
        
        wait(RVALID);
        data = RDATA;
        @(posedge axi_clk);
        RREADY <= 1'b1;
        @(posedge axi_clk);
        RREADY <= 1'b0;

    endtask

    //Main testbench logic 

    initial begin
        $display("Starting tb_top_timer.sv");
        //initialize signals + reset
        axi_clk = 0;
        rst_n = 1'b0;
        AWVALID <= 0;
        WDVALID <= 0;
        BREADY <= 0;
        ARVALID <= 0;
        RREADY <= 0;
        repeat(5) @(posedge axi_clk); //wait 5 clock cycles.
        rst_n = 1'b1; //stop reset
        @(posedge axi_clk);

        //apply prescaler value for counter to prescaler reg
        $display("Writing 10 to prescaler reg");
        axi_write(ADDR_PRESCALER, 32'd10);
        //read back to verify that its applied prescaler
        axi_read(ADDR_PRESCALER, read_data);
        $display("Prescaler value = %0d", read_data);
        //enable timer in timer_core
        axi_write(ADDR_CONTROL, 32'h0000_0001); //set enable bit [0]
        $display("Enabling Timer");
        //wait for counter to incrament (wait 60 clock cycles);
        $display("waiting 60 clock cycles");
        repeat(60) @(posedge axi_clk);
        //read counter value
        axi_read(ADDR_COUNTER, read_data);
        $display("Counter value = %0d, should be 5", read_data);
        //reset counter (write 2 to control reg)
        axi_write(ADDR_CONTROL, 32'h0000_0002);
        $display("Resetting counter");
        //check counter is reset
        axi_read(ADDR_COUNTER, read_data);
        $display("Counter value after RESET = %0d", read_data);

        $display("Finished");
        $finish;
    end
endmodule
