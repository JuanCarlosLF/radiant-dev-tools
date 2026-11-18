package com.jclopez.radiant.devtools.application.scan.report

import com.jclopez.radiant.devtools.application.scan.MapId
import com.jclopez.radiant.devtools.application.scan.ScanResultsRepository
import com.jclopez.radiant.devtools.contract.scanner.Diagnostic
import com.jclopez.radiant.devtools.contract.scanner.ItemFinding
import com.jclopez.radiant.devtools.contract.scanner.ScanResults
import com.jclopez.radiant.devtools.contract.scanner.ScanStatus
import com.jclopez.radiant.devtools.contract.scanner.Severity
import com.jclopez.radiant.devtools.contract.scanner.SoulFinding
import com.jclopez.radiant.devtools.contract.scanner.Source
import com.jclopez.radiant.devtools.contract.scanner.TutorStation
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class GetScanReportTest {

    @Test
    fun `success with warnings remains usable`() = runTest {
        val report = GetScanReport(FakeRepository(successWithWarning()))()

        assertEquals(ScanStatus.SUCCESS, report.status)
        assertTrue(report.usable)
        assertEquals(1, report.itemCount)
        assertEquals(1, report.warningCount)
        assertEquals(0, report.errorCount)
    }

    @Test
    fun `failed results are not usable`() = runTest {
        val report = GetScanReport(FakeRepository(successWithWarning().copy(status = ScanStatus.FAILED)))()

        assertEquals(ScanStatus.FAILED, report.status)
        assertFalse(report.usable)
    }

    @Test
    fun `map filter narrows items and diagnostics`() = runTest {
        val report = GetScanReport(FakeRepository(resultsWithTwoMaps()))(MapId(2))

        assertEquals(1, report.itemCount)
        assertEquals("potion", report.items.single().itemId)
        assertEquals(1, report.warningCount)
        assertEquals("map_two_warning", report.diagnostics.single().code)
        assertEquals(source(2), report.diagnostics.single().source)
    }

    @Test
    fun `unfiltered report preserves diagnostics without a source`() = runTest {
        val report = GetScanReport(
            FakeRepository(successWithWarning().copy(diagnostics = listOf(diagnosticWithoutSource())))
        )()

        assertEquals(null, report.diagnostics.single().source)
    }

    @Test
    fun `empty collections produce an empty report`() = runTest {
        val report = GetScanReport(
            FakeRepository(ScanResults(1, ScanStatus.SUCCESS, emptyList(), emptyList(), emptyList(), emptyList()))
        )()

        assertEquals(0, report.itemCount)
        assertEquals(0, report.soulCount)
        assertEquals(0, report.tutorStationCount)
        assertTrue(report.items.isEmpty())
        assertTrue(report.diagnostics.isEmpty())
    }

    @Test
    fun `retains every soul occurrence while counting unique map events`() = runTest {
        val report = GetScanReport(FakeRepository(resultsWithRepeatedSouls()))()

        assertEquals(3, report.soulCount)
        assertEquals(5, report.souls.size)
        assertEquals(1, report.warningCount)
        assertEquals(1, report.diagnostics.count { it.code == "duplicate_soul_event" })

        val repeated = report.souls.filter { it.source.mapId == 1 && it.source.eventId == 7 }
        assertEquals(3, repeated.size)
        assertEquals(listOf("stg_a1f3", "stg_b2e7", "stg_c4h1"), repeated.map { it.stageId })
        assertEquals(listOf(listOf("surf"), listOf("cut"), listOf("bike")), repeated.map { it.requires })
        assertEquals(listOf("First", "Second", "Third"), repeated.map { it.notes })
        assertEquals(listOf(0, 1, 2), repeated.map { it.source.pageIndex })

        val duplicateWarning = report.diagnostics.single { it.code == "duplicate_soul_event" }
        assertEquals(null, duplicateWarning.source)
        assertEquals(repeated.map { it.source }, duplicateWarning.relatedSources)
    }

    @Test
    fun `four occurrences across three events produce one duplicate warning`() = runTest {
        val report = GetScanReport(FakeRepository(resultsWithFourSouls()))()

        assertEquals(4, report.souls.size)
        assertEquals(3, report.soulCount)
        assertEquals(1, report.warningCount)
        assertEquals(2, report.diagnostics.single { it.code == "duplicate_soul_event" }.relatedSources.size)
    }

    @Test
    fun `same event id on another map is a distinct soul event`() = runTest {
        val report = GetScanReport(FakeRepository(resultsWithRepeatedSouls()))(MapId(2))

        assertEquals(MapId(2), report.mapId)
        assertEquals("Map 2", report.mapName)
        assertEquals(1, report.soulCount)
        assertEquals(1, report.souls.size)
        assertTrue(report.diagnostics.none { it.code == "duplicate_soul_event" })
        assertEquals(2, report.souls.single().source.mapId)
        assertEquals(7, report.souls.single().source.eventId)
    }

    @Test
    fun `map filter scopes soul details counts warnings and related locations`() = runTest {
        val report = GetScanReport(FakeRepository(resultsWithRepeatedSouls()))(MapId(1))

        assertEquals(MapId(1), report.mapId)
        assertEquals("Map 1", report.mapName)
        assertEquals(2, report.soulCount)
        assertEquals(3, report.souls.filter { it.source.eventId == 7 }.size)
        assertEquals(1, report.warningCount)
        assertEquals(3, report.diagnostics.single { it.code == "duplicate_soul_event" }.relatedSources.size)
        assertTrue(report.diagnostics.single { it.code == "duplicate_soul_event" }.relatedSources.all { it.mapId == 1 })
    }

    @Test
    fun `selected map name comes from an item source when no souls exist`() = runTest {
        val report = GetScanReport(
            FakeRepository(
                ScanResults(
                    schemaVersion = 1,
                    status = ScanStatus.SUCCESS,
                    items = listOf(item("potion", 1, 3)),
                    souls = emptyList(),
                    tutorStations = emptyList(),
                    diagnostics = emptyList(),
                )
            )
        )(MapId(3))

        assertEquals(MapId(3), report.mapId)
        assertEquals("Map 3", report.mapName)
        assertEquals(0, report.soulCount)
        assertTrue(report.souls.isEmpty())
    }

    @Test
    fun `selected map without artifact source name keeps map name absent`() = runTest {
        val report = GetScanReport(
            FakeRepository(
                ScanResults(
                    schemaVersion = 1,
                    status = ScanStatus.SUCCESS,
                    items = emptyList(),
                    souls = emptyList(),
                    tutorStations = emptyList(),
                    diagnostics = listOf(diagnosticWithoutSource()),
                )
            )
        )(MapId(3))

        assertEquals(MapId(3), report.mapId)
        assertEquals(null, report.mapName)
        assertEquals(0, report.soulCount)
        assertTrue(report.souls.isEmpty())
    }

    @Test
    fun `global report has no requested map scope and preserves scanner diagnostics`() = runTest {
        val report = GetScanReport(FakeRepository(resultsWithRepeatedSouls().copy(
            diagnostics = listOf(diagnostic("scanner_warning", Severity.WARNING, 1)),
        )))()

        assertEquals(null, report.mapId)
        assertEquals(null, report.mapName)
        assertEquals(3, report.soulCount)
        assertEquals(2, report.warningCount)
        assertEquals(0, report.errorCount)
        assertEquals("scanner_warning", report.diagnostics.first().code)
        assertEquals("duplicate_soul_event", report.diagnostics.last().code)
    }

    @Test
    fun `scoped scanner warnings and errors remain alongside derived warnings`() = runTest {
        val report = GetScanReport(
            FakeRepository(
                resultsWithRepeatedSouls().copy(
                    diagnostics = listOf(
                        diagnostic("scanner_warning", Severity.WARNING, 1),
                        diagnostic("scanner_error", Severity.ERROR, 1),
                    ),
                )
            )
        )(MapId(1))

        assertEquals(2, report.warningCount)
        assertEquals(1, report.errorCount)
        assertEquals(
            listOf("scanner_warning", "scanner_error", "duplicate_soul_event"),
            report.diagnostics.map { it.code },
        )
    }

    @Test
    fun `failed filtered report remains unusable with duplicate warning`() = runTest {
        val report = GetScanReport(
            FakeRepository(resultsWithRepeatedSouls().copy(status = ScanStatus.FAILED))
        )(MapId(1))

        assertEquals(ScanStatus.FAILED, report.status)
        assertFalse(report.usable)
        assertEquals(1, report.warningCount)
        assertEquals(2, report.soulCount)
    }

    private fun successWithWarning() = ScanResults(
        schemaVersion = 1,
        status = ScanStatus.SUCCESS,
        items = listOf(item("potion", 1)),
        souls = emptyList(),
        tutorStations = emptyList(),
        diagnostics = listOf(diagnostic("warning", Severity.WARNING, 1)),
    )

    private fun resultsWithTwoMaps() = ScanResults(
        schemaVersion = 1,
        status = ScanStatus.SUCCESS,
        items = listOf(item("pokeball", 1), item("potion", 3, 2)),
        souls = listOf(soul(1), soul(2)),
        tutorStations = listOf(TutorStation("station", "Tutor", emptyList())),
        diagnostics = listOf(
            diagnostic("map_one_warning", Severity.WARNING, 1),
            diagnostic("map_two_warning", Severity.WARNING, 2),
        ),
    )

    private fun resultsWithRepeatedSouls() = ScanResults(
        schemaVersion = 1,
        status = ScanStatus.SUCCESS,
        items = emptyList(),
        souls = listOf(
            soul(1, 7, 0, "stg_a1f3", listOf("surf"), "First"),
            soul(1, 7, 1, "stg_b2e7", listOf("cut"), "Second"),
            soul(1, 7, 2, "stg_c4h1", listOf("bike"), "Third"),
            soul(1, 8, 0, "stg_d8k3", emptyList(), "Fourth"),
            soul(2, 7, 0, "stg_e5m9", listOf("surf"), "Other map"),
        ),
        tutorStations = emptyList(),
        diagnostics = emptyList(),
    )

    private fun resultsWithFourSouls() = ScanResults(
        schemaVersion = 1,
        status = ScanStatus.SUCCESS,
        items = emptyList(),
        souls = listOf(
            soul(1, 7, 0, "stg_a1f3", listOf("surf"), "First"),
            soul(1, 7, 1, "stg_b2e7", listOf("cut"), "Second"),
            soul(1, 8, 0, "stg_d8k3", emptyList(), "Third"),
            soul(2, 7, 0, "stg_e5m9", listOf("surf"), "Other map"),
        ),
        tutorStations = emptyList(),
        diagnostics = emptyList(),
    )

    private fun item(itemId: String, quantity: Int, mapId: Int = 1) = ItemFinding(
        itemId = itemId,
        quantity = quantity,
        stageId = "stg_a1f3",
        requires = emptyList(),
        source = source(mapId),
        tags = emptyList(),
        notes = "",
    )

    private fun soul(
        mapId: Int,
        eventId: Int = 7,
        pageIndex: Int = 0,
        stageId: String = "stg_a1f3",
        requires: List<String> = emptyList(),
        notes: String = "",
    ) = SoulFinding(
        stageId = stageId,
        requires = requires,
        source = source(mapId, eventId, pageIndex),
        notes = notes,
    )

    private fun diagnostic(code: String, severity: Severity, mapId: Int) = Diagnostic(
        code = code,
        severity = severity,
        message = "message",
        source = source(mapId),
    )

    private fun diagnosticWithoutSource() = Diagnostic(
        code = "missing_source",
        severity = Severity.WARNING,
        message = "message",
        source = null,
    )

    private fun source(mapId: Int, eventId: Int = 7, pageIndex: Int = 0) = Source(
        kind = null,
        command = null,
        mapId = mapId,
        mapName = "Map $mapId",
        eventId = eventId,
        eventName = "Event",
        pageIndex = pageIndex,
        commandIndex = 0,
        x = 4,
        y = 5,
    )

    private class FakeRepository(private val results: ScanResults) : ScanResultsRepository {
        override suspend fun getScanResults(): ScanResults = results
    }
}
