# October 2026 image security validation

## Decision

Tested on 2026-10-29. **Package remediation verified; digest-only updates
rejected.** Every upstream candidate accepted the eMudhra test certificate with
its original CA bundle (HTTP 200, curl exit 0). None was adopted. Instead, the
existing digest-pinned Bookworm build and devcontainer environments now upgrade
CA certificates and Brotli before use, enforcing the fixed Brotli version floor.
Linux distribution and Rust version lines are unchanged.

Registry digests below are the multi-platform manifest digests returned by
`docker buildx imagetools inspect` for the existing tags, not assertions that
the images are secure. Local curl output identifies the tested userspace as
Linux x86_64; other platforms were not validated.

## Upstream candidates

| Location | Image tag | Candidate digest | eMudhra result | Brotli result | Decision |
| --- | --- | --- | --- | --- | --- |
| Dockerfile, database stage | `alpine:3.20` | `sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc` | Original CA bundle: HTTP 200, exit 0 | No Brotli package in untouched base; installing curl adds `brotli-libs 1.1.0-r2`, whose backport status was not verified | Reject candidate |
| Dockerfile, build stage | `rust:1.81` | `sha256:7b7f7ae5e49819e708369d49925360bde2af4f1962842e75a14af17342f08262` | HTTP 200, exit 0 | Debian Bookworm `libbrotli1 1.0.9-2+b6`: vulnerable | Reject candidate |
| .devcontainer/devcontainer.json | `mcr.microsoft.com/devcontainers/rust:1-1-bookworm` | `sha256:fc57fb865035c5395e85246c8842b071ced6e7cde727b3c98abbcc794eaf4759` | HTTP 200, exit 0 | Debian Bookworm `libbrotli1 1.0.9-2+b6`: vulnerable | Existing digest is still current, but fails security checks |
| Dockerfile, final stage | `scratch` | Not applicable | Cannot execute curl | No OS packages | Empty build base, not a registry image; preserve unchanged |

All three candidates were successfully pulled by digest before testing. The
Rust candidate contains `ca-certificates 20230311`; the devcontainer contains
`ca-certificates 20230311+deb12u1`.

### Certificate test

The Debian-based images were tested without package upgrades or the repository's
manual CA exclusions, using:

```sh
docker run --rm --entrypoint curl "$IMAGE" \
  --connect-timeout 15 --max-time 30 \
  -sS -o /dev/null -w 'HTTP %{http_code}\n' \
  https://dv-g3b-emudhra.we-have-a-problem.com/
```

Both returned `HTTP 200`, exit 0, with no certificate error on stderr.

Alpine does not include curl. In a disposable container, its original
`/etc/ssl/certs/ca-certificates.crt` was copied to `/tmp` before installing curl.
Testing with `--cacert /tmp/original-ca-certificates.crt` returned HTTP 200,
exit 0. Installing curl also installed `ca-certificates 20261020-r0`; testing
the resulting default trust store instead returned HTTP 000, exit 60, with:

```text
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

That second result validates only the modified disposable container, not the
upstream Alpine digest. It must not be used to approve the candidate.

## Configured environment validation

| Environment | Change | Brotli result | HTTPS control | eMudhra result |
| --- | --- | --- | --- | --- |
| Rust build stage, existing pinned base | Upgrade CA certificates and `libbrotli1`; enforce package version floor; retain CA exclusions | `1.0.9-2+deb12u1`, passes Debian version comparison | HTTP 200 | HTTP 000, exit 60 |
| Devcontainer, existing pinned base | New Dockerfile applies the same fixes before startup, replacing the CA-only post-create command | `1.0.9-2+deb12u1`, passes Debian version comparison | HTTP 200 | HTTP 000, exit 60 |
| Alpine database stage, existing pinned base | No change; validate existing CA package installation and exclusions | No Brotli package in configured stage before test-tool installation | HTTP 200 | HTTP 000, exit 60 |

The edited Rust security layer and new devcontainer Dockerfile were built locally.
Both install `ca-certificates 20250419~deb12u2`. The positive HTTPS control was
`https://deb.debian.org/debian/`; an initial control using example.com could not
resolve and was replaced. Certificate failures captured stderr:

```text
curl: (60) SSL certificate problem: unable to get local issuer certificate
```

For Alpine, the configured stage's CA bundle was saved before installing curl
and explicitly selected with `--cacert` for both checks. This avoids counting
test-tool package installation as a fix to the configured trust store.

Build-time `dpkg --compare-versions` checks fail if the installed Bookworm Brotli
version is below `1.0.9-2+deb12u1`. Debian package version comparison handles the
backported fix correctly without relying on curl's upstream Brotli version string.

## Dependency and scope findings

- The original tracked-file inventory contained one Dockerfile, one devcontainer
  configuration, and GitHub Actions workflows; no Compose or GitLab CI files.
  Workflows have no additional explicit container image inputs.
- All external Dockerfile base references remain digest
  pinned. The final `FROM scratch` has no upstream digest to resolve.
- Cargo.lock has no matches for Brotli, OpenSSL, native-tls, Rustls, WebPKI,
  curl, or Reqwest. No application dependency changes were justified for these
  two issues by that inventory; this is not a full Rust vulnerability audit.
- The scratch runtime copies only the compiled Rust binary and GeoLite2 data.
  It cannot run the requested certificate or package commands. Full application
  compilation was interrupted before completion. Final image construction and
  a binary dependency audit were not performed; the database download requires
  a MaxMind license key. No claim is made that the binary is vulnerability-free.
- Existing CA exclusions were retained, with devcontainer exclusions moved to
  image build time. Configured trust stores passed the checks above. These
  results do not establish that the untouched upstream images are fixed.
- The devcontainer's Rust OCI feature remains at `:1` with `version: latest`.
  It installs additional tooling after the base image; its resolved artifact and
  resulting environment were not validated. It is not a Docker base image.
- Makefile publishing tags and README deployment examples refer to this
  repository's generated application image, not additional upstream base images.
  They were not changed to invented digests for artifacts not built here.
- No GitHub Actions files were changed. Every existing workflow already invokes
  the SHA-pinned Ubuntu CA helper and sets `NODE_OPTIONS=--use-openssl-ca` plus
  OS certificate paths. The helper is a composite action invoking its CA script;
  it does not establish that the runner's bundled Node/Brotli is patched.
  GitHub-hosted runner images and JavaScript action runtimes remain GitHub-managed
  and were not locally validated. No claim is made that their Brotli exposure
  has been remediated by this PR.

## Required follow-up

Digest-only remediation cannot pass the requested gate on these existing tags.
The package-level fixes above address the configured Bookworm environments.
Obtain patched upstream images on the same release/flavor lines before replacing
their digests, and retain CA mitigations until replacements pass validation.

For Bookworm, Debian identifies `1.0.9-2+deb12u1` as the fixed Brotli package
version. Validate installed versions with Debian version comparison, since
backported fixes need not change the upstream `1.0.9` version string.
Alpine 3.20 ended normal support on 2026-04-01; changing its release line
requires approval under the flavor/version constraint.

Re-run the certificate test and package checks on every proposed digest and
configured build/devcontainer environment before accepting any image update.

## References

- <https://nvd.nist.gov/vuln/detail/CVE-2026-111497>
- <https://security-tracker.debian.org/tracker/CVE-2026-111497>
- <https://nodejs.org/en/blog/vulnerability/october-2026-security-releases>
- <https://alpinelinux.org/releases/>