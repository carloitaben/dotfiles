# Services, Layers, And Modules

Use this when defining service tags, module surfaces, layer implementations, runtime wiring, typed errors, or `Effect.fn` operation boundaries.

## Module Surface

One opinionated application-module style uses file-local role names and one canonical ES module namespace projection. Follow the existing codebase's module style when it has one; this convention is not required by Effect.

```ts
export type Interface = {
  readonly get: (
    id: UserId,
  ) => Effect.Effect<User, NotFound | PersistenceError>;
};

export class Service extends Context.Service<Service, Interface>()(
  "@app/UserRepo",
) {}

export const layer = Layer.effect(
  Service,
  Effect.gen(function* () {
    const sql = yield* SqlClient.SqlClient;

    const get = Effect.fn("UserRepo.get")(function* (id: UserId) {
      // ...
    });

    return Service.of({ get });
  }),
);

export class NotFound extends Schema.TaggedErrorClass<NotFound>()(
  "UserRepo.NotFound",
  { id: UserId },
) {}
```

When the service shape is simple, define it inline with `make` instead of a separate `Interface` type:

```ts
import { Context, Effect } from "effect";

export class Service extends Context.Service<Service>()("@app/Logger", {
  make: Effect.gen(function* () {
    const config = yield* Config;
    return {
      log: (msg: string) => Effect.log(`[${config.prefix}] ${msg}`),
    };
  }),
}) {}
```

Consumers use the module namespace.

```ts
import * as UserRepo from "./user-repo.js";

const program = Effect.gen(function* () {
  const repo = yield* UserRepo.Service;
  return yield* repo.get(id);
});
```

Each consumer owns the namespace via `import * as`, giving every consumer the same domain-first name without a TypeScript `namespace`, wrapper object, or repeated consumer-side aliases.

```ts
// Sibling module: import the owning leaf directly.
import * as UserRepo from "./user-repo.js";
```

Guidance:

- Do not name the tag class `UserRepo` inside `user-repo.ts`; the module namespace is the domain name.
- In this module style, consumers namespace a module's exports with `import * as UserRepo from "./user-repo.js"`. The module itself defines and exports everything inline with individual `export const`, `export type`, and `export class` declarations.
- Export only intentional surface; keep local schemas, row codecs, helpers, and implementation details unexported.
- Do not introduce TypeScript `namespace` declarations for organization.
- Use a named service class such as `class UserRepo extends Context.Service...` when an external library or existing codebase does not use module namespace style.

## Layer Constructors

Choose the layer constructor that matches the thing produced.

```ts
Layer.succeed(Service, impl); // already-built service
Layer.sync(Service, () => impl); // lazy synchronous service
Layer.effect(Service, makeEffect); // effectful service acquisition
```

Guidance:

- Default real implementations to `Layer.effect(Service, Effect.gen(...))`.
- Use `Layer.effectContext(...)` when one acquisition intentionally supplies multiple services, especially first-class test stubs or one client backing several service tags.
- Use `Layer.unwrap(...)` when config or runtime discovery chooses/builds the layer.
- Use `Layer.fresh(...)` or `Effect.provide(layer, { local: true })` only when a test or operation needs isolated acquisition.
- Use `Context.Reference` rarely, only for ambient/defaultable runtime references where a safe default is real.

## Long-Lived Work

A layer that starts a stream, listener, worker, subscription, or forever loop must fork that work into the layer scope. Layer acquisition must complete.

```ts
export const layer = Layer.effectDiscard(
  Effect.gen(function* () {
    const events = yield* Events.Service;

    yield* events.stream.pipe(
      Stream.runForEach(handleEvent),
      Effect.forkScoped,
    );
  }),
);
```

Guidance:

- Use `Effect.forkScoped`, `FiberSet`, or `FiberMap` for scoped background work.
- Do not run forever work inline during layer acquisition.
- Do not expose public `start` methods unless the domain explicitly needs manual lifecycle control.

## Runtime Wiring

- Use `Layer.provide(...)` to hide an implementation dependency.
- Use `Layer.provideMerge(...)` only when the dependency should remain exposed for downstream consumers.
- Use `Layer.mergeAll(...)` for independent exposed layers.
- Prefer flat, topologically sorted runtime layer values with named subgraphs.
- Avoid using `provideMerge` as a blind make-it-compile tool.
- Avoid hiding important authority or lifecycle dependencies behind broad invisible provisioning.

## Effect.fn

Use extra `Effect.fn(...)` arguments for wrappers that apply to the whole function call. Each transform receives `(effect, ...originalArgs)`.

```ts
const readAttachment = Effect.fn("Attachment.read")(
  function* (ref: AttachmentRef) {
    return yield* api.read(ref);
  },
  (effect, ref) =>
    effect.pipe(attachmentError("Attachment.read", { attachmentId: ref.id })),
);
```

Good whole-function transforms:

- error classification
- localized recovery
- logging annotations
- spans
- retry
- timeout
- ensuring cleanup
- small local provisioning
- result mapping

Guidance:

- Keep the generator body focused on the core workflow.
- Use transforms when the wrapper needs original arguments.
- Do not build long clever pipelines; one or two transforms is usually enough.
- Do not use this for local branch-level handling inside the workflow.

## Operation Error Helpers

For boundary errors with operation labels, prefer a shared curried `mapError` helper over hand-writing wrappers in every module.

```ts
const persistenceError = operationError(PersistenceError.make);

const row = yield * query.pipe(persistenceError("UserRepository.findById"));
```

Name the local helper after the error it produces, such as `persistenceError`, `projectionError`, or `processingError`. Use `Effect.fn(...)` and spans for observability in addition to payload labels, not instead of them.
