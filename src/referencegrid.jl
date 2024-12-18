# referencegrid.jl

"""
        referencegrid(df::AbstractDataFrame, effectsdict)

## Description

Construct a reference grid DataFrame from all possible combinations of the
input effects dictionary `effectsdict` values.
"""
function referencegrid(df::AbstractDataFrame, effectsdict)
    
    kys = collect(keys(effectsdict));
    cp = vec(collect(Iterators.product(values(effectsdict)...)));
    df = similar(df, length(cp));
    df = select(df, kys)

    for (i, c) in (enumerate∘eachcol)(df)
        c .= [e[i] for e in cp]
    end

    return df
end

export referencegrid

function marginrange(dat, marginvar; margresolution = 0.01, allvalues = false)

	vbltype = (nonmissingtype∘eltype)(dat[!, marginvar])
	
	vls = (sunique∘skipmissing)(dat[!, marginvar]);
	return if ((vbltype <: AbstractFloat) | (vbltype <: Int)) & !allvalues
		mn, mx = extrema(vls)
		collect(mn:margresolution:mx)
	else
		sunique(vls)
	end
end

export marginrange

function margingrid(
	dat, margvar;
	additions = nothing,
	margresolution = 0.01,
	stratifykin = true,
	kin = kin
)
	vbltype = eltype(dat[!, margvar])
	cts = (vbltype <: AbstractFloat) | (vbltype <: Int)

	vls = (sunique∘skipmissing∘vcat)(dats[:tpr][!, margvar], dats[:fpr][!, margvar]);

	if isnothing(additions)
		additions = if cts
			mn, mx = extrema(vls)
			[margvar => collect(mn:margresolution:mx)]
		elseif !cts
			[margvar => sunique(vls)]
		end
	end

	ed = usualeffects(dats, additions; stratifykin)
	rg = referencegrid(dats, ed)
	return rg
end

function standarddict(dat; kinvals = false)
    age = :age;
    ed = Dict{Symbol, Any}();
    if !isnothing(kinvals)
        ed[kin] = kinvals
    end
    ed[age] = mean(dat[!, age])
    push!(ed, distmeans(dat)...)
    
    return ed
end

export standarddict

function estimaterates!(
    rg, bimodel::EModel;
    typical = mean,
    invlink = logistic,
    iters = 10_000
)
    for r in[:tpr, :fpr]
        effects!(
            rg, bimodel[r];
            eff_col = r, err_col = Symbol("err_" * string(r)),
            typical, invlink
        )
    end
    
    if !isnothing(iters)
        j_calculations!(rg, iters)
    end
end

function estimaterates!(
    rg, model::RegressionModel;
    r = :tpr,
    typical = mean,
    invlink = logistic,
    iters = 0,
)
    
    effects!(
        rg, model;
        eff_col = r, err_col = Symbol("err_" * string(r)),
        typical, invlink
    )
    
end

export estimaterates!

function ci_rates!(rg)
    for r in [:tpr, :fpr, :j]
        if string(r) ∈ names(rg)
            nm = ("ci_" * string(r)) |> Symbol
            er = ("err_" * string(r)) |> Symbol
            rg[!, nm] = ci.(rg[!, r], rg[!, er]; area = 1.96)
        end
    end
end

export ci_rates!


"""
        referencegridunit(
            dat, variables, efdict; sortvars = [:village_code, :perceiver]
        )


## Description

Create a reference grid from the unique values of specified units with specified variable values (`variables`). Units will be repeated if repeated measurement variables are included (e.g., `relation`).

"""
function referencegridunit(
    dat, variables, effectsdict; sortvars = [:village_code, :perceiver]
)

    # data sufficient to define unique cognizers
    df = unique(dat[!, variables])

    # check that rows in effects DataFrame equals number of perceivers
    # set the design for the marginal means

    # add variables fixed across all observations (units)
    for (k, v) in effectsdict
        if length(v) == 1
            df[!, k] = fill(v, nrow(df))
        else
            @assert v == unique(df[!, k])
        end
    end

    sort!(df, sortvars)

    return df
end

export referencegridunit
