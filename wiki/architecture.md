# DarBD — Lightweight Embedded Database Engine
**DarBD** is a lightweight embedded database engine designed to offer simplicity, performance, and consistency for applications that require efficient local data storage with basic concurrency support. It features standard CRUD operations, a journaling system, caching optimizations, and early-stage transactional support through proto-transactions.

---

## Core Features
- **CRUD operations** (Create, Read, Update, Delete)
- **Concurrent access** with conflict prevention
- **Proto-transactions** and **proto-rollback** mechanisms
- **Journaling** for audit and recovery
- **Caching optimizations** for frequently accessed data
- **Deadlock prevention** through `.lckpgs` lock file

---

## Locking Mechanism
Each time a transaction is initiated, DarBD adds the page to the `.lckpgs` file. This lock file is used to prevent deadlocks and includes a Time-To-Live (TTL) of 30 seconds, configurable via the `dbConf.yaml` file. If a transaction ends abruptly or is not properly cleaned up, the system automatically deletes the stale lock to ensure consistency and prevent hanging states.

### Lock Timeout and Proto-Transactions
When a **proto-transaction** is initiated (an early stage of a full transaction), the engine performs the following steps:

1. Adds the corresponding page id to the `.lckpgs` file to mark it as in use.
2. Spawns a coroutine associated with a 30-second timer.

**Transaction Completion**
- If the transaction is successfully committed or cancelled:
  - The page entry is removed from `.lckpgs`.
  - The corresponding timer coroutine is cancelled.

**Timeout Handling**
- If the system crashes or the process is interrupted:
  - The coroutine continues running.
  - After 30 seconds, the engine removes the page from `.lckpgs` to allow recovery.

---

## Internal Buffering: `SafeSpace`
`SafeSpace` is a sandbox-capable buffer designed to safely handle operations that are prone to corruption—such as updates and proto-transactions. Before any change is committed to disk, it is first staged in `DarSafeSpace`, allowing consistency checks to take place in isolation.

What makes it safer is that **every operation is logged to the journal before execution**, providing a rollback mechanism and ensuring data durability. This approach enhances integrity and atomicity, especially in low-resource environments.

---

## CRUD Operations

### Create
- Data is packed using the schema's field order and packet pattern.
- The page size and record count are updated.
- The operation is logged in the journal for durability and traceability.

### Read
- Supports two modes: `"r"` for record-based and `"f"` for field-based queries.
  - `"r"` mode: Read a specific record or a range by the OSR.
  - `"f"` mode: Provide a Lua table of fields to extract.

### Update
- The record is located by index and loaded into memory.
- It is passed to `SafeSpace`, where it is safely updated (e.g., `{ name = "New" }`).
- After validation, the updated record is written back to disk.

### Delete
- The byte offset of the record is passed directly.
- The record is marked with the appropriate control byte (`ASCII0` or `ASCII2`) depending on its reuse strategy.
- No shifting of subsequent data is performed, allowing for lazy deletion and future compaction.

---

## Proto-Transactions
Proto-transactions provide early transactional consistency without full ACID compliance.

### Lifecycle
1. **Initialization**:
   - The target page is locked via `.lckpgs`.
   - A coroutine is launched with a 30-second timeout.

2. **Execution**:
   - Changes are staged in `SafeSpace`.
   - The journal logs every operation before execution.

3. **Commit**:
   - Staged changes are flushed to disk.
   - `.lckpgs` is updated and the journal is checkpointed.

4. **Cancel**:
   - No changes are applied.
   - The journal logs a rollback.
   - The page is unlocked.

5. **Interruption**:
   - If not finalized, the coroutine ensures cleanup after timeout.

---

## File Formats

### `.ixf` — B-tree Index Files
- Stores SHA-256 hashed keys in a B-tree structure.
- **Order**: 75 (max 74 keys per node)
- Keys map to `{ page = "path", slot = x }`
- Multiple indexes can exist per table (e.g., `index.ixf`, `email.ixf`).

### `.lckpgs` — Lock Pages File
- Tracks `.dbpgs` pages used in proto-transactions.
- Entries expire after timeout or manual unlock.

### `.dbpgs` — Data Pages File
- Stores packed records for each table.
- Each record is placed in an 8192-byte page.
- Each page follows the schema pattern defined in the global metadata at the start of the file.
- Format includes metadata like size and records.

### `SafeSpace`
- Temporary buffer for staging changes.
- Supports journaling, rollback, and atomic write.

For improved compression of file formats, refer to this [`section`]("./file_formats.md").

---

## Internal Byte Markers in `.dbpgs` Pages
To manage record states efficiently, DarBD uses a control byte at the start of each record slot in `.dbpgs` files. The control byte can take one of the following values:

- **`ASCII0` (`\0`) – Reserved Space**  
  Marks a deleted record whose space is reserved for recovery or delayed compaction.

- **`ASCII1` (`\1`) – Compactable Slot**  
  Marks a slot that contains outdated data and is eligible for compaction.

- **`ASCII2` (`\2`) – Free Slot**  
  Indicates an empty slot available for immediate reuse.

This marking system enables lazy deletion, efficient compaction, and safe record management without full-page rewrites.

---

This architecture makes **DarBD** ideal for embedded applications, small-scale data storage, and environments where performance and data integrity are critical without requiring a full SQL engine.
