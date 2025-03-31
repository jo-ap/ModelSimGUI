module ModelSimGUI

using Catalyst 
using ColorSchemes
using DifferentialEquations 
using Makie
using LaTeXStrings
using Latexify

export simgui

# plot solution type with Makie as series
Makie.convert_arguments(T::Type{<:Series}, sol::ODESolution) = Makie.convert_arguments(T, sol.t, hcat(sol.u...))

# default settings 
ODE_ALG = AutoVern9(Rodas5())
FIG_SIZE = (1000, 600)
TSPAN = (0.0, 100.0)
SLIDER_RANGE = 0:0.1:10
SLIDER_FORMAT = x -> "$(round(x, digits = 2))"
N_TP = 501

function default_colors(n::Int)
  if n <= 7
    return Makie.wong_colors()
  elseif n <= 10
    return colorschemes[:seaborn_colorblind].colors
  end
  return get(colorschemes[:batlow], range(0.0, 1.0, length = n))
end

function simgui(
    model::Union{Function,<:ReactionSystem},
    u0::NamedTuple,
    p::NamedTuple;
    fig_size = FIG_SIZE,
    ode_alg = ODE_ALG,
    colors = default_colors(length(u0)), 
    tspan = TSPAN, 
    slider_range = SLIDER_RANGE,
    slider_format = SLIDER_FORMAT,
    n_tp = N_TP
  ) 

  # create figure and axis
  fig = Figure(size=fig_size);
  ax = Axis(fig[1,1]);

  # sliders for interactivity
  slider_names = latexify.([string.([keys(p)...]); string.([keys(u0)...]) .* "(0)"])
  sliders = [(
    label = name,
    range = slider_range,
    format = slider_format
  ) 
    for name in slider_names
  ]
  lsgrid = SliderGrid(fig[1,2], sliders..., tellheight=false)
  sliderobservables = [s.value for s in lsgrid.sliders]
  slider_values = lift(sliderobservables...) do slvalues...
    [slvalues...]
  end
  # set to inital values
  for i in 1:length(sliderobservables)
    set_close_to!(lsgrid.sliders[i], [values(p)..., values(u0)...][i])
  end

  # solve ode problem depending on slider
  _p = @lift $(slider_values)[1:length(p)]
  _u0 = @lift $(slider_values)[length(p)+1:end]
  prob = @lift ODEProblem(model, $_u0, tspan, $_p)
  sol = @lift solve($prob, ode_alg, saveat=LinRange(tspan..., n_tp))

  # plot solution
  series!(ax, sol, labels=latexify.(string.(keys(u0))), color=colors)

  # add legend
  axislegend(ax)

  # update y axis range on change
  on(sol) do sol
    ylims!(ax, 0, 1.1*maximum(sol))
  end

  # layout
  rowgap!(lsgrid.layout, 7)
  colsize!(fig.layout, 1, Relative(2/3))

  return fig
end

end # module ModelSimGUI
