# nakadi-client [![Hackage version](https://img.shields.io/hackage/v/nakadi-client.svg?label=Hackage)](https://hackage.haskell.org/package/nakadi-client) [![Stackage version](https://www.stackage.org/package/nakadi-client/badge/lts?label=Stackage)](https://www.stackage.org/package/nakadi-client) [![Build Status](https://travis-ci.org/mtesseract/nakadi-client.svg?branch=master)](https://travis-ci.org/mtesseract/nakadi-client)

### About

`nakadi-client` is a BSD2/BSD3 licensed Haskell client library for
interacting with the [Nakadi event
broker](https://zalando.github.io/nakadi/) system developed by
[Zalando](https://github.com/zalando). The streaming is built on top
of [Conduit](https://haskell-lang.org/library/conduit).

Please note that the **API is not considered stable yet**.

`nakadi-client` provides:

- Docker based test suite testing against the official Nakadi [docker
  image](https://github.com/zalando/nakadi#running-a-server).

- A type-safe API for interacting with Nakadi. For example, the name
  of an event type has type `EventTypeName`, not `Text` or something
  generic. Correct types for values like `CursorOffset` are provided
  (which must be treated as opaque strings).

- Integrated and configurable retry mechanism.

- Conduit based interfaces for streaming events.

- Support for temporary subscriptions.

- Convenient Subscription API interface (`subscriptionProcess` &
  `subscriptionProcessConduit`), which frees the user from any manual
  bookkeeping.

- Mechanism for registering callbacks for logging and token injection.

### Example

Example code showing how to dump a subscription:

```haskell
dumpSubscription :: (MonadLogger m, MonadNakadi IO m) => Nakadi.SubscriptionId -> m ()
dumpSubscription subscriptionId =
  Nakadi.subscriptionProcess Nothing subscriptionId processBatch

  where processBatch :: MonadLogger m => Nakadi.SubscriptionEventStreamBatch Value -> m ()
        processBatch batch =
          logInfoN (tshow batch)
```
