import SwiftUI

struct PreviewHTMLBuilder {
    static func buildHTML(store: AppStore, now: Date) -> String {
        let theme = store.currentTheme
        let schedule = store.prayerSchedule.isEmpty
            ? ScheduleSimulator.generateSchedule(for: store.location, date: now, iqamaConfig: store.iqama, jumuahConfig: store.jumuah)
            : store.prayerSchedule

        let state = PrayerStateMachine.evaluate(
            now: now,
            schedule: schedule,
            adhanActiveSeconds: store.advanced.adhanActiveSeconds,
            iqamaConfig: store.iqama,
            prayerInProgressMinutes: store.advanced.prayerInProgressMinutes
        )

        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"

        let bgColor = colorToCSS(theme.palette.background)
        let surfaceColor = colorToCSS(theme.palette.surface)
        let primaryColor = colorToCSS(theme.palette.primary)
        let accentColor = colorToCSS(theme.palette.accent)
        let textPrimary = colorToCSS(theme.palette.textPrimary)
        let textSecondary = colorToCSS(theme.palette.textSecondary)

        let gradientCSS: String
        if theme.layers.gradientStops.count >= 2 {
            let stops = theme.layers.gradientStops.map { "\(colorToCSS($0.color)) \(Int($0.location * 100))%" }.joined(separator: ", ")
            gradientCSS = "linear-gradient(180deg, \(stops))"
        } else {
            gradientCSS = bgColor
        }

        let prayerRows = schedule.map { pt in
            let isActive = state.currentPrayer == pt.prayer
            let adhanStr = tf.string(from: pt.time)
            let iqamaStr = pt.iqamaTime.map { tf.string(from: $0) } ?? "—"
            let nameAr = pt.prayer.displayNameAr
            let nameEn = pt.prayer.displayName
            let activeClass = isActive ? "active" : ""
            return """
            <tr class="\(activeClass)">
                <td class="prayer-name"><span class="ar">\(nameAr)</span><span class="en">\(nameEn)</span></td>
                <td class="time">\(adhanStr)</td>
                <td class="time">\(iqamaStr)</td>
            </tr>
            """
        }.joined(separator: "\n")

        let hijriHelper = HijriDateHelper.hijriString(from: now)
        let gregorianFormatter = DateFormatter()
        gregorianFormatter.dateFormat = "EEEE, d MMMM yyyy"
        let gregorianDate = gregorianFormatter.string(from: now)

        let phaseLabel = store.display.language == .ar ? state.phaseLabelAr : state.phaseLabel
        let countdownValue: String
        if state.phase == .normal && state.countdownSeconds > 0 {
            countdownValue = formatCountdown(state.countdownSeconds)
        } else if state.phase == .adhanActive {
            countdownValue = formatCountdown(state.adhanRemainingSeconds)
        } else if state.phase == .iqamaCountdown {
            countdownValue = formatCountdown(state.iqamaCountdownSeconds)
        } else {
            countdownValue = ""
        }

        let phaseColor: String
        switch state.phase {
        case .normal: phaseColor = accentColor
        case .adhanActive: phaseColor = "#FF9500"
        case .iqamaCountdown: phaseColor = "#AF52DE"
        case .prayerInProgress: phaseColor = "#34C759"
        }

        return """
        <!DOCTYPE html>
        <html lang="ar" dir="rtl">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, 'SF Pro Display', system-ui, sans-serif;
            background: \(gradientCSS);
            color: \(textPrimary);
            min-height: 100vh;
            overflow: hidden;
            position: relative;
        }
        .vignette {
            position: fixed; inset: 0;
            background: radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.4) 100%);
            pointer-events: none; z-index: 1;
        }
        .container {
            position: relative; z-index: 2;
            display: flex; flex-direction: row;
            height: 100vh; padding: 20px;
            gap: 20px;
        }
        .left-col {
            flex: 1; display: flex; flex-direction: column;
            justify-content: center; align-items: center; gap: 12px;
        }
        .right-col {
            flex: 1; display: flex; flex-direction: column;
            justify-content: center; gap: 12px;
        }
        .clock {
            font-size: clamp(48px, 10vw, 120px);
            font-weight: 700; letter-spacing: -2px;
            text-shadow: 0 0 30px \(accentColor)44;
            font-variant-numeric: tabular-nums;
        }
        .date-block {
            text-align: center; color: \(textSecondary);
            font-size: clamp(12px, 2vw, 18px);
        }
        .date-block .hijri { color: \(primaryColor); margin-bottom: 4px; }
        .countdown-card {
            background: \(surfaceColor)88;
            border: 1px solid \(primaryColor)33;
            border-radius: 16px; padding: 16px;
            text-align: center;
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
        }
        .countdown-label { font-size: 14px; color: \(textSecondary); margin-bottom: 4px; }
        .countdown-value {
            font-size: clamp(24px, 5vw, 48px);
            font-weight: 700; font-variant-numeric: tabular-nums;
            color: \(phaseColor);
            text-shadow: 0 0 20px \(phaseColor)66;
        }
        .phase-badge {
            display: inline-block; padding: 4px 12px;
            border-radius: 20px; font-size: 12px; font-weight: 600;
            background: \(phaseColor)22; color: \(phaseColor);
            border: 1px solid \(phaseColor)44;
        }
        .prayer-table {
            background: \(surfaceColor)88;
            border: 1px solid \(primaryColor)22;
            border-radius: 16px; overflow: hidden;
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
        }
        .prayer-table table { width: 100%; border-collapse: collapse; }
        .prayer-table th {
            padding: 10px 14px; text-align: center;
            font-size: 12px; font-weight: 600;
            color: \(textSecondary); text-transform: uppercase;
            border-bottom: 1px solid \(primaryColor)22;
        }
        .prayer-table td { padding: 10px 14px; text-align: center; }
        .prayer-table tr:not(:last-child) td { border-bottom: 1px solid \(primaryColor)11; }
        .prayer-table tr.active td {
            background: \(accentColor)18;
            color: \(accentColor);
            font-weight: 600;
        }
        .prayer-name { text-align: right !important; }
        .prayer-name .ar { font-size: 16px; display: block; }
        .prayer-name .en { font-size: 11px; color: \(textSecondary); display: block; }
        .time { font-variant-numeric: tabular-nums; font-size: 16px; font-weight: 500; }
        .city-label {
            text-align: center; font-size: 12px;
            color: \(textSecondary); opacity: 0.7;
        }
        .ticker {
            position: fixed; bottom: 0; left: 0; right: 0;
            background: \(surfaceColor)66; padding: 8px 0;
            overflow: hidden; z-index: 3;
            border-top: 1px solid \(primaryColor)15;
        }
        .ticker-text {
            white-space: nowrap; display: inline-block;
            animation: scroll-rtl 30s linear infinite;
            font-size: 14px; color: \(textSecondary);
        }
        @keyframes scroll-rtl {
            0% { transform: translateX(100%); }
            100% { transform: translateX(-100%); }
        }
        .pattern-overlay {
            position: fixed; inset: 0; z-index: 0;
            opacity: 0.06; pointer-events: none;
            background-image: repeating-conic-gradient(\(primaryColor)15 0% 25%, transparent 0% 50%);
            background-size: 40px 40px;
        }
        @media (max-width: 600px) {
            .container { flex-direction: column; padding: 12px; gap: 10px; }
            .left-col, .right-col { flex: none; }
        }
        </style>
        </head>
        <body>
        <div class="pattern-overlay"></div>
        <div class="vignette"></div>
        <div class="container">
            <div class="left-col">
                <div class="clock" id="clock">\(tf.string(from: now))</div>
                <div class="date-block">
                    <div class="hijri">\(hijriHelper)</div>
                    <div>\(gregorianDate)</div>
                </div>
                <div class="countdown-card">
                    <div class="countdown-label">\(phaseLabel)</div>
                    <div class="countdown-value">\(countdownValue)</div>
                    <div class="phase-badge">\(state.phase == .normal ? "Normal" : phaseLabel)</div>
                </div>
                <div class="city-label">\(store.location.cityName)</div>
            </div>
            <div class="right-col">
                <div class="prayer-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Prayer</th>
                                <th>Adhan</th>
                                <th>Iqama</th>
                            </tr>
                        </thead>
                        <tbody>
                            \(prayerRows)
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="ticker">
            <span class="ticker-text">
                سبحان الله والحمد لله ولا إله إلا الله والله أكبر &nbsp; ● &nbsp;
                اللهم صل وسلم على نبينا محمد &nbsp; ● &nbsp;
                لا حول ولا قوة إلا بالله &nbsp; ● &nbsp;
                أستغفر الله العظيم &nbsp; ● &nbsp;
            </span>
        </div>
        <script>
        function updateClock() {
            const now = new Date();
            const h = String(now.getHours()).padStart(2, '0');
            const m = String(now.getMinutes()).padStart(2, '0');
            const s = String(now.getSeconds()).padStart(2, '0');
            document.getElementById('clock').textContent = h + ':' + m + ':' + s;
        }
        setInterval(updateClock, 1000);
        updateClock();
        </script>
        </body>
        </html>
        """
    }

    private static func colorToCSS(_ color: Color) -> String {
        let resolved = UIColor(color)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0; var a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    private static func formatCountdown(_ totalSeconds: Int) -> String {
        let h = totalSeconds / 3600
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
