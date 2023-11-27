# processing.jl

"""
        populate_datacols!(r4, vs, rd, noupd, hh, unit)

## Description

Add data from `rd` dictionary of `Respondent` objects, imputing with earlier waves as allowed by `noupd` list of variables to not update.

`hh` only needed for variable types.
"""
function populate_datacols!(r4, vs2, rd, noupd, hh, unit, wv)
    
    _setup_populate!(r4, vs2, hh)

    for c in intersect(vs2, Symbol.(names(r4)))
        _populate_datacol!(r4, c, rd, noupd, unit, wv)
    end
end

function _setup_populate!(r4, vs2, resp)
    for v in vs2
        r4[!, v] = Vector{eltype(resp[!, v])}(undef, nrow(r4))
    end
    r4[!, :impute] = [Dict{Symbol, Int}() for _ in 1:nrow(r4)];
end

function _populate_datacol!(r4, c, rd, noupd, unit, wv)
    Threads.@threads for i in eachindex(r4[!, c])
        # if variable `c` is not in blacklist, impute
        r4[i, c] = if c ∉ noupd
            vl, w = firstval(
                rd[r4[i, unit]].properties[c];
                waves = keys(rd[r4[i, unit]].properties[c])
            )
            if (w < wv) & (w > 0)
                # track imputation
                r4[i, :impute][c] = w
            end
            vl
        else
            # impute
            rd[r4[i, unit]].properties[c][wv]
        end
    end
end

"""
        firstval(x; waves = [4,3,2,1])

## Description

Return most recent value, or missing if all are missing.
"""
function firstval(x; waves = [4,3,2,1])
    for i in waves
        if !ismissing(x[i])
            return x[i], i
        end
    end
    return missing, 0
end

function variableassign!(rd, rgnp, vs2, unit; wave = :wave)
    Threads.@threads for ri in eachrow(rgnp)
        for q in setdiff(vs2, [:wave, :village_code, :name, :building_id, :date_of_birth, :man])
            for (w, vl) in zip(ri[wave], ri[q])
                rd[ri[unit]].properties[q][w] = vl
            end
            
            for j in 2:4
                v1 = get(rd[ri[unit]].properties[q], j-1, missing)
                v2 = get(rd[ri[unit]].properties[q], j, missing)
                
                rd[ri[unit]].change[q][j-1] = if ismissing(v1) & ismissing(v2)
                        false
                elseif ismissing(v1) | ismissing(v2) # if only one missing -> change
                        true
                    elseif v1 != v2
                        true
                    elseif v1 == v2
                        false
                end
            end
        end
    end
end

function imputed_var!(r4, fv)
    imp = r4[!, :impute_r]
    v = Symbol(string(fv) * "_imputed_when")
    r4[!, v] = missings(Int, nrow(r4));
    for (i, e) in enumerate(imp)
        r4[i, v] = get(e, fv, missing)
    end
    @show v
    return v
end

export imputed_var!

