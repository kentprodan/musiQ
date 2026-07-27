# musiQ — KDE Plasma client (placeholder)

Not implemented yet. Planned: Qt/QML with Kirigami (latest), following KDE
HIG conventions natively rather than through a themed webview.

Will consume `core/musiq-core` through a Rust Qt binding (e.g. `cxx-qt`)
calling directly into the core crate — Linux desktop clients can link
`musiq-core` in-process rather than crossing the UniFFI boundary, since
they share the same language.

Until this exists, Linux desktop users are served by the interim
[`clients/desktop-tauri`](../desktop-tauri) client. See
[`docs/architecture.md`](../../docs/architecture.md) for the overall plan.
