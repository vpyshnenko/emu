# Emu Causality Theory  
## Chapter 6 — Resource Probing and Adaptive Measurement of Causal Waves

Causality defines what must happen.  
Resources define whether it can be accommodated.

When Emu runs under finite memory and finite bandwidth, the unfolding causal wave interacts with resource limits.

If the engine is made adaptive — able to grow its pending queue capacity dynamically — it becomes a **resource probe** for causal dynamics.

This chapter formalizes how Emu can measure the resource requirements of an avalanche.

---

## 1. The Resource Probe Principle

Let an avalanche be initiated from snapshot:

    (σ₀, [])

If the engine allows dynamic growth of the FIFO frontier E, then running the avalanche to completion yields exact measurements of:

- Peak memory pressure
- Total computational work
- Expansion characteristics
- Burst behavior

Thus the engine becomes not only an evaluator, but an instrument.

---

## 2. Peak Pending Events (Memory Requirement)

Define:

    MaxQueueSize = max_t |E_t|

where E_t is the queue content at runtime step t.

Interpretation:

- Minimum pending-event capacity required to execute the avalanche without overflow.
- Peak causal surface area.
- Maximum constructed deterministic future.

This is the primary memory metric of the avalanche.

---

## 3. Total Work (Compute Requirement)

Define:

    TotalDelivered = number of dequeue operations
    Volume = Σₖ |Gₖ|

Since each delivery corresponds to one dequeue step:

    TotalDelivered = Volume

Interpretation:

- Total causal work performed.
- Total state transitions executed.
- CPU cost proxy (ignoring per-step cost variation).

---

## 4. Execution Time Under Bandwidth Model

Assume engine bandwidth:

    B = deliveries per unit time

Then estimated execution time:

    Time ≈ TotalDelivered / B

This provides a throughput-based performance estimate.

---

## 5. Instantaneous Growth Dynamics

At each delivery step t:

    |E_{t+1}| = |E_t| - 1 + e_t

where:

    e_t = number of emissions produced at step t

Net growth per step:

    Δ_t = e_t - 1

Interpretation:

- If Δ_t > 0 → queue expands
- If Δ_t = 0 → steady state
- If Δ_t < 0 → queue contracts

Average growth:

    AvgEmission = TotalEmitted / TotalDelivered
    λ_avg = AvgEmission

If λ_avg > 1 → supercritical growth  
If λ_avg = 1 → critical  
If λ_avg < 1 → subcritical

---

## 6. Adaptive Queue Strategies

To measure avalanche resource demand without artificial truncation, the engine may use:

### 6.1 Dynamically Growing Memory

- Expand in-memory queue as needed.
- Stops only on physical memory exhaustion.

Provides direct measurement of MaxQueueSize.

---

### 6.2 Spill-to-Disk Queue

- Maintain FIFO semantics.
- Store overflow events on secondary storage.

Preserves causal correctness while allowing measurement of large waves.

---

### 6.3 Hard Cap (Non-Probing Mode)

If queue size exceeds Q_max:

- Abort avalanche
- Signal overflow

This enforces resource envelope but prevents full measurement.

---

## 7. Divergence Detection

If during adaptive probing:

- MaxQueueSize grows without bound
- Or TotalDelivered exceeds safe limits

Then avalanche is divergent.

In this case, probe yields:

- Observed growth rate
- Partial metrics
- Classification (supercritical regime)

Even truncated measurements provide geometric insight.

---

## 8. Resource Profile of an Avalanche

A complete resource profile includes:

- MaxQueueSize
- TotalDelivered
- MaxWidth
- CausalDepth
- λ_avg
- λ_max

This profile characterizes both:

- Semantic geometry
- Operational demand

---

## 9. Predictive Capacity Planning

Given resource profile, one can:

- Estimate minimum required queue capacity
- Estimate CPU budget
- Detect supercritical topology
- Design damping mechanisms
- Define safe operational envelopes

Thus resource probing supports:

- Stability engineering
- Capacity planning
- Network design tuning

---

## 10. Causality–Resource Duality

Causal wave geometry determines:

- How much must be processed
- How wide expansion becomes
- How long propagation continues

Engine resources determine:

- Whether this propagation can be sustained
- Whether the wave collapses or overwhelms the system

Therefore:

> Causality describes the necessary unfolding.
> Resources describe the admissible unfolding.

---

## 11. Summary

An adaptive Emu engine transforms from:

    Pure semantic evaluator

into:

    Deterministic causal resource analyzer.

By allowing the frontier to grow dynamically, Emu can measure:

- Memory pressure
- Computational work
- Growth dynamics
- Stability regime

This completes the causal theory arc:

- Structural layering (BFS)
- Horizon model (past / present / future)
- Geometric dynamics (depth / width / volume)
- Stability regimes (criticality)
- Resource probing and capacity constraints

Emu thus admits a unified theory of deterministic causal mechanics and operational resource geometry.