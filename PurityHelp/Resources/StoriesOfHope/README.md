# Stories of Hope

- **File name:** `stories.json`
- **Location:** `PurityHelp/Resources/StoriesOfHope/stories.json` (this folder)

The app loads this file at launch. **Categories in the app are derived from the JSON**: the app collects every unique `category` value from the stories, sorts them, and shows "All" plus those categories as filters. Add or rename categories by changing the `category` field in the JSON.

**Historical stories** (e.g. St. Mary of Egypt, Augustine, Desert Fathers, Pascal, St. Mark Ji Tianxiang) are included in `stories.json` with `"category": "Historical"`. Add or edit them here so everything lives in one place.

If the file is missing or empty, the app falls back to a small built-in set so the list is never empty.

**JSON shape (each object):**

- `id` (string)
- `title` (string)
- `category` (string): any label you want; the app uses these to build the category filter list
- `tradition` (string, optional): e.g. "Catholic", "Orthodox", "Protestant"
- `context` (string): 2–4 sentences; shown as the main summary
- `whatHelped` (string, optional): bullet list or paragraph
- `takeaway` (string)
- `source` (string, optional): attribution

After editing `stories.json`, rebuild the app so the updated file is copied into the bundle.
