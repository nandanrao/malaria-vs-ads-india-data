import geopandas as gpd
import pandas as pd
import shapely.geometry.polygon as ply
import xxhash


def add_geo(r, geo):
    r["geometry"] = geo
    return r


def split_geos(r):
    if isinstance(r.geometry, ply.Polygon):
        return pd.DataFrame([r])
    df = pd.DataFrame([add_geo(r, geo) for geo in r.geometry])
    return df


def bufferz(c, rad, d):
    r = c.combine_first(d)
    r["geometry"] = c.geometry.buffer(rad)

    return r, (c.osm_id, d.distcode, d.distname, d.statename, c.geometry, rad / 1000)


def hsh(n):
    return xxhash.xxh32(n).hexdigest()


def prep_dists(dists, states, excludes):
    dists = pd.concat([split_geos(r) for _, r in dists.iterrows()]).reset_index(
        drop=True
    )
    dists = gpd.GeoDataFrame(dists, geometry="geometry", crs=4326)
    dists = dists[dists.statename.isin(states)]
    dists = dists[~dists.distname.isin(excludes)]
    dists["disthash"] = dists.distname.map(hsh)

    # Project to meter distance projection
    dists = dists.to_crs(3857)
    return dists


def make_clusters(cities, dists, buffer_margin):
    dat = [
        (c, d)
        for _, d in dists.iterrows()
        for _, c in cities[cities.within(d.geometry)].iterrows()
    ]

    dat = [
        (c, d.geometry.exterior.distance(c.geometry) - buffer_margin, d) for c, d in dat
    ]
    dat = [bufferz(*t) for t in dat]
    rows = [r for r, _ in dat]

    cities_df = pd.DataFrame(
        [t for _, t in dat],
        columns=["id", "distcode", "distname", "state", "geometry", "rad"],
    )
    cities_df = gpd.GeoDataFrame(cities_df, geometry="geometry", crs=3857).to_crs(4326)
    cities_df["lng"] = cities_df.geometry.map(lambda g: g.coords[0][0])
    cities_df["lat"] = cities_df.geometry.map(lambda g: g.coords[0][1])
    cities_df = pd.DataFrame(cities_df)
    cities_df = cities_df.drop(columns=["geometry"])
    cities_df["disthash"] = cities_df.distname.map(hsh)

    gdf = (
        gpd.GeoDataFrame(pd.DataFrame(rows), geometry="geometry", crs=3857)
        .to_crs(4326)
        .reset_index(drop=True)
    )

    # fix one city issue!
    cities_df.loc[cities_df.distname == "Balrampur", "distcode"] = "182"
    gdf.loc[gdf.distname == "Balrampur", "distcode"] = "182"
    gdf["disthash"] = gdf.distname.map(hsh)

    return gdf, cities_df
