import pandas as pd
import re


def get_treatment():
    return pd.read_csv("raw/ma-with-treatment.csv")[["disthash", "treatment"]].rename(
        columns={"disthash": "stratumid"}
    )


def merge(df):
    baseline = pd.read_csv("final/baseline.csv")
    treatment = get_treatment()
    return df.merge(baseline, on="stratumid").merge(treatment)


def get_treatment_from_stratum(r):
    res = re.search(r"treatment-(\d)", r.stratumid)
    if res:
        r.treatment = int(res[1])
    return r


def ind_effect():
    df = pd.read_csv("final/responses/MNM.csv")

    # Only the non-1-shot respondents
    ind_effect_users = df[df.shortcode.isin({"extraendhin"})].userid.unique()
    ied = df[df.userid.isin(ind_effect_users)]

    # We accidentally pushed some respondents directly to wave 1
    ups_users = ied[(ied.wave == "1") & (ied.week < 10)].userid.unique()
    ied = ied[~ied.userid.isin(ups_users)].reset_index(drop=True)

    # Add individual treatment assignment
    ind_assignment = pd.read_csv("raw/ind-effect-with-assignment.csv")[
        ["userid", "ind_treatment"]
    ]
    ind_assignment["userid"] = ind_assignment.userid.astype(int)
    ied = ied.merge(ind_assignment)

    # Add cluster treatment assignment
    treatment = get_treatment()
    ied = ied.merge(treatment, how="left")
    ied = ied.apply(get_treatment_from_stratum, 1)

    return ied


def xsection():
    # TODO: add individual assignments to MNM.csv data, where applicable
    # TODO: get the endline here so you get info

    files = ["final/responses/MNM.csv", "final/responses/1-shot.csv"]
    df = pd.concat([pd.read_csv(p) for p in files]).reset_index(drop=True)
    shortcodes = {"extrabasehin", "extrabasehinbail", "extrabasehin1shot"}
    df = df[df.shortcode.isin(shortcodes)].reset_index()
    return merge(df)


def panel():
    df = pd.read_csv("final/responses/malaria-no-more.csv").rename(
        columns={"clusterid": "stratumid"}
    )

    return merge(df)


def main():
    conf = [(xsection, "xsection"), (panel, "panel"), (ind_effect, "individual")]
    for fn, outfi in conf:
        fn().to_csv(f"final/regression-data/{outfi}.csv", index=False)


if __name__ == "__main__":
    main()
