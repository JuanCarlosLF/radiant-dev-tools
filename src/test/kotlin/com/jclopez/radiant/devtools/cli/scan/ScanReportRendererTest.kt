package com.jclopez.radiant.devtools.cli.scan

import com.jclopez.radiant.devtools.application.scan.MapId
import com.jclopez.radiant.devtools.application.scan.report.ScanReport
import com.jclopez.radiant.devtools.contract.scanner.ScanStatus
import com.jclopez.radiant.devtools.contract.scanner.Severity
import com.jclopez.radiant.devtools.contract.scanner.Source
import com.jclopez.radiant.devtools.contract.scanner.SourceKind
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class ScanReportRendererTest {

    @Test
    fun `global summary uses the report soul count and shows informational total`() {
        val report = report(
            mapId = null,
            mapName = null,
            soulCount = 3,
            souls = listOf(soul(1), soul(2), soul(3), soul(4)),
        )

        val output = ScanReportRenderer.render(report)

        assertContains(output, "Souls: 3/108")
        assertFalse(output.contains("Souls: 4/108"))
        assertContains(output, "Diagnostics: none")
    }

    @Test
    fun `filtered summary uses only the map count`() {
        val output = ScanReportRenderer.render(
            report(
                mapId = 7,
                mapName = "Map Seven",
                soulCount = 3,
                souls = listOf(soul(1), soul(2), soul(3), soul(4)),
            )
        )

        assertContains(output, "Hay 3 almas en Map Seven (7)")
        assertFalse(output.contains("/108"))
    }

    @Test
    fun `filtered zero souls uses the known map name`() {
        val output = ScanReportRenderer.render(
            report(mapId = 7, mapName = "Map Seven", soulCount = 0, souls = emptyList())
        )

        assertContains(output, "Hay 0 almas en Map Seven (7)")
        assertFalse(output.contains("No se han detectado almas"))
    }

    @Test
    fun `filtered zero souls without a map name uses the exact fallback`() {
        val output = ScanReportRenderer.render(
            report(mapId = 999, mapName = null, soulCount = 0, souls = emptyList())
        )

        assertContains(output, "No se han detectado almas para el mapa 999 en este escaneo.")
        assertFalse(output.contains("/108"))
    }

    @Test
    fun `renders every soul occurrence with its prepared source details`() {
        val output = ScanReportRenderer.render(
            report(
                mapId = null,
                mapName = null,
                soulCount = 2,
                souls = listOf(
                    soul(1, pageIndex = 0, stageId = "stg_a1f3", requires = listOf("surf"), notes = "First note"),
                    soul(1, pageIndex = 1, stageId = "stg_b2e7", requires = listOf("cut"), notes = "Second note"),
                ),
            )
        )

        assertContains(output, "stage=stg_a1f3")
        assertContains(output, "stage=stg_b2e7")
        assertContains(output, "requires=[surf]")
        assertContains(output, "requires=[cut]")
        assertContains(output, "notes=First note")
        assertContains(output, "notes=Second note")
        assertContains(output, "map=1 (Map 1)")
        assertContains(output, "event=7 (Event 7)")
        assertContains(output, "page=0")
        assertContains(output, "page=1")
        assertContains(output, "command=4")
        assertContains(output, "coordinates=10,11")
        assertContains(output, "kind=event")
        assertContains(output, "script_command")
    }

    @Test
    fun `renders nullable source metadata without crashing`() {
        val nullableSource = source(1).copy(kind = null, command = null)
        val output = ScanReportRenderer.render(
            report(
                mapId = null,
                mapName = null,
                soulCount = 1,
                souls = listOf(
                    ScanReport.Soul("stg_a1f3", emptyList(), "", nullableSource)
                ),
            )
        )

        assertContains(output, "kind=null")
        assertContains(output, "command=4 (null)")
    }

    @Test
    fun `renders all duplicate related sources without source unknown`() {
        val sources = listOf(
            source(mapId = 1, eventId = 7, pageIndex = 0),
            source(mapId = 1, eventId = 7, pageIndex = 1),
            source(mapId = 1, eventId = 7, pageIndex = 2),
        )
        val output = ScanReportRenderer.render(
            report(
                mapId = null,
                mapName = null,
                soulCount = 1,
                souls = listOf(soul(1)),
                diagnostics = listOf(
                    ScanReport.Diagnostic(
                        code = "duplicate_soul_event",
                        severity = Severity.WARNING,
                        message = "Duplicate soul event",
                        source = null,
                        relatedSources = sources,
                    )
                ),
            )
        )

        assertContains(output, "[duplicate_soul_event]")
        sources.forEach { related ->
            assertContains(output, "page=${related.pageIndex}")
        }
        assertFalse(output.contains("source=unknown"))
    }

    @Test
    fun `preserves source-less and ordinary diagnostic source rendering`() {
        val output = ScanReportRenderer.render(
            report(
                mapId = null,
                mapName = null,
                soulCount = 0,
                souls = emptyList(),
                diagnostics = listOf(
                    ScanReport.Diagnostic(
                        code = "missing_source",
                        severity = Severity.WARNING,
                        message = "No source",
                        source = null,
                    ),
                    ScanReport.Diagnostic(
                        code = "scanner_warning",
                        severity = Severity.WARNING,
                        message = "Located warning",
                        source = source(mapId = 3, eventId = 9, pageIndex = 4),
                    ),
                ),
            )
        )

        assertContains(output, "[missing_source] No source at source=unknown")
        assertContains(output, "[scanner_warning] Located warning at map=3, event=9, page=4, command=4, coordinates=10,11")
    }

    private fun report(
        mapId: Int?,
        mapName: String?,
        soulCount: Int,
        souls: List<ScanReport.Soul>,
        diagnostics: List<ScanReport.Diagnostic> = emptyList(),
    ) = ScanReport(
        status = ScanStatus.SUCCESS,
        usable = true,
        mapId = mapId?.let(::MapId),
        mapName = mapName,
        itemCount = 0,
        soulCount = soulCount,
        tutorStationCount = 0,
        warningCount = diagnostics.count { it.severity == Severity.WARNING },
        errorCount = diagnostics.count { it.severity == Severity.ERROR },
        items = emptyList(),
        souls = souls,
        diagnostics = diagnostics,
    )

    private fun soul(
        mapId: Int,
        eventId: Int = 7,
        pageIndex: Int = 0,
        stageId: String = "stg_a1f3",
        requires: List<String> = emptyList(),
        notes: String = "",
    ) = ScanReport.Soul(
        stageId = stageId,
        requires = requires,
        notes = notes,
        source = source(mapId, eventId, pageIndex),
    )

    private fun source(mapId: Int, eventId: Int = 7, pageIndex: Int = 0) = Source(
        kind = SourceKind.EVENT,
        command = "script_command",
        mapId = mapId,
        mapName = "Map $mapId",
        eventId = eventId,
        eventName = "Event $eventId",
        pageIndex = pageIndex,
        commandIndex = 4,
        x = 10,
        y = 11,
    )
}
