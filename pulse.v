`default_nettype none
/* turns a long pulse into a 1 cycle pulse */

module pulse (
	input wire clk,
	input wire in,
    input wire reset,
    output reg out
    );

    initial begin
        out <= 0;
    end

    reg last = 0;
    always @(posedge clk) begin
        if(reset)begin
            last <= 0;
            out <= 0;
        end else begin
            last <= in;
            if(last == 0 && in == 1)
                out <= 1;
            else
                out <= 0;
        end     
    end

    `ifdef FORMAL_A
   
        // past valid signal
        reg f_past_valid = 0;
        reg f_past_valid_2 = 0;

        initial
            assume(!in);

        always @(posedge clk)
            f_past_valid <= 1'b1;

        always @(posedge clk)
            f_past_valid_2 <= f_past_valid;

        // output can't go high without an input
        always @(posedge clk)
            if(f_past_valid)
                if(!$past(in))
                    assert(!out);

        // cover a long pulse
        always @(posedge clk)
            if(f_past_valid)
                cover(in && $past(in));

        // prove out pulse == 1 clk
        always @(posedge clk)
            if(f_past_valid_2)
                if($past(out))
                    assert(!$past(out,2) && !out);

    
    `endif
endmodule
