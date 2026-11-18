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
        val souls = results.souls
            .filter { mapId == null || it.source.mapId == mapId.value }
            .map { finding ->
                ScanReport.Soul(
                    stageId = finding.stageId,
                    requires = finding.requires,
                    notes = finding.notes,
                    source = finding.source,
                )
            }
        val soulGroups = souls.groupBy { SoulEventKey(it.source.mapId, it.source.eventId) }
        val duplicateSoulDiagnostics = soulGroups.values
            .filter { occurrences -> occurrences.size > 1 }
            .map { occurrences ->
                ScanReport.Diagnostic(
                    code = "duplicate_soul_event",
                    severity = Severity.WARNING,
                    message = "Multiple soul occurrences were found for the same map event.",
                    source = null,
                    relatedSources = occurrences.map { it.source },
                )
            }
        val diagnostics = results.diagnostics
            .filter { mapId == null || it.source?.mapId == mapId.value }
            .map { diagnostic ->
                ScanReport.Diagnostic(
                    code = diagnostic.code,
                    severity = diagnostic.severity,
                    message = diagnostic.message,
                    source = diagnostic.source,
                )
            } + duplicateSoulDiagnostics
        val artifactSources = buildList {
            addAll(results.items.map { it.source })
            addAll(results.souls.map { it.source })
            addAll(results.diagnostics.mapNotNull { it.source })
        }
        val mapName = mapId?.let { selectedMap ->
            artifactSources
                .firstOrNull { it.mapId == selectedMap.value && it.mapName.isNotBlank() }
                ?.mapName
        }

        return ScanReport(
            status = results.status,
            usable = results.status == ScanStatus.SUCCESS,
            mapId = mapId,
            mapName = mapName,
            itemCount = items.size,
            soulCount = soulGroups.size,
            tutorStationCount = results.tutorStations.size,
            warningCount = diagnostics.count { it.severity == Severity.WARNING },
            errorCount = diagnostics.count { it.severity == Severity.ERROR },
            items = items,
            souls = souls,
            diagnostics = diagnostics,
        )
    }
}

private data class SoulEventKey(
    val mapId: Int,
    val eventId: Int,
)

data class ScanReport(
    val status: ScanStatus,
    val usable: Boolean,
    val mapId: MapId?,
    val mapName: String?,
    val itemCount: Int,
    val soulCount: Int,
    val tutorStationCount: Int,
    val warningCount: Int,
    val errorCount: Int,
    val items: List<Item>,
    val souls: List<Soul>,
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

    data class Soul(
        val stageId: String,
        val requires: List<String>,
        val notes: String,
        val source: Source,
    )

    data class Diagnostic(
        val code: String,
        val severity: Severity,
        val message: String,
        val source: Source?,
        val relatedSources: List<Source> = emptyList(),
    )
}
