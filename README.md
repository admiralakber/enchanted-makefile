# ✨ Aqeel's Enchanted Makefile ✨

A magically minimal yet powerful Makefile template that auto-documents your commands with zero fuss. Perfect for container-driven projects, developer tooling, or simply keeping tasks tidy!

## 🪄 Features

- **Automatic Documentation**: Commands defined with special `##` comments are automatically displayed with `make help`.
- **Container Friendly**: Quickly configure and manage OCI containers with Podman or Docker.
- **Whimsical & Practical**: Brings joy and clarity to your project workflows.
- **NEW: Makefile.lite**: See `Makefile.lite` for just the help without the OCI part, great for little projects.

## 🚀 Quick Start

1. **Clone the repo**:
   ```bash
   git clone https://github.com/admiralakber/enchanted-makefile.git
   ```

2. **Copy the Makefile into your project**:
   ```bash
   cp enchanted-makefile/Makefile ./
   ```

3. **Configure your project settings** at the top of the Makefile:

   ```makefile
   PROJECT_USE        = Your Project Name
   IMAGE_NAMESPACE    = your-namespace
   IMAGE_NAME         = your-image-name
   REGISTRY           = registry.gitlab.com
   ```

4. **Start using it**:
   ```bash
   make help
   ```

## 🐈‍⬛ Example: Adding a New Command

Simply define your target in the Makefile:

```makefile
dev/shell: ## Open an interactive dev shell
	$(CONTAINER_RUNTIME) run $(CONTAINER_ARGS) $(IMAGE_BASE) bash
```

Run `make help` to see your new magic command appear automatically!

## 🚀 Example: Out of the box functionality

If you simply clone the repo and type `make`:

```
✨ Welcome to Aqeel's Enchanted Makefile ✨
🪄 For you: Your Project Name (Customize Me!)
-----------------------------------------
📂 Project:   admiralakber/enchanted-makefile
🌐 Remote:    git@github.com:admiralakber/enchanted-makefile.git
🌿 Branch:    main
📦 Registry:  registry.gitlab.com
🖼 Image:     registry.gitlab.com/your-namespace/your-image-name:0c51a4d

Commands:
  help                      Display available make targets with descriptions and project info
  oci/build                 Build image with current git commit hash tag (warns if dirty)
  oci/list                  List all local images for this project with timestamps
  oci/push-latest           Push commit-hash and 'latest' tags
  oci/push                  Push commit-hash image to registry (requires clean worktree)
  oci/run                   Run container with specified command (default: bash). Usage: make oci/run [CMD=...]
  oci/tag-branch            Tag commit-hash image with sanitized git branch name
  oci/tag-latest            Tag commit-hash image as 'latest'
-----------------------------------------
```

**NEW: If you just want the help, see `Makefile.lite`**

`make -f Makefile.lite` out of the box produces:

```
✨ Welcome to Aqeel's Enchanted Makefile ✨
🪄 For you: Your Project Name (Customize Me!)
-----------------------------------------
⚠ Git working directory has uncommitted changes.
📂 Project:   admiralakber/enchanted-makefile
🌐 Remote:    git@github.com:admiralakber/enchanted-makefile.git
🌿 Branch:    main

Commands:
  help                      Display available make targets with descriptions and project info
-----------------------------------------
```

## 🌟 Community Snippets

Check out the snippets/ folder for additional snippets contributed by the community. These snippets are shared under The Unlicense, allowing you maximum freedom to use and adapt them.

Feel free to add your own useful snippets to this community library!

## 📖 License & More Magic

Licensed under MIT.

🌐 [github.com/admiralakber/enchanted-makefile](https://github.com/admiralakber/enchanted-makefile)

