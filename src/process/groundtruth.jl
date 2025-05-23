# groundtruth.jl

Tx = Tuple{Union{String, Vector{String}}, Union{String, Vector{String}}}

struct GroundTruth
    col::Symbol
    rel::Vector{NamedTuple{(:con, :css), Tx}}
    waves::Vector{Int}
    alter_source::Union{Nothing, String}
    cx::DataFrame
end

export GroundTruth

"""
        groundtruth(css, con; alter_source = "Census", nets = nets)

## Description

Add the ground truth network information to `css`.
"""
function groundtruth(css, con; alter_source = "Census", nets = nets)

    waveset = [[4],[3],[1], [4, 3, 1], [4, 3], [4, 1], [3, 1]]

    cs = select(css, [:village_code, :perceiver, :alter1, :alter2, :relation]);
    @assert css.perceiver == cs.perceiver

    unrls = nets.union
    anyrls = String.(sunique(con.relationship))

    _groundtruth(cs, con, waveset, unrls, anyrls; alter_source)

    return cs
end

export groundtruth

function _groundtruth(
    cs, con, waveset,
    # complex relationship
    unrls, anyrls; alter_source
)

    for w in waveset

        # connections
        s_ = mkgroundtruth(
            :socio,
            [(con = rl.ft, css = rl.ft), (con = rl.pp, css = rl.pp)],
            w,
            cs, con;
            alter_source
        );  # match relationship for ground truth

        u_ = mkgroundtruth(
            :union,
            [(con = unrls, css = rl.ft), (con = unrls, css = rl.pp)],
            w,
            cs, con;
            alter_source
        ); # union for ground truth

        a_ = mkgroundtruth(
            :any,
            [(con = anyrls, css = rl.ft), (con = anyrls, css = rl.pp)],
            w,
            cs, con;
            alter_source
        ); # any for ground truth

        k_ = mkgroundtruth(
            :kin,
            [(con = "are_related", css = rl.ft), (con = "are_related", css = rl.pp)],
            w,
            cs, con;
            alter_source
        ); # (any) kin (type) for ground truth

        o_ = mkgroundtruth(
            :other,
            [(con = rl.pp, css = rl.ft), (con = rl.pp, css = rl.pp)],
            w,
            cs, con;
            alter_source
        ); # other relation (flipped from `s_`) for ground truth

        # apply groundtruth
        groundtruth!(cs, s_)
        groundtruth!(cs, u_)
        groundtruth!(cs, a_)
        groundtruth!(cs, k_)
        groundtruth!(cs, o_)
    end
end

"""
        mkgroundtruth(
            col::Symbol,
            relset,
            waves::Vector{Int},
            cs::T,
            cx::T;
            alter_source = "Census"
        ) where T<:AbstractDataFrame

## Description

`cs`: css data
`cx`: connections data
"""
function mkgroundtruth(
    col::Symbol,
    relset,
    waves::Vector{Int},
    cs::T,
    cx::T;
    alter_source = "Census"
) where T<:AbstractDataFrame

    rname = Symbol(string(col) * string(waves...))
    
    # add column, cs
    cs[!, rname] = missings(String, nrow(cs));
    
    # handle, cx
    cx_ = if !isnothing(alter_source)
        xr = [alter_source, ""] # for combinations with "" value
        @subset cx :wave .∈ Ref(waves) :alter_source .∈ Ref(xr);
    else
        @subset cx :wave .∈ Ref(waves)
    end
    
    select!(cx_, [:wave, :village_code, :ego, :alter, :relationship]);
    cx_.tie = [(a,b) for (a,b) in zip(cx_.alter, cx_.ego)];
    addcombination!(cx_, relset, string(col))
    
    # return object with relevant data
    return GroundTruth(
        col,
        relset,
        waves,
        alter_source,
        cx_
    );
end

export mkgroundtruth

function addcombination!(cx, relset, rname)
    xs = sunique([x.con for x in relset])
    if eltype(xs) <: AbstractVector
        for x in xs
            nw = @subset cx :relationship .∈ Ref(x)
            nw.relationship .= rname
            append!(cx, nw)
        end
    end
end

export addcombination!

