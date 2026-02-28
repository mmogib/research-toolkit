# deps.jl — Central dependency management
# All shared dependencies go here. Scripts add only script-specific packages.

using LinearAlgebra
using SparseArrays
using Printf
using Random
using Statistics
using Dates

# Constraint sets
using LazySets
import LazySets: σ, an_element

# Data I/O
using DataFrames
using CSV

# Progress bars
using ProgressMeter
