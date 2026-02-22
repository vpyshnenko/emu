# Emu Causality Theory  
## Chapter 2 — Event Horizon: Past, Present, and Constructed Future

Emu execution admits a precise temporal interpretation grounded in causality.

At any moment during an avalanche, the global snapshot

    S = (σ, E)

naturally partitions reality into four regions:

- Past
- Present
- Near Future
- Far Future

This partition is not metaphorical — it is structurally induced by the FIFO frontier.

---

## 1. Past

The **past** consists of all events that have already been delivered.

Formally:

- All dequeued emissions.
- All state updates already applied to σ.
- All steps recorded in history.

Properties:

- Irreversible.
- Deterministically fixed.
- No longer modifiable.
- Fully realized causality.

The past defines the current state σ.

---

## 2. Present

The **present** is the single event currently being processed.

At each small-step transition:

- The head of E is removed.
- Its delivery executes.
- State may change.
- New emissions may be appended.

The present is therefore:

> The active causal transformation step.

It is the only moment where σ changes.

---

## 3. Near Future (The Event Horizon)

The **near future** consists of the contents of the FIFO frontier E.

These events:

- Have already been emitted.
- Are already causally determined.
- Have a fixed order.
- Will be delivered unless divergence or resource exhaustion intervenes.

We call this region the **constructed future**.

It is analogous to a moving horizon:

- Everything inside it is inevitable.
- Everything beyond it is not yet constructed.

Formally:

    NearFuture = E

Interpretation:

> The frontier represents the boundary of materialized deterministic consequences.

---

## 4. Far Future (Latent Causality)

Beyond the queue lies the **far future**.

These are events that:

- Have not yet been emitted.
- Depend on pending deliveries.
- Exist only as latent potential encoded in δ and topology.

They are not probabilistic.

Because Emu is deterministic:

> The far future is fully determined by (σ, E),
> but not yet constructed.

Thus Emu's future is constructive rather than predictive.

---

## 5. The Event Horizon Interpretation

We define the **event horizon** as:

> The boundary between already-constructed deterministic events and not-yet-constructed deterministic consequences.

At any time:

- Past = delivered events
- Present = current delivery
- Horizon = E (pending queue)
- Beyond horizon = latent expansion

This structure resembles a causal wave:

    Processed Past | Frontier | Unconstructed Future

The frontier moves forward as the avalanche progresses.

---

## 6. Properties of the Horizon

### 6.1 Deterministic Inevitable Future

Every event in E is:

- Already causally fixed.
- Ordered.
- Guaranteed to execute (absent resource bounds).

Thus the near future is fully predictable.

---

### 6.2 Horizon Width

The size of E reflects:

- The breadth of the current causal surface.
- The number of already-determined future events.

It measures *constructed future volume*, not temporal depth.

---

### 6.3 Horizon Movement

Each dequeue step:

- Shrinks the frontier by one.
- Possibly expands it via new emissions.

Thus the horizon:

- Advances forward.
- May widen or narrow.
- Eventually collapses to empty upon termination.

---

## 7. Constructive Time in Emu

Time in Emu is not precomputed.

It unfolds constructively:

1. Injection creates generation 0.
2. Delivery constructs generation 1.
3. Delivery constructs generation 2.
4. And so on.

The future does not exist until emitted.

Yet once emitted, it becomes inevitable.

Thus Emu exhibits:

> Constructive determinism.

---

## 8. Termination as Horizon Collapse

An avalanche terminates when:

    E = []

At that moment:

- The near future is empty.
- No further events are constructed.
- The causal wave has fully dissipated.

The horizon collapses.

---

## 9. Summary

At any snapshot S = (σ, E):

- Past is realized causality.
- Present is active transformation.
- Near future is the constructed deterministic horizon.
- Far future is latent but determined.

The FIFO frontier is therefore not merely a queue.

It is the moving boundary of deterministic causal unfolding.