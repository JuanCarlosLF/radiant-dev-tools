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

    private fun item(itemId: String, quantity: Int, mapId: Int = 1) = ItemFinding(
        itemId = itemId,
        quantity = quantity,
        stageId = "stg_a1f3",
        requires = emptyList(),
        source = source(mapId),
        tags = emptyList(),
        notes = "",
    )

    private fun soul(mapId: Int) = SoulFinding(
        stageId = "stg_a1f3",
        requires = emptyList(),
        source = source(mapId),
        notes = "",
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

    private fun source(mapId: Int) = Source(
        kind = null,
        command = null,
        mapId = mapId,
        mapName = "Map $mapId",
        eventId = 7,
        eventName = "Event",
        pageIndex = 0,
        commandIndex = 0,
        x = 4,
        y = 5,
    )

    private class FakeRepository(private val results: ScanResults) : ScanResultsRepository {
        override suspend fun getScanResults(): ScanResults = results
    }
}
