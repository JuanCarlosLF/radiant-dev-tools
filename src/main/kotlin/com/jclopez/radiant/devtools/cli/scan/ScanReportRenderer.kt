package com.jclopez.radiant.devtools.cli.scan

import com.jclopez.radiant.devtools.application.scan.report.ScanReport

object ScanReportRenderer {
    fun render(report: ScanReport): String = buildString {
        appendLine("Scan report")
        appendLine("Status: ${report.status.name.lowercase()}")
        appendLine("Usable: ${report.usable}")
        appendLine(
            "Counts: items=${report.itemCount}, souls=${report.soulCount}, " +
                "tutor_stations=${report.tutorStationCount}, warnings=${report.warningCount}, " +
                "errors=${report.errorCount}",
        )

        if (report.items.isEmpty()) {
            appendLine("Items: none")
        } else {
            appendLine("Items:")
            report.items.forEach { item ->
                appendLine(
                    "- ${item.itemId} x${item.quantity} " +
                        "(stage=${item.stageId}, map=${item.mapId.value}, " +
                        "event=${item.eventId}, coordinates=${item.x},${item.y})",
                )
            }
        }

        appendSoulSummary(report)

        if (report.souls.isEmpty()) {
            appendLine("Souls: none")
        } else {
            appendLine("Souls:")
            report.souls.forEach { soul ->
                appendLine(
                    "- stage=${soul.stageId} requires=${soul.requires} notes=${soul.notes} " +
                        formatSoulSource(soul.source),
                )
            }
        }

        if (report.diagnostics.isEmpty()) {
            appendLine("Diagnostics: none")
        } else {
            appendLine("Diagnostics:")
            report.diagnostics.forEach { diagnostic ->
                appendDiagnostic(diagnostic)
            }
        }

        if (!report.usable) {
            appendLine("Result is not usable.")
        }
    }.trimEnd()

    private fun StringBuilder.appendSoulSummary(report: ScanReport) {
        if (report.mapId == null) {
            appendLine("Souls: ${report.soulCount}/108")
        } else if (report.mapName == null && report.soulCount == 0) {
            appendLine("No se han detectado almas para el mapa ${report.mapId.value} en este escaneo.")
        } else {
            appendLine("Hay ${report.soulCount} almas en ${report.mapName ?: ""} (${report.mapId.value})")
        }
    }

    private fun StringBuilder.appendDiagnostic(diagnostic: ScanReport.Diagnostic) {
        append(
            "- ${diagnostic.severity.name.lowercase()} " +
                "[${diagnostic.code}] ${diagnostic.message}"
        )
        when {
            diagnostic.source != null -> append(" at ${formatDiagnosticSource(diagnostic.source)}")
            diagnostic.relatedSources.isEmpty() -> append(" at source=unknown")
        }
        appendLine()

        if (diagnostic.relatedSources.isNotEmpty()) {
            appendLine("  Related sources:")
            diagnostic.relatedSources.forEachIndexed { index, source ->
                appendLine("  - ${index + 1}: ${formatSoulSource(source)}")
            }
        }
    }

    private fun formatSoulSource(source: com.jclopez.radiant.devtools.contract.scanner.Source): String =
        "source(kind=${source.kind?.name?.lowercase() ?: "null"}, " +
            "command=${source.commandIndex} (${source.command ?: "null"}), " +
            "map=${source.mapId} (${source.mapName}), " +
            "event=${source.eventId} (${source.eventName}), " +
            "page=${source.pageIndex}, coordinates=${source.x},${source.y})"

    private fun formatDiagnosticSource(source: com.jclopez.radiant.devtools.contract.scanner.Source): String =
        "map=${source.mapId}, event=${source.eventId}, page=${source.pageIndex}, " +
            "command=${source.commandIndex}, coordinates=${source.x},${source.y}"
}
