def binarize_col(df, col, targ, new_col=None):
    if not new_col:
        new_col = col

    s = df[col] == targ
    s[df[col].isna()] = None
    return df.assign(**{new_col: s})


def binarize(df, cols):
    for c in cols:
        df = binarize_col(df, *c)
    return df
