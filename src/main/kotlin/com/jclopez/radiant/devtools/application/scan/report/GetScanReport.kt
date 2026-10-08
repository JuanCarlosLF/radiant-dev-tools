package com.jclopez.radiant.devtools.application.scan.report

import com.jclopez.radiant.devtools.application.scan.MapId
import com.jclopez.radiant.devtools.application.scan.ScanResultsRepository
import com.jclopez.radiant.devtools.contract.scanner.ScanStatus
import com.jclopez.radiant.devtools.contract.scanner.Severity
import com.jclopez.radiant.devtools.contract.scanner.Source

class GetScanReport(
    private val repository: ScanResultsRepository,
) {
    suspend operator fun invoke(mapId: MapId? = null): ScanReport {
        val results = repository.getScanResults()
        val items = results.items
            .filter { mapId == null || it.source.mapId == mapId.value }
            .map { finding ->
                ScanReport.Item(
                    itemId = finding.itemId,
                    quantity = finding.quantity,
                    stageId = finding.stageId,
                    mapId = MapId(finding.source.mapId),
                    eventId = finding.source.eventId,
                    x = finding.source.x,
                    y = finding.source.y,
                )
            }
        val soulCount = results.souls.count { mapId == null || it.source.mapId == mapId.value }
        val diagnostics = results.diagnostics
            .filter { mapId == null || it.source?.mapId == mapId.value }
            .map { diagnostic ->
                ScanReport.Diagnostic(
                    code = diagnostic.code,
                    severity = diagnostic.severity,
                    message = diagnostic.message,
                    source = diagnostic.source,
                )
            }

        return ScanReport(
            status = results.status,
            usable = results.status == ScanStatus.SUCCESS,
            itemCount = items.size,
            soulCount = soulCount,
            tutorStationCount = results.tutorStations.size,
            warningCount = diagnostics.count { it.severity == Severity.WARNING },
            errorCount = diagnostics.count { it.severity == Severity.ERROR },
            items = items,
            diagnostics = diagnostics,
        )
    }
}

data class ScanReport(
    val status: ScanStatus,
    val usable: Boolean,
    val itemCount: Int,
    val soulCount: Int,
    val tutorStationCount: Int,
    val warningCount: Int,
    val errorCount: Int,
    val items: List<Item>,
    val diagnostics: List<Diagnostic>,
) {
    data class Item(
        val itemId: String,
        val quantity: Int,
        val stageId: String,
        val mapId: MapId,
        val eventId: Int,
        val x: Int,
        val y: Int,
    )

    data class Diagnostic(
        val code: String,
        val severity: Severity,
        val message: String,
        val source: Source?,
    )
}
