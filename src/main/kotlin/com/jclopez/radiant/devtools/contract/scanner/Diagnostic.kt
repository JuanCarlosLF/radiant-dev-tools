package com.jclopez.radiant.devtools.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Diagnostic(
    val code: String,
    val severity: Severity,
    val message: String,
    val source: Source? = null,
)

@Serializable
enum class Severity {
    @SerialName("warning")
    WARNING,

    @SerialName("error")
    ERROR,
}
