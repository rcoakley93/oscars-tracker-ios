# Creative assets (iOS 27, P6-17)

Optional App Store creative assets, shown on iOS and iPadOS 27 and later. We use **one universal asset** for both the product page header and search results, so the brand reads the same in both places (Apple's suggestion). Made by `scripts/frame-store-images.py --creative` from the iphone-6.9 raw shots (`-sample-data -store-shots`). **Final (Oct 25): upload `universal.png`.** The user uploads it in App Store Connect: the version's Product Page Information → Header and Search Results → Header, then tick **Use header asset in search results**.

| File | What | Size |
|---|---|---|
| `universal.png` | The logo, "Track every nominee. Beat your friends.", and the real Films tab | 5244 × 2950, 16:9, PNG |
| `universal-wordmark.png` | **Fallback only:** the same, with the name in Playfair in place of the logo, if App Review objects to the logo under guideline 5.2.1 | same |

- **Size and format:** Apple's [Creative assets specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications). The universal asset is exactly 5244 × 2950 and must be PNG with no alpha. Checked Oct 25, 2026.
- **Safe area:** 1402 × 962 at x 1921, y 660 (x 1921–3323, y 660–1622), centred across and above centre. Apple's spec page doesn't print it; this is the art-safe layer of Apple's universal template as measured by others. The logo, the line and the phone all sit inside it, and outside it is only velvet, so the wide header crop and the 3:2 search crop show the same thing. Check it in App Store Connect's **Preview** (iPhone and iPad, both orientations) before you submit.
- The safe area is close to 3:2, so in search results (about 365 pt wide on an iPhone) the content fills the tile and the line reads at about 23 pt.
- **Fallback, if Preview shows a crop that doesn't work:** dedicated assets, a header at 3840 × 1646 (21:9, safe x 1097–2743, y 493–1154) and search results at 3840 × 2560 (3:2, safe x 836–3004, y 765–1795).
- **Logo:** `BrandLogo` has a statuette silhouette inside the film reel. The user accepts it (Oct 25), consistent with the app icon; `universal-wordmark.png` is kept in case App Review objects under 5.2.1.
- Not uploaded.
