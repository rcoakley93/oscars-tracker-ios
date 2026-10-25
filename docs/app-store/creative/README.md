# Creative assets (iOS 27, P6-17)

Optional App Store creative assets, shown on iOS and iPadOS 27 and later. **Header = `universal.png`, search results = `search.png`.** The user approved the universal asset as the product page header (Oct 25), but at search-card size its centre-safe art was too small to read, so search results gets a dedicated asset. All of them are made by `scripts/frame-store-images.py --creative` from the iphone-6.9 raw shots (`-sample-data -store-shots`). The PM uploads them in App Store Connect once the user approves: the version's Product Page Information → **Header** gets `universal.png`, and **Search Results** gets `search.png`, with **Use header asset in search results** left unticked.

| File | What | Size |
|---|---|---|
| `universal.png` | **Header.** The logo, "Track every nominee. Beat your friends.", and the real Films tab, all in the centre safe area | 5244 × 2950, 16:9, PNG |
| `universal-wordmark.png` | **Fallback only:** the same, with the name in Playfair in place of the logo | same |
| `search.png` | **Search results.** "Track every nominee. Beat your friends." large on the left (about 9% of the height) under the logo, a big phone with the real Films tab on the right, bleeding off the bottom | 3840 × 2560, 3:2, PNG |
| `search-wordmark.png` | **Fallback only:** the same, with "Oscars Tracker" in Playfair in place of the logo | same |

- **Size and format:** Apple's [Creative assets specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications). PNG with no alpha. The universal asset is 5244 × 2950; App Store Connect takes a search results asset at 5244 × 2950, 3840 × 2560 or 1920 × 1280, and we use 3840 × 2560. Checked Oct 25, 2026.
- **Header safe area:** 1402 × 962 at x 1921, y 660 (x 1921–3323, y 660–1622), centred across and above centre. Apple's spec page doesn't print it; this is the art-safe layer of Apple's universal template as measured by others. The logo, the line and the phone all sit inside it, and outside it is only velvet.
- **Search results layout:** the search card shows about a 16:9 band across the middle of the 3:2 asset, so the logo and headline sit inside y 200–2360 and the phone's header, progress card and posters fall in that band too. It reads at 520 px wide (the card's size). Check it in App Store Connect's **Preview** (iPhone and iPad) before you submit.
- **Logo:** `BrandLogo` has a statuette silhouette inside the film reel. The user accepts it (Oct 25), consistent with the app icon; the `-wordmark` fallbacks are kept in case App Review objects under guideline 5.2.1.
- Apple's asset best practices: no prices, URLs, awards or marketplace logos; sample data only; suitable for 4+.
- Not uploaded.
