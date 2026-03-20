from arcgis.gis import GIS
import re

# ---------------- CONFIG ----------------
DRY_RUN = False  # True = print changes only, False = actually update the web map
GROUP_NAME = "Your Group Name"  # Replace with a group name, or set to None to process all web maps in the org
# ---------------------------------------


# Connect to your organization
gis = GIS("https://your-org.maps.arcgis.com/home", "your_username", "your_password")

# ---------------- HELPERS ----------------
def get_item_from_url_or_title(service_url):
    """
    Return (itemId, canonical_service_url).
    Attempts URL match first, then falls back to matching by service title.
    """
    if not service_url:
        return None, None

    base_url = service_url.rstrip('/')

    # Strip trailing layer index (e.g. /0, /1)
    if base_url.split('/')[-1].isdigit():
        base_url = '/'.join(base_url.split('/')[:-1])

    # ---- URL search ----
    items = gis.content.search(
        query=f'url:"{base_url}"',
        item_type="Feature Service",
        max_items=1
    )
    if items:
        item = items[0]
        return item.id, item.url

    # ---- Title fallback ----
    match = re.search(
        r'/services/([^/]+)/(MapServer|FeatureServer)',
        base_url,
        re.IGNORECASE
    )
    if match:
        service_title = match.group(1)
        items_by_title = gis.content.search(
            query=f'title:"{service_title}"',
            item_type="Feature Service",
            max_items=1
        )
        if items_by_title:
            item = items_by_title[0]
            print(f"  [WARNING] URL search failed, matched by title: {service_title}")
            return item.id, item.url

    print(f"  [ERROR] Could not resolve item for URL/title: {service_url}")
    return None, None


def item_exists(itemid):
    """Check if an item exists in AGO."""
    try:
        return gis.content.get(itemid) is not None
    except Exception:
        return False


def process_layer(layer, changed):
    """Recursively validate and fix itemId + URL for layers and group layers."""
    current_itemid = layer.get("itemId")
    original_url = layer.get("url")

    if current_itemid:
        if item_exists(current_itemid):
            print(f"Layer itemId valid: {layer.get('title', 'Unnamed Layer')} -> {current_itemid}")
        else:
            print(f"Layer itemId invalid: {layer.get('title', 'Unnamed Layer')} -> {current_itemid}")

            new_itemid, new_url = get_item_from_url_or_title(original_url)
            if new_itemid:
                layer["itemId"] = new_itemid
                if new_url:
                    # Preserve layer index if present
                    layer_index_match = None
                    if original_url:
                        m = re.search(r"/(\d+)$", original_url.rstrip('/'))
                        if m:
                            layer_index_match = m.group(1)
                    if layer_index_match:
                        layer["url"] = f"{new_url.rstrip('/')}/{layer_index_match}"
                    else:
                        layer["url"] = new_url
                    print("  [UPDATED] Updated layer URL to canonical service URL (with layer index if present)")
                changed = True
                print(f"  [OK] Corrected layer itemId to {new_itemid}")
            else:
                print("  [ERROR] Could not fix layer via URL or title")

    # Recurse into group layers
    if "layers" in layer:
        for sublayer in layer["layers"]:
            changed = process_layer(sublayer, changed)

    # Recurse into tables inside group layers
    if "tables" in layer:
        for table in layer["tables"]:
            current_itemid = table.get("itemId")
            original_url = table.get("url")
            if current_itemid:
                if item_exists(current_itemid):
                    print(f"Table itemId valid: {table.get('title', 'Unnamed Table')} -> {current_itemid}")
                else:
                    print(f"Table itemId invalid: {table.get('title', 'Unnamed Table')} -> {current_itemid}")

                    new_itemid, new_url = get_item_from_url_or_title(original_url)
                    if new_itemid:
                        table["itemId"] = new_itemid
                        if new_url:
                            table_index_match = None
                            if original_url:
                                m = re.search(r"/(\d+)$", original_url.rstrip('/'))
                                if m:
                                    table_index_match = m.group(1)
                            if table_index_match:
                                table["url"] = f"{new_url.rstrip('/')}/{table_index_match}"
                            else:
                                table["url"] = new_url
                            print("  [UPDATED] Updated table URL to canonical service URL (with table index if present)")
                        changed = True
                        print(f"  [OK] Corrected table itemId to {new_itemid}")
                    else:
                        print("  [ERROR] Could not fix table via URL or title")

    return changed


# ---------------- MAIN ----------------
if GROUP_NAME:
    groups = gis.groups.search(query=GROUP_NAME, max_groups=1)
    if not groups:
        print(f"No group found with name '{GROUP_NAME}'")
        exit()
    group = groups[0]
    print(f"Processing web maps in group: {group.title} ({group.id})")
    webmaps = [i for i in group.content() if i.type == "Web Map"]
else:
    print("Processing all web maps in the organization")
    webmaps = gis.content.search(query='type:"Web Map"', max_items=10000)

if not webmaps:
    print("No web maps found.")
    exit()

for wm in webmaps:
    if "(prod)" in wm.title.lower():
        print(f"Skipping web map (prod): {wm.title}")
        continue

    print(f"\nProcessing web map: {wm.title} ({wm.id})")
    data = wm.get_data()
    changed = False

    # Operational layers
    if "operationalLayers" in data:
        for layer in data["operationalLayers"]:
            changed = process_layer(layer, changed)

    # Top-level tables
    if "tables" in data:
        for table in data["tables"]:
            current_itemid = table.get("itemId")
            if current_itemid:
                if item_exists(current_itemid):
                    print(f"Table itemId valid: {table.get('title', 'Unnamed Table')} -> {current_itemid}")
                else:
                    print(f"Table itemId invalid: {table.get('title', 'Unnamed Table')} -> {current_itemid}")

                    new_itemid, new_url = get_item_from_url_or_title(table.get("url"))
                    if new_itemid:
                        table["itemId"] = new_itemid
                        if new_url:
                            table["url"] = new_url
                            print("  [UPDATED] Updated table URL to canonical service URL")
                        changed = True
                        print(f"  [OK] Corrected table itemId to {new_itemid}")
                    else:
                        print("  [ERROR] Could not fix table via URL or title")

    # Apply update
    if changed:
        if DRY_RUN:
            print("[WARNING] Changes detected but DRY_RUN=True -- no update applied")
        else:
            wm.update(data=data)
            print(f"[OK] Updated web map: {wm.title}")
    else:
        print("No changes needed.")