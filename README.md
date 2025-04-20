# DarBD — Embedded Lua Database Engine

**DarBD** is a lightweight, Lua-powered embedded database engine designed for simplicity, performance, and transparency.  
It is built to work **anywhere Lua runs**, but is especially tailored for **ComputerCraft 1.114** on **Minecraft 1.20.1**, where low-resource environments and scriptability matter most (and where you only get 4MB of RAM and broken dreams).

---

## Why DarBD?

- **Optimized for ComputerCraft** – perfect for in-game database needs.
- **Runs anywhere Lua does** – compatible with Lua 5.1+.
- **Transparent architecture** – easy to inspect, hack, and extend.
- **Lightweight and fast** – ideal for embedded systems and prototypes.
- **Concurrent-safe** – lock files prevent deadlocks and ensure safe writes.
- **Integrated shell** – query and inspect the database interactively.
- **Proto-transactions** – group operations with rollback support.

---

## 📌 Built for Lua — Optimized for ComputerCraft

DarBD is compatible with any Lua 5.1+ interpreter, making it usable in standalone scripts, embedded systems, or educational tools.  
However, its architecture, simplicity, and file-based operation model were designed **with ComputerCraft in mind**

This makes DarBD ideal for:

- 🧠 **ComputerCraft automation scripts**
- 🧪 **In-game database simulations**
- 🕹 **Minecraft-based data storage and retrieval**
- 💾 **Rednet-connected server-client setups**

---

## 📋 Requirements

- Minecraft: 1.20.1 (Who knows if it works in lower versions!)
- ComputerCraft Mod: 1.114 or higher

---

## 🚀 Installation

1. Use this command in the terminal of the computer/pocket computer to use.

```bash
wget run https://raw.githubusercontent.com/DarThunder/Dar-DB/refs/heads/main/installer.lua
```

2. Wait for the installation process to complete.

---

## 🧪 How It Works — Basic Example

```lua
-- Launch DarBD Shell
lua darDB

Welcome to DarDB!
nil> use myDatabase
myDatabase> create table users
myDatabase> insert into users {id = 1, name = "Alice", age = 25}
myDatabase> insert into users {id = 2, name = "Bob", age = 30}
myDatabase> select * from users where age > 26
```

You can script interactions directly via Lua or use the shell interface.

---

## 💻 The DarBD Shell

DarBD includes a simple REPL-style shell that allows:

- Creating and managing tables
- Running select, insert, update, delete
- Reading system logs and journal entries
- Inspecting buffer state and locking files

Just run `lua darDB` and interact with your database in real time.

---

## 🔍 Use Cases

- 🛠 **Embedded applications** needing small local storage
- 🧪 **Educational tools** for learning how DB engines work
- 🧬 **Experimental environments** where DB transparency is key
- 🕹 **Games or simulations** requiring fast lightweight data management
- 🧰 **Prototyping** without the overhead of large SQL engines
- 📦 **ComputerCraft** programs needing structured persistent data

---

## 📂 File Structure Overview

```text
/dardb
├── src/
│ ├── core/ # Main logic of the engine
│ │ ├── core.lua
│ │ ├── dardb.lua
│ │ ├── dbio.lua
│ │ ├── page_mgr.lua
│ │ ├── scheduler.lua
│ │ └── task_bus.lua
│ ├── storage/ # File and format management
│ │ ├── codec.lua
│ │ └── safe_space.lua
│ ├── index/ # Indexing and search functions and structures
│ │ ├── b_tree.lua
│ │ ├── b_tree_node.lua
│ │ ├── index.lua
│ │ └── record.lua
│ ├── utils/ # General utility functions (validations, helpers) P.D it still do nothing
│ │ ├── helpers.lua
│ │ └── service_utils.lua
│ └── config/ # Global configuration (if add any)
├── tests/ # Unit tests for the project
├── wiki/ # Additional documentation, guides, and usage examples
├── README.md
└── LICENSE
```

---

## 🔁 DarDB Engine Flow (Query Lifecycle)
Under construction. Turns out, doing everything in Lua is harder than it sounds.

## 🔧 Under the Hood

DarBD is powered by:

- Custom **B-tree index** for efficient reads
- Lua tables as the main record structure
- `.lckpgs` lock files for preventing race conditions
- A journaling system for crash recovery and auditing
- Proto-transactions for atomic sequences of operations

For deeper understanding, see [`Architecture`](wiki/architecture.md) and [`File format`](wiki/file_formats.md)

---

## 🧠 Built for Developers

DarBD is not trying to replace full-scale DBMS like SQLite or PostgreSQL (and literally can’t, it’s written in Lua). Instead, it's built to give developers:

- Total control over structure and flow
- A sandbox to understand, modify, and extend database logic
- A playground for transaction logic, indexing, and storage

---

## 📜 License

[`MIT License`](LICENSE)

---

## 👨‍💻 Author

Made with ❤️ by DarThunder
