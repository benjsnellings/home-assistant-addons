# Changelog

## 0.3.4

- Stop running Claude/Cursor/Pi updates in cont-init (Pi `npm install` hung and Supervisor restarted the add-on)
- Refresh tools in the background tool-updater service after boot, with per-step timeouts

## 0.3.3

- Set `init: false` so s6-overlay can be PID 1 (fixes `s6-overlay-suexec: fatal: can only run as pid 1`)

## 0.3.2

- Install Node.js 22 from official binaries (bookworm apt Node 18 cannot run Pi)
- Switch Pi package to `@earendil-works/pi-coding-agent`

## 0.3.1

- Switch to Debian bookworm base (glibc) so Cursor Agent's bundled Node works
- Use glibc Claude binaries to match the new base

## 0.3.0

- Install Claude Code, Cursor Agent, and Pi; keep them current via start + 6h update hooks
- Add `cursor_api_key`, `openrouter_api_key`, `openrouter_model` for plan/provider auth
- Add writable `/workspace` for Multica agent workdirs
- Leave default `runtime_name` empty so all three tools register

## 0.2.1

- Require Multica token; stop s6 crash-loops on auth/config failure
- Pin Multica + Claude downloads with SHA256 verification
- Re-login when token option is set (token rotation)
- Remove unused log_level option

## 0.2.0

- Dedicated read-write Multica daemon container
- Overrideable `device_name` / `runtime_name`
- s6-overlay service supervision

## 0.1.0

- Initial combined add-on (superseded)
