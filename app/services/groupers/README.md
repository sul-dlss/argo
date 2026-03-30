# Description Groupers: Domain Model, Flow, and Data Shapes

This directory contains the grouping pipeline used by `DescriptionsGrouper` to transform flattened description exports into stable semantic columns.

The grouping functionality exists to turn highly variable, position-dependent metadata (form1, form2, note1, note2, etc.) into stable, semantically meaningful columns so records can be compared side-by-side without losing context. In the raw exported data, the same concept (for example, resource type, abstract, or genre) may appear at different numeric positions in different records, may repeat within a record, and may coexist with sparse or missing fields; grouping improves the organization of this information by first building a frequency-informed canonical slot map, then rewriting each description so like data lands in like columns. This makes downstream views and exports far more readable and analyzable, preserves repeated-value adjacency, and still handles edge cases safely (e.g., fallback behavior when no canonical slot is selected), which is exactly what the service-level tests are asserting across simple, complex, and mixed-repeat datasets.

## Why groupers exist

Exported description data is flattened and positional (`form1`, `form2`, `note1`, `note2`), but positional order is not semantically stable across objects. Groupers normalize this into stable slot columns based on semantic identity.

Examples:
- forms are grouped by semantic form token (`type` or `value`)
- notes are grouped by semantic note token (`[displayLabel, type]` tuple)

---

## Core terms (shared vocabulary)

- **Prefix**
  A family of indexed fields:
  - forms: `formN.*`
  - notes: `noteN.*`

- **Token**
  Semantic identity used for grouping.
  - forms token key: `type || value`
  - notes token key: `[displayLabel, type]`

- **Slot**
  Canonical output column index in a prefix family:
  - `form1`, `form2`, ...
  - `note1`, `note2`, ...

- **Seed mapping**
  Global map built before per-record rewriting:
  - `{"form1" => "resource type", ...}`
  - `{"note1" => [nil, nil], ...}`

- **Slot mapping**
  Per-description map from old prefix to canonical slot:
  - `{"old_form3" => "form1", ...}`
  - `{"old_note2" => "note5", ...}`

---

## High-level architecture

Top-level orchestrator:
- `Groupers::DescriptionsGrouper`

Domain groupers:
- `Groupers::FormsGrouper`
- `Groupers::NotesGrouper`

Shared infrastructure:
- `Groupers::SeedMappingBuilder`
- `Groupers::TokenMappingRewriter`
- `Groupers::SlotAllocationPipeline`

Domain-specific policies/components:
- `FormsGrouper::Token`
- `FormsGrouper::SlotAllocator`
- `FormsGrouper::SlotSelectionPolicy`
- `NotesGrouper::Token`
- `NotesGrouper::TokenMatchCounter`
- `NotesGrouper::SlotAllocator`
- `NotesGrouper::SlotSelectionPolicy`

---

## Data flow and shapes

## 1) Input shape (pre-grouping)

Groupers receive:

`Hash<String (druid), Hash<String (denormalized Cocina property), String (value)>>`

Where key = record id (e.g. druid), value = flattened field hash, essentially a denormalization of the deeply nested Cocina structure into a flat set of key/value pairs.

Example (single record, simplified):

```ruby
{
  "druid:bb976rq0538" => {
    "form1.value" => "still image",
    "form1.type" => "resource type",
    "form2.value" => "ink on paper",
    "form2.type" => "form",
    "note1.value" => " from disc label.",
    "note2.value" => "System requirements...",
    "note2.type" => "system details"
  },
  # ...
}
```
---

## 2) Seed mapping build

Each grouper computes rows, then passes grouper-specific strategy functions to `SeedMappingBuilder`:

- `prefix` → string ("form" or "note")
- `rows` → array of token rows (one row per record)
- `unique_order_strategy(rows)` → unique tokens in frequency order
- `repeat_counts_strategy(rows)` → max repeats per token across rows
- `expand_strategy(unique, repeats)` → expanded token list (adjacent repeats)

This produces a final map with prefix numbering (formN or noteN).

### Forms rows shape

`Array<Array<String|nil>>`

