# religion distribution

rhv4 = load_object("clean_data/rhv4_" * dte * ".jld2");

rc = @chain rhv4 begin
    groupby(:religion)
    combine(nrow => :n)
end

rc.pct = rc.n .* inv(sum(rc.n));

rc