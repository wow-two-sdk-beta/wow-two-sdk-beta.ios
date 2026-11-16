# Background uploads

Use one `BackgroundUploads` per fixed iOS session identifier. Submit a file-body request with a non-secret ID that
identifies the account, destination and immutable content. The session can continue while the app is suspended.
A repeated ID attaches to the matching in-flight transfer, and a reply already delivered during reconnect is
available once. Persist the application's queue and reconcile it against the authoritative server after relaunch.

Pass UIKit's background session completion to `reconnect(completion:)` for the matching identifier. The SDK calls it
on the main actor after URLSession has delivered its events. `cancelUploads(includingUnidentified:matching:)`
cancels session tasks that outlived their original callers. Cancel the Swift task to cancel its attached transfer.

Use a trusted HTTPS upload endpoint that serves the file PUT directly. iOS background sessions follow redirects
automatically. The SDK accepts completion from the original URL and leaves application receipt validation to the
caller. The helper bounds held response bytes and does not persist a credential or a photo copy itself.
