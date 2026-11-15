# Discretized Weil-Bombieri Trace-Moment Ratio Probe (CBQN)
n ← 128
# Candidate compactly supported cosine-tapered test weights on [-1, 1]
u ← (¯1 + 2 × (↕n) ÷ n-1)
w ← (1 - u×u) × (1 + 0.35 × •math.Cos 3.141592653589793 × u)

# Construct normalized Toeplitz Gram kernel R_ij = sinc(pi * (u_i - u_j)) * w_i * w_j
diff ← 3.141592653589793 × (u -⌜ u)
sinc ← {(0=𝕩) ◶ ⟨(•math.Sin 𝕩)÷𝕩, 1⟩}¨ diff
R ← sinc × (w ×⌜ w)

# Compute Tr(R) and Hilbert-Schmidt norm squared Tr(R^2) = +˝ +˝ R × ⍉R
diagIdx ← (↕n) × n + 1
trR ← +˝ diagIdx ⊏ ⥊R
hs2 ← +˝ +˝ R × ⍉R

# Lower bound ratio Tr(R)^2 / (n * ||R||_HS^2)
(trR × trR) ÷ (n × hs2)
