package com.jclopez.radiant.devtools.contract.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Derived, regenerable record of one concrete item acquisition.
 * Lives in the `items` collection of `scan-results.json`.
 */
@Serializable
data class ItemFinding(
    @SerialName("item_id")
    val itemId: String,
    val quantity: Int = 1,
    @SerialName("stage_id")
    val stageId: String,
    val requires: List<String> = emptyList(),
    val source: Source,
    val tags: List<String> = emptyList(),
    val notes: String = "",
)
