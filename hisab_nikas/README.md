# hisab_nikas

Flutter ERP app with local SQLite storage and an optional Laravel API connection.

## Connecting to a local Laravel API

- Start Laravel so it listens on the network: `php artisan serve --host=0.0.0.0`.
- In the app's Settings, set the API base URL to the Laravel API root ending in `/api/v1`.
- For an Android emulator, use `http://10.0.2.2:8000/api/v1`.
- For a physical phone, use the computer's LAN IP (for example, `http://192.168.1.10:8000/api/v1`) and keep both devices on the same network.
- Use **Test Connection** in Settings. The Laravel API must provide `GET /test` and `POST /parties/sync`.

Party create, edit, and delete requests are sent to Laravel first, so successful changes are stored in the configured MySQL database and visible in phpMyAdmin. The app also caches server records in local SQLite. If Laravel is unavailable or rejects a request, the app shows the error instead of reporting a successful MySQL save. Android permits HTTP traffic for this local-development setup; use HTTPS for production.

On Flutter Web, SQLite data is persisted in the browser's IndexedDB. The `web/sqlite3.wasm` and `web/sqflite_sw.js` runtime files are required; regenerate them after updating `sqflite_common_ffi_web` with `dart run sqflite_common_ffi_web:setup`. Browser data is scoped to the site origin, including its port.

