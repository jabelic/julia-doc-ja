# Install dependencies needed to build the documentation.
Base.HOME_PROJECT[] = nothing
empty!(LOAD_PATH)
push!(LOAD_PATH, @__DIR__, "@stdlib")
empty!(DEPOT_PATH)
pushfirst!(DEPOT_PATH, joinpath(@__DIR__, "deps"))
using Pkg
Pkg.instantiate()

using Documenter, DocumenterLaTeX

baremodule GenStdLib end

# Documenter Setup.

symlink_q(tgt, link) = isfile(link) || symlink(tgt, link)
cp_q(src, dest) = isfile(dest) || cp(src, dest)

# make links for stdlib package docs, this is needed until #552 in Documenter.jl is finished
const STDLIB_DOCS = []
const STDLIB_DIR = Sys.STDLIB
const EXT_STDLIB_DOCS = ["Pkg"]
cd(joinpath(@__DIR__, "src")) do
    Base.rm("stdlib"; recursive=true, force=true)
    mkdir("stdlib")
    for dir in readdir(STDLIB_DIR)
        sourcefile = joinpath(STDLIB_DIR, dir, "docs", "src")
        if dir in EXT_STDLIB_DOCS
            sourcefile = joinpath(sourcefile, "basedocs.md")
        else
            sourcefile = joinpath(sourcefile, "index.md")
        end
        if isfile(sourcefile)
            targetfile = joinpath("stdlib", dir * ".md")
            push!(STDLIB_DOCS, (stdlib = Symbol(dir), targetfile = targetfile))
            if Sys.iswindows()
                cp_q(sourcefile, targetfile)
            else
                symlink_q(sourcefile, targetfile)
            end
        end
    end
end

# Check if we are building a PDF
const render_pdf = "pdf" in ARGS

# Generate a suitable markdown file from NEWS.md and put it in src
str = read(joinpath(@__DIR__, "..", "NEWS.md"), String)
splitted = split(str, "<!--- generated by NEWS-update.jl: -->")
@assert length(splitted) == 2
replaced_links = replace(splitted[1], r"\[\#([0-9]*?)\]" => s"[#\g<1>](https://github.com/JuliaLang/julia/issues/\g<1>)")
write(joinpath(@__DIR__, "src", "NEWS.md"), replaced_links)

Manual = [
    "manual/getting-started.md",
    "manual/variables.md",
    "manual/integers-and-floating-point-numbers.md",
    "manual/mathematical-operations.md",
    "manual/complex-and-rational-numbers.md",
    "manual/strings.md",
    "manual/functions.md",
    "manual/control-flow.md",
    "manual/variables-and-scoping.md",
    "manual/types.md",
    "manual/methods.md",
    "manual/constructors.md",
    "manual/conversion-and-promotion.md",
    "manual/interfaces.md",
    "manual/modules.md",
    "manual/documentation.md",
    "manual/metaprogramming.md",
    "manual/arrays.md",
    "manual/missing.md",
    "manual/networking-and-streams.md",
    "manual/parallel-computing.md",
    "manual/asynchronous-programming.md",
    "manual/multi-threading.md",
    "manual/distributed-computing.md",
    "manual/running-external-programs.md",
    "manual/calling-c-and-fortran-code.md",
    "manual/handling-operating-system-variation.md",
    "manual/environment-variables.md",
    "manual/embedding.md",
    "manual/code-loading.md",
    "manual/profile.md",
    "manual/stacktraces.md",
    "manual/performance-tips.md",
    "manual/workflow-tips.md",
    "manual/style-guide.md",
    "manual/faq.md",
    "manual/noteworthy-differences.md",
    "manual/unicode-input.md",
]

BaseDocs = [
    "base/base.md",
    "base/collections.md",
    "base/math.md",
    "base/numbers.md",
    "base/strings.md",
    "base/arrays.md",
    "base/parallel.md",
    "base/multi-threading.md",
    "base/constants.md",
    "base/file.md",
    "base/io-network.md",
    "base/punctuation.md",
    "base/sort.md",
    "base/iterators.md",
    "base/c.md",
    "base/libc.md",
    "base/stacktraces.md",
    "base/simd-types.md",
]

StdlibDocs = [stdlib.targetfile for stdlib in STDLIB_DOCS]

DevDocs = [
    "devdocs/reflection.md",
    "Documentation of Julia's Internals" => [
        "devdocs/init.md",
        "devdocs/ast.md",
        "devdocs/types.md",
        "devdocs/object.md",
        "devdocs/eval.md",
        "devdocs/callconv.md",
        "devdocs/compiler.md",
        "devdocs/functions.md",
        "devdocs/cartesian.md",
        "devdocs/meta.md",
        "devdocs/subarrays.md",
        "devdocs/isbitsunionarrays.md",
        "devdocs/sysimg.md",
        "devdocs/llvm.md",
        "devdocs/stdio.md",
        "devdocs/boundscheck.md",
        "devdocs/locks.md",
        "devdocs/offset-arrays.md",
        "devdocs/require.md",
        "devdocs/inference.md",
        "devdocs/ssair.md",
        "devdocs/gc-sa.md",
    ],
    "Developing/debugging Julia's C code" => [
        "devdocs/backtraces.md",
        "devdocs/debuggingtips.md",
        "devdocs/valgrind.md",
        "devdocs/sanitizers.md",
    ]
]


