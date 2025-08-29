# %%
# R 1:10
1:10

# %%
# R seq(1, 10, 0.1)
x = 1:0.1:10
collect(x)

# %%
# R x <- 1:10
# R head(x, 3)
# R tail(x, 3)
x = 1:10
first(x, 3)
last(x, 3)

# %%
# rep(1.0, 3)
repeat([1.0], 3)

# %%
# R c(1, 2)
(1, 2)

# %%
# R matrix(1:3, ncol=1)
[1, 2, 3]

# %%
# R matrix(1:3, nrow=3)
[1 2 3]

# %%
# Unicode
# R alpha = 2e-4
# R DeltaRho = 1

# %%
# R for (i in 1:10) { ... }
for i in 1:3
    println(i)
end

# %%
# ifelse(x < 10, "yi", "iy")
x = 7
x < 10 ? "yi" : "iy"

