# Signal Horizon

An animated Plasma 6 wallpaper. A dark abstract seascape sits under the
real current night sky. One continuous scene spans all your monitors.

**[▶ Open the live preview](https://adirtyscoundrel.github.io/signal-horizon-wallpaper/)**
— the wallpaper runs in your browser with the real sky. Switch cities
(Toronto, New York, London, Amsterdam, Tokyo, Sydney) or view the full panorama.

![animated preview](docs/preview.gif)

## What you see

- The actual sky for your location, computed from the HYG star catalog
  (25,791 stars to magnitude 7.5). Stars rise and set with the real sky.
- The Milky Way as a soft band along the true galactic plane, with
  thousands of faint stars crowded along it.
- The planets, computed live from Keplerian orbital elements. They move
  against the stars night by night and rise and set on their own.
- A moon with a halo and a shimmering light path on the water.
- Layered mountain silhouettes, a lighthouse with a sweeping beam, a
  distant fishing boat, and sea stacks. Stars reflect in the water.
- Set the location to the Netherlands and the lighthouse becomes a Dutch
  windmill with turning sails. Try Amsterdam in the live preview.

The sky recomputes every minute. The scene animates at about 30 fps.
All monitors share one wall-clock scene, so the panorama stays in sync.

## Requirements

- KDE Plasma 6 (tested on 6.8).
- Wayland session recommended. The animation path is tuned for the
  Plasma 6 Wayland desktop.

## Install

Download the tarball from the latest release, then run:

    kpackagetool6 --type Plasma/Wallpaper --install signal-horizon-1.1.1.tar.gz

Or install from a clone of this repository:

    git clone https://github.com/aDirtyScoundrel/signal-horizon-wallpaper.git
    kpackagetool6 --type Plasma/Wallpaper --install signal-horizon-wallpaper

Then right-click the desktop, choose "Configure Desktop and Wallpaper",
and select "Signal Horizon".

To upgrade an existing install, use `--upgrade` instead of `--install`.

## Configure

Open `contents/ui/main.qml` in the installed package
(`~/.local/share/plasma/wallpapers/dev.hadaly.signalhorizon/`).

- `lat` and `lon`: your observer location. Default is Toronto
  (43.6532, -79.3832). Set these for your city so the sky matches.
- `hue`: accent colour, 0-360. Default 210 (cold silver-blue).
- `speed`: animation speed multiplier. Default 1.
- `intensity`: glow and shimmer strength. Default 1.

After an edit, restart plasmashell or re-select the wallpaper:

    systemctl --user restart plasma-plasmashell.service

The scene adapts to any monitor layout. The panorama width comes from
your actual screen arrangement, and each monitor shows its slice.

## Data sources

- Star positions: HYG Database v4.1 (astronexus/HYG-Database),
  CC BY-SA 4.0. The bundled `stars.js` is a derived work.
- Milky Way band and scatter: generated along the galactic equator.
- Planetary elements: JPL approximate Keplerian elements (public domain).

## License

Code: MIT. Star data in `contents/ui/stars.js`: CC BY-SA 4.0.