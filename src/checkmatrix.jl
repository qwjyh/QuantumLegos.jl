"""
CheckMatrix

# Fields
- `cmat`: matrix itself (matrix of `Bool` since we consider only pauli ops.)
- `nlegs`: number of columns ÷ 2
- `ngens`: number of rows

# Constructor
    CheckMatrix(cmat::AbstractMatrix{Bool})
See also [`checkmatrix`](@ref).
"""
mutable struct CheckMatrix
    # change this to AbstractMatrix{Bool} to accept BitMatrix?
    cmat::Matrix{Bool}
    nlegs::Int64
    ngens::Int64
    function CheckMatrix(cmat::Matrix{Bool}, nlegs::Integer, ngens::Integer)
        size(cmat)[1] == ngens ||
            throw(ArgumentError("`ngens` must equal to number of row of `cmat`"))
        size(cmat)[2] == nlegs * 2 ||
            throw(ArgumentError("`nlegs * 2` must equal to number of row of `cmat`"))
        new(cmat, nlegs, ngens)
    end
end

function CheckMatrix(cmat::AbstractMatrix{Bool})
    s = size(cmat)
    s[2] % 2 == 0 || throw(ArgumentError("invalid `cmat` size"))
    CheckMatrix(cmat, s[2] ÷ 2, s[1])
end

Base.:(==)(x::T, y::T) where {T <: CheckMatrix} = (==)(x.cmat, y.cmat)
Base.copy(x::CheckMatrix) = CheckMatrix(copy(x.cmat))

function Base.show(io::IO, ::MIME"text/plain", cmat::CheckMatrix)
    print(io, "CheckMatrix with $(cmat.ngens) generators, $(cmat.nlegs) legs:\n")
    display_height, display_width = displaysize(io)
    cur_vpos = 1
    for row in eachrow(cmat.cmat)
        cur_hpos = 1
        for (i, elem) in enumerate(row)
            sep = i == cmat.nlegs + 1 ? " | " : "  "
            elem_width = length(sep) + 1
            print(io, sep)
            if elem
                printstyled(io, 1, color = :default)
                cur_hpos += elem_width
            else
                printstyled(io, 0, color = :light_black)
                cur_hpos += elem_width
            end
            if cur_hpos > display_width - 5
                print(io, "  …")
                break
            end
        end
        print(io, "\n")
        cur_vpos += 1
        if cur_vpos > display_height - 6
            cur_hpos = 1
            for i in 1:(cmat.nlegs * 2)
                sep = i == cmat.nlegs + 1 ? " | " : "  "
                elem_width = length(sep) + 1
                print(io, sep)
                print(io, "⋮")
                cur_hpos += elem_width
                if cur_hpos > display_width - 5
                    print(io, "  ⋱\n")
                    break
                end
            end
            return nothing
        end
    end
end

"""
    checkmatrix(stbgens::AbstractVector{T})::CheckMatrix where {T <: PauliOp}

Get [`CheckMatrix`](@ref) from stabilizer generator.
"""
function checkmatrix(stbgens::AbstractVector{T})::CheckMatrix where {T <: PauliOp}
    # no stbgens
    if length(stbgens) == 0
        throw(ArgumentError("No stabilizer is provided. Need at least one."))
    end
    # check whether all stbgens have the same length
    stbgens_length = length.(stbgens)
    all(==(stbgens_length[1]), stbgens_length[2:end]) || begin
        @error "lengths of stbgens: " length.(stbgens)
        throw(ArgumentError("All stabilizer must have the same length"))
    end

    ngens = length(stbgens)
    nlegs = length(stbgens[1])
    cmat = zeros(Bool, (ngens, nlegs * 2))
    for (i, gen) in enumerate(stbgens)
        # get X Z component (can be more optimized)
        xs = gen .== PauliOps.X
        zs = gen .== PauliOps.Z
        ys = gen .== PauliOps.Y
        xs = xs .| ys
        zs = zs .| ys
        cmat[i, :] .= vcat(xs, zs)
    end
    return CheckMatrix(cmat)
end

"""
    xpart(cmat::CheckMatrix)

Get X part (left half) of CheckMatrix.
"""
function xpart(cmat::CheckMatrix)
    cmat.cmat[:, 1:(cmat.nlegs)]
end

