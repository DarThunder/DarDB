# Custom File Formats: `.dbpgs`, `.ixf` and `.lckpgs`

This document outlines the current structure and purpose of the core file formats used by the DarBD engine: `.dbpgs` (database pages), `.ixf` (index file), and `.lckpgs` (lock registry).

---

## `.dbpgs` Files (Database Binary Pages)

Each `.dbpgs` file is a **master-slave structured container** that holds multiple 8KB pages. These pages store serialized records and are separated internally via metadata offsets. Rather than using one file per page, all related pages are embedded in a single `.dbpgs` file for performance and simplicity.

### General Structure

- **Global metadata**: pattern, fields, OSR(Offset Standard Record)
- **Total size per page**: 8192 bytes (8KB)
- **Text encoding**: UTF-8
- **Each page** is preceded by a **metadata header** (64 bytes) describing offset, record count, and data order

### Global Metadata (Header)

Each `.dbpgs` file begins with global metadata, which defines how records are interpreted.

#### Structure:

- `pattern`: A comma-separated list of field types (e.g., `c10,i2,i1`), null-terminated (`\0`)
- `fields`: A comma-separated list of field names (e.g., `nombre,edad,is_deleted`), null-terminated (`\0`)
- `osr`: A 2-byte big-endian integer indicating the offset where actual data records begin

#### Example:

```
pattern: c10,i2,i1\0
fields: nombre,edad,is_deleted\0
osr: 0x000D
```

#### Hex Representation:

```
63 31 30 2C 69 32 2C 69 31 00 ; pattern
6E 6F 6D 62 72 65 2C 65 64 61 64 2C 69 73 5F 64 65 6C 65 74 65 64 00 ; fields
00 0D ; osr
```

### Metadata per Page (Header)

```
size: <integer> (size in bytes) with a offset of 4 bytes
records: <integer> (number of records) with a offset of 1 byte
```

#### Example:

```
size: 0x394
records: 0x05
```

#### Hex Representation:

```
[00-03]  00 00 03 94 ; size
[04]     05 ; records
```

### Records

Each record is serialized as a binary blob using **fixed-width encoding**. Fields are concatenated **without delimiters**, and the field size is strictly based on the schema definition (`pattern`).

#### Binary Structure

Each record is: [field1][field2]...[fieldN]

- Fields are encoded **in order**, as defined in the metadata
- No separators or delimiters are used
- Fields are **fixed-size** and **null-padded** (for strings)

#### Example Schema

```lua
{
    name = c10,   -- 10 bytes (string)
    age = i2,     -- 2 bytes (unsigned int, big endian)
    active = i1   -- 1 byte (boolean)
}
```

#### Record Encodings (UTF-8 + binary)

| Name   | Age (i2)    | Active (i1)  | Total Bytes |
| ------ | ----------- | ------------ | ----------- |
| Carlos | 0x001E (30) | 0x01 (true)  | 13 bytes    |
| Ana    | 0x000F (15) | 0x00 (false) | 13 bytes    |

**Carlos encoded:**

```
43 61 72 6C 6F 73 00 00 00 00  ; "Carlos" + 4 nulls (c10)
00 1E                          ; age = 30
01                             ; active = true
```

**Ana encoded:**

```
41 6E 61 00 00 00 00 00 00 00  ; "Ana" + 7 nulls (c10)
00 0F                          ; age = 15
00                             ; active = false
```

#### Supported Data Types

| Type    | Encoding | Size      | Notes                 |
| ------- | -------- | --------- | --------------------- |
| string  | cN       | N bytes   | Null-padded (`\0`)    |
| integer | iN       | N=1,2,4   | Big-endian by default |
| bool    | i1       | 1 byte    | 0x00=false, 0x01=true |
| float   | f4/f8    | 4/8 bytes | IEEE 754 standard     |

#### Key Advantages

- Fast access: Direct byte offset to any record
- Compact storage: No delimiters or escaping
- Predictable size: Easy to calculate page and record boundaries

#### Future Extensions

- Type tagging for schema evolution
- Compression flags in record headers
- Binary blob support (BLOB)

---

## `.ixf` Files (Index Files)

`.ixf` files define persistent **B-Tree indexes** on specified fields. Each `.ixf` file corresponds to one indexed column and maps hashed keys to logical locations inside `.dbpgs` file (slot).

### Key Characteristics

- Each index is stored **separately** for each indexed field (email, created_at, etc.)
- Each key in the tree is the **SHA-256 hash** of the indexed value
- The index maps to page metadata (e.g. `{ slot = 5 }`)

### Node Format (Serialized Lua Table)

```lua
{
  is_leaf = false,
  keys = { "c647611...", "12e4937..." },
  pointers = {
    { record = 5 },
    { record = 12 },
  },
  children = {
    {}, {}, {}
  }
}
```

#### Leaf Nodes

- Contain hash keys and pointers to physical locations
- Do not have children
- May optionally be linked to siblings for range scans

#### Internal Nodes

- Contain hash keys, pointers, and children
- Guide traversal during search operations

#### Multiple Indexes

A table with multiple indexes will have multiple `.ixf` files:

- `index.ixf`: for primary keys
- `email.ixf`, `created_at.ixf`, etc.: for secondary indexes

---

## `.lckpgs` Files (Lock Registry)

The `.lckpgs` file is a simple lock tracking mechanism used to prevent concurrent writes or reads to sensitive page regions.

### Structure and Usage

- Each line in the file contains a locked page's offset inside a `.dbp` file
- Example content:

```
users.dbp@0
users.dbp@8192
```

### Concurrency Notes

- Before reading/writing a page, its lock must be acquired by appending to `.lckpgs`
- Lock must be released after the operation (line removal)
- This method avoids platform-dependent file locking

---

## Future Plans

- Switch to a binary format for `.ixf` files for performance
- Add type annotations or schemas per page
- Implement compression and CRC validation per page
