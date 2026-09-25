package com.jclopez.radiant.devtools.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Shared provenance DTO for findings and diagnostics.
 *
 * Item findings populate [kind] and [command]; soul findings and
 * diagnostics leave them as `null`. Callers must validate the
 * fields their container requires.
 */
@Serializable
data class Source(
    val kind: SourceKind? = null,
    val command: String? = null,
    @SerialName("map_id")
    val mapId: Int,
    @SerialName("map_name")
    val mapName: String,
    @SerialName("event_id")
    val eventId: Int,
    @SerialName("event_name")
    val eventName: String,
    @SerialName("page_index")
    val pageIndex: Int,
    @SerialName("command_index")
    val commandIndex: Int,
    val x: Int,
    val y: Int,
)

/** Where an item delivery was detected. Only meaningful for items. */
@Serializable
enum class SourceKind {
    @SerialName("event")
    EVENT,

    @SerialName("shop")
    SHOP,
}
