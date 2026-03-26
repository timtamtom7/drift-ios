import Foundation
import os.log
import UIKit
import PDFKit

/// Service for exporting sleep data in various formats: PDF reports, JSON, and CSV.
@MainActor
class SleepExportService: ObservableObject {
    @Published var isExporting = false
    @Published var lastExportURL: URL?

    private let logger = Logger(subsystem: "com.drift.sleep", category: "ExportService")

    // MARK: - Export PDF Report

    /// Generates a formatted PDF sleep report for a given date range
    func generatePDFReport(
        records: [SleepRecord],
        title: String = "Drift Sleep Report",
        includeTrends: Bool = true,
        includeInsights: Bool = true
    ) async throws -> URL {
        isExporting = true
        defer { isExporting = false }

        logger.info("Generating PDF report with \(records.count) records")

        let pdfData = await renderPDF(
            records: records,
            title: title,
            includeTrends: includeTrends,
            includeInsights: includeInsights
        )

        let fileName = "Drift_SleepReport_\(formattedFileDate()).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try pdfData.write(to: tempURL)
        lastExportURL = tempURL

        logger.info("PDF report saved to \(tempURL.lastPathComponent)")
        return tempURL
    }

    // MARK: - Export JSON

    func generateJSONExport(records: [SleepRecord]) async throws -> URL {
        logger.info("Generating JSON export with \(records.count) records")

        let export = DriftSleepExportData(
            generatedAt: Date(),
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            recordCount: records.count,
            records: records.map { SleepRecordExport(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(export)

        let fileName = "Drift_SleepExport_\(formattedFileDate()).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try jsonData.write(to: tempURL)
        lastExportURL = tempURL

        logger.info("JSON export saved to \(tempURL.lastPathComponent)")
        return tempURL
    }

    // MARK: - Export CSV

    func generateCSVExport(records: [SleepRecord]) async throws -> URL {
        logger.info("Generating CSV export with \(records.count) records")

        var csvLines: [String] = []

        // Header
        let header = [
            "Date",
            "Total Hours",
            "Score",
            "Deep Sleep (min)",
            "REM Sleep (min)",
            "Light Sleep (min)",
            "Awake (min)",
            "Heart Rate Min",
            "Heart Rate Max",
            "Heart Rate Avg",
            "HRV Avg",
            "Respiratory Rate Avg",
            "SpO2 Avg",
            "Caffeine (mg)",
            "Exercise (min)",
            "Mindful Minutes"
        ].joined(separator: ",")
        csvLines.append(header)

        // Data rows
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for record in records.sorted(by: { $0.date > $1.date }) {
            var fields: [String] = []
            fields.append(dateFormatter.string(from: record.date))
            fields.append(String(format: "%.1f", record.totalHours))
            fields.append("\(record.score)")
            fields.append("\(record.deepSleepMinutes)")
            fields.append("\(record.remSleepMinutes)")
            fields.append("\(record.lightSleepMinutes)")
            fields.append("\(record.awakeMinutes)")
            fields.append(record.heartRateMin.map { String($0) } ?? "")
            fields.append(record.heartRateMax.map { String($0) } ?? "")
            fields.append(record.heartRateAvg.map { String($0) } ?? "")
            fields.append(record.hrvAvg.map { String(format: "%.1f", $0) } ?? "")
            fields.append(record.respiratoryRateAvg.map { String(format: "%.1f", $0) } ?? "")
            fields.append(record.spo2Avg.map { String(format: "%.1f", $0) } ?? "")
            fields.append(record.caffeineMg.map { String(format: "%.1f", $0) } ?? "")
            fields.append(record.exerciseMinutes.map { String(format: "%.1f", $0) } ?? "")
            fields.append(record.mindfulMinutes.map { String(format: "%.1f", $0) } ?? "")
            csvLines.append(fields.joined(separator: ","))
        }

        let csvString = csvLines.joined(separator: "\n")
        let csvData = Data(csvString.utf8)

        let fileName = "Drift_SleepExport_\(formattedFileDate()).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        try csvData.write(to: tempURL)
        lastExportURL = tempURL

        logger.info("CSV export saved to \(tempURL.lastPathComponent)")
        return tempURL
    }

    // MARK: - PDF Rendering

    private func renderPDF(
        records: [SleepRecord],
        title: String,
        includeTrends: Bool,
        includeInsights: Bool
    ) async -> Data {
        let pageWidth: CGFloat = 612  // US Letter width
        let pageHeight: CGFloat = 792 // US Letter height
        let margin: CGFloat = 50

        let pdfMetaData = [
            kCGPDFContextCreator: "Drift",
            kCGPDFContextAuthor: "Drift App",
            kCGPDFContextTitle: title
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        let data = renderer.pdfData { context in
            var currentY: CGFloat = 0
            var pageNumber = 0

            func startNewPage() {
                context.beginPage()
                pageNumber += 1
                currentY = margin

                // Page header (not on first page)
                if pageNumber > 1 {
                    let headerText = "Drift Sleep Report — Page \(pageNumber)"
                    let headerFont = UIFont.systemFont(ofSize: 9, weight: .regular)
                    let headerAttributes: [NSAttributedString.Key: Any] = [
                        .font: headerFont,
                        .foregroundColor: UIColor.gray
                    ]
                    let headerRect = CGRect(x: margin, y: 20, width: pageWidth - 2 * margin, height: 20)
                    headerText.draw(in: headerRect, withAttributes: headerAttributes)
                    currentY = 45
                }
            }

            func checkNewPageNeeded(height: CGFloat) {
                if currentY + height > pageHeight - margin {
                    startNewPage()
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor, x: CGFloat, y: CGFloat, width: CGFloat) {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 4

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraphStyle
                ]

                let rect = CGRect(x: x, y: y, width: width, height: .greatestFiniteMagnitude)
                let boundingRect = text.boundingRect(with: rect.size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                text.draw(in: CGRect(x: x, y: y, width: width, height: boundingRect.height), withAttributes: attributes)
                currentY += boundingRect.height + 8
            }

            func drawSeparator() {
                checkNewPageNeeded(height: 1)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: currentY))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: currentY))
                UIColor.lightGray.withAlphaComponent(0.3).setStroke()
                path.lineWidth = 0.5
                path.stroke()
                currentY += 16
            }

            // === PAGE 1 ===
            startNewPage()

            // Title
            let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
            drawText(title, font: titleFont, color: .black, x: margin, y: currentY, width: pageWidth - 2 * margin)
            currentY += 8

            let dateFont = UIFont.systemFont(ofSize: 12, weight: .regular)
            let dateRange = formatDateRange(records: records)
            drawText(dateRange, font: dateFont, color: .gray, x: margin, y: currentY, width: pageWidth - 2 * margin)
            currentY += 8

            let generatedFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let generatedText = "Generated on \(formattedNow()) by Drift"
            drawText(generatedText, font: generatedFont, color: .lightGray, x: margin, y: currentY, width: pageWidth - 2 * margin)
            currentY += 30

            drawSeparator()

            // Summary stats
            let sectionFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
            drawText("Summary", font: sectionFont, color: .black, x: margin, y: currentY, width: pageWidth - 2 * margin)
            currentY += 16

            let (avgScore, avgHours, avgDeep, avgRem) = calculateAverages(records: records)
            let statFont = UIFont.systemFont(ofSize: 11, weight: .regular)
            let statColor = UIColor.darkGray

            let stats = [
                "Total nights tracked: \(records.count)",
                "Average sleep score: \(avgScore) / 100",
                "Average sleep duration: \(String(format: "%.1f", avgHours)) hours",
                "Average deep sleep: \(avgDeep) minutes",
                "Average REM sleep: \(avgRem) minutes"
            ]

            for stat in stats {
                drawText("• \(stat)", font: statFont, color: statColor, x: margin + 10, y: currentY, width: pageWidth - 2 * margin - 10)
            }

            currentY += 10
            drawSeparator()

            // Sleep records table
            checkNewPageNeeded(height: 100)
            drawText("Sleep History", font: sectionFont, color: .black, x: margin, y: currentY, width: pageWidth - 2 * margin)
            currentY += 16

            // Table header
            let colWidths: [CGFloat] = [80, 70, 60, 70, 70, 70, 70]
            let colNames = ["Date", "Score", "Hours", "Deep", "REM", "Light", "Awake"]
            let headerBgRect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: 22)
            UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 0.06).setFill()
            UIBezierPath(rect: headerBgRect).fill()

            let tableHeaderFont = UIFont.systemFont(ofSize: 9, weight: .semibold)
            UIColor.darkGray.setFill()
            var colX = margin + 4
            for (i, colName) in colNames.enumerated() {
                colName.draw(at: CGPoint(x: colX, y: currentY + 6), withAttributes: [
                    .font: tableHeaderFont,
                    .foregroundColor: UIColor.darkGray
                ])
                colX += colWidths[i]
            }
            currentY += 22

            // Table rows
            let rowFont = UIFont.systemFont(ofSize: 10, weight: .regular)
            let dateF = DateFormatter()
            dateF.dateFormat = "MMM d"

            for (rowIndex, record) in records.sorted(by: { $0.date > $1.date }).prefix(30).enumerated() {
                checkNewPageNeeded(height: 20)
                if rowIndex % 2 == 0 {
                    let rowRect = CGRect(x: margin, y: currentY, width: pageWidth - 2 * margin, height: 18)
                    UIColor(white: 0.97, alpha: 1).setFill()
                    UIBezierPath(rect: rowRect).fill()
                }

                var rowX = margin + 4
                let values = [
                    dateF.string(from: record.date),
                    "\(record.score)",
                    String(format: "%.1f", record.totalHours),
                    "\(record.deepSleepMinutes)m",
                    "\(record.remSleepMinutes)m",
                    "\(record.lightSleepMinutes)m",
                    "\(record.awakeMinutes)m"
                ]

                for (i, value) in values.enumerated() {
                    let textColor: UIColor = i == 1 ? scoreColor(for: record.score) : .black
                    value.draw(at: CGPoint(x: rowX, y: currentY + 4), withAttributes: [
                        .font: rowFont,
                        .foregroundColor: textColor
                    ])
                    rowX += colWidths[i]
                }
                currentY += 18
            }

            // Trends section
            if includeTrends && records.count >= 3 {
                drawSeparator()
                checkNewPageNeeded(height: 100)
                drawText("Trends & Insights", font: sectionFont, color: .black, x: margin, y: currentY, width: pageWidth - 2 * margin)
                currentY += 16

                let insights = generateTextInsights(records: records)
                for insight in insights {
                    checkNewPageNeeded(height: 30)
                    drawText("• \(insight)", font: statFont, color: statColor, x: margin + 10, y: currentY, width: pageWidth - 2 * margin - 10)
                }
            }

            // Footer
            currentY = pageHeight - 30
            let footerText = "This report was generated by Drift. For medical concerns, consult a healthcare professional."
            footerText.draw(at: CGPoint(x: margin, y: currentY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                .foregroundColor: UIColor.lightGray
            ])
        }