"""
    zpart(cmat::CheckMatrix)

Get Z part (right half) of CheckMatrix.
"""
function zpart(cmat::CheckMatrix)
    cmat.cmat[:, (cmat.nlegs + 1):end]
end

function xzparts(cmat::CheckMatrix)
    return xpart(cmat), zpart(cmat)
end

"""
    generators(cmat::CheckMatrix)::Vector{PauliOp}

Get generators from [`CheckMatrix`](@ref).
"""
function generators(cmat::CheckMatrix)::Vector{PauliOp}
    gens = PauliOp{cmat.nlegs}[]
    for row in eachrow(cmat.cmat)
        gen = map(zip(row[1:(cmat.nlegs)], row[(cmat.nlegs + 1):end])) do (x, z)
            g = PauliOps.I
            x && (g = g * PauliOps.X)
            z && (g = g * PauliOps.Z)
            g
        end
        push!(gens, gen)
    end
    gens
end

@doc raw"""
    direct_sum(cmat_1::T, cmat_2::T)::T where {T <: CheckMatrix}

Returns block diagonal `CheckMatrix` consists of `cmat_1` and `cmat_2`.

# CheckMatrix transform
When adding a lego $l$ with check matrix $H_l$ to a state with check matrix $H_s$,
the resulting check matrix of the state will be
```math
\begin{pmatrix}
    H_s & O   \\
    O   & H_l \\
\end{pmatrix}
```
"""
function direct_sum(cmat_1::T, cmat_2::T)::T where {T <: CheckMatrix}
    # expand size and fill?
    old_x, old_z = xzparts(cmat_1)
    add_x, add_z = xzparts(cmat_2)
    new_x = cat(old_x, add_x, dims = (1, 2))
    new_z = cat(old_z, add_z, dims = (1, 2))
    CheckMatrix(hcat(new_x, new_z))
end

"""
    eliminate_column!(
        cmat::CheckMatrix,
        col::Integer,
        avoid_row::AbstractVector{T},
    )::Union{Nothing, Int64} where {T <: Integer}

Perform Gauss Elimination on `col`.
Keep only one `1` on `col` and remove from other rows by performing multiplication.
Choose row not in `avoid_row`.
If all rows with 1 on `col` are in `avoid_row`, then the last row of them is chose to keep 1.
If all rows on `col` is 0, return nothing.

# Return
Row index which have 1 on `col`.
If all row on `col` is 0, return nothing.

# Example
```jldoctest
julia> ex_cmat = CheckMatrix(Bool[1 0 1 0; 1 1 1 1])
CheckMatrix with 2 generators, 2 legs:
  1  0 | 1  0
  1  1 | 1  1

julia> QuantumLegos.eliminate_column!(ex_cmat, 1, Int64[])
1

julia> ex_cmat
CheckMatrix with 2 generators, 2 legs:
  1  0 | 1  0
  0  1 | 0  1
```
"""
function eliminate_column!(
    cmat::CheckMatrix,
    col::Integer,
    avoid_row::AbstractVector{T},
)::Union{Nothing, Int64} where {T <: Integer}
    all(avoid_row .≤ cmat.ngens) || throw(ArgumentError("avoid_row is out of index"))
    @assert col ≤ cmat.nlegs * 2

    row_ids = findall(cmat.cmat[:, col])  # row with 1 on `col`
    @debug "ids of rows with 1 on col $(col) = $(row_ids)"
    if isempty(row_ids)
        @debug "No 1 on column $(col)."
        return nothing
    end
    if length(row_ids) == 1
        # already have only 1 1
        @debug "Already have only 1 1. Nothing to do."
        return row_ids[1]
    else
        @debug "More than 1 1. Need some operation."
        row_id_id = findfirst(!∈(avoid_row), row_ids)
        row_id = if isnothing(row_id_id)
            @debug "Rows with 1 are duplicated with avoid_row."
            # select last row_ids
            pop!(row_ids)
        else
            popat!(row_ids, row_id_id)
        end
        @debug "Selected row:$(row_id) to keep 1 on col:$(col)."
        for row in row_ids
            cmat.cmat[row, :] .⊻= cmat.cmat[row_id, :]
        end
        @debug "Finished. now only row:$(row_id) has 1 on col:$(col)"
        return row_id
    end
    error("Unreachable")
end

