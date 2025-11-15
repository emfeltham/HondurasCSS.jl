# bivariate_perceiver.jl

"""
        perceivercontour!(
            lo, sbar; kin = :kin431, nlevels = 10, colormap = :berlin
        )

## Description

`sbar`: unadjusted subject-level means. should also contain marginal means
estimates from some selected `EModel`.
"""
function perceivercontour!(
    lo, sbar;
    kin = kin,
    nlevels = 10,
    colormap = :berlin,
    axsz = 325
)

    # one color range for all four plots (extrema over all densities)
    lv = range(
        extrema(reduce(vcat, [x.density for x in sbar.dens]))...;
        length = nlevels
    );
        
    axs = []

    # positions for each type
    # kin on top row, non-kin on bottom
    pdict = Dict(
        ("free_time", true) => (1, 1),
        ("free_time", false) => (2, 1),
        ("personal_private", true) => (1, 2),
        ("personal_private", false) => (2, 2),
    ) |> sort

    psx = Any[];
    for i in 1:nrow(sbar)
        ps = pdict[(sbar.relation[i], sbar[i, kin])]
        title = replace(unwrap(sbar.relation[i]), "_" => " ")
        title = uppercase(title[1]) * title[2:end]
        ax = Axis(
            lo[ps...];
            ylabel = "True positive rate",
            xlabel = "False positive rate",
            xgridvisible = false, ygridvisible = false,
            # title,
            # titlefontsize = 26,
            yticks = [0, 0.25, 0.5, 0.75, 1],
            xticks = [0, 0.25, 0.5, 0.75, 1],
            width = axsz,
            height = axsz
        )

        push!(axs, ax)
        push!(psx, ps)
    end

    axs[3].ylabel = ""
    axs[4].ylabel = ""
    axs[2].xlabel = ""
    axs[4].xlabel = ""

    labelfontsize = 18

    Label(
        lo[1, 2, Right()], "Kin",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        justification = :right,
        halign = :left,
        padding = (10, 0, 0, 0)
    )

    Label(
        lo[2, 2, Right()], "Non-kin",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        justification = :left,
        halign = :left,
        padding = (10, 0, 0, 0)
    )
    
    Label(
        lo[1, 1, Top()], "Free time",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        padding = (0, 0, 10, 0)
    )

    Label(
        lo[1, 2, Top()], "Personal private",
        rotation = 0,
        font = :bold,
        fontsize = labelfontsize,
        padding = (0, 0, 10, 0)
    )
  
    cos = [];

    # same order as axes above...
    for (r, ax) in zip(eachrow(sbar), axs)        
        lines!(ax, 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey);
        
        vlines!(ax, [0, 1], color = (:black, 0.3));
        hlines!(ax, [0, 1], color = (:black, 0.3));

        chanceline!(ax);
        improvementline!(ax);

        # distribution
        co = contour!(
            ax, r.dens.x, r.dens.y, r.dens.density;
            levels = lv, colormap
        )
        push!(cos, co)

        # marginal means
        # marker = ifelse(!r[kin], :rect, :cross);
        scatter!(ax, (r[:fpr_adj], r[:tpr_adj]); color = oi[4])
        scatter!(ax, r[:fpr_tpr_bar]; color = :black)
        
        ylims!(ax, -0.02, 1.02)
        xlims!(ax, -0.02, 1.02)
    end

    ylims!(axs[1], -0.02, 1.02)
    xlims!(axs[1], -0.02, 1.02)

    linkaxes!(axs...)

    lol = lo[3, 1:2] = GridLayout();
    rowsize!(lo, 3, Relative(0.2/5))

    Colorbar(
        lol[1, 1];
        limits = extrema(lv), colormap,
        flipaxis = false, vertical = false,
        label = "Density"
    )

    group_color = [
        MarkerElement(;
            color, strokecolor = :transparent, marker = :circle
        ) for color in [:black, oi[4]]
    ]

    color_leg = ["No", "Yes"];
    leg_titles = ["Adjusted"];

    Legend(
        lol[1, 2],
        [group_color],
        [color_leg],
        leg_titles,
        tellheight = false, tellwidth = false,
        orientation = :horizontal,
        # titleposition = :left,
        nbanks = 1, framevisible = false
    )

    colsize!(lol, 1, Relative(4/5))
    # set equal axes
    # colsize!(lo, 1, Aspect(1, 1.0))
    # colsize!(lo, 2, Aspect(1, 1.0))
