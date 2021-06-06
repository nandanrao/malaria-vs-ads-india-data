from datetime import datetime

import geopandas as gpd
import pandas as pd
from vlab_prepro import Preprocessor

from costs import prep_facebook_data
from generate_responses import format_round_a

from .utils import binarize


def mean_cols(df, cols):
    return {col: df[col].mean() for col in cols}


binary_cols = [
    ("malaria5year", "Yes"),
    ("malaria2weeks", "Yes"),
    ("dwelling", "Kutcha (made of mud, tin, straw)", "kutcha"),
    ("dwelling", "Pucca (have cement/brick wall and floor", "pucca"),
    ("education", "University degree or higher", "university"),
    ("occupation", "Unemployed", "unemployed"),
    ("sleepundernet", "Yes"),
]


def matching_stats(df):
    means = [
        "kutcha",
        "pucca",
        "university",
        "unemployed",
        "malaria5year",
        "malaria2weeks",
        "sleepundernet",
    ]
    vals = {
        **mean_cols(df, means),
        "population": df.tot_p.max(),
        "current_total": df.shape[0],
    }

    return pd.Series(vals)


def get_dist_info(path):
    geod = gpd.read_file(path)
    district_info = (
        geod.groupby("disthash")
        .apply(lambda df: df.iloc[0][["disthash", "tot_p"]])
        .reset_index(drop=True)
    )
    return district_info


def make_districts(cluster, cities):
    dist_info = get_dist_info(cluster)
    cities = pd.read_csv(cities)
    cities = cities[cities.rad >= 1.0]
    cities = cities.merge(dist_info, how="left", on="disthash")

    districts = (
        cities.groupby("distname")
        .head(1)
        .reset_index(drop=True)
        .drop(columns=["rad", "lng", "lat", "distcode", "id"])
    )

    return districts


def make_baseline(time_limit):
    rdf = pd.read_csv("raw/responses-malaria-no-more.csv")
    forms = pd.read_csv("raw/forms-malaria-no-more.csv")

    districts = make_districts(
        "final/geography/cluster.shp", "final/geography/base-cities.csv"
    )

    p = Preprocessor()
    df = p.parse_timestamp(rdf)
    df = df[df.timestamp <= datetime.fromisoformat(time_limit)].reset_index(drop=True)
    d = format_round_a(df, forms)

    d = binarize(d, binary_cols)

    d = d[d.wave == 0].reset_index(drop=True)
    d["disthash"] = d.clusterid

    d = d.merge(districts)
    d = d.dropna(subset=["occupation"])

    dist_info = prep_facebook_data("raw/fb-export-vlab-1.csv", d)

    baseline = (
        d.groupby("disthash")
        .apply(matching_stats)
        .reset_index()
        .merge(dist_info)
        .rename(columns={"disthash": "stratumid"})
    )

    baseline.columns = baseline.columns.map(
        lambda x: f"cluster_{x}" if x != "stratumid" else x
    )

    return baseline


if __name__ == "__main__":
    baseline = make_baseline("2020-08-19T00:00+00:00")
    baseline.to_csv("final/baseline.csv", index=False)
