package com.jclopez.radiant.devtools.adapter.scanner

import com.jclopez.radiant.devtools.contract.scanner.Diagnostic
import com.jclopez.radiant.devtools.contract.scanner.ItemFinding
import com.jclopez.radiant.devtools.contract.scanner.ScanResults
import com.jclopez.radiant.devtools.contract.scanner.ScanStatus
import com.jclopez.radiant.devtools.contract.scanner.Severity
import com.jclopez.radiant.devtools.contract.scanner.SoulFinding
import com.jclopez.radiant.devtools.contract.scanner.Source
import com.jclopez.radiant.devtools.contract.scanner.SourceKind
import com.jclopez.radiant.devtools.contract.scanner.TutorCost
import com.jclopez.radiant.devtools.contract.scanner.TutorOffer
import com.jclopez.radiant.devtools.contract.scanner.TutorStation
import kotlinx.serialization.SerializationException
import java.io.IOException
import java.nio.file.Path
import kotlinx.coroutines.test.runTest
import kotlin.io.path.createTempFile
import kotlin.io.path.deleteIfExists
import kotlin.io.path.writeText
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertNull

class ScanResultReaderTest {

    private val reader = ScanResultReader()
    private val tempFiles = mutableListOf<Path>()

    @AfterTest
    fun cleanTempFiles() {
        tempFiles.forEach { it.deleteIfExists() }
        tempFiles.clear()
    }

    @Test
    fun `read() given complete v1 document when read then maps every field exactly`() = runTest {
        // GIVEN
        val path = writeTemp(resourceText("scan-results-v1-complete.json"))

        // WHEN
        val result = reader.read(path)

        // THEN
        assertEquals(expectedComplete(), result)
    }

    @Test
    fun `read() given explicit empty collections when read then returns empty lists`() = runTest {
        // GIVEN
        val path = writeTemp(
            """{"schema_version":1,"status":"success","items":[],"souls":[],"tutor_stations":[],"diagnostics":[]}"""
        )

        // WHEN
        val result = reader.read(path)

        // THEN
        assertEquals(ScanResults(1, ScanStatus.SUCCESS, emptyList(), emptyList(), emptyList(), emptyList()), result)
    }

    @Test
    fun `read() given missing required root key when read then fails`() = runTest {
        // GIVEN
        val path = writeTemp(
            """{"schema_version":1,"status":"success","items":[],"souls":[],"tutor_stations":[]}"""
        )

        // WHEN
        val failure = runCatching { reader.read(path) }.exceptionOrNull()

        // THEN
        assertIs<SerializationException>(failure)
    }

    @Test
    fun `read() given missing required nested field when read then fails`() = runTest {
        // GIVEN
        val path = writeTemp(completeJson().replace(""""quantity": 3,""", ""))

        // WHEN
        val failure = runCatching { reader.read(path) }.exceptionOrNull()

        // THEN
        assertIs<SerializationException>(failure)
    }

    @Test
    fun `read() given nullable field present with null when read then accepts null`() = runTest {
        // GIVEN
        val path = writeTemp(
            """{"schema_version":1,"status":"success","items":[],"souls":[],"tutor_stations":[],"diagnostics":[{"code":"missing_stage","severity":"warning","message":"m","source":null}]}"""
        )

        // WHEN
        val result = reader.read(path)

        // THEN
        assertNull(result.diagnostics.single().source)
    }

    @Test
    fun `read() given nullable field absent when read then fails`() = runTest {
        // GIVEN
        val path = writeTemp(
            """{"schema_version":1,"status":"success","items":[],"souls":[],"tutor_stations":[],"diagnostics":[{"code":"missing_stage","severity":"warning","message":"m"}]}"""
        )

        // WHEN
        val failure = runCatching { reader.read(path) }.exceptionOrNull()

        // THEN
        assertIs<SerializationException>(failure)
    }

    @Test
    fun `read() given unknown key when read then fails`() = runTest {
        // GIVEN
        val path =
            writeTemp(completeJson().replace(""""status": "success"""", """"status": "success", "zzz_unknown": 1"""))

        // WHEN
        val failure = runCatching { reader.read(path) }.exceptionOrNull()

        // THEN
        assertIs<SerializationException>(failure)
    }

    @Test
    fun `read() given unsupported schema version when read then rejects the document`() = runTest {
        // GIVEN
        val path = writeTemp(completeJson().replace(""""schema_version": 1""", """"schema_version": 42"""))

        // WHEN
        val failure = runCatching { reader.read(path) }.exceptionOrNull()

        // THEN
        assertIs<IllegalStateException>(failure)
    }

    @Test
    fun `read() given missing file when read then fails`() = runTest {
        // GIVEN
        val missing = createTempFile("absent-scan", ".json")
        missing.deleteIfExists()

        // WHEN
        val failure = runCatching { reader.read(missing) }.exceptionOrNull()

        // THEN
        assertIs<IOException>(failure)
    }

    private fun completeJson(): String = resourceText("scan-results-v1-complete.json")

    private fun resourceText(name: String): String =
        requireNotNull(javaClass.getResourceAsStream("/scanner/$name")) { "Missing test resource: $name" }
            .bufferedReader().readText()

    private fun writeTemp(content: String): Path {
        val path = createTempFile("scan-results", ".json")
        path.writeText(content)
        tempFiles.add(path)
        return path
    }

    private fun expectedComplete(): ScanResults = ScanResults(
        schemaVersion = 1,
        status = ScanStatus.SUCCESS,
        items = listOf(
            ItemFinding(
                itemId = "POTION",
                quantity = 3,
                stageId = "stg_c4h1",
                requires = listOf("rock_smash"),
                source = Source(
                    kind = SourceKind.EVENT,
                    command = "pbReceiveItem(:POTION, 3)",
                    mapId = 2,
                    mapName = "Pueblo Hojaverde",
                    eventId = 37,
                    eventName = "Test Event",
                    pageIndex = 0,
                    commandIndex = 1,
                    x = 19,
                    y = 19,
                ),
                tags = listOf("hidden", "gift"),
                notes = "Hidden reward in the eastern room",
            )
        ),
        souls = listOf(
            SoulFinding(
                stageId = "stg_f7n2",
                requires = listOf("cut"),
                source = Source(
                    kind = SourceKind.EVENT,
                    command = null,
                    mapId = 4,
                    mapName = "Ruta 205",
                    eventId = 12,
                    eventName = "Soul Event",
                    pageIndex = 1,
                    commandIndex = 0,
                    x = 8,
                    y = 30,
                ),
                notes = "Wisp near the flowers",
            )
        ),
        tutorStations = listOf(
            TutorStation(
                id = "tutor_pueblo",
                name = "Move Tutor",
                offers = listOf(
                    TutorOffer(
                        move = "ROCKSMASH",
                        cost = TutorCost(greenShard = 2, redShard = 0, blueShard = 1, yellowShard = 0),
                    )
                ),
            )
        ),
        diagnostics = listOf(
            Diagnostic(
                code = "missing_stage",
                severity = Severity.WARNING,
                message = "The annotated page does not declare a stage.",
                source = Source(
                    kind = SourceKind.EVENT,
                    command = null,
                    mapId = 2,
                    mapName = "Pueblo Hojaverde",
                    eventId = 37,
                    eventName = "Test Event",
                    pageIndex = 1,
                    commandIndex = 1,
                    x = 19,
                    y = 19,
                ),
            )
        ),
    )
}
