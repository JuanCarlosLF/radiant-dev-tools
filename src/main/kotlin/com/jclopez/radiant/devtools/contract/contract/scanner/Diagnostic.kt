package com.jclopez.radiant.devtools.contract.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Error or warning found during a scan.
 * Lives in the `diagnostics` collection of `scan-results.json`.
 * Diagnostics are never valid findings and never mix with
 * `items`, `souls` or `tutor_stations`. Tools key on [code], not on [message].
 */
@Serializable
data class Diagnostic(
    val code: String,
    val severity: Severity,
    val message: String,
    val source: Source? = null,
)

/** Diagnostic gravity. Any [ERROR] forces the scan status to `failed`. */
@Serializable
enum class Severity {
    @SerialName("warning")
    WARNING,

    @SerialName("error")
    ERROR,
}
