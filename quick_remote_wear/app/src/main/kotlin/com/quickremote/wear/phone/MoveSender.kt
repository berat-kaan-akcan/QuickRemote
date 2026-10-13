package com.quickremote.wear.phone

/**
 * Paces the laser's movement on its way to the phone. A message takes two
 * hops (watch, phone, computer) over a link whose speed varies, so the watch
 * keeps at most [window] movements on their way: one leaves every
 * [minIntervalMs] until that many wait for the phone's answer ([delivered]),
 * and new movement is summed meanwhile. A slow link then makes larger steps
 * instead of a growing queue. An answer that has not come after [lostMs] is
 * taken as lost.
 */
class MoveSender(
    private val minIntervalMs: Long,
    private val window: Int = 1,
    private val lostMs: Long = Long.MAX_VALUE,
) {
    private var x = 0f
    private var y = 0f

    /** When each unanswered movement left, oldest first. */
    private val onTheirWay = ArrayDeque<Long>()
    private var sentAtMs: Long? = null

    fun add(dx: Float, dy: Float) {
        x += dx
        y += dy
    }

    /** The movement to send at [nowMs], or null when there is none or it has to wait. */
    fun take(nowMs: Long): Pair<Float, Float>? {
        if (waitMs(nowMs) != 0L) return null
        onTheirWay.addLast(nowMs)
        sentAtMs = nowMs
        return rest()
    }

    /**
     * How long the summed movement has to wait, for the interval or for the
     * oldest unanswered movement to count as lost; 0: it can go. Null when
     * nothing moved, or when only an answer ([delivered]) can let it go.
     */
    fun waitMs(nowMs: Long): Long? {
        if (x == 0f && y == 0f) return null
        while (onTheirWay.isNotEmpty() && nowMs - onTheirWay.first() >= lostMs) onTheirWay.removeFirst()
        val interval = sentAtMs?.let { (it + minIntervalMs - nowMs).coerceAtLeast(0) } ?: 0
        if (onTheirWay.size < window) return interval
        if (lostMs == Long.MAX_VALUE) return null
        return maxOf(interval, onTheirWay.first() + lostMs - nowMs)
    }

    /** The phone answered the oldest movement on its way. */
    fun delivered() {
        onTheirWay.removeFirstOrNull()
    }

    /** What is left when the finger lifts, to send whatever is on its way. */
    fun rest(): Pair<Float, Float>? {
        if (x == 0f && y == 0f) return null
        return (x to y).also {
            x = 0f
            y = 0f
        }
    }

    fun reset() {
        x = 0f
        y = 0f
        onTheirWay.clear()
        sentAtMs = null
    }
}
