# %%
function f(x, y)
    [2x, 3y]
end
f(1, 1)

# %%
x = 1:4
y = 10x

# %%
X, Y = f.(x, y)

# %%
F[:; 1]

# %%
F[:; 2]

