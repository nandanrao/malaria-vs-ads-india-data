import geopandas as gpd

from clusters.shapes import make_clusters, prep_dists

if __name__ == "__main__":
    cities = gpd.read_file("raw/geography/Cities_India/cities_towns_suburbs.shp")
    districts = gpd.read_file(
        "raw/geography/Districts+Demographics_India/Demographics_of_India.shp"
    )

    states = ["Jharkhand", "Chhatisgarh", "Uttar Pradesh"]
    capitols = ["Lucknow", "Ranchi", "Raipur", "Khordha"]

    # Split geos to make one row per polygon
    dists = prep_dists(districts, states, capitols)
    cities = cities.to_crs(3857)

    dists.to_file("final/geography/districts.shp")

    dd, df = make_clusters(cities, dists, 2000)

    df.to_csv("final/geography/base-cities.csv", index=False)

    dd.to_file("final/geography/cluster.shp")
