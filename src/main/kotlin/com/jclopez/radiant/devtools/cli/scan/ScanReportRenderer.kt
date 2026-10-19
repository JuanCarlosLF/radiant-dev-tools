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

        if (report.diagnostics.isEmpty()) {
            appendLine("Diagnostics: none")
        } else {
            appendLine("Diagnostics:")
            report.diagnostics.forEach { diagnostic ->
                val source = diagnostic.source?.let {
                    " at map=${it.mapId}, event=${it.eventId}, page=${it.pageIndex}, " +
                        "command=${it.commandIndex}, coordinates=${it.x},${it.y}"
                } ?: " at source=unknown"
                appendLine(
                    "- ${diagnostic.severity.name.lowercase()} " +
                        "[${diagnostic.code}] ${diagnostic.message}$source",
                )
            }
        }

        if (!report.usable) {
            appendLine("Result is not usable.")
        }
    }.trimEnd()
}
