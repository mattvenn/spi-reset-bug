`default_nettype none
module top (
	input  ext_clk,
    output spi_miso,
    input spi_clk,
    input spi_mosi,
    input spi_ss,
    input reset,
    output pmod1_1,
    output pmod1_2,
    output pmod1_3,
    output pmod1_4
);
    wire spi_we;
    wire spi_re;
    wire clk_32m;

    // for capturing the traces
    assign pmod1_1 = spi_miso;
    assign pmod1_2 = spi_clk;
    assign pmod1_3 = read_count != 1'b0;
    assign pmod1_4 = reset;

    `ifndef FORMAL
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        // 32mhz
        .DIVR(4'b0011),
        .DIVF(7'b0101000),
        .DIVQ(3'b101), 
        .FILTER_RANGE(3'b010)

    ) uut (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(ext_clk),
        .PLLOUTCORE(clk_32m)
    );
    `endif

    `ifdef FORMAL
        wire clk_32m = ext_clk;
    `endif

    // register widths
    localparam REG_GEN        = 7'h7D; 
    localparam REG_RD_CNT     = 7'h7E; 

    // change this number to alter the outcome of the test
    `ifndef FORMAL
    localparam SPI_LEN = 8 * 12;
    `else
    localparam SPI_LEN = 8; // reduce clocks needed to read registers, so can use lower depth in sby config file
    `endif

    wire [6:0] addr;

    wire [SPI_LEN-1:0] wdat;
    reg [SPI_LEN-1:0] rdat;

    spi_slave #(.dsz(SPI_LEN)) spi_slave(.reset(reset), .clk(clk_32m), .spimiso(spi_miso), .spiclk(spi_clk), .spimosi(spi_mosi), .spicsl(spi_ss), .we(spi_we), .re(spi_re), .wdat(wdat), .addr(addr), .rdat(rdat));

    reg [SPI_LEN-1:0] read_count = 0;
    reg [SPI_LEN-1:0] general_reg = 25000; // test register for testing SPI read/write

    wire spi_re_clk_en;
    wire spi_re_s;
    // first CDC synchronize the spi_re signal as coming from raspberry pi
    sync2 spi_re_sync(.reset(reset), .clk(clk_32m), .d(spi_re), .q(spi_re_s));
    // convert long spi read & write pulses to a single clock pulse of clk_32m
    // spi_re will last about 1.6 clk_32m cycles if SPI is 20MHz.
    pulse spi_read_clk_en (.clk(clk_32m), .in(spi_re_s), .out(spi_re_clk_en), .reset(reset));

    // connect up SPI writes
    always @(posedge clk_32m) begin
            if(reset)
                general_reg <= 0;
            else if(spi_we) begin
            case(addr)
                REG_GEN: 
                    general_reg <= wdat;
            endcase
        end
    end
    // connect up SPI reads
    always @(posedge clk_32m) begin
        if(reset)
            read_count <= 0;
        else if(spi_re_clk_en) begin
            read_count <= read_count + 1;
            case(addr) 
                REG_RD_CNT:
                    rdat <= read_count;
                REG_GEN:
                    rdat <= general_reg;
                default: 
                    rdat <= 0;
            endcase
        end
    end

    `ifdef FORMAL
        reg f_past_valid = 0;
        always @(posedge ext_clk)
            f_past_valid <= 1;

        // start in reset
        initial assume(reset);

        // produce a trace that shows read_count != 0
        always @(posedge ext_clk) begin
            cover(read_count == 1);
        end

        // prove that only way read_count can change if with spi_mosi changing
        reg f_mosi_signalled = 0;
        always @(posedge ext_clk) begin
            if(spi_mosi)
                f_mosi_signalled <= 1'b1;
            if(!f_mosi_signalled)
                assert(read_count == 0);
        end

        // prove at reset counts go to 0
        always @(posedge ext_clk) begin
            if(f_past_valid)
                if($past(reset)) begin
                    assert(read_count == 0);
                    assert(general_reg == 0);
                end
        end
    `endif

endmodule

// sync signal to different clock domain
// Adapted from Clifford E. Cumming's paper:
// http://www.sunburst-design.com/papers/CummingsSNUG2008Boston_CDC.pdf
module sync2 (
  output reg q,
  input  wire d,
  input wire  clk,
  input wire  reset);
  reg q1; // 1st stage ff output
  always @(posedge clk or posedge reset) begin
    if (reset) {q,q1} <= 0;
    else        {q,q1} <= {q1,d};
    end
endmodule
