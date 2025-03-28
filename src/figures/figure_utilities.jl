# figure_utilities.jl

"""
        ratecolor(x)

## Description

"""
function ratecolor(x)
    return if (x == :tpr) | (string(x) == "TPR")
        yale.blues[3]
    elseif (x == :fpr) | (x == :tnr) | (string(x) == "FPR")
        # yale.accent[2]
        columbia.secondary[1]
    elseif (x == :peirce) | (x == :j) | (string(x) == "J")
        yale.blues[3]-columbia.secondary[1]
        # yale.accent[1]
    else
        oi[7]
    end
end

export ratecolor

"""
        chanceline!(ax)

## Description

Add line of chance to ROC-space plot, the line L"y = x".
"""
function chanceline!(ax; linestyle = :dot, color = yale.grays[1], tr = 0.9)
    lines!(ax, (0.0:0.1:1.0), 0:0.1:1.0; linestyle, color = (color, tr))
end

"""
        improvementline!(ax)

## Description

Add direction of improvement to ROC-space plot. The line represents the
direction along which acuracy improves without changing the ratio TPR:FPR.

This is the line L"y = 1 - x".
"""
function improvementline!(ax; tr = 0.9, linestyle = :dash)
    # line of improvement
    lines!(ax, (0.5:-0.1:0), 0.5:0.1:1; linestyle, color = (yale.accent[1], tr))
    lines!(ax, (1:-0.1:0.5), 0:0.1:0.5; linestyle, color = (yale.accent[2], tr))
end

@inline valproc(x) = string(round(x; digits = 1))

"""
        sloperad(pts)

## Description

Calculate the slope in radians given two points.

"""
function sloperad(pts)
    x1, y1 = pts[1]; x2, y2 = pts[2]
    return (y2 - y1) / (x2 - x1) |> atan
end

function save2(name, fg)
    save(name, fg; pt_per_unit = 2)
end

export save2
