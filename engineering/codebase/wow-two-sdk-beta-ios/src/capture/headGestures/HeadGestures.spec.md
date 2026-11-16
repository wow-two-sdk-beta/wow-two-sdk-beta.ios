# Headphone gestures

Use `HeadphoneGestures` on the main actor. The app must supply the localized
`NSMotionUsageDescription` in its Info.plist before it can start motion updates.
Connection observation does not start the motion stream. Start motion only
when the app is ready to receive a gesture and motion-capable headphones are
connected. Stop when that screen leaves, becomes inactive, or no longer needs
a gesture. No samples are written to disk.

`HeadGestureDetector` accepts monotonic timestamps and pitch and yaw in radians.
It tracks a one-second rolling resting position, ignoring the first half second
after start. A nod is a pitch excursion and return with little yaw. A shake
has opposing yaw excursions with little pitch. A 1.2-second cooldown
prevents repeated actions. Device testing determines how these defaults
behave while speaking and posing.