"""
    eliminate_column!(cmat::CheckMatrix, col::Integer,
    avoid_row::AbstractVector{T}) where {T <: Union{Nothing, Integer}}

`avoid_row` can include `Nothing`, which is ignored in actual evaluation.
"""
function eliminate_column!(
    cmat::CheckMatrix,
    col::Integer,
    avoid_row::AbstractVector{T},
) where {T <: Union{Nothing, Integer}}
    eliminate_column!(cmat, col, Vector{Integer}(filter(!isnothing, avoid_row)))
end

@inline function swap_row!(m::AbstractMatrix, i::Integer, j::Integer)
    i == j && return nothing
    @inbounds m[i, :], m[j, :] = m[j, :], m[i, :]
end

"""
    align_row!(m::AbstractMatrix, row::Integer, occupied::Vector{Union{Nothing, Integer}}) -> Integer
    align_row!(m::AbstractMatrix, row::Nothing, occupied::Vector{Union{Nothing, Integer}}) -> Nothing

Swap row at `row` in `m` and row at next to the maximum in `occupied`.
`occupied` is supposed to be a list of returns from [`eliminate_column!`](@ref).
If `row` is in `occupied`, do nothing and returns `row`.
If `row` is `nothing`, return `nothing`.

# Arguments
- `m::AbstractMatrix`: mutated
- `row::Union{Nothing, Integer}`: row to be aligned
- `occupied::Vector{Union{Nothing, Integer}}`: indices of already occupied rows. `row` will be next to these rows.

# Return
- Row index where `row` is moved.
"""
function align_row! end

function align_row!(
    m::AbstractMatrix,
    row::Integer,
    occupied::AbstractVector{T},
) where {T <: Integer}
    if row ∈ occupied
        return row
    end
    target = if isempty(occupied)
        1 # begin
    else
        maximum(occupied) + 1 # TODO: might cause out of index
    end
    swap_row!(m, row, target)
    target
end

function align_row!(
    _::AbstractMatrix,
    row::Nothing,
    _::AbstractVector{T},
) where {T <: Union{Nothing, Integer}}
    nothing
end
function align_row!(
    m::AbstractMatrix,
    row::Integer,
    occupied::AbstractVector{T},
) where {T <: Union{Nothing, Integer}}
    filter!(!isnothing, occupied)
    occupied = Vector{Integer}(occupied)
    align_row!(m, row, occupied)
end

# TODO: improve perf (see README.md)
"""
    ref!(cmat::CheckMatrix) -> Int

Convert `cmat` to row echelon form.

Returns rank of check matrix.

# Examples
```jldoctest
julia> cmat = CheckMatrix(Bool[
           1 0 1 0 1 1 0 1
           0 1 0 0 0 1 0 0
           1 1 1 0 1 0 1 1
           0 1 0 0 0 1 0 0
       ])
CheckMatrix with 4 generators, 4 legs:
  1  0  1  0 | 1  1  0  1
  0  1  0  0 | 0  1  0  0
  1  1  1  0 | 1  0  1  1
  0  1  0  0 | 0  1  0  0


julia> QuantumLegos.ref!(cmat)
3

julia> cmat
CheckMatrix with 4 generators, 4 legs:
  1  0  1  0 | 1  1  0  1
  0  1  0  0 | 0  1  0  0
  0  0  0  0 | 0  0  1  0
  0  0  0  0 | 0  0  0  0

```
"""
function ref!(cmat::CheckMatrix)
    # TODO: remain cmat shape when rank is max
    # For manual debugging stabilizer generators
    # Requires LinearAlgebra
    # if cmat.ngens == rank(cmat.cmat)
    #     return cmat.ngens
    # end
    r = 0 # row
    # for col in eachcol(cmat.cmat)
    for i in 1:(cmat.nlegs * 2)
        isall0 = true
        rid = 0
        for k in (r + 1):(cmat.ngens)
            if cmat.cmat[k, i]
                isall0 = false
                rid = k
                break
            end
        end
        if isall0
            continue
        end
        r += 1
        swap_row!(cmat.cmat, r, rid)
        for k in (rid + 1):(cmat.ngens)
            if cmat.cmat[k, i]
                @. cmat.cmat[k, :] = cmat.cmat[r, :] ⊻ cmat.cmat[k, :]
            end
        end
        #
        # rids = Int[]
        # for j in (r + 1):(cmat.ngens)
        #     cmat.cmat[j, i] && push!(rids, j)
        # end
        # # rids = findall(col) |> filter(>(r))
        # if isempty(rids) # all 0
        #     continue
        # end
        # r += 1
        # rid = popfirst!(rids)
        # swap_row!(cmat.cmat, r, rid)
        # if isempty(rids) # only 1 1
        #     continue
        # end
        # for i in rids
        #     @. cmat.cmat[i, :] = cmat.cmat[r, :] ⊻ cmat.cmat[i, :]
        # end
        if r == cmat.ngens
            break
        end
    end
    r # rank
end

"""
    eliminate_dependent_row!(cmat::CheckMatrix) -> CheckMatrix

Remove dependent rows to keep only independent generators.
"""
function eliminate_dependent_row!(cmat::CheckMatrix)
    # convert to reduced row echelon form: ref!
    # remove all-zero rows
    r = ref!(cmat)
    num_zero = cmat.ngens - r
    if num_zero > 0
        cmat.cmat = cmat.cmat[1:r, :]
        cmat.ngens = r
    end
    return cmat
end

"""
    self_trace!(cmat::CheckMatrix, col_1::Integer, col_2::Integer)

Take a self-trace of checkmatrix `cmat` with column `col_1` and `col_2`.

# Example
TODO
"""
function self_trace!(cmat::CheckMatrix, col_1::Integer, col_2::Integer)#::CheckMatrix
    if !(col_1 ≤ cmat.nlegs && col_2 ≤ cmat.nlegs)
        throw(
            ArgumentError(
                "Invalid column index(specified index is too large: $(max(col_1, col_2)) > $(cmat.nlegs))",
            ),
        )
    end
    if col_1 == col_2
        throw(ArgumentError("Can't trace two same legs"))
    end
    # sort to col_1 < col_2
    if col_1 > col_2
        col_1, col_2 = col_2, col_1
    end
    @debug "Initial cmat" cmat

    # TODO: cmat.nlegs ≤ 2 ?

    # organize cmat to where col_1 and col_2 have less than 3 true
    ## do for X on col_1
    col_1_x_id = eliminate_column!(cmat, col_1, Int64[])
    col_1_x_id = align_row!(cmat.cmat, col_1_x_id, Int64[])
    @debug "Finished eliminating of X" cmat
    ## do for Z on col_1
    col_1_z_id = eliminate_column!(cmat, col_1 + cmat.nlegs, [col_1_x_id])
    col_1_z_id = align_row!(cmat.cmat, col_1_z_id, [col_1_x_id])
    @debug "Finished elimination of Z" cmat
    @debug "col_1 X:" findall(cmat.cmat[:, col_1])
    @debug "col_1 Z:" findall(cmat.cmat[:, col_1 + cmat.nlegs])
    ## repeat for col_2
    ## for X on col_2
    col_2_x_id = eliminate_column!(cmat, col_2, [col_1_x_id, col_1_z_id])
    col_2_x_id = align_row!(cmat.cmat, col_2_x_id, [col_1_x_id, col_1_z_id])
    @debug "Finished eliminating of X" cmat
    ## do for Z on col_1
    col_2_z_id =
        eliminate_column!(cmat, col_2 + cmat.nlegs, [col_1_x_id, col_1_z_id, col_2_x_id])
    col_2_z_id = align_row!(cmat.cmat, col_2_z_id, [col_1_x_id, col_1_z_id, col_2_x_id])
    @debug "Finished elimination of Z" cmat
    @debug "col_2 X:" findall(cmat.cmat[:, col_2])
    @debug "col_2 Z:" findall(cmat.cmat[:, col_2 + cmat.nlegs])

    @debug "Finished Gauss Elimination" cmat
    # @info "col x/z s $([col_1_x_id, col_1_z_id, col_2_x_id, col_2_z_id])"

    # then adding them
    # select rows which have same value on col_1 and col_2
    # trace (remove col_1, col_2) and remove duplicate row(or dependent row: i.e. row-elim.)
    @debug "Tracing"
    # assert that col_1, col_2 have 1s only on row 1, 2, 3, 4
    @assert findall(cmat.cmat[:, col_1]) .|> ≤(1) |> all
    @assert findall(cmat.cmat[:, col_1 + cmat.nlegs]) .|> ≤(2) |> all
    @assert findall(cmat.cmat[:, col_2]) .|> ≤(3) |> all
    @assert findall(cmat.cmat[:, col_2 + cmat.nlegs]) .|> ≤(4) |> all
    col_12_xz_ids = [col_1_z_id, col_1_x_id, col_2_x_id, col_2_z_id] |> filter(!isnothing)

    # note that col_1 < col_2
    remaining_x_cols =
        [1:(col_1 - 1)..., (col_1 + 1):(col_2 - 1)..., (col_2 + 1):(cmat.nlegs)...]
    remaining_cols = [remaining_x_cols..., (remaining_x_cols .+ cmat.nlegs)...]
    if cmat.ngens ≤ 3
        # TODO:
        # @warn "cmat has ≤ 3 generators" cmat
        subsets_row = eachrow(cmat.cmat) |> subsets |> collect
        filter!(!isempty, subsets_row)
        generated_rows = map(subsets_row) do vs
            reduce(.⊻, vs)
        end
        # matching on col
        filter!(generated_rows) do v
            v[[col_1, col_2]] == v[[col_1 + cmat.nlegs, col_2 + cmat.nlegs]]
        end
        new_ngens = length(generated_rows)
        new_cmat = zeros(Bool, (new_ngens, 2 * (cmat.nlegs - 2)))
        for (i, v) in enumerate(generated_rows)
            new_cmat[i, :] .= v[remaining_cols]
        end

        cmat.cmat = new_cmat
        cmat.nlegs -= 2
        @assert size(cmat.cmat)[2] == 2 * cmat.nlegs "cmat size mismatched"
        cmat.ngens = size(cmat.cmat)[1]
        @assert cmat.ngens == new_ngens
    elseif cmat.cmat[1, col_1] &&
       cmat.cmat[2, col_1 + cmat.nlegs] &&
       cmat.cmat[3, col_2] &&
       cmat.cmat[4, col_2 + cmat.nlegs]
        @assert Set([col_1_x_id, col_1_z_id, col_2_x_id, col_2_z_id]) == Set([1, 2, 3, 4])
        # All errors correctable (D.9) (row 2, 3 swapped)
        cmat.cmat[1, :] .⊻= cmat.cmat[3, :]
        cmat.cmat[2, :] .⊻= cmat.cmat[4, :]
        @assert cmat.cmat[1, col_1] && cmat.cmat[3, col_2] "Test whether the form is D.10"
        @assert cmat.cmat[2, col_1 + cmat.nlegs] && cmat.cmat[4, col_2 + cmat.nlegs] "Test whether the form is D.10"
        new_cmat = zeros(Bool, (cmat.ngens - 2, 2 * (cmat.nlegs - 2)))
        new_cmat[1, :] .= cmat.cmat[1, remaining_cols]
        new_cmat[2, :] .= cmat.cmat[2, remaining_cols]
        new_cmat[3:end, :] .= cmat.cmat[5:end, remaining_cols]

        cmat.cmat = new_cmat
        cmat.nlegs -= 2
        cmat.ngens -= 2
    else#if maximum(col_12_xz_ids) == 3 # TODO: can be split
        # TODO need some cases
        # @warn "Implementing..."
        # @info cmat cmat

        row_123 = eachrow(cmat.cmat)[1:3]
        subsets_from_123 = collect(subsets(row_123))
        filter!(!isempty, subsets_from_123)
        generated_from_123 = map(subsets_from_123) do vs
            reduce(.⊻, vs)
        end
        filter!(generated_from_123) do v
            # matched
            v[[col_1, col_2]] == v[[col_1 + cmat.nlegs, col_2 + cmat.nlegs]]
        end
        n_generated_from_123 = length(generated_from_123)
        new_ngens = n_generated_from_123 + cmat.ngens - 3
        new_cmat = zeros(Bool, (new_ngens, 2 * (cmat.nlegs - 2)))
        for (i, v) in enumerate(generated_from_123)
            new_cmat[i, :] .= v[remaining_cols]
        end
        new_cmat[(n_generated_from_123 + 1):end, :] .= cmat.cmat[4:end, remaining_cols]

        cmat.cmat = new_cmat
        cmat.nlegs -= 2
        @assert cmat.nlegs == size(new_cmat)[2] ÷ 2
        cmat.ngens = size(new_cmat)[1]
    end
    # ngens is updated below
    eliminate_dependent_row!(cmat)
    return cmat
end
