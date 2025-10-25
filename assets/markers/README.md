# Marker Images

The app uses the following SVG images for custom markers:

- `person.svg`: Icon for user location (person silhouette)
- `ambulance.svg`: Icon for ambulance locations
- `hospital.svg`: Icon for hospital locations

These SVG files are loaded at runtime and converted to bitmap for use as Google Maps markers.

If SVG loading fails, the app falls back to default colored markers:
- Person: Blue marker
- Ambulance: Green marker
- Hospital: Red marker