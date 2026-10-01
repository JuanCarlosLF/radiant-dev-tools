package com.jclopez.radiant.devtools.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

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

@Serializable
enum class SourceKind {
    @SerialName("event")
    EVENT,

    @SerialName("shop")
    SHOP,
}
