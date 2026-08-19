# Five-minute interviewer walkthrough

1. Launch mock mode and use `Demo Login`. Point out the protected route and
   that this path uses only resettable local fixture data.
2. On **Workout plans**, resize from phone to tablet to desktop. Show the bottom
   bar, rail, and desktop header navigation switching at the documented breakpoints.
3. Open **Upper A**. The prescription is ordered, has targets, and shows the
   last completed bench/row performance. Start the workout.
4. In **Workout**, log a bench set and call out the immediate pending row. Start
   a 1:30 rest timer; it is stored as an absolute deadline rather than an
   in-memory countdown. Add an eligible catalog exercise, then remove it before
   logging a set.
5. Finish the session and open its completed detail from **Workout history**.
   Show duration, working-set count, canonical volume, and the immutable set
   snapshot. Return to Upper A to show its performance becomes the prior context
   for the next workout.

Optional resilience moment: rerun with
`--dart-define=TRANSMUTE_MOCK_FAIL_FIRST_SET=true`, log a set, and use the
displayed retryable failure state. Explain that API mode uses the same repository
interfaces but makes only the standalone contract’s documented calls.
