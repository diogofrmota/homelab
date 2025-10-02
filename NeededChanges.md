# General:
- Direct Internet Exposure: Port-forwarding without additional security layers

# ArgoCD:
- Overly Permissive Ingress: whitelist-source-range: "0.0.0.0/0" exposes CLI/webhook endpoints globally
- No Authentication: Commented out OAuth2 proxy config leaves UI unprotected

Recomendations: Enable OAuth2 proxy for UI authentication. Restrict CLI/webhook ingress to your Tailscale IP range.

# Headscale:
- Admin exposed - OAuth2 protects admin but still externally accessible