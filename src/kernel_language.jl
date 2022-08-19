#TODO: add ParallelStencil.ParallelKernel. in front of all kernel lang in macros! Later: generalize more for z?

##
macro nx_l(args...) check_initialized(); checknoargs(args...); esc(nx_l(args...)); end


##
macro ny_l(args...) check_initialized(); checknoargs(args...); esc(ny_l(args...)); end


##
macro nz_l(args...) check_initialized(); checknoargs(args...); esc(nz_l(args...)); end


##
macro t_h(args...) check_initialized(); checknoargs(args...); esc(t_h(args...)); end


##
macro t_h2(args...) check_initialized(); checknoargs(args...); esc(t_h2(args...)); end


##
macro tx_h(args...) check_initialized(); checknoargs(args...); esc(tx_h(args...)); end


##
macro ty_h(args...) check_initialized(); checknoargs(args...); esc(ty_h(args...)); end


##
macro tx_h2(args...) check_initialized(); checknoargs(args...); esc(tx_h2(args...)); end


##
macro ty_h2(args...) check_initialized(); checknoargs(args...); esc(ty_h2(args...)); end


##
macro ix_h(args...) check_initialized(); checknoargs(args...); esc(ix_h(args...)); end


##
macro iy_h(args...) check_initialized(); checknoargs(args...); esc(iy_h(args...)); end


##
macro ix_h2(args...) check_initialized(); checknoargs(args...); esc(ix_h2(args...)); end


##
macro iy_h2(args...) check_initialized(); checknoargs(args...); esc(iy_h2(args...)); end


##
macro loop(args...) check_initialized(); checkargs_loop(args...); esc(loop(args...)); end


##
macro loopopt(args...) check_initialized(); checkargs_onchipmemopt(args...); esc(loopopt(args...)); end


## ARGUMENT CHECKS

function checknoargs(args...)
    if (length(args) != 0) @ArgumentError("no arguments allowed.") end
end

function checkargs_loop(args...)
    if (length(args) != 4) @ArgumentError("wrong number of arguments.") end
end

function checkargs_onchipmemopt(args...)
    if (length(args) != 6) @ArgumentError("wrong number of arguments.") end
end


## FUNCTIONS FOR INDEXING AND DIMENSIONS

function nx_l(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :(@blockDim().x + (2*SHMEM_HALO_X))
end

function ny_l(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :(@blockDim().y + (2*SHMEM_HALO_Y))
end

function nz_l(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :(@blockDim().z + (2*SHMEM_HALO_Z))
end

function t_h(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@threadIdx().y-1)*@blockDim().x + @threadIdx().x)
end

function t_h2(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :(@t_h() + @nx_l()*@ny_l() - @blockDim().x*@blockDim().y)
end

function tx_h(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@t_h() -1) % @nx_l() + 1)
end

function ty_h(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@t_h() -1) ÷ @nx_l() + 1)
end

function tx_h2(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@t_h2()-1) % @nx_l() + 1)
end

function ty_h2(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@t_h2()-1) ÷ @nx_l() + 1)
end

function ix_h(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@blockIdx().x-1)*@blockDim().x + @tx_h()  - SHMEM_HALO_X)
end

function iy_h(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@blockIdx().y-1)*@blockDim().y + @ty_h()  - SHMEM_HALO_Y)
end

function ix_h2(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@blockIdx().x-1)*@blockDim().x + @tx_h2() - SHMEM_HALO_X)
end

