package dev.technetsec.dysprosium

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService

/**
 * Quick Settings tile "PC": opens the app's quick sheet (wake, profiles, reboot to Windows).
 *
 * It launches MainActivity with the intent extra the quick_actions plugin reads, so Flutter gets
 * it exactly like an app-icon shortcut of type "sheet" (see lib/quick.dart). No platform channel.
 */
class PcTileService : TileService() {
    override fun onClick() {
        super.onClick()
        if (isLocked) unlockAndRun { open() } else open()
    }

    private fun open() {
        val intent = Intent(this, MainActivity::class.java)
            .setAction(Intent.ACTION_RUN)
            .putExtra(QUICK_ACTION_EXTRA, "sheet")
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this, 0, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    companion object {
        // quick_actions_android's QuickActions.EXTRA_ACTION (checked in 1.0.34). Re-check this if
        // quick_actions is upgraded and the tile stops opening the sheet.
        const val QUICK_ACTION_EXTRA = "some unique action key"
    }
}