end

export perceivercontour!

"""

## Description

- `plo`: parent layout
"""
function bivariate_perceiver!(
    plo, sbar; kin = :kin431, nlevels = 12, colormap = :berlin
)

    lxx = plo[1, 1:2] = GridLayout();
    lo = lxx[1, 1] = GridLayout();

    los, cos, lo1, lop, lop2, ll = perceivercontour!(
        lo, sbar; kin, nlevels, colormap
    )

    labelpanels!([los[[1, 2]]..., l2])
end

export bivariate_perceiver

function perceivercontour_nonkin!(
    lo, sbar;
    nlevels = 10,
    colormap = :berlin,
    axsz = 325
)

    labelfontsize = 18

    # one color range for all four plots (extrema over all densities)
    lv = range(
        extrema(reduce(vcat, [x.density for x in sbar.dens]))...;
        length = nlevels
    );
        
    axs = []
    psx = Any[];

    ft = findfirst(sbar.relation .== "free_time")
    pp = findfirst(sbar.relation .== "personal_private")
    c = (yale.grays[end-2], 0.6) # point lines

    for (i, r) in zip(1:2, [ft, pp])
        
        title = replace(unwrap(sbar.relation[i]), "_" => " ")
        title = uppercase(title[1]) * title[2:end]
        
        ax = Axis(
            lo[1, i];
            ylabel = "True positive rate",
            xlabel = "False positive rate",
            title,
            titlesize = 22,
            yticks = [0, 0.25, 0.5, 0.75, 1],
            xticks = [0, 0.25, 0.5, 0.75, 1],
            width = axsz,
            height = axsz
        )

        p1 = Point2f(sbar[r, :fpr_tpr_bar]);
        p2 = Point2f(sbar[r, :fpr_adj], sbar[r, :tpr_adj]);
        vlines!(ax, p1[1]; color = c, ymax = p1[2], linestyle = :solid)
        vlines!(ax, p2[1]; color = c, ymax = p2[2], linestyle = :solid)

        hlines!(ax, p1[2]; color = c, xmax = p1[1])
        hlines!(ax, p2[2]; color = c, xmax = p2[1])

        push!(axs, ax)
    end

    # axs[1].xlabel = ""
    # axs[2].xlabel = ""
  
    cos = [];

    # same order as axes above...
    for (r, ax) in zip(eachrow(sbar), axs)        
        lines!(ax, 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey);
        
        vlines!(ax, [0, 1], color = (:black, 0.3));
        hlines!(ax, [0, 1], color = (:black, 0.3));

        chanceline!(ax);
        improvementline!(ax);

        # distribution
        co = contour!(
            ax, r.dens.x, r.dens.y, r.dens.density;
            levels = lv, colormap
        )
        push!(cos, co)

        # marginal means
        scatter!(ax, (r[:fpr_adj], r[:tpr_adj]); color = oi[4])
        scatter!(ax, r[:fpr_tpr_bar]; color = :black)
        
        ylims!(ax, -0.02, 1.02)
        xlims!(ax, -0.02, 1.02)
    end

    ylims!(axs[1], -0.02, 1.02)
    xlims!(axs[1], -0.02, 1.02)

    linkaxes!(axs...)

    lol = lo[2, 1:2] = GridLayout(valign = :top);

    Colorbar(
        lol[1, 1];
        limits = extrema(lv), colormap,
        flipaxis = false, vertical = false,
        label = "Density",
    )

    group_color = [
        MarkerElement(;
            color, strokecolor = :transparent, marker = :circle
        ) for color in [:black, oi[4]]
    ]

    color_leg = ["No", "Yes"];
    leg_titles = ["Adjusted"];

    Legend(
        lol[1, 2],
        [group_color],
        [color_leg],
        leg_titles,
        tellheight = false, tellwidth = false,
        orientation = :horizontal,
        nbanks = 1, framevisible = false
    )

    colsize!(lol, 1, Relative(4/5))
    return axs
end

export perceivercontour_nonkin!

function perceivercontour_kin!(
    lo, sbar;
    nlevels = 10,
    colormap = :berlin,
    axsz = 325
)

    labelfontsize = 18

    # one color range for all four plots (extrema over all densities)
    lv = range(
        extrema(reduce(vcat, [x.density for x in sbar.dens]))...;
        length = nlevels
    );
        
    axs = []
    psx = Any[];

    ft = findfirst(sbar.relation .== "free_time")
    pp = findfirst(sbar.relation .== "personal_private")
    c = (yale.grays[end-2], 0.6) # point lines

    for (i, r) in zip(1:2, [ft, pp])
        
        title = replace(unwrap(sbar.relation[i]), "_" => " ")
        title = uppercase(title[1]) * title[2:end]
        
        ax = Axis(
            lo[1, i];
            ylabel = "True positive rate",
            xlabel = "False positive rate",
            title,
            titlesize = 22,
            yticks = [0, 0.25, 0.5, 0.75, 1],
            xticks = [0, 0.25, 0.5, 0.75, 1],
            width = axsz,
            height = axsz
        )

        p1 = Point2f(sbar[r, :fpr_tpr_bar]);
        p2 = Point2f(sbar[r, :fpr_adj], sbar[r, :tpr_adj]);
        vlines!(ax, p1[1]; color = c, ymax = p1[2], linestyle = :solid)
        vlines!(ax, p2[1]; color = c, ymax = p2[2], linestyle = :solid)

        hlines!(ax, p1[2]; color = c, xmax = p1[1])
        hlines!(ax, p2[2]; color = c, xmax = p2[1])

        push!(axs, ax)
    end

    # axs[1].xlabel = ""
    # axs[2].xlabel = ""
  
    cos = [];

    # same order as axes above...
    for (r, ax) in zip(eachrow(sbar), axs)        
        lines!(ax, 0:0.1:1, 0:0.1:1; linestyle = :dot, color = :grey);
        
        vlines!(ax, [0, 1], color = (:black, 0.3));
        hlines!(ax, [0, 1], color = (:black, 0.3));

        chanceline!(ax);
        improvementline!(ax);

        # distribution
        co = contour!(
            ax, r.dens.x, r.dens.y, r.dens.density;
            levels = lv, colormap
        )
        push!(cos, co)

        shp = :rect
        # marginal means

        pk = Point2f(r[:fpr_adj], r[:tpr_adj])
        pnk = Point2f(r[:fpr_adj_], r[:tpr_adj_])

        direction = (pk- pnk)*0.95
        arrows!(ax, [pnk], [direction], color = (:black, 0.6))

        scatter!(ax, pk; color = oi[4], marker = shp)
        scatter!(ax, r[:fpr_tpr_bar]; color = :black, marker = shp)

        scatter!(ax, pnk; color = oi[4])
        scatter!(ax, r[:fpr_tpr_bar_]; color = :black)
        
        ylims!(ax, -0.02, 1.02)
        xlims!(ax, -0.02, 1.02)
    end

    ylims!(axs[1], -0.02, 1.02)
    xlims!(axs[1], -0.02, 1.02)

    linkaxes!(axs...)

    lol = lo[2, 1:2] = GridLayout(valign = :top);

    Colorbar(
        lol[1, 1];
        limits = extrema(lv), colormap,
        flipaxis = false, vertical = false,
        label = "Density",
    )

    group_color = [
        MarkerElement(;
            color, strokecolor = :transparent, marker = :circle
        ) for color in [:black, oi[4]]
    ]

    color_leg = ["No", "Yes"];
    leg_titles = ["Adjusted"];

    Legend(
        lol[1, 2],
        [group_color],
        [color_leg],
        leg_titles,
        tellheight = false, tellwidth = false,
        orientation = :horizontal,
        nbanks = 1, framevisible = false
    )

    colsize!(lol, 1, Relative(4/5))
    return axs
end

export perceivercontour_kin!
