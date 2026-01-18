# Makefile for the TMML Companion Project

# ANSI color codes
BLUE := \033[1;34m
GREEN := \033[1;32m
YELLOW := \033[1;33m
RED := \033[1;31m
CYAN := \033[1;36m
RESET := \033[0m

# Variables
PROJECT_NAME := TMML Companion
BIN_DIR := ./bin
MODE := debug
TARGET := ./target/$(MODE)
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u '+%Y-%m-%dT%H:%M:%SZ')
RUST_VERSION := $(shell rustc --version 2>/dev/null || echo "unknown")

SITE_URL := https://music-comp.github.io/tmml-mc/
BACKUP_SITE_URL := https://music-comp.codeberg.page/tmml-mc/
PUBLISH_BRANCH := pages
CODE_BRANCH := $(GIT_BRANCH)
DEST_DIR := ./book

LOCALHOST := $(shell hostname | grep -q '\.local$$' && hostname || echo "$$(hostname).local")
LOCALPORT := 5099

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)║$(RESET) \"$(BLUE)$(PROJECT_NAME)\" Build System$(RESET)                            $(CYAN)║$(RESET)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(GREEN)Book:$(RESET)"
	@echo "  $(YELLOW)make book$(RESET)             - Build mdbook (preserves worktree)"
	@echo "  $(YELLOW)make serve$(RESET)            - Serve mdbook at $(LOCALHOST):$(LOCALPORT)"
	@echo "  $(YELLOW)make watch$(RESET)            - Watch for changes and rebuild"
	@echo ""
	@echo "$(GREEN)Publishing:$(RESET)"
	@echo "  $(YELLOW)make setup$(RESET)            - Set up pages branch worktree"
	@echo "  $(YELLOW)make deploy$(RESET)           - Build and deploy book to Codeberg/Github pages"
	@echo ""
	@echo "$(GREEN)Cleaning:$(RESET)"
	@echo "  $(YELLOW)make clean$(RESET)            - Clean bin directory"
	@echo "  $(YELLOW)make clean-all$(RESET)        - Full clean (cargo clean)"
	@echo ""
	@echo "$(GREEN)Utilities:$(RESET)"
	@echo "  $(YELLOW)make push$(RESET)             - Pushes to Codeberg and Github"
	@echo "  $(YELLOW)make tracked-files$(RESET)    - Save list of tracked files"
	@echo ""
	@echo "$(GREEN)Information:$(RESET)"
	@echo "  $(YELLOW)make info$(RESET)             - Show build information"
	@echo "  $(YELLOW)make check-tools$(RESET)      - Verify required tools are installed"
	@echo ""
	@echo "$(CYAN)Current status:$(RESET) Branch: $(GIT_BRANCH) | Commit: $(GIT_COMMIT)"
	@echo ""

# Info target
.PHONY: info
info:
	@echo ""
	@echo "$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)║$(RESET)  $(BLUE)Build Information$(RESET)                                       $(CYAN)║$(RESET)"
	@echo "$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(GREEN)Project:$(RESET)"
	@echo "  Name:           $(PROJECT_NAME)"
	@echo "  Build Mode:     $(MODE)"
	@echo "  Build Time:     $(BUILD_TIME)"
	@echo ""
	@echo "$(GREEN)Paths:$(RESET)"
	@echo "  Build Dir:      $(DEST_DIR)/"
	@echo "  Workspace:      $$(pwd)"
	@echo ""
	@echo "$(GREEN)Git:$(RESET)"
	@echo "  Branch:         $(GIT_BRANCH)"
	@echo "  Commit:         $(GIT_COMMIT)"
	@echo ""
	@echo "$(GREEN)Tools:$(RESET)"
	@echo "  Rust:           $(RUST_VERSION)"
	@echo "  Cargo:          $$(cargo --version 2>/dev/null || echo 'not found')"
	@echo "  mdbook:         $$(mdbook --version 2>/dev/null || echo 'not found')"
	@echo ""

.PHONY: setup
setup:
	@echo "$(BLUE)Setting up worktree...$(RESET)"
	@git fetch origin 2>/dev/null || true
	@if [ -d "$(DEST_DIR)/.git" ] || git worktree list | grep -q "$(DEST_DIR)"; then \
		echo "$(YELLOW)Worktree already exists$(RESET)"; \
	else \
		if [ -d "$(DEST_DIR)" ]; then \
			echo "$(CYAN)• Removing existing build directory...$(RESET)"; \
			rm -rf $(DEST_DIR); \
		fi; \
		if git show-ref --verify --quiet refs/heads/$(PUBLISH_BRANCH) 2>/dev/null || \
		   git show-ref --verify --quiet refs/remotes/origin/$(PUBLISH_BRANCH) 2>/dev/null; then \
			echo "$(CYAN)• Branch '$(PUBLISH_BRANCH)' exists, creating worktree...$(RESET)"; \
			git worktree add $(DEST_DIR) $(PUBLISH_BRANCH); \
		else \
			echo "$(CYAN)• Creating orphan branch '$(PUBLISH_BRANCH)'...$(RESET)"; \
			git worktree add --detach $(DEST_DIR); \
			cd $(DEST_DIR) && \
			git checkout --orphan $(PUBLISH_BRANCH) && \
			git reset --hard && \
			git commit --allow-empty -m "Initialize $(PUBLISH_BRANCH) branch" && \
			echo "$(GREEN)✓ Orphan branch created$(RESET)"; \
		fi; \
		echo "$(GREEN)✓ Worktree created at $(DEST_DIR)/$(RESET)"; \
	fi

# Check tools target
.PHONY: check-tools
check-tools:
	@echo "$(BLUE)Checking for required tools...$(RESET)"
	@command -v rustc >/dev/null 2>&1 && echo "$(GREEN)✓ rustc found (version: $$(rustc --version))$(RESET)" || echo "$(RED)✗ rustc not found$(RESET)"
	@command -v cargo >/dev/null 2>&1 && echo "$(GREEN)✓ cargo found (version: $$(cargo --version))$(RESET)" || echo "$(RED)✗ cargo not found$(RESET)"
	@command -v rustfmt >/dev/null 2>&1 && echo "$(GREEN)✓ rustfmt found$(RESET)" || echo "$(RED)✗ rustfmt not found (install: rustup component add rustfmt)$(RESET)"
	@cargo clippy --version >/dev/null 2>&1 && echo "$(GREEN)✓ clippy found$(RESET)" || echo "$(RED)✗ clippy not found (install: rustup component add clippy)$(RESET)"
	@cargo llvm-cov --version >/dev/null 2>&1 && echo "$(GREEN)✓ llvm-cov found$(RESET)" || echo "$(RED)✗ llvm-cov not found (install: cargo install cargo-llvm-cov)$(RESET)"
	@command -v git >/dev/null 2>&1 && echo "$(GREEN)✓ git found$(RESET)" || echo "$(RED)✗ git not found$(RESET)"
	@test -f Cargo.toml && echo "$(GREEN)✓ Cargo.toml found$(RESET)" || echo "$(RED)✗ Cargo.toml not found$(RESET)"

# Cleaning targets
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning bin directory...$(RESET)"
	@rm -rf $(BIN_DIR)
	@echo "$(GREEN)✓ Clean complete$(RESET)"

.PHONY: clean-all
clean-all: clean
	@echo "$(BLUE)Performing full cargo clean...$(RESET)"
	@cargo clean
	@echo "$(GREEN)✓ Full clean complete$(RESET)"

# Testing & Quality targets
.PHONY: test
test:
	@echo "$(BLUE)Running tests...$(RESET)"
	@echo "$(CYAN)• Running all workspace tests...$(RESET)"
	@cargo test --all-features --workspace
	@echo "$(GREEN)✓ All tests passed$(RESET)"

# Book targets
.PHONY: book
book:
	@echo "$(BLUE)Building mdbook...$(RESET)"
	@mdbook build
	@echo "$(CYAN)• Restoring worktree link...$(RESET)"
	@echo "gitdir: $$(pwd)/.git/worktrees/$(DEST_DIR)" > $(DEST_DIR)/.git
	@echo "$(GREEN)✓ Book built at $(DEST_DIR)/$(RESET)"

# Development targets
.PHONY: serve
serve:
	@echo "$(BLUE)Starting mdbook server...$(RESET)"
	@echo "$(CYAN)• Serving at http://$(LOCALHOST):$(LOCALPORT)$(RESET)"
	@mdbook serve -n $(LOCALHOST) -p $(LOCALPORT)

.PHONY: watch
watch:
	@echo "$(BLUE)Watching for changes...$(RESET)"
	@echo "$(CYAN)• Will rebuild on file changes$(RESET)"
	@mdbook watch

# Utility targets
.PHONY: tracked-files
tracked-files:
	@echo "$(BLUE)Saving tracked files list...$(RESET)"
	@mkdir -p $(TARGET)
	@git ls-files > $(TARGET)/git-tracked-files.txt
	@echo "$(GREEN)✓ Tracked files saved to $(TARGET)/git-tracked-files.txt$(RESET)"
	@echo "$(CYAN)• Total files: $$(wc -l < $(TARGET)/git-tracked-files.txt)$(RESET)"

.PHONY: push
push:
	@echo "$(BLUE)Pushing changes ...$(RESET)"
	@echo "$(CYAN)• Codeberg:$(RESET)"
	@git push codeberg $(CODE_BRANCH) && git push codeberg --tags
	@echo "$(GREEN)✓ Pushed$(RESET)"
	@echo "$(CYAN)• Github:$(RESET)"
	@git push github $(CODE_BRANCH) && git push github --tags
	@echo "$(GREEN)✓ Pushed$(RESET)"

.PHONY: deploy
deploy: book
	@echo "$(BLUE)Deploying site...$(RESET)"
	@echo "$(CYAN)Updating git worktree $(DEST_DIR) dir for $(PUBLISH_BRANCH) branch ...$(RESET)"
	@cd $(DEST_DIR) && \
	git add -A && \
	(git commit -m "Book rebuild - $(BUILD_TIME)" || echo "$(YELLOW)No changes to commit$(RESET)")
	@echo "$(CYAN)• Codeberg:$(RESET)"
	@git push codeberg $(PUBLISH_BRANCH)
	@echo "$(GREEN)✓ Published$(RESET)"
	@echo "$(CYAN)• Github:$(RESET)"
	@git push github $(PUBLISH_BRANCH)
	@echo "$(GREEN)✓ Published$(RESET)"
	@echo "$(GREEN)✓ Deployment complete$(RESET)"
	@echo "$(CYAN)→ Site should now be live at:"
	@echo "$(CYAN)• Codeberg: $(RESET)$(BLUE)$(BACKUP_SITE_URL)$(RESET)"
	@echo "$(CYAN)• Github: $(RESET)$(BLUE)$(SITE_URL)$(RESET)"
