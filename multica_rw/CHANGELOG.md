# Changelog

## 0.2.1

- Require Multica token; stop s6 crash-loops on auth/config failure
- Pin Multica + Claude downloads with SHA256 verification
- Re-login when token option is set (token rotation)
- Remove unused log_level option

## 0.2.0

- Dedicated read-write Multica daemon container
- Overrideable `device_name` / `runtime_name` (packaged defaults when blank)
- s6-overlay service supervision (Supervisor manages container lifecycle)

## 0.1.0

- Initial combined add-on (superseded by split RO/RW add-ons)
