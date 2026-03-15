# Script 3 - Update Views / Joined Views with sourceSchemaChangesAllowed = True
#
# This script finds all Feature Service views in an ArcGIS Online organization
# that reference a specific source Hosted Feature Layer (HFL), then sets
# sourceSchemaChangesAllowed to True on each of them.
#
# This is necessary when you need to push schema changes (e.g. new fields)
# from a source HFL down to its dependent views without breaking them.
#
# Intended to be run inside an ArcGIS Online Notebook environment, where
# GIS("home") automatically uses the current signed-in credentials.

from arcgis.gis import GIS
from arcgis.features import FeatureLayerCollection

# ── Connect to ArcGIS Online ──────────────────────────────────────────────────
# "home" uses the current notebook session's credentials.
# Note: ensure you are signed in with an account that has admin rights —
# updating view definitions requires administrative privileges.
gis = GIS("home")

# ── Configuration ─────────────────────────────────────────────────────────────
# Set this to the Item ID of the source HFL whose views you want to update.
source_item_id = "0b83556135ac421f8b89495208b6edee"

# ── Step 1: Get all views in the organization ─────────────────────────────────
# Query for all Feature Services flagged as View Services.
# max_items=1000 is the AGO API cap per request — increase pagination logic
# if your org has more than 1000 views.
all_views = gis.content.search(
    query='type:"Feature Service" AND typekeywords:"View Service"',
    max_items=1000
)

# ── Step 2: Find views that reference the source HFL ─────────────────────────
# Each view can have one or more related source items (joined views have two).
# We walk the Service2Data relationship for every view and collect any that
# reference our target source_item_id.
matching_view_ids = []

for view in all_views:
    try:
        related = view.related_items(rel_type="Service2Data")
        for item in related:
            if item.id == source_item_id:
                matching_view_ids.append(view.id)
                break  # No need to check further sources for this view
    except Exception as e:
        print(f"Error checking view {view.id}: {e}")

# ── Step 3: Report which views were found ─────────────────────────────────────
print(f"\nViews that reference source item {source_item_id}:")
for vid in matching_view_ids:
    print(f"  {vid}")

if not matching_view_ids:
    print("  None found. Check that the source_item_id is correct.")

# ── Step 4: Set sourceSchemaChangesAllowed = True on each view ────────────────
# update_definition() patches the service definition JSON on the REST endpoint.
# Setting sourceSchemaChangesAllowed to True tells AGO to allow the view's
# schema to be updated when the source layer's schema changes.
for vid in matching_view_ids:
    try:
        view_item = gis.content.get(vid)
        flc = FeatureLayerCollection.fromitem(view_item)

        update_result = flc.manager.update_definition({
            "sourceSchemaChangesAllowed": True
        })

        print(f"Updated {vid}: {update_result}")

    except Exception as e:
        print(f"Failed to update {vid}: {e}")
