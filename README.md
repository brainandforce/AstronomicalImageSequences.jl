# AstronomicalImageSequences.jl

[![Build Status][ci-status-img]][ci-status-url]
[![Aqua.jl][aqua-img]][aqua-url]

AstronomicalImageSequences.jl provides support for astronomical image sequences in the most generic possible way.
This package provides types that allow for grouping images by relevant categories, such as session date, equipment used, or even portions of a mosaic, so that different steps (such as calibration, registration, etc.) can use all of the data relevant to an imaging project (for instance, registering every frame against a single reference across the entire project).

Although this package primarily defines types for working with image data, it also provides a function for calibrating images.

[repo-url]:         https://github.com/brainandforce/ImageStacking.jl
[docs-stable-img]:  https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]:  https://brainandforce.github.io/ImageStacking.jl/stable
[docs-dev-img]:     https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]:     https://brainandforce.github.io/ImageStacking.jl/dev
[ci-status-img]:    https://github.com/brainandforce/ImageStacking.jl/workflows/CI/badge.svg
[ci-status-url]:    https://github.com/brainandforce/ImageStacking.jl/actions
[aqua-img]:         https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg
[aqua-url]:         https://github.com/JuliaTesting/Aqua.jl
[codecov-img]:      https://codecov.io/gh/brainandforce/ImageStacking.jl/branch/main/graph/badge.svg
[codecov-url]:      https://codecov.io/gh/brainandforce/ImageStacking.jl/