function groundtruth!(cs, gts::GroundTruth)

    cx = gts.cx;

    # output target
    nom = gts.col
    crs = [x.con for x in gts.rel]
    nomvar = Symbol(string(gts.col) * string(gts.waves...))

    if string(nomvar) ∉ names(cs)
        error("target variable does not exist in cs")
    end

    # if con relationship is given as is a vector
    # the target relationship in cx is gts.col
    con_relations = if eltype(unique(crs)) <: AbstractVector
        fill(string(nom), length(crs))
    else
        crs
    end

    # basically, will be rl.ft and rl.pp
    cs_relations = [x.css for x in gts.rel]

    villages = sunique(cs[!, ids.vc])

    # setup reference objects
    gcs = groupby(cs, [ids.vc, :relation]); # basis
    gcx = groupby(cx, [ids.vc]); # all relations in village
    grcx = groupby(cx, [ids.vc, :relationship]); # filter to relation

    # check connections data for nodes and tie that appears in css
    Threads.@threads for i in villages
        
        # same for css and con, modify to pairs for more complex
        for (conrel, cssrel) in zip(con_relations, cs_relations)
            # node-universe for village
            gci = gcx[(village_code = i,)];
            # reference-network for village
            # could be: same as css relationship, a different relationship, or
            # a (wider-scope) combination of relationships
            gcir = grcx[(village_code = i, relationship = conrel)];

            # node reference for whole village
            uall = (sunique∘vcat)(gci[!, :ego], gci[!, :alter]);
            # (reference) ties in (defined) village network
            erel = gcir.tie;
            
            g = gcs[(village_code = i, relation = cssrel)]; # css region
            pix, _ = parentindices(g);

            # for each row in group, find the tie in 
            for (l, a1, a2) in zip(pix, g[!, :alter1], g[!, :alter2])
                if (a1 ∈ uall) & (a2 ∈ uall)

                    # ego-alter in con (ego nominates)
                    a1nom = (a1, a2) ∈ erel; # a1 nominates
                    a2nom = (a2, a1) ∈ erel; # a2 nominates

                    # not really needed
                    # just use `ifelse()` to make, as needed for analysis
                    # cs[l, socio] = a1nom | a2nom # either nominates
                    
                    cs[l, nomvar] = if a1nom & a2nom
                        "Yes"
                    elseif a1nom & !a2nom
                        "Alter 1"
                    elseif !a1nom & a2nom
                        "Alter 2"
                    else
                        "No"
                    end
                end
            end
        end
    end
end

export groundtruth!

function binarize_gt(vbl; a1 = "Alter 1", a2 = "Alter 2", a = "Alter")
    c1 = vbl .== "Yes"
    c2 = (vbl .== a1) .| (vbl .== a2) | (gt[!, x] .== a)
    return passmissing(ifelse).(c1 .| c2, true, false)
end

function binarize_gt(gt, x; a1 = "Alter 1", a2 = "Alter 2", a = "Alter")
    c1 = gt[!, x] .== "Yes"
    c2 = (gt[!, x] .== a1) .| (gt[!, x] .== a2) .| (gt[!, x] .== a)
    return passmissing(ifelse).(c1 .| c2, true, false)
end

function binarize_gt!(gt, x; a1 = "Alter 1", a2 = "Alter 2", a = "Alter")
    c1 = gt[!, x] .== "Yes"
    c2 = (gt[!, x] .== a1) .| (gt[!, x] .== a2) | (gt[!, x] .== a)
    gt[!, x] = passmissing(ifelse).(c1 .| c2, true, false)
end

function binarize_gt!(
    gt, p::Pair{Symbol, Symbol}; a1 = "Alter 1", a2 = "Alter 2", a = "Alter"
)
    x, x2 = p
    c1 = gt[!, x] .== "Yes"
    c2 = (gt[!, x] .== a1) .| (gt[!, x] .== a2) | (gt[!, x] .== a)
    gt[!, x2] = passmissing(ifelse).(c1 .| c2, true, false)
end

export binarize_gt, binarize_gt!

"""
        groundtruthprocess!(gt)

## Description

Binarize according to union rule (count Alter-value or "Yes").
"""
function groundtruthprocess!(gt)
    vs = Symbol.(names(gt)[6:end]);

    # lose which alter information
    for v in vs
        replace!(gt[!,v], [x => "Alter" for x in ["Alter 1", "Alter 2"]]...)
    end

    # make categorical
    for v in vs
        gt[!,v] = categorical(gt[!,v], ordered = true)
        levels!(gt[!,v], ["No", "Alter", "Yes"])
    end

    gt.relation = categorical(gt.relation);

    # Convert to binary. Leave the three-valued variables as tagged "_full".
    for x in vs
        y = Symbol(string(x) * "_full")
        gt[!, y] = gt[!, x]
        # union rule: count Alter-value or "Yes"
        gt[!, x] = binarize_gt(gt, x);
    end
end

export groundtruthprocess!

"""
        vsmerge!(
            df, gt; vs = [:socio4, :socio431, :kin4, :kin431, :union4, :union431, :any4, :any431]
        )

## Description

Merge selected variables, `vs`, into df, checking order on `xs`. Rely on the fact that the order is the same.

- `vs`: variables to copy to `df`
"""
function vsmerge!(
    df, gt;
    vs = [:socio4, :socio431, :kin4, :kin431, :union4, :union431, :any4, :any431],
    xs = [:perceiver, :alter1, :alter2, :relation]
)
    # important check prior to hcat (check that order is the same)
    for x in xs
        @assert df[!, x] == gt[!, x]
    end

    for x in vs
        df[!, x] = gt[!, x]
    end
end

export vsmerge!
