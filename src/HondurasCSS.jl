module HondurasCSS

# version notes
# We need this older version of MixedModels to ensure consistent compatibility with models
# that we've run.
# Pkg.add(name="MixedModels", version="4.14.0")  # Pre-xtol_zero_abs version

import Base.getindex
import Pkg
using Reexport

# add "." when running these here, "." for external usage
# (total of two dots)
# Pkg.develop(path = "./HondurasTools.jl"); # general functions, definitions
# Pkg.develop(path = "./NiceDisplay.jl"); # tables, figures

# https://github.com/human-nature-lab/HondurasTools.jl
# https://github.com/emfeltham/NiceDisplay.jl

@reexport using HondurasTools
@reexport using NiceDisplay

@reexport using NiceDisplay.Graphs
@reexport using NiceDisplay.GraphMakie

import HondurasTools.sortedges!

# other dependencies
using GeometryBasics
using Random

import MultivariateStats # stressfocus.jl
import NiceDisplay.LinearAlgebra:norm

using KernelDensity

#=
Only include packages that are not already exported by HondurasTools
and NiceDisplay
=#

# CairoMakie, AlgebraOfGraphics # exported from NiceDisplay
# DataFrames, DataFramesMeta # exported from NiceDisplay

# modeling
@reexport using GLM
import GLM.Normal
@reexport using MixedModels
@reexport using Effects

using StatsFuns: logistic, logit
export logistic, logit

using ColorVectorSpace

##

files_g = [
    "EModel.jl", "errors.jl",
    "effects_utilities.jl", "analysis_utilities.jl",
    "variables.jl"
];

for x in files_g; include(x) end

files_fg = "figures/" .* [
    "plotting.jl",
    "figure_utilities.jl", "stressfocus.jl",
    "unitbarplot.jl",
    "backgroundplot.jl",
    "rocplot.jl",
    "effectsplot.jl",
    "biplot.jl", "interface_plot.jl",
    "roc-style.jl", "roc-pred.jl",
    "tiedist.jl", "pairdist.jl",
    "clustdiff.jl",
    "individualpredictions!.jl",
    "bivariate_perceiver.jl",
    "coefplot.jl",
    "distanceplot.jl",
    "stage2_figure.jl",
    "riddle_plot!.jl",
    "homophily_plot.jl",
    # paper figures
    "figure1.jl",
    "figure_bivar.jl",
    "figure4_alt.jl",
    "figure4.jl",
    "interaction.jl",
    "contrasttable.jl",
    "roc_space.jl"
];

for x in files_fg; include(x) end

files_an = "analysis/" .* [
    "accuracies.jl", "accuracy_functions.jl", "bootmargins.jl",
    "riddles_functions.jl",
    "riddles_functions_pbs.jl",
    "parametricbootstrap2.jl",
    "tpr_fpr_functions_pbs.jl",
    "stage2.jl",
    "homophily.jl",
    "effects!.jl",
    "newstrap.jl"
];

for x in files_an; include(x) end

files_p = "process/" .* [
    "clean_css.jl", "css_process_raw.jl",
    "cssdistances_without_ndf.jl", "cssdistances.jl",
    "groundtruth.jl"
];

for x in files_p; include(x) end

include("tie_properties.jl")
include("referencegrid.jl")
include("j_calculations.jl")
include("margincalculations.jl")
include("bootellipse.jl")
include("ratetradeoff.jl")
include("adjustedcoeftable.jl")

include("figures/roc_distance.jl")

# include("figures/contrasttable.jl")
include("tpr_fpr.jl")

include("process/utilities.jl")

end # module HondurasCSS
