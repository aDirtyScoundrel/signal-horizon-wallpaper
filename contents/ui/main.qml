import QtQuick
import org.kde.plasma.plasmoid
import "stars.js" as StarsData

WallpaperItem {
    id: root

    // Observer location (default: Toronto). Change for your city.
    property real lat: 43.6532
    property real lon: -79.3832

    // Scene tuning.
    property real hue: 210
    property real speed: 1
    property real intensity: 1

    property real sliceX: -1
    property real totalW: 7680
    property real sceneTime: 0
    property var starPts: []
    property var faintPts: []
    property var mwPts: []
    property var planetPts: []

    function screenWidth() {
        var s = Qt.application.screens;
        var w = 0;
        for (var i = 0; i < s.length; i++) {
            w = Math.max(w, s[i].virtualX + s[i].width);
        }
        return Math.max(w, 1920);
    }

    // Real current sky for the observer location. HYG catalog to mag 7.5,
    // Milky Way galactic plane, and JPL approximate planetary elements.
    // Recomputed every minute so the wallpaper tracks the actual sky.
    function computeSky() {
        var D2R = Math.PI / 180;
        var jd = Date.now() / 86400000 + 2440587.5;
        var gmst = (280.46061837 + 360.98564736629 * (jd - 2451545.0)) % 360;
        var lst = (gmst + root.lon) % 360;
        if (lst < 0) lst += 360;
        var latR = root.lat * D2R;
        var TW = root.totalW;
        var skyH = root.height * 0.66 * 0.92;

        function toScreen(raH, decD) {
            var ha = ((lst - raH * 15) % 360) * D2R;
            if (ha < 0) ha += 2 * Math.PI;
            var dec = decD * D2R;
            var alt = Math.asin(Math.sin(dec) * Math.sin(latR)
                      + Math.cos(dec) * Math.cos(latR) * Math.cos(ha));
            if (!isFinite(alt) || alt < 0.017) return null;
            var az = Math.atan2(Math.sin(ha),
                     Math.cos(ha) * Math.sin(latR) - Math.tan(dec) * Math.cos(latR));
            az = (az / D2R + 180) % 360;
            return { x: az / 360 * TW, y: skyH * (1 - alt / (Math.PI / 2)) };
        }

        var bright = [], faint = [];
        var S = StarsData.STARS;
        for (var i = 0; i < S.length; i++) {
            var mg = S[i][2];
            var p = toScreen(S[i][0], S[i][1]);
            if (!p) continue;
            if (mg <= 5.0) {
                bright.push({
                    x: p.x, y: p.y,
                    r: Math.max(0.5, 2.3 - 0.38 * mg),
                    a: Math.min(0.95, Math.max(0.18, 0.85 - 0.13 * mg)),
                    m: mg, ph: i * 0.7
                });
            } else {
                faint.push({
                    x: p.x, y: p.y,
                    r: Math.max(0.7, 2.0 - 0.14 * mg),
                    a: Math.max(0.35, 0.8 - 0.06 * mg)
                });
            }
        }
        var MW = StarsData.MW_STARS;
        for (var m = 0; m < MW.length; m++) {
            var pm = toScreen(MW[m][0], MW[m][1]);
            if (!pm) continue;
            faint.push({ x: pm.x, y: pm.y, r: 0.9, a: Math.max(0.4, 0.85 - 0.06 * MW[m][2]) });
        }
        var band = [];
        var MB = StarsData.MW_BAND;
        for (var b = 0; b < MB.length; b++) {
            var pb = toScreen(MB[b][0], MB[b][1]);
            if (!pb) continue;
            band.push({ x: pb.x, y: pb.y, I: MB[b][2] });
        }

        // Planets: Keplerian heliocentric -> geocentric -> equatorial.
        var T = (jd - 2451545.0) / 36525.0;
        function helio(el) {
            var a = el[0][0] + el[0][1] * T;
            var e = el[1][0] + el[1][1] * T;
            var I = (el[2][0] + el[2][1] * T) * D2R;
            var L = el[3][0] + el[3][1] * T;
            var lp = el[4][0] + el[4][1] * T;
            var Om = (el[5][0] + el[5][1] * T) * D2R;
            var w = lp * D2R - Om;
            var M = ((L - lp) % 360) * D2R;
            var E = M;
            for (var it = 0; it < 6; it++) E = M + e * Math.sin(E);
            var xp = a * (Math.cos(E) - e);
            var yp = a * Math.sqrt(1 - e * e) * Math.sin(E);
            var cw = Math.cos(w), sw = Math.sin(w);
            var cO = Math.cos(Om), sO = Math.sin(Om);
            var cI = Math.cos(I), sI = Math.sin(I);
            return [
                (cw * cO - sw * sO * cI) * xp + (-sw * cO - cw * sO * cI) * yp,
                (cw * sO + sw * cO * cI) * xp + (-sw * sO + cw * cO * cI) * yp,
                (sw * sI) * xp + (cw * sI) * yp
            ];
        }
        var earth = helio(StarsData.EARTH);
        var eps = 23.43928 * D2R;
        var planets = [];
        var PL = StarsData.PLANETS;
        for (var pi = 0; pi < PL.length; pi++) {
            var h = helio(PL[pi][1]);
            var x = h[0] - earth[0], y = h[1] - earth[1], z = h[2] - earth[2];
            var lam = Math.atan2(y, x);
            var beta = Math.atan2(z, Math.sqrt(x * x + y * y));
            var ra = Math.atan2(Math.sin(lam) * Math.cos(eps) - Math.tan(beta) * Math.sin(eps), Math.cos(lam));
            var dec = Math.asin(Math.sin(beta) * Math.cos(eps) + Math.cos(beta) * Math.sin(eps) * Math.cos(lam));
            var pp = toScreen((ra / D2R % 360 + 360) % 360 / 15, dec / D2R);
            if (!pp) continue;
            var pmg = PL[pi][2];
            planets.push({
                x: pp.x, y: pp.y,
                r: Math.min(3.6, Math.max(1.1, 2.3 - 0.2 * pmg)),
                a: Math.min(0.95, Math.max(0.22, 0.85 - 0.13 * pmg)),
                m: pmg, ph: pi * 1.3, name: PL[pi][0]
            });
        }

        root.starPts = bright;
        root.faintPts = faint;
        root.mwPts = band;
        root.planetPts = planets;
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.computeSky()
    }

    function updateSlice() {
        root.totalW = screenWidth();
        var p = root.mapToGlobal(Qt.point(0, 0));
        var x = Math.round(p.x);
        var maxX = Math.max(0, root.totalW - root.width);
        if (x < 0) x = 0;
        if (x > maxX) x = maxX;
        root.sliceX = x;
    }

    Component.onCompleted: { updateSlice(); computeSky(); }
    onWidthChanged: updateSlice()
    onHeightChanged: updateSlice()

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: root.updateSlice()
    }

    Image {
        id: noiseTile
        source: "noise_tile.png"
        visible: false
        cache: true
    }

    // Abstract dark seascape under the real sky: pointed summits,
    // shimmering sea, lighthouse, boat, sea stacks. Canvas is the
    // animation path that submits frames on Plasma 6 Wayland.
    Canvas {
        id: cv
        anchors.fill: parent
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Threaded

        onPaint: {
            var ctx = getContext("2d");
            var W = width, H = height;
            var t = root.sceneTime;
            var mx = Math.max(0, root.sliceX);
            var sp = root.speed;
            var inten = root.intensity;
            var TOTAL_W = root.totalW;
            var seaLine = H * 0.66;

            function hash(n) {
                var x = Math.sin(n * 127.1 + 311.7) * 43758.5453;
                return x - Math.floor(x);
            }
            function hsl(h, s, l, a) {
                return "hsla(" + h + "," + s + "%," + l + "%," + a + ")";
            }

            // --- Sky: near-black navy gradient. ---
            var sky = ctx.createLinearGradient(0, 0, 0, seaLine);
            sky.addColorStop(0, "#03040a");
            sky.addColorStop(0.6, "#070b16");
            sky.addColorStop(1, "#0c1220");
            ctx.fillStyle = sky;
            ctx.fillRect(0, 0, W, seaLine);

            // Dither the sky gradient only (breaks 8-bit banding, keeps
            // stars and structures crisp).
            var nox = -(mx % 128);
            for (var nx = nox; nx < W; nx += 128) {
                for (var ny = 0; ny < seaLine; ny += 128) {
                    ctx.drawImage(noiseTile, nx, ny);
                }
            }

            // Faint cold glow behind the peaks, breathing slowly.
            var glowX = TOTAL_W * 0.585 - mx;
            var breathe = 0.75 + 0.25 * Math.sin(t * 0.1 * sp);
            if (glowX > -600 && glowX < W + 600) {
                var rg = ctx.createRadialGradient(glowX, seaLine * 0.62, 10, glowX, seaLine * 0.62, 560);
                rg.addColorStop(0, hsl(root.hue, 30, 60, 0.05 * inten * breathe));
                rg.addColorStop(1, hsl(root.hue, 30, 60, 0));
                ctx.fillStyle = rg;
                ctx.fillRect(glowX - 560, seaLine * 0.62 - 560, 1120, 1120);
            }

            // --- Moon: pale disc with a soft halo, upper sky. ---
            var moonY = seaLine * 0.32;
            if (glowX > -320 && glowX < W + 320) {
                var halo = ctx.createRadialGradient(glowX, moonY, 20, glowX, moonY, 300);
                halo.addColorStop(0, hsl(root.hue, 25, 85, 0.12 * inten * breathe));
                halo.addColorStop(0.4, hsl(root.hue, 25, 85, 0.045 * inten * breathe));
                halo.addColorStop(1, hsl(root.hue, 25, 85, 0));
                ctx.fillStyle = halo;
                ctx.fillRect(glowX - 300, moonY - 300, 600, 600);

                var disc = ctx.createRadialGradient(glowX - 10, moonY - 10, 4, glowX, moonY, 46);
                disc.addColorStop(0, "rgba(236,240,248,0.95)");
                disc.addColorStop(0.75, "rgba(214,222,236,0.9)");
                disc.addColorStop(0.96, "rgba(190,200,220,0.75)");
                disc.addColorStop(1, "rgba(180,192,214,0)");
                ctx.fillStyle = disc;
                ctx.beginPath();
                ctx.arc(glowX, moonY, 46, 0, 6.2832);
                ctx.fill();
            }

            // --- Milky Way: soft glow along the real galactic plane. ---
            ctx.save();
            ctx.beginPath();
            ctx.rect(0, 0, W, seaLine * 0.96);
            ctx.clip();
            ctx.globalCompositeOperation = "lighter";
            var mw = root.mwPts;
            for (var mi = 0; mi < mw.length; mi++) {
                var mp = mw[mi];
                var mlx = mp.x - mx;
                if (mlx < -160 || mlx > W + 160) continue;
                var stretch = 1 + Math.max(0, (160 - mp.y)) / 160 * 1.4;
                var rad = 70 * stretch;
                var ma = 0.06 * mp.I * inten;
                var mg = ctx.createRadialGradient(mlx, mp.y, 3, mlx, mp.y, rad);
                mg.addColorStop(0, hsl(root.hue, 15, 78, ma.toFixed(3)));
                mg.addColorStop(1, hsl(root.hue, 15, 78, 0));
                ctx.fillStyle = mg;
                ctx.fillRect(mlx - rad, mp.y - rad, rad * 2, rad * 2);
                var radc = 30 * stretch;
                var mc = ctx.createRadialGradient(mlx, mp.y, 1, mlx, mp.y, radc);
                mc.addColorStop(0, hsl(root.hue, 12, 85, (0.05 * mp.I * inten).toFixed(3)));
                mc.addColorStop(1, hsl(root.hue, 12, 85, 0));
                ctx.fillStyle = mc;
                ctx.fillRect(mlx - radc, mp.y - radc, radc * 2, radc * 2);
            }
            ctx.restore();

            // --- Faint stars (mag 5-7.5 + Milky Way scatter). ---
            var fp = root.faintPts;
            for (var fi = 0; fi < fp.length; fi++) {
                var fpt = fp[fi];
                var fx = fpt.x - mx;
                if (fx < -2 || fx > W + 2) continue;
                ctx.fillStyle = "rgba(200,212,235," + fpt.a.toFixed(3) + ")";
                ctx.fillRect(fx - fpt.r, fpt.y - fpt.r, fpt.r * 2, fpt.r * 2);
            }

            // --- Bright stars: the real current sky. ---
            ctx.save();
            ctx.beginPath();
            ctx.rect(0, 0, W, seaLine * 0.96);
            ctx.clip();
            var pts = root.starPts;
            for (var s = 0; s < pts.length; s++) {
                var st2 = pts[s];
                var sx3 = st2.x - mx;
                if (sx3 < -4 || sx3 > W + 4) continue;
                var twk = 0.85 + 0.15 * Math.sin(t * (0.25 + (st2.ph % 1) * 0.5) * sp + st2.ph);
                ctx.fillStyle = "rgba(225,232,250," + (st2.a * twk).toFixed(3) + ")";
                ctx.beginPath();
                ctx.arc(sx3, st2.y, st2.r, 0, 6.2832);
                ctx.fill();
            }
            // Planets: steady light (no twinkle), small halo.
            var pl = root.planetPts;
            for (var pli = 0; pli < pl.length; pli++) {
                var plp = pl[pli];
                var plx = plp.x - mx;
                if (plx < -12 || plx > W + 12) continue;
                var phg = ctx.createRadialGradient(plx, plp.y, 0.5, plx, plp.y, plp.r * 4);
                phg.addColorStop(0, "rgba(240,238,228," + (0.10 * plp.a).toFixed(3) + ")");
                phg.addColorStop(1, "rgba(240,238,228,0)");
                ctx.fillStyle = phg;
                ctx.fillRect(plx - plp.r * 4, plp.y - plp.r * 4, plp.r * 8, plp.r * 8);
                ctx.fillStyle = "rgba(242,240,232," + plp.a + ")";
                ctx.beginPath();
                ctx.arc(plx, plp.y, plp.r, 0, 6.2832);
                ctx.fill();
            }
            ctx.restore();

            // --- Mountains: a few distinct asymmetric summits per monitor,
            // balanced but not mirrored. ---
            var peaks = [];
            var nP = 7;
            for (var pi = 0; pi < nP; pi++) {
                var cxp = (pi + 0.5) * (TOTAL_W / nP) + (hash(pi * 53 + 200) - 0.5) * 600;
                var hp = 0.55 + hash(pi * 59 + 201) * 0.45;
                var wp = 380 + hash(pi * 61 + 202) * 320;
                var asym = 0.7 + hash(pi * 67 + 203) * 0.7;
                peaks.push({ cx: cxp, h: hp, w: wp, a: asym });
            }
            function ridge(gx, layer) {
                var v = 0.012 * Math.sin(gx * 0.0004 + layer * 2.2);
                var shift = layer * 140 - 140;
                for (var q = 0; q < peaks.length; q++) {
                    var pk = peaks[q];
                    var d = gx - (pk.cx + shift);
                    var w = d < 0 ? pk.w * pk.a : pk.w;
                    var ad = Math.abs(d);
                    if (ad < w) {
                        var u = 1 - ad / w;
                        v += pk.h * Math.pow(u, 0.75) * (1 - layer * 0.12);
                    }
                }
                return v - 0.2;
            }
            var layers = [
                { base: 0.52, amp: 0.30, col: "#101827", haze: 0.05 },
                { base: 0.58, amp: 0.24, col: "#0a0f1c", haze: 0.03 },
                { base: 0.64, amp: 0.16, col: "#05080f", haze: 0.0 }
            ];
            var step = 12;
            for (var L = 0; L < 3; L++) {
                var ly = layers[L];
                ctx.beginPath();
                ctx.moveTo(-step, seaLine + 2);
                for (var x2 = -step; x2 <= W + step; x2 += step) {
                    var gx2 = x2 + mx;
                    var y2 = H * ly.base - H * ly.amp * ridge(gx2, L);
                    ctx.lineTo(x2, y2);
                }
                ctx.lineTo(W + step, seaLine + 2);
                ctx.closePath();
                ctx.fillStyle = ly.col;
                ctx.fill();
                if (ly.haze > 0) {
                    ctx.save();
                    ctx.globalCompositeOperation = "lighter";
                    var hz = ctx.createLinearGradient(0, H * (ly.base - ly.amp), 0, H * ly.base);
                    hz.addColorStop(0, hsl(root.hue, 25, 55, 0));
                    hz.addColorStop(1, hsl(root.hue, 25, 55, ly.haze * inten));
                    ctx.fillStyle = hz;
                    ctx.fillRect(0, H * (ly.base - ly.amp), W, H * ly.amp);
                    ctx.restore();
                }
            }

            // --- Sea: dark gradient + abstract shimmer. ---
            var sea = ctx.createLinearGradient(0, seaLine, 0, H);
            sea.addColorStop(0, "#0d1526");
            sea.addColorStop(0.4, "#091020");
            sea.addColorStop(1, "#050a14");
            ctx.fillStyle = sea;
            ctx.fillRect(0, seaLine, W, H - seaLine);
            for (var nx2 = nox; nx2 < W; nx2 += 128) {
                for (var ny2 = seaLine; ny2 < H; ny2 += 128) {
                    ctx.drawImage(noiseTile, nx2, ny2);
                }
            }

            // --- Star/planet reflections: mirrored across the sea line,
            // compressed, softened, gently wobbling. ---
            ctx.save();
            ctx.beginPath();
            ctx.rect(0, seaLine, W, H - seaLine);
            ctx.clip();
            var comp = 0.45;
            var seaDepthR = H - seaLine;
            var refl = pts.concat(pl);
            for (var r = 0; r < refl.length; r++) {
                var ptR = refl[r];
                if (ptR.m > 3.2) continue;
                var lxR = ptR.x - mx + Math.sin(t * 0.4 * sp + ptR.ph) * 2.5;
                var dyR = seaLine + (seaLine - ptR.y) * comp;
                if (lxR < -8 || lxR > W + 8 || dyR > H + 8) continue;
                var fadeR = 1 - (dyR - seaLine) / seaDepthR;
                var twR = 0.85 + 0.15 * Math.sin(t * 0.3 * sp + ptR.ph);
                var aR = ptR.a * 0.18 * fadeR * twR * inten;
                var radR = ptR.r * 1.8 + 1.2;
                var rgR = ctx.createRadialGradient(lxR, dyR, 0.3, lxR, dyR, radR);
                rgR.addColorStop(0, "rgba(215,226,250," + aR.toFixed(3) + ")");
                rgR.addColorStop(1, "rgba(215,226,250,0)");
                ctx.fillStyle = rgR;
                ctx.beginPath();
                ctx.arc(lxR, dyR, radR, 0, 6.2832);
                ctx.fill();
            }
            ctx.restore();

            ctx.save();
            ctx.globalCompositeOperation = "lighter";
            // Thin horizon light line.
            var hl = ctx.createLinearGradient(0, seaLine - 3, 0, seaLine + 5);
            hl.addColorStop(0, hsl(root.hue, 30, 65, 0));
            hl.addColorStop(0.5, hsl(root.hue, 30, 65, 0.07 * inten * breathe));
            hl.addColorStop(1, hsl(root.hue, 30, 65, 0));
            ctx.fillStyle = hl;
            ctx.fillRect(0, seaLine - 3, W, 8);

            // Moonlight path: tapered soft glow plus broken shimmer streaks.
            if (glowX > -300 && glowX < W + 300) {
                var seaDepth = H - seaLine;
                for (var pass = 0; pass < 3; pass++) {
                    var wTop = 90 + pass * 70;
                    var wBot = 260 + pass * 110;
                    var aPass = (0.045 - pass * 0.013) * inten * breathe;
                    ctx.beginPath();
                    ctx.moveTo(glowX - wTop / 2, seaLine);
                    ctx.lineTo(glowX + wTop / 2, seaLine);
                    ctx.lineTo(glowX + wBot / 2, H);
                    ctx.lineTo(glowX - wBot / 2, H);
                    ctx.closePath();
                    var rg2 = ctx.createLinearGradient(0, seaLine, 0, H);
                    rg2.addColorStop(0, hsl(root.hue, 25, 65, aPass.toFixed(3)));
                    rg2.addColorStop(1, hsl(root.hue, 25, 65, 0));
                    ctx.fillStyle = rg2;
                    ctx.fill();
                }
                for (var g = 0; g < 44; g++) {
                    var hg1 = hash(g * 29 + 130);
                    var hg2 = hash(g * 31 + 131);
                    var hg3 = hash(g * 37 + 132);
                    var gyg = seaLine + 4 + hg1 * (seaDepth - 8);
                    var depth = (gyg - seaLine) / seaDepth;
                    var spread = 40 + depth * 200;
                    var gxg = glowX + (hg2 - 0.5) * spread;
                    var lg = 14 + hg3 * 70 * (0.4 + depth);
                    var oscg = 0.5 + 0.5 * Math.sin(t * (0.25 + hg3 * 0.5) * sp + g * 2.1);
                    var ag = (0.03 + 0.09 * oscg) * inten * breathe * (1 - depth * 0.55);
                    ctx.fillStyle = hsl(root.hue, 20, 78, ag.toFixed(3));
                    ctx.fillRect(gxg - lg / 2, gyg, lg, 1.3);
                }
            }

            // Horizontal shimmer streaks.
            var seaDrift = t * 2.0 * sp;
            for (var c = 0; c < 130; c++) {
                var h1 = hash(c * 17 + 90);
                var h2 = hash(c * 19 + 91);
                var h3 = hash(c * 23 + 92);
                var gy2 = seaLine + 6 + h1 * (H - seaLine - 12);
                var len = 26 + h2 * 170;
                var gx3 = (h3 * TOTAL_W + seaDrift * (0.4 + h2)) % TOTAL_W;
                var lx3 = gx3 - mx;
                if (lx3 < -len || lx3 > W + len) continue;
                var osc = 0.5 + 0.5 * Math.sin(t * (0.2 + h2 * 0.4) * sp + c * 1.7);
                var depthFade = 1 - (gy2 - seaLine) / (H - seaLine);
                var ac = (0.02 + 0.06 * osc) * inten * (0.35 + 0.65 * depthFade);
                ctx.fillStyle = hsl(root.hue, 22, 70, ac.toFixed(3));
                ctx.fillRect(lx3, gy2, len, 1.2);
            }
            ctx.restore();

            // --- Lighthouse on a headland left of center: balances the moon. ---
            var lhX = TOTAL_W * 0.397 - mx;
            if (lhX > -400 && lhX < W + 400) {
                var baseY = seaLine;
                var towerH = H * 0.16;
                var topY = baseY - towerH;
                ctx.beginPath();
                ctx.moveTo(lhX - 170, baseY + 30);
                ctx.quadraticCurveTo(lhX - 90, baseY - 26, lhX - 20, baseY - 20);
                ctx.lineTo(lhX + 30, baseY - 18);
                ctx.quadraticCurveTo(lhX + 110, baseY - 10, lhX + 180, baseY + 30);
                ctx.closePath();
                ctx.fillStyle = "#060a12";
                ctx.fill();
                ctx.beginPath();
                ctx.moveTo(lhX - 15, baseY - 16);
                ctx.lineTo(lhX - 9, topY + 14);
                ctx.lineTo(lhX + 9, topY + 14);
                ctx.lineTo(lhX + 15, baseY - 16);
                ctx.closePath();
                ctx.fillStyle = "#0a1120";
                ctx.fill();
                ctx.fillStyle = "#16203a";
                ctx.fillRect(lhX - 12, topY + towerH * 0.45, 24, 7);
                ctx.fillStyle = "#0a1120";
                ctx.fillRect(lhX - 10, topY, 20, 14);
                var lampY = topY + 7;
                var pulse = 0.8 + 0.2 * Math.sin(t * 0.3 * sp);
                ctx.save();
                ctx.globalCompositeOperation = "lighter";
                var lg2 = ctx.createRadialGradient(lhX, lampY, 1, lhX, lampY, 70);
                lg2.addColorStop(0, hsl(42, 30, 80, 0.16 * inten * pulse));
                lg2.addColorStop(1, hsl(42, 30, 80, 0));
                ctx.fillStyle = lg2;
                ctx.fillRect(lhX - 70, lampY - 70, 140, 140);
                ctx.fillStyle = hsl(42, 35, 85, 0.85 * pulse);
                ctx.fillRect(lhX - 5, topY + 3, 10, 8);
                ctx.beginPath();
                ctx.rect(0, 0, W, seaLine);
                ctx.clip();
                var ang = t * 0.26 * sp;
                for (var bb = 0; bb < 2; bb++) {
                    var ba = ang + bb * Math.PI;
                    var bdx = Math.cos(ba), bdy = Math.sin(ba) * 0.35;
                    var bL = 950;
                    var bfx = lhX + bdx * bL, bfy = lampY + bdy * bL;
                    var bpx = -bdy, bpy = bdx;
                    var bg2 = ctx.createLinearGradient(lhX, lampY, bfx, bfy);
                    bg2.addColorStop(0, hsl(42, 30, 80, 0.05 * inten));
                    bg2.addColorStop(1, hsl(42, 30, 80, 0));
                    ctx.fillStyle = bg2;
                    ctx.beginPath();
                    ctx.moveTo(lhX, lampY);
                    ctx.lineTo(bfx + bpx * 48, bfy + bpy * 48);
                    ctx.lineTo(bfx - bpx * 48, bfy - bpy * 48);
                    ctx.closePath();
                    ctx.fill();
                }
                ctx.restore();
                ctx.save();
                ctx.globalCompositeOperation = "lighter";
                for (var wg = 0; wg < 10; wg++) {
                    var hw1 = hash(wg * 41 + 300);
                    var hw2 = hash(wg * 43 + 301);
                    var wy = seaLine + 8 + hw1 * (H - seaLine - 16) * 0.7;
                    var wx = lhX + (hw2 - 0.5) * (30 + (wy - seaLine) * 0.5);
                    var wl = 8 + hw2 * 30;
                    var wo = 0.5 + 0.5 * Math.sin(t * (0.25 + hw1 * 0.4) * sp + wg * 2.7);
                    ctx.fillStyle = hsl(42, 28, 75, (0.02 + 0.05 * wo) * inten);
                    ctx.fillRect(wx - wl / 2, wy, wl, 1.2);
                }
                ctx.restore();
            }

            // --- Distant fishing boat on the left water. ---
            var boatX = TOTAL_W * 0.143 - mx;
            if (boatX > -120 && boatX < W + 120) {
                var bob = Math.sin(t * 0.5 * sp) * 1.8;
                var by = seaLine + 34 + bob;
                ctx.save();
                ctx.translate(boatX, by);
                ctx.rotate(Math.sin(t * 0.35 * sp) * 0.02);
                ctx.fillStyle = "#060a12";
                ctx.beginPath();
                ctx.moveTo(-24, -2);
                ctx.quadraticCurveTo(-18, 8, 0, 8);
                ctx.quadraticCurveTo(18, 8, 26, -4);
                ctx.lineTo(21, -4);
                ctx.quadraticCurveTo(0, 3, -20, -4);
                ctx.closePath();
                ctx.fill();
                ctx.fillRect(-1, -34, 2, 34);
                ctx.restore();
                var lampBy = by - 34;
                ctx.save();
                ctx.globalCompositeOperation = "lighter";
                var blg = ctx.createRadialGradient(boatX, lampBy, 0.5, boatX, lampBy, 20);
                blg.addColorStop(0, hsl(42, 35, 82, 0.14 * inten));
                blg.addColorStop(1, hsl(42, 35, 82, 0));
                ctx.fillStyle = blg;
                ctx.fillRect(boatX - 20, lampBy - 20, 40, 40);
                ctx.fillStyle = hsl(42, 40, 85, 0.85);
                ctx.fillRect(boatX - 1.5, lampBy - 1.5, 3, 3);
                for (var br = 0; br < 5; br++) {
                    var hb1 = hash(br * 71 + 400), hb2 = hash(br * 73 + 401);
                    var bry = by + 12 + hb1 * 60;
                    var brx = boatX + (hb2 - 0.5) * (14 + (bry - by) * 0.4);
                    var bro = 0.5 + 0.5 * Math.sin(t * (0.3 + hb1 * 0.4) * sp + br * 2.2);
                    ctx.fillStyle = hsl(42, 30, 78, (0.02 + 0.05 * bro) * inten);
                    ctx.fillRect(brx - 5, bry, 10 + hb2 * 12, 1.1);
                }
                ctx.restore();
            }

            // --- Sea stacks rising from the right water. ---
            var stacks = [
                { x: TOTAL_W * 0.800, h: 0.085, w: 46 },
                { x: TOTAL_W * 0.837, h: 0.135, w: 64 },
                { x: TOTAL_W * 0.871, h: 0.06, w: 38 }
            ];
            for (var si = 0; si < stacks.length; si++) {
                var st = stacks[si];
                var sx2 = st.x - mx;
                if (sx2 < -150 || sx2 > W + 150) continue;
                var sh = H * st.h, sw = st.w;
                var sbase = seaLine + 16;
                ctx.beginPath();
                ctx.moveTo(sx2 - sw / 2, sbase);
                ctx.lineTo(sx2 - sw * 0.32, sbase - sh * 0.7);
                ctx.lineTo(sx2 - sw * 0.18, sbase - sh * 0.82);
                ctx.lineTo(sx2 - sw * 0.05, sbase - sh);
                ctx.lineTo(sx2 + sw * 0.12, sbase - sh * 0.88);
                ctx.lineTo(sx2 + sw * 0.3, sbase - sh * 0.62);
                ctx.lineTo(sx2 + sw / 2, sbase);
                ctx.closePath();
                ctx.fillStyle = "#05080f";
                ctx.fill();
                ctx.save();
                ctx.globalCompositeOperation = "lighter";
                ctx.fillStyle = hsl(root.hue, 25, 70, 0.035 * inten);
                ctx.fillRect(sx2 - sw * 0.7, sbase - 1, sw * 1.4, 1.5);
                ctx.restore();
            }
        }
    }

    // ~30 fps scene clock, wall-clock based so all monitors stay in sync.
    Timer {
        interval: 33
        running: true
        repeat: true
        onTriggered: {
            root.sceneTime = Date.now() / 1000.0;
            cv.requestPaint();
        }
    }
}