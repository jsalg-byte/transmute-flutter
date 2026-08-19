# Focused demo: product decisions

## One active workout

The demo presents one active workout at a time. A second start attempt is not
treated as a convenience feature: it must resume the existing record. This
keeps set order, rest state, and completion evidence intelligible.

## Rest time is a deadline, not a counter

`restEndsAt` is an absolute UTC timestamp in durable device storage. A rebuild
or restart derives remaining time from that deadline, avoiding timer drift and
false resets.

## Mock mode and API mode have different jobs

Mock mode provides repeatable local demonstrations. API mode uses an explicit
adapter for the existing `/v1` service and never assumes its aggregate read
model is the focused demo's original DTO contract.

## Offline set logging is command replay, not a local workout fork

A validated set is first stored in protected device storage with a UUID
`clientOperationId`. It appears as **saved on this device, waiting to sync**.
The command is retried periodically and on an explicit **Sync now** action.
The client never marks it as server-logged until the API acknowledges it, and a
workout cannot be finished while pending commands remain.

Network/5xx failures remain eligible for automatic retry. A validation,
authorization, or completed-workout rejection is retained as an attention item
but is not retried automatically; the user can resolve it by restoring the
active record or discarding the workout intentionally.

Safe replay requires API migration `006_offline_set_sync.sql` and
`GET /v1/capabilities` returning `offlineSetSync: true`. The Flutter client
uses the previous online-only behavior when that capability is absent; this
prevents duplicate sets against an older deployment.

## Deliberate exclusions

The demo owns auth, plans, active set logging/rest, history, responsive
navigation, and mock/API adapters. It does not expose unrelated Expo surfaces
as incomplete routes merely because the API has endpoints for them.
