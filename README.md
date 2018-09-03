<img src="icon.png" width=150>

Good Spirits is a drink tracking iOS app that helps you stay under government limits for "low-risk" drinking. Includes charts and stats, the ability to pull your check-ins from Untappd, and the ability to sync your drinks as calories to HealthKit.

You can find the App Store version [here][app]. Unfortunately, HealthKit is not available in this release. You can always compile the app yourself to get this functionality.

<img src="screenshot.jpg" />

# Technical Details

Compiling the code should be pretty straight-forward. Just make sure to run `git submodule update --init --recursive` beforehand.

Note that there are three unique build configurations in this project, designed to toggle donation and HealthKit functionality. By default, all features should be enabled, but you can change this in your Scheme settings.

# Licensing

The source code is available under the GPL license with absolutely no support or maintenance commitments. Note that GPL-licensed code isn't compatible with the App Store. If you're interested in releasing a fork on the App Store, please contact me.

You can find licenses for all third-party assets in the Licenses.txt file.

The app icon is **not** licensed for public use! You may not use the name of the app ("Good Spirits") nor the app icon in any of your own projects.

[app]: https://itunes.apple.com/us/app/good-spirits/id1434237439?mt=8&ref=github