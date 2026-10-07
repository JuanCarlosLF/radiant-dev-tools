package com.jclopez.radiant.devtools.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ScanResults(
    @SerialName("schema_version")
    val schemaVersion: Int,
    val status: ScanStatus,
    val items: List<ItemFinding>,
    val souls: List<SoulFinding>,
    @SerialName("tutor_stations")
    val tutorStations: List<TutorStation>,
    val diagnostics: List<Diagnostic>,
)

@Serializable
enum class ScanStatus {
    @SerialName("success")
    SUCCESS,

    @SerialName("failed")
    FAILED,
}

