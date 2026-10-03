# Agent guide

## Orient first

- Read [architecture](docs/ARCHITECTURE.md) for the actual layer/state map and [decisions](docs/DECISIONS.md) for fixes and constraints that are easy to break.
- In [API_CONTRACT.md](docs/API_CONTRACT.md), use **Expo adapter contract (implemented core loop)** plus its failure/offline and general rules as the current contract. The later focused-demo endpoint/DTO tables are explicitly retired historical material; do not implement those routes in production code.
- Planning/spec documents (`PRD`, parity plan, build spec, launch roadmap, implementation checklist, vertical slices) describe intent or snapshots. When they disagree with current source or the implemented API contract, verify before following them.
- The Fastify API is a separate repository at `/Users/mzootfb/Sites/transmute-mobile`. API behavior or SQL migrations belong there; do not treat this Flutter checkout as the server or database.

## Change boundaries

- Keep widgets on Riverpod and repository interfaces. Register a feature service in `lib/core/providers.dart`, define its interface in `lib/core/domain/repositories.dart`, and implement both API and mock adapters in `lib/core/api/api_repositories.dart` and `lib/core/data/mock_repositories.dart`.
- Keep wire mapping in API repositories and use verified payload fields. No speculative casing/alias fallbacks. Server data is canonical; client optimistic state must remain explicitly pending until acknowledged.
- Nutrition has an unusual established contract: the meal payload field is named `grams`, but the quantity follows the food's saved serving unit. Check the **Food catalog and meals** entry in `docs/API_CONTRACT.md` before changing quantity conversions.
- `ActiveSessionController` owns active-workout writes and invalidation. Preserve capability-gated set replay, stable operation IDs, and the one-active-session invariant; details are in [DECISIONS.md](docs/DECISIONS.md) and [STATE_TRANSITIONS.md](docs/STATE_TRANSITIONS.md).
- Do not commit, push, or deploy unless the user asks for that action. Recheck current branch, working tree, API migration state, and external Coolify settings before release operations.

## UI/UX polish

- For UI polish, use the installed `better-ui` and `better-accessibility` skills as review lenses, not as a mandate to replace the product style. Preserve Transmute's identity, existing theme/palette preferences, and components in `lib/shared/design_system`; evolve those shared tokens/components before adding one-off styling.
- Those skills contain web/CSS examples. Translate principles into Flutter APIs (`ThemeData`, `Semantics`, focus/keyboard handling, touch targets, and reduced-motion-aware animations); do not copy CSS/ARIA instructions literally or impose iOS-native styling on every platform.
- Exercise loading, empty, error, disabled, success, and recovery states where relevant. The user performs browser verification; report non-browser checks separately and do not claim browser QA.

## Local development

Use the pinned FVM SDK (`.fvm/flutter_sdk/bin/flutter`), not a system Flutter.

```sh
.fvm/flutter_sdk/bin/flutter pub get
.fvm/flutter_sdk/bin/flutter run -d chrome --dart-define=TRANSMUTE_REPOSITORY_MODE=mock
.fvm/flutter_sdk/bin/flutter analyze
.fvm/flutter_sdk/bin/flutter test
```

For real API mode, run `-d web-server --web-hostname=localhost --web-port=8081` and add:

```sh
--dart-define=TRANSMUTE_REPOSITORY_MODE=api
--dart-define=TRANSMUTE_API_BASE_URL=https://api.transmute.mzootfb.xyz
```

Use `http://localhost:8081` exactly; CORS treats `127.0.0.1:8081` as a different, unallowed origin. Widget tests bind local sockets; sandbox socket denial happens before tests execute and is not an assertion failure. The user performs browser verification.

## Production web and migrations

- Production serves checked-in `release/web` through `Dockerfile`/Nginx. A plain `flutter build web` updates only `build/web`. For a requested production web release, run `./scripts/build_web_release.sh`, then include its generated `release/web` bundle with the source commit; otherwise Coolify may serve the previous UI. See [DEPLOYMENT.md](docs/DEPLOYMENT.md).
- Docker/Coolify does not apply API migrations. Inspect the exact schema and migration before applying one, then verify the affected authenticated API behavior; `/health` alone is insufficient. Migration history and live server state must be checked at task time.
- Do not put credentials or private service values in Dart defines or the generated bundle. The API base URL is public configuration.

## Documentation map

- [API contract](docs/API_CONTRACT.md) · [domain model](docs/DOMAIN_MODEL.md) · [session transitions](docs/STATE_TRANSITIONS.md)
- [design system](docs/DESIGN_SYSTEM.md) · [UI rules](docs/UI_SPEC.md)
- [deployment](docs/DEPLOYMENT.md) · [build specification](docs/FLUTTER_BUILD_SPEC.md)
- [current blockers and verification ownership](docs/BLOCKERS.md)
