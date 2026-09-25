package com.jclopez.radiant.devtools.contract.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Derived, regenerable record of one Spiritomb soul appearance.
 * Lives in the `souls` collection of `scan-results.json`.
 * Souls are not inventory items: no item id, quantity or source kind.
 */
@Serializable
data class SoulFinding(
    @SerialName("stage_id")
    val stageId: String,
    val requires: List<String> = emptyList(),
    val source: Source,
    val notes: String = "",
)
