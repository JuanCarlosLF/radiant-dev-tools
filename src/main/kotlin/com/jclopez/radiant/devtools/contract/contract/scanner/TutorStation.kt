package com.jclopez.radiant.devtools.contract.contract.scanner

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Persistent tutor station grouping the offers taught by one NPC.
 * Lives in the `tutor_stations` collection of `scan-results.json`.
 * The visible UI order of each offer is its index inside [offers].
 */
@Serializable
data class TutorStation(
    val id: String,
    val name: String,
    val offers: List<TutorOffer> = emptyList(),
)

/** One persistent offer inside a [TutorStation]: move taught and shard cost. */
@Serializable
data class TutorOffer(
    val move: String,
    val cost: TutorCost = TutorCost(),
)

/**
 * Sparse shard cost. Omitted zeros and `{}` mean free.
 * No unknown keys and no negative values.
 */
@Serializable
data class TutorCost(
    @SerialName("green_shard")
    val greenShard: Int = 0,
    @SerialName("red_shard")
    val redShard: Int = 0,
    @SerialName("blue_shard")
    val blueShard: Int = 0,
    @SerialName("yellow_shard")
    val yellowShard: Int = 0,
)
