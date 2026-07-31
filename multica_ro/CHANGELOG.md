# Changelog

## 0.3.0

- Install Claude Code, Cursor Agent, and Pi; keep them current via start + 6h update hooks
- Add `cursor_api_key`, `openrouter_api_key`, `openrouter_model` for plan/provider auth
- Add writable `/workspace` (even when `/config` is read-only) for Multica agent workdirs
- Leave default `runtime_name` empty so all three tools register

## 0.2.1

- Require Multica token; stop s6 crash-loops on auth/config failure
- Pin Multica + Claude downloads with SHA256 verification
- Re-login when token option is set (token rotation)
- Mount share/media read-only to match the RO threat model
- Remove unused log_level option

## 0.2.0

- Dedicated read-only Multica daemon container
- Overrideable `device_name` / `runtime_name`
- s6-overlay service supervision

## 0.1.0

- Initial combined add-on (superseded)