        return data
    }

    // MARK: - Helpers

    private func calculateAverages(records: [SleepRecord]) -> (score: Int, hours: Double, deep: Int, rem: Int) {
        guard !records.isEmpty else { return (0, 0, 0, 0) }
        let avgScore = records.map { $0.score }.reduce(0, +) / records.count
        let avgHours = records.map { $0.totalHours }.reduce(0, +) / Double(records.count)
        let avgDeep = records.map { $0.deepSleepMinutes }.reduce(0, +) / records.count
        let avgRem = records.map { $0.remSleepMinutes }.reduce(0, +) / records.count
        return (avgScore, avgHours, avgDeep, avgRem)
    }

    private func generateTextInsights(records: [SleepRecord]) -> [String] {
        var insights: [String] = []
        let sorted = records.sorted { $0.date > $1.date }
        let recent = Array(sorted.prefix(7))

        let avgScore = recent.compactMap { Optional($0.score) }.reduce(0, +) / max(1, recent.count)
        insights.append("Your average score over the past \(recent.count) nights is \(avgScore).")

        // Consistency
        let bedtimes = recent.compactMap { record -> Int? in
            guard record.fellAsleepTime.hour >= 18 || record.fellAsleepTime.hour < 4 else { return nil }
            return record.fellAsleepTime.hour * 60 + record.fellAsleepTime.minute
        }
        if bedtimes.count >= 2 {
            let variance = bedtimes.map { abs($0 - (bedtimes.reduce(0, +) / bedtimes.count)) }.reduce(0, +) / bedtimes.count
            if variance < 30 {
                insights.append("Your bedtime is very consistent — you're within 30 minutes most nights.")
            } else if variance < 60 {
                insights.append("Your bedtime varies by about an hour. More consistency would improve your score.")
            } else {
                insights.append("Your bedtime varies significantly. A more regular schedule would help.")
            }
        }

        // Deep sleep
        let avgDeep = recent.map { $0.deepSleepMinutes }.reduce(0, +) / max(1, recent.count)
        if avgDeep < 60 {
            insights.append("Your deep sleep is on the lower end. Aim for at least 1-2 hours of deep sleep per night.")
        } else {
            insights.append("Your deep sleep duration is good at \(avgDeep) minutes per night.")
        }

        // Social jetlag
        let weekdayRecords = recent.filter { record in
            let weekday = Calendar.current.component(.weekday, from: record.date)
            return weekday != 1 && weekday != 7
        }
        let weekendRecords = recent.filter { record in
            let weekday = Calendar.current.component(.weekday, from: record.date)
            return weekday == 1 || weekday == 7
        }

        if let wAvg = averageBedtime(weekdayRecords), let weAvg = averageBedtime(weekendRecords) {
            let diff = abs(wAvg - weAvg)
            if diff > 60 {
                insights.append("There's a significant \(diff / 60)h+ difference between your weekday and weekend sleep schedule.")
            }
        }

        return insights
    }

    private func averageBedtime(_ records: [SleepRecord]) -> Int? {
        let bedtimes = records.compactMap { record -> Int? in
            let h = record.fellAsleepTime.hour
            let m = record.fellAsleepTime.minute
            if h >= 18 || h < 4 {
                return (h < 12 ? h + 24 : h) * 60 + m
            }
            return nil
        }
        guard !bedtimes.isEmpty else { return nil }
        return bedtimes.reduce(0, +) / bedtimes.count
    }

    private func scoreColor(for score: Int) -> UIColor {
        if score >= 80 { return UIColor(red: 0.2, green: 0.83, blue: 0.6, alpha: 1) } // insightAccent
        if score >= 60 { return UIColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1) } // warningAccent
        return UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1) // heartRate
    }

    private func formatDateRange(records: [SleepRecord]) -> String {
        guard let earliest = records.min(by: { $0.date < $1.date })?.date,
              let latest = records.max(by: { $0.date < $1.date })?.date else {
            return "No records"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return "\(formatter.string(from: earliest)) – \(formatter.string(from: latest))"
    }

    private func formattedFileDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func formattedNow() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Data Models

struct DriftSleepExportData: Codable {
    let generatedAt: Date
    let appVersion: String
    let recordCount: Int
    let records: [SleepRecordExport]
}

struct SleepRecordExport: Codable {
    let date: Date
    let totalDurationMinutes: Int
    let totalHours: Double
    let fellAsleepTime: Date
    let wokeUpTime: Date
    let score: Int
    let deepSleepMinutes: Int
    let remSleepMinutes: Int
    let lightSleepMinutes: Int
    let awakeMinutes: Int
    let heartRateMin: Int?
    let heartRateMax: Int?
    let heartRateAvg: Int?
    let hrvAvg: Double?
    let respiratoryRateAvg: Double?
    let spo2Avg: Double?
    let spo2DropsBelow90: Int?
    let wristTempAvg: Double?
    let caffeineMg: Double?
    let exerciseMinutes: Double?
    let mindfulMinutes: Double?
    let insight: String?

    init(from record: SleepRecord) {
        self.date = record.date
        self.totalDurationMinutes = record.totalMinutes
        self.totalHours = record.totalHours
        self.fellAsleepTime = record.fellAsleepTime
        self.wokeUpTime = record.wokeUpTime
        self.score = record.score
        self.deepSleepMinutes = record.deepSleepMinutes
        self.remSleepMinutes = record.remSleepMinutes
        self.lightSleepMinutes = record.lightSleepMinutes
        self.awakeMinutes = record.awakeMinutes
        self.heartRateMin = record.heartRateMin
        self.heartRateMax = record.heartRateMax
        self.heartRateAvg = record.heartRateAvg
        self.hrvAvg = record.hrvAvg
        self.respiratoryRateAvg = record.respiratoryRateAvg
        self.spo2Avg = record.spo2Avg
        self.spo2DropsBelow90 = record.spo2DropsBelow90
        self.wristTempAvg = record.wristTempAvg
        self.caffeineMg = record.caffeineMg
        self.exerciseMinutes = record.exerciseMinutes
        self.mindfulMinutes = record.mindfulMinutes
        self.insight = record.insight
    }
}

// MARK: - Date Extension

private extension Date {
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }
}
