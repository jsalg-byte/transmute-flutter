# Implementation checklist and surface map

- [x] Contract operations verified: login, refresh/logout/me, plans/catalog,
  active-session discovery/start/read, session exercises/sets/rest/complete/
  discard, and completed history are all explicitly specified.
- [x] Bootstrap pinned Flutter/Dart dependencies and configuration.
- [x] Implement repository interfaces plus contract-faithful mock and REST adapters.
- [x] Implement protected routes, responsive shell, and every in-scope product slice.
- [x] Add unit, widget, native integration tests, release artifacts, and interviewer handoff documentation.

| Screen | Route | Provider/controller | Repository method | API operation |
| --- | --- | --- | --- | --- |
| Login | `/login` | `authControllerProvider` | `AuthRepository.login` | `POST /auth/login` |
| Plans | `/plans` | `plansProvider`, `activeSessionProvider` | `PlanRepository.listPlans`, `SessionRepository.activeSession` | `GET /workout-plans`, `GET /workout-sessions/active` |
| Plan detail | `/plans/:planId` | `planProvider`, `activeSessionProvider` | `PlanRepository.getPlan`, `SessionRepository.startSession` | `GET /workout-plans/{id}`, `POST /workout-sessions` |
| Active workout | `/session` | `activeSessionProvider` | `SessionRepository.activeSession`, all session mutations | `GET /workout-sessions/active`, session endpoints below |
| Exercise picker | dialog on `/session` | `exerciseSearchProvider` | `PlanRepository.searchExercises` | `GET /exercises?q=` |
| History | `/history` | `historyProvider` | `SessionRepository.completedHistory` | `GET /workout-sessions?status=completed` |
| Completed detail | `/history/:sessionId` | `sessionDetailProvider` | `SessionRepository.getSession` | `GET /workout-sessions/{id}` |

Session mutations map one-for-one to the contract: `PATCH /workout-sessions/{id}`
for `restEndsAt`; `POST`/`DELETE` session exercise endpoints; `POST`, `PATCH`,
and `DELETE` logged-set endpoints; `POST /complete`; and confirmed `DELETE`
for discard. The REST adapter deliberately has no Expo compatibility fallbacks.