if render_pdf
const PAGES = [
    "Manual" => ["index.md", Manual...],
    "Base" => BaseDocs,
    "Standard Library" => StdlibDocs,
    "Developer Documentation" => DevDocs,
    hide("NEWS.md"),
]
else
const PAGES = [
    "Julia Documentation" => "index.md",
    hide("NEWS.md"),
    "Manual" => Manual,
    "Base" => BaseDocs,
    "Standard Library" => StdlibDocs,
    "Developer Documentation" => DevDocs,
]
end

for stdlib in STDLIB_DOCS
    @eval using $(stdlib.stdlib)
    # All standard library modules get `using $STDLIB` as their global
    DocMeta.setdocmeta!(Base.root_module(Base, stdlib.stdlib), :DocTestSetup, :(using $(stdlib.stdlib)), recursive=true)
end
# A few standard libraries need more than just the module itself in the DocTestSetup.
# This overwrites the existing ones from above though, hence the warn=false.
DocMeta.setdocmeta!(SparseArrays, :DocTestSetup, :(using SparseArrays, LinearAlgebra), recursive=true, warn=false)
DocMeta.setdocmeta!(UUIDs, :DocTestSetup, :(using UUIDs, Random), recursive=true, warn=false)
DocMeta.setdocmeta!(Pkg, :DocTestSetup, :(using Pkg, Pkg.Artifacts), recursive=true, warn=false)
DocMeta.setdocmeta!(Pkg.BinaryPlatforms, :DocTestSetup, :(using Pkg, Pkg.BinaryPlatforms), recursive=true, warn=false)

let r = r"buildroot=(.+)", i = findfirst(x -> occursin(r, x), ARGS)
    global const buildroot = i === nothing ? (@__DIR__) : first(match(r, ARGS[i]).captures)
end

const format = if render_pdf
    LaTeX(
        platform = "texplatform=docker" in ARGS ? "docker" : "native"
    )
else
    Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
        canonical = ("deploy" in ARGS) ? "https://docs.julialang.org/en/v1/" : nothing,
        assets = ["assets/julia-manual.css", ],
        analytics = "UA-28835595-6",
        collapselevel = 1,
        sidebar_sitename = false,
        edit_link = "main",
    )
end

makedocs(
    build     = joinpath(buildroot, "doc", "_build", (render_pdf ? "pdf" : "html"), "ja"),
    modules   = [Base, Core, [Base.root_module(Base, stdlib.stdlib) for stdlib in STDLIB_DOCS]...],
    clean     = true,
    doctest   = ("doctest=fix" in ARGS) ? (:fix) : ("doctest=only" in ARGS) ? (:only) : ("doctest=true" in ARGS) ? true : false,
    linkcheck = "linkcheck=true" in ARGS,
    linkcheck_ignore = ["https://bugs.kde.org/show_bug.cgi?id=136779"], # fails to load from nanosoldier?
    strict    = true,
    checkdocs = :none,
    format    = format,
    sitename  = "The Julia Language",
    authors   = "The Julia Project",
    pages     = PAGES,
)

# Define our own DeployConfig
struct BuildBotConfig <: Documenter.DeployConfig end
function Documenter.deploy_folder(::BuildBotConfig; devurl, repo, branch, kwargs...)
    haskey(ENV, "DOCUMENTER_KEY") || return Documenter.DeployDecision(; all_ok=false)
    if Base.GIT_VERSION_INFO.tagged_commit
        # Strip extra pre-release info (1.5.0-rc2.0 -> 1.5.0-rc2)
        ver = VersionNumber(VERSION.major, VERSION.minor, VERSION.patch,
            isempty(VERSION.prerelease) ? () : (VERSION.prerelease[1],))
        subfolder = "v$(ver)"
        return Documenter.DeployDecision(; all_ok=true, repo, branch, subfolder)
    elseif Base.GIT_VERSION_INFO.branch == "master"
        return Documenter.DeployDecision(; all_ok=true, repo, branch, subfolder=devurl)
    end
    return Documenter.DeployDecision(; all_ok=false)
end

const devurl = "v$(VERSION.major).$(VERSION.minor)-dev"

# Hack to make rc docs visible in the version selector
struct Versions versions end
function Documenter.Writers.HTMLWriter.expand_versions(dir::String, v::Versions)
    # Find all available docs
    available_folders = readdir(dir)
    cd(() -> filter!(!islink, available_folders), dir)
    filter!(x -> occursin(Base.VERSION_REGEX, x), available_folders)

    # Look for docs for an "active" release candidate and insert it
    vnums = [VersionNumber(x) for x in available_folders]
    master_version = maximum(vnums)
    filter!(x -> x.major == 1 && x.minor == master_version.minor-1, vnums)
    rc = maximum(vnums)
    if !isempty(rc.prerelease) && occursin(r"^rc", rc.prerelease[1])
        src = "v$(rc)"
        @assert src ∈ available_folders
        push!(v.versions, src => src, pop!(v.versions))
    end

    return Documenter.Writers.HTMLWriter.expand_versions(dir, v.versions)
end

deploydocs(
    repo = "github.com/JuliaLang/docs.julialang.org.git",
    deploy_config = BuildBotConfig(),
    target = joinpath(buildroot, "doc", "_build", "html", "ja"),
    dirname = "ja",
    devurl = devurl,
    versions = Versions(["v#.#", devurl => devurl]),
)
