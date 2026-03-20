# 6/11/2025

import geopandas as gpd
import pandas as pd
from shapely.geometry import Point
import os

# Input args
gdb = r"C:\path\to\your_geodatabase.gdb"
manholes_layer = "Manholes"
pipes_layer = "SewerLines"
output_csv = r"output_pipe_mapping.csv"
buffer_dist = 1  # meters

# Load data into memory
print("Loading manholes...")
manholes = gpd.read_file(gdb, layer=manholes_layer).to_crs(epsg=3857)
print("Loading pipes...")
pipes = gpd.read_file(gdb, layer=pipes_layer).to_crs(epsg=3857)

# Field lists — adjust to match your schema
invert_id_fields = [f"SEWER_ID_REF_{i}" for i in range(1, 7)]
invert_elev_fields = [f"MEAS_INV_{i}" for i in range(1, 7)]

mapped_ids = set()
mapped_pipes = set()
records = []

print("Buffering manholes for spatial matching...")
manholes["geometry_buffer"] = manholes.geometry.buffer(buffer_dist)


def pipe_endpoints(geom):
    """Return the start and end points of a pipe geometry."""
    if geom.geom_type == "LineString":
        return [Point(geom.coords[0]), Point(geom.coords[-1])]
    elif geom.geom_type == "MultiLineString":
        first_line = geom.geoms[0]
        last_line = geom.geoms[-1]
        return [Point(first_line.coords[0]), Point(last_line.coords[-1])]
    else:
        raise ValueError(f"Unsupported geometry type: {geom.geom_type}")


# === MAIN PROCESSING LOOP ===
print("Processing manholes and matching to pipes...")
for _, mh in manholes.iterrows():
    mh_id = mh["ManholeID"]
    mh_guid = mh["GlobalID"]
    invert_ids = [mh[f] for f in invert_id_fields]
    invert_elevs = [mh[f] for f in invert_elev_fields]

    for i, ref_id in enumerate(invert_ids):
        if not ref_id or ref_id in mapped_ids:
            continue

        nearby_pipes = pipes[pipes.intersects(mh.geometry_buffer)]
        for _, pipe in nearby_pipes.iterrows():
            pipe_guid = pipe["GlobalID"]
            if (pipe_guid, ref_id) in mapped_pipes:
                continue

            try:
                ends = pipe_endpoints(pipe.geometry)
            except Exception as e:
                print(f"Skipping pipe {pipe_guid} due to geometry error: {e}")
                continue

            match_found = False
            for end in ends:
                other_mhs = manholes[
                    (manholes["GlobalID"] != mh_guid) &
                    (manholes.geometry.distance(end) < buffer_dist)
                ]

                for _, other in other_mhs.iterrows():
                    other_ids = [other[f] for f in invert_id_fields]
                    other_elevs = [other[f] for f in invert_elev_fields]

                    try:
                        j = other_ids.index(ref_id)
                    except ValueError:
                        continue

                    elev1 = invert_elevs[i]
                    elev2 = other_elevs[j]
                    rim1 = mh["MANHOLE_ELEVATION"]
                    rim2 = other["MANHOLE_ELEVATION"]

                    if pd.isnull(elev1) or pd.isnull(elev2) or pd.isnull(rim1) or pd.isnull(rim2):
                        continue

                    depth1 = rim1 - elev1
                    depth2 = rim2 - elev2

                    # Greater depth-to-invert = downstream
                    if depth1 > depth2:
                        upstream = (mh_guid, mh_id, elev1)
                        downstream = (other["GlobalID"], other["ManholeID"], elev2)
                        upstream_depth = depth1
                        downstream_depth = depth2
                    else:
                        upstream = (other["GlobalID"], other["ManholeID"], elev2)
                        downstream = (mh_guid, mh_id, elev1)
                        upstream_depth = depth2
                        downstream_depth = depth1

                    records.append({
                        "PipeGlobalID": pipe_guid,
                        "ReferenceID": ref_id,
                        "UpstreamMH_GlobalID": upstream[0],
                        "UpstreamMH_ID": upstream[1],
                        "UpstreamInvert": upstream[2],
                        "UpstreamInvertDepth": upstream_depth,
                        "DownstreamMH_GlobalID": downstream[0],
                        "DownstreamMH_ID": downstream[1],
                        "DownstreamInvert": downstream[2],
                        "DownstreamInvertDepth": downstream_depth
                    })
                    print(f"Mapped pipe {pipe_guid} between {upstream[1]} and {downstream[1]}")
                    mapped_ids.add(ref_id)
                    mapped_pipes.add((pipe_guid, ref_id))
                    match_found = True
                    break

                if match_found:
                    break

# === OUTPUT ===
print(f"Writing {len(records)} records to CSV...")
df = pd.DataFrame(records)
df.to_csv(output_csv, index=False)
print(f"Done. Output written to: {output_csv}")