### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ 3c6bf5ec-909f-11ee-06bd-83347655e198
begin
    import Pkg
    Pkg.develop(path = "..")
    using QuantumLegos
end

# ╔═╡ 9088d661-7bf1-43fb-ab88-77fa325a5cf3
stabilizers = pauliop.(["IIXXXX", "IIZZZZ", "ZIZZII", "IZZIZI", "IXXXII", "XIXIXI"])

# ╔═╡ f806287c-592d-476b-a912-205d2031fd93
lego = Lego(stabilizers)

# ╔═╡ 93251f25-5829-45a7-8aed-f76c834050a9
state = State([lego, lego], Tuple{LegoLeg, LegoLeg}[])

# ╔═╡ 924588fb-0020-47e6-a918-98084d1fabad
state.cmat

# ╔═╡ 99f153a1-da44-499a-b8af-e5c484b70597
QuantumLegos.self_trace!(state.cmat, 3, 9)

# ╔═╡ 726061b5-0d3a-4bf4-aebd-81a2c0fe7ea1
state.cmat |> generators

# ╔═╡ 69a71bfd-81d3-4961-9051-5f19be20f286
pg = state.cmat |> generators |> GeneratedPauliGroup |> collect

# ╔═╡ 656d8d7a-0ede-4621-99f0-9f83619c6a73
pauliop("XIIXIXIIXI") in pg # example on Fig.6

# ╔═╡ Cell order:
# ╠═3c6bf5ec-909f-11ee-06bd-83347655e198
# ╠═9088d661-7bf1-43fb-ab88-77fa325a5cf3
# ╠═f806287c-592d-476b-a912-205d2031fd93
# ╠═93251f25-5829-45a7-8aed-f76c834050a9
# ╠═924588fb-0020-47e6-a918-98084d1fabad
# ╠═99f153a1-da44-499a-b8af-e5c484b70597
# ╠═726061b5-0d3a-4bf4-aebd-81a2c0fe7ea1
# ╠═69a71bfd-81d3-4961-9051-5f19be20f286
# ╠═656d8d7a-0ede-4621-99f0-9f83619c6a73
