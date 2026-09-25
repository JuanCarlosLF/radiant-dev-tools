package com.jclopez.radiant.devtools.contract.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Root container published by the Ruby scanner as `scan-results.json`.
 *
 * Holds exactly the six approved root keys: schema version, status,
 * the three finding collections and diagnostics. No extra keys.
 */
@Serializable
data class ScanResults(
    @SerialName("schema_version")
    val schemaVersion: Int,
    val status: ScanStatus,
    val items: List<ItemFinding> = emptyList(),
    val souls: List<SoulFinding> = emptyList(),
    @SerialName("tutor_stations")
    val tutorStations: List<TutorStation> = emptyList(),
    val diagnostics: List<Diagnostic> = emptyList(),
)

/** Execution status of a scan. Any error forces [FAILED]; warnings keep [SUCCESS]. */
@Serializable
enum class ScanStatus {
    @SerialName("success")
    SUCCESS,

    @SerialName("failed")
    FAILED,
}

