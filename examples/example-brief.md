# BRIEF — Add a rate-limit to the public API (worked example)

<!-- A sanitized illustration of a Phase-1 brief. Notice: the code the planner
     needs is INLINED. The premium session never opens the repo. -->

## Goal
Add a per-IP rate limit (60 req/min) to the public REST API. At the end,
requests over the limit return HTTP 429 with a `Retry-After` header, and the
limit is covered by tests.

## Constraints
- Node/Express, TypeScript strict. No new heavy dependencies — use the existing
  Redis client.
- Must not affect authenticated internal routes (`/internal/*`).
- Responses must stay JSON; error shape is `{ error: string }`.

## Acceptance criteria
- [ ] Over-limit requests return 429 + `Retry-After`.
- [ ] `/internal/*` is exempt.
- [ ] Unit tests cover: under limit, at limit, over limit, exempt route.
- [ ] `npm test` and `npm run lint` are green.

## Prior decisions that bind this work
- Redis is already the shared store (below) — do not introduce an in-memory
  limiter; it breaks across the 3 app instances.

## Repo context (inlined)

### `src/app.ts` (middleware registration)
```ts
import express from "express";
import { publicRouter } from "./routes/public";
import { internalRouter } from "./routes/internal";

export const app = express();
app.use(express.json());
app.use("/internal", internalRouter);
app.use("/", publicRouter);       // ← rate limit goes BEFORE this line
```

### `src/redis.ts` (the client to reuse)
```ts
import { createClient } from "redis";
export const redis = createClient({ url: process.env.REDIS_URL });
await redis.connect();
// available: redis.incr(key), redis.expire(key, seconds), redis.ttl(key)
```

### Test style — `src/routes/__tests__/public.test.ts` (existing pattern)
```ts
import request from "supertest";
import { app } from "../../app";

it("returns 200 for a normal request", async () => {
  const res = await request(app).get("/ping");
  expect(res.status).toBe(200);
});
```

## Known risks / traps
- Redis `incr` on first hit returns 1 — set the TTL only when the counter is
  created, or the window never resets.
- `Retry-After` is in seconds — compute from the key's remaining TTL.

## Out of scope
- Auth changes, dashboards, per-user (vs per-IP) limits — a later task.
