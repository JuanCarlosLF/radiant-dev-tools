package com.jclopez.radiant.devtools.adapter.scan

import com.jclopez.radiant.devtools.adapter.scanner.ScanResultReader
import com.jclopez.radiant.devtools.contract.scanner.ScanStatus
import kotlinx.coroutines.test.runTest
import java.io.IOException
import java.nio.file.Path
import kotlin.io.path.createTempFile
import kotlin.io.path.deleteIfExists
import kotlin.io.path.writeText
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

class JsonScanResultsRepositoryTest {

    private val tempFiles = mutableListOf<Path>()

    @AfterTest
    fun cleanTempFiles() {
        tempFiles.forEach { it.deleteIfExists() }
        tempFiles.clear()
    }

    @Test
    fun `delegates file reading to the injected reader`() = runTest {
        // GIVEN
        val path = createTempFile("scan-results", ".json")
        tempFiles.add(path)
        path.writeText(
            """{"schema_version":1,"status":"success","items":[],"souls":[],"tutor_stations":[],"diagnostics":[]}"""
        )
        val repository = JsonScanResultsRepository(ScanResultReader(), path)

        // WHEN
        val result = repository.getScanResults()

        // THEN
        assertEquals(ScanStatus.SUCCESS, result.status)
        assertTrue(result.items.isEmpty())
        assertTrue(result.souls.isEmpty())
        assertTrue(result.tutorStations.isEmpty())
        assertTrue(result.diagnostics.isEmpty())
    }

    @Test
    fun `propagates reader failures`() = runTest {
        // GIVEN
        val path = createTempFile("absent-scan", ".json")
        tempFiles.add(path)
        path.deleteIfExists()
        val repository = JsonScanResultsRepository(ScanResultReader(), path)

        // WHEN
        val failure = runCatching { repository.getScanResults() }.exceptionOrNull()

        // THEN
        assertIs<IOException>(failure)
    }
}
