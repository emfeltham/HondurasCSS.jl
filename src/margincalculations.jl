# margincalculations.jl

"""
        addmargins!(margindict, vbldict, bimodel, dat)

## Description

`margindict::Dict{Symbol, @NamedTuple{rg::DataFrame, name::String}}`: Margin dictionary to store estimated referencegrids by variable.

Calculates for most variables, but will not work for distance.
"""
function addmargins!(
    margindict, vbldict, bimodel, dat;
    margresolution = 0.001, allvalues = false
)
    Threads.@threads for p in keys(vbldict)
        e, name = vbldict[p]
        ed = standarddict(dat; kinvals = [false, true])
        ed[e] = marginrange(dat, e; margresolution, allvalues)
        rg = referencegrid(dat, ed)
        estimaterates!(rg, bimodel; iters = 20_000)
        ci_rates!(rg)
        margindict[e] = (rg = rg, name = name,)
    end
end

export addmargins!

function altermargins_bs!(
    margindict, bm, βset, invlink, K; bivar = true
)

    bms = [deepcopy(bm) for _ in eachindex(1:length(margindict))]
    kys = (collect∘keys)(margindict)

    # for (i, p) in (enumerate∘eachindex)(kys)
    Threads.@threads for i in eachindex(1:length(margindict))
        p = kys[i]
        e, _ = margindict[p]
        ses, bv = j_calculations_pb!(e, bms[i], βset, invlink, K; bivar)
        e[!, :err_j_bs] = ses
        e[!, :bivar_bs] = eachrow(bv)
    end
end

export altermargins_bs!

"""
        margindistgrid(d_; margresolution = 0.01, allvalues = true)

## Description

Estimate margins for distance variables.

`d_::Tuple{Symbol, Symbol}` = (:dists_p, :dists_p_notinf)

"""
function margindistgrid(
    d_::Tuple{Symbol, Symbol}, dat; margresolution = 0.01, allvalues = true
)

    ed = standarddict(dat; kinvals = [false, true])
    ed[d_[1]] = marginrange(dat, d_[1]; margresolution, allvalues)
    ed[d_[1]] = ed[d_[1]][ed[d_[1]] .> 0]
    ed[d_[2]] = true
    rg1 = referencegrid(dat, ed)

    ed2 = standarddict(dat; kinvals = [false, true])
    ed2[d_[2]] = false
    ed2[d_[1]] = 0
    rg2 = referencegrid(dat, ed2)

    return vcat(rg1, rg2)    
end

export margindistgrid