Example:
```ruby
[
  # Each line has the form types for a given object in the order they were handed to the groupers, not deduped.
  ["resource type", "form", "extent"],
  ["resource type", "resource type", "form"]
]
```

### Notes rows shape

`Array<Array<Array(String|nil)>>`
(each token is `[displayLabel, type]`)

Example:
```ruby
[
  # Each line has the note tuples (display label, type) for a given object in the order they were handed to the groupers, not deduped
  [[nil, "abstract"], ["Provenance", "ownership"], [nil, nil]],
  [[nil, "abstract"], [nil, nil]]
]
```

---

## 3) Per-description flow

`TokenMappingRewriter` performs shared in-place key rewriting.

### 3a) Temporary collision-safe rename

Before:
- `form1.value`, `form1.type`
- `note2.value`, `note2.type`

After:
- `old_form1.value`, `old_form1.type`
- `old_note2.value`, `old_note2.type`

### 3b) Slot assignment and key rewrite

For each `prefixN` key:
1. extract number (`N`)
2. compute token from `old_prefixN`
3. allocator chooses canonical slot
4. if allocator returns `nil`, fallback to original slot number (`prefixN`)
5. rewrite key prefix from `old_prefixN` to chosen slot

Result shape remains flattened hash, but with canonicalized slot indices.

### Slot allocator shape

The slot allocator receives an ordered mapping for a given grouper (form or note) reflecting the total number of form elements in the given object, e.g.:

```ruby
{
  "form1" => "resource type",
  "form2" => "resource type",
  "form3" => "form",
  "form4" => "extent",
  "form5" => "digital origin",
  "form6" => "genre"
}
```

As more descriptions are grouped, this ordered mapping evolves, e.g., appending `"form7" => "manuscript"`

---

## 4) Output shape (post-grouping)

Same top-level shape as input:

`Hash<String, Hash<String, String>>`

But keys now align semantically across records:

```ruby
{
  "druid:bb976rq0538" => {
  "form1.value" => "still image",
  "form1.type" => "resource type",
  "form3.value" => "ink on paper",
  "form3.type" => "form",
  "note1.value" => "Title from disc label.",
  "note8.value" => "System requirements...",
  "note8.type" => "system details"
  },
  # ...
}

```
---

## Intentional behavior differences: Forms vs Notes

These divergences are deliberate and must be preserved.

### Forms allocator fallback

- If no suitable existing slot is found, forms append a new slot to global mapping.
- This allows mapping evolution for new form token shapes as more descriptions are examined and mapped.

### Notes allocator fallback

- Notes allocator returns nil when no slot is selected.
- Rewriter then falls back to original note (noteN).
- Notes selection is tuple-count-sensitive via TokenMatchCounter.

---

## Shared pipeline contracts

## SeedMappingBuilder contracts

- `unique_order_strategy.call(rows)` → `Array<Token>`
- `repeat_counts_strategy.call(rows)` → `Hash{Token => Integer}`
 `expand_strategy.call(unique, repeats)` → `Array<Token>`

Returns:
- `Hash{String => Token}` keyed by `"#{prefix}#{index}"`

## SlotAllocationPipeline contracts

- `slots_for.call(token)` → `Array<String>`
- `choose_existing.call(slots token:, key:, slot_mapping:)` → `String|nil`
- `fallback.call(token:, key:, slot_mapping:)` → `String|nil`

Returns:
- canonical slot string or `nil`

---

## Safe refactoring rules

1. Preserve token semantics per domain:
   - forms: type || value
   - notes: [displayLabel, type]
2. Preserve fallback divergence (forms append, notes nil → rewriter fallback).
3. Keep shared classes behavior-agnostic; domain behavior belongs in policies.
4. Change one seam at a time and run:
   - `bundle exec rspec spec/services/descriptions_grouper_spec.rb`

---

## Where to start when reading code

1. `DescriptionsGrouper`
2. `FormsGrouper` & `NotesGrouper` (top-level group + seed strategy methods)
3. `TokenMappingRewriter`
4. `SlotAllocator` + `SlotSelectionPolicy``
5. `Token` classes and `notes `TokenMatchCounter`