function iy_h2(args...; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    return :((@blockIdx().y-1)*@blockDim().y + @ty_h2() - SHMEM_HALO_Y)
end


## FUNCTIONS FOR PERFORMANCE OPTIMSATIONS

#TODO: name mangling for generated vars as loopoffset, i.
function loop(dim::Integer, index::Symbol, loopsize, body; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    dimvar = (:x,:y,:z)[dim]
    return quote
        loopoffset = (@blockIdx().$dimvar-1)*$loopsize
        for i = 1:$loopsize
            $index = i + loopoffset
            $body
        end
    end
end

#TODO: see what to do with global consts as SHMEM_HALO_X,... Support later multiple vars for opt (now just A=T...)
#TODO: add input check and errors
#TODO: maybe gensym with macro @gensym
function loopopt(dim::Integer, indices, loopsize, shmemhalo, A, body; package::Symbol=get_package())
    if (package ∉ SUPPORTED_PACKAGES) @KeywordArgumentError("$ERRMSG_UNSUPPORTED_PACKAGE (obtained: $package).") end
    if isa(indices,Expr) indices = indices.args else indices = [indices] end
    if isa(shmemhalo,Expr) shmemhalo = shmemhalo.args else shmemhalo = [shmemhalo] end
    if dim == 3
        shmemhalox, shmemhaloy = shmemhalo
        ix, iy, iz   = indices
        i            = gensym_world("i", @__MODULE__)
        tx           = gensym_world("tx", @__MODULE__)
        ty           = gensym_world("ty", @__MODULE__)
        ix_h         = gensym_world("ix_h", @__MODULE__)
        ix_h2        = gensym_world("ix_h2", @__MODULE__)
        iy_h         = gensym_world("iy_h", @__MODULE__)
        iy_h2        = gensym_world("iy_h2", @__MODULE__)
        loopoffset   = gensym_world("loopoffset", @__MODULE__)
        A_izp1       = gensym_world(string(A, "_izp1"), @__MODULE__)
        A_ix_iy_izm1 = gensym_world(string(A, "_ix_iy_izm1"), @__MODULE__)
        A_ix_iy_iz   = gensym_world(string(A, "_ix_iy_iz"), @__MODULE__)
        A_ix_iy_izp1 = gensym_world(string(A, "_ix_iy_izp1"), @__MODULE__)
        A_ixm1_iy_iz = gensym_world(string(A, "_ixm1_iy_iz"), @__MODULE__)
        A_ixp1_iy_iz = gensym_world(string(A, "_ixp1_iy_iz"), @__MODULE__)
        A_ix_iym1_iz = gensym_world(string(A, "_ix_iym1_iz"), @__MODULE__)
        A_ix_iyp1_iz = gensym_world(string(A, "_ix_iyp1_iz"), @__MODULE__)

        body = substitute(body, :($A[$ix,$iy,$iz-1]), A_ix_iy_izm1)
        body = substitute(body, :($A[$ix,$iy,$iz  ]), A_ix_iy_iz  )
        body = substitute(body, :($A[$ix,$iy,$iz+1]), A_ix_iy_izp1)
        body = substitute(body, :($A[$ix-1,$iy,$iz]), A_ixm1_iy_iz)
        body = substitute(body, :($A[$ix+1,$iy,$iz]), A_ixp1_iy_iz)
        body = substitute(body, :($A[$ix,$iy-1,$iz]), A_ix_iym1_iz)
        body = substitute(body, :($A[$ix,$iy+1,$iz]), A_ix_iyp1_iz)
        
        return quote
            $tx            = @threadIdx().x + $shmemhalox
            $ty            = @threadIdx().y + $shmemhaloy
            $ix_h          = @ix_h()  #(@blockIdx().x-1)*@blockDim().x + @tx_h()  - SHMEM_HALO_X
            $ix_h2         = @ix_h2() #(@blockIdx().x-1)*@blockDim().x + @tx_h2() - SHMEM_HALO_X
            $iy_h          = @iy_h()  #(@blockIdx().y-1)*@blockDim().y + @ty_h()  - SHMEM_HALO_Y
            $iy_h2         = @iy_h2() #(@blockIdx().y-1)*@blockDim().y + @ty_h2() - SHMEM_HALO_Y
            $loopoffset    = (@blockIdx().z-1)*$loopsize #TODO: MOVE UP - see no perf change! interchange other lines!
            $A_izp1        = @sharedMem(eltype($A), (@nx_l(), @ny_l()))
            $A_ix_iy_izm1  = 0.0
            $A_ix_iy_iz    = $A[$ix,$iy,1+$loopoffset]
            $A_ix_iy_izp1  = 0.0
            $A_ixm1_iy_iz  = 0.0
            $A_ixp1_iy_iz  = 0.0
            $A_ix_iym1_iz  = 0.0
            $A_ix_iyp1_iz  = 0.0
            for $i = 1:$loopsize
                $iz = $i + $loopoffset
                @sync_threads()
                if (@t_h() <= cld(@nx_l()*@ny_l(),2) && $ix_h>0 && $ix_h<=size($A,1) && $iy_h>0 && $iy_h<=size($A,2) && $iz<size($A,3)) 
                    $A_izp1[@tx_h(),@ty_h()] = $A[$ix_h,$iy_h,$iz+1] 
                end
                if (@t_h2() > cld(@nx_l()*@ny_l(),2) && $ix_h2>0 && $ix_h2<=size($A,1) && $iy_h2>0 && $iy_h2<=size($A,2) && $iz<size($A,3)) 
                    $A_izp1[@tx_h2(),@ty_h2()] = $A[$ix_h2,$iy_h2,$iz+1]
                end
                @sync_threads()
                $A_ix_iy_izp1 = $A_izp1[$tx,$ty]
                $body
                $A_ixm1_iy_iz = $A_izp1[$tx-1,$ty]
                $A_ixp1_iy_iz = $A_izp1[$tx+1,$ty]
                $A_ix_iym1_iz = $A_izp1[$tx,$ty-1]
                $A_ix_iyp1_iz = $A_izp1[$tx,$ty+1]
                $A_ix_iy_izm1 = $A_ix_iy_iz
                $A_ix_iy_iz   = $A_ix_iy_izp1
            end
        end
    else
        @ArgumentError("@loopopt: only dim=3 is currently supported.")
    end
end


## FUNCTIONS FOR SHARED MEMORY ALLOCATION
