module async_trap (async_sig, clk, reset, trapped_edge);

input async_sig, clk, reset;
output trapped_edge;

logic q_1, q_2;

// ff_1
always_ff @(posedge async_sig, posedge reset)
begin
	if (reset)
		q_1 <= 0;
	else
		q_1 <= 1;
end

// ff_2
always_ff @(posedge clk, posedge reset)
begin
	if (reset)
		q_2 <= 0;
	else
		q_2 <= q_1;
end
	
// ff_3
always_ff @(posedge clk, posedge reset)
begin
	if (reset)
		trapped_edge <= 0;
	else
		trapped_edge <= q_2;
end

endmodule