# figure4 (alt).jl

function figure4_alt!(los, vars, md; ellipsecolor = (yale.grays[end-2], 0.75), ellipsehulls = nothing)
	for (e, lx) in zip(vars, los)
		rg, margvarname = md[e]
		bpd = (
			rg = rg, margvar = e, margvarname = margvarname,
			tnr = true, jstat = true
		);
		hull = get(ellipsehulls,e,nothing)
		# biplot!(los[i], tp; ellipsecolor, ellipsehull = hull)


		l1 = lx[1, 1] = GridLayout()
		l2 = lx[1, 2] = GridLayout()

		colsize!(lx, 1, Fixed(350))
		colsize!(lx, 2, Fixed(350))
		# colsize!(l1, 1, Fixed(250))

		if e ∈ [:degree, :age, :wealth_d1_4]
			colsize!(l2, 1, Fixed(225))
		end
		
		rocplot!(
			l1,
			bpd.rg, bpd.margvar, bpd.margvarname;
			ellipsecolor,
			ellipsehull = hull,
			markeropacity = nothing,
			kinlegend = true,
			dolegend = true,
			axsz = 250,
		)

		effectsplot!(
			l2, bpd.rg, bpd.margvar, bpd.margvarname, true;
			dropkin = true,
			dolegend = true,
			axh = 250,
			axw = 275
		)
	end

	labelpanels!(los)
end

function make_figure4_alt!(fg, md, transforms, vars; ellipsecolor = (yale.grays[end-2], 0.75), ellipsehulls = nothing)

	# plot at the mean TPR prediction over the dist_p range
	let
		tprbar = mean(md[:dists_p].rg[md[:dists_p].rg.dists_p_notinf .== true, :tpr])
		md[:dists_a].rg.tpr .= tprbar
	end

	lo = GridLayout(fg[1:4, 1:2], width = 950*2)
	los = GridLayout[];
	cnt = 0
	for i in 1:4
		for j in 1:2
			cnt+=1
			if cnt <= length(vars)
				l = lo[i, j] = GridLayout()
				push!(los, l)
			end
		end
	end
	figure4_alt!(los, vars, md; ellipsecolor, ellipsehulls)
end

export make_figure4_alt!

function figure3!(los, vars, md; ellipsecolor = (yale.grays[end-2], 0.75), ellipsehulls = nothing)
	for (e, lx) in zip(vars, los)
		
		rg, margvarname = md[e]
		bpd = (
			rg = rg, margvar = e, margvarname = margvarname,
			tnr = true, jstat = true
		);
		hull = get(ellipsehulls, e, nothing)
		
		l1 = lx[1, 1] = GridLayout()
		l2 = lx[1, 2] = GridLayout()

		# colsize!(lx, 1, Fixed(400))
		# colsize!(lx, 2, Fixed(400))
		# colsize!(l1, 1, Fixed(250))

		if e ∈ [
			:degree, :age, :wealth_d1_4,
			:age_diff_a, :age_mean_a,
			:degree_diff_a, :degree_mean_a,
			:dists_p, :dists_a,
		]
			colsize!(l2, 1, Fixed(300))
		end
	
		if (e == :dists_a) | (e == :dists_p)
			distance_roc!(
				l1,
				bpd.rg, bpd.margvar, bpd.margvarname;
				markeropacity = 1,
				ellipsecolor,
				ellipsehull = hull,
				axsz = 250,
			)

			distance_eff!(
				l2, bpd.rg, bpd.margvar, bpd.margvarname;
				dropkin = true,
				coloredticks = true,
				axh = 250,
				axw = 275
			)
		else
			rocplot!(
				l1,
				bpd.rg, bpd.margvar, bpd.margvarname;
				ellipsecolor,
				ellipsehull = hull,
				markeropacity = nothing,
				kinlegend = true,
				dolegend = true,
				axsz = 250,
			)

			effectsplot!(
				l2, bpd.rg, bpd.margvar, bpd.margvarname, true;
				dropkin = true,
				dolegend = true,
				axh = 250,
				axw = 275
			)
		end
	end
end

export figure3!
