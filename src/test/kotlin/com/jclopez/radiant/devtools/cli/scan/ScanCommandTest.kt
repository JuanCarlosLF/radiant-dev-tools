package com.jclopez.radiant.devtools.cli.scan

import com.jclopez.radiant.devtools.adapter.scan.JsonScanResultsRepository
import com.jclopez.radiant.devtools.adapter.scanner.ScanResultReader
import com.jclopez.radiant.devtools.application.scan.ScanResultsRepository
import com.jclopez.radiant.devtools.application.scan.report.GetScanReport
import com.jclopez.radiant.devtools.contract.scanner.ScanResults
import kotlinx.coroutines.test.runTest
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.PrintStream
import java.nio.file.Path
import kotlin.io.path.createTempFile
import kotlin.io.path.deleteIfExists
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals

class ScanCommandTest {

    private val tempFiles = mutableListOf<Path>()

    @AfterTest
    fun cleanTempFiles() {
        tempFiles.forEach { it.deleteIfExists() }
        tempFiles.clear()
    }

    @Test
    fun `renders actionable missing results guidance on stderr only`() = runTest {
        // GIVEN
        val path = createTempFile("missing-scan", ".json")
        tempFiles.add(path)
        path.deleteIfExists()
        val stdout = ByteArrayOutputStream()
        val stderr = ByteArrayOutputStream()
        val command = ScanCommand(
            GetScanReport(JsonScanResultsRepository(ScanResultReader(), path)),
            PrintStream(stdout),
            PrintStream(stderr),
        )

        // WHEN
        val exitCode = command.execute(emptyList())

        // THEN
        val resolvedPath = path.toAbsolutePath().normalize()
        val line = System.lineSeparator()
        assertEquals(3, exitCode)
        assertEquals("", stdout.toString(Charsets.UTF_8))
        assertEquals(
            "No se ha encontrado el resultado del escaneo \"$resolvedPath\"$line$line" +
                "Asegúrate de que la raíz es \"radiant-devtools\" y \"artifacts\\scan-results.json\" existe.$line" +
                "Asegúrate de que has generado el artefacto mediante el scanner Ruby antes.$line",
            stderr.toString(Charsets.UTF_8),
        )
    }

    @Test
    fun `keeps generic IO handling unchanged`() = runTest {
        // GIVEN
        val stdout = ByteArrayOutputStream()
        val stderr = ByteArrayOutputStream()
        val repository = object : ScanResultsRepository {
            override suspend fun getScanResults(): ScanResults = throw IOException("permission denied")
        }
        val command = ScanCommand(
            GetScanReport(repository),
            PrintStream(stdout),
            PrintStream(stderr),
        )

        // WHEN
        val exitCode = command.execute(emptyList())

        // THEN
        val line = System.lineSeparator()
        assertEquals(3, exitCode)
        assertEquals("", stdout.toString(Charsets.UTF_8))
        assertEquals("I/O error: permission denied$line", stderr.toString(Charsets.UTF_8))
    }
}
