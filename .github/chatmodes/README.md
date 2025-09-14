# GitHub Copilot Chat Modes

This directory contains specialized chat modes for GitHub Copilot that provide expert assistance for different development tasks.

## Available Chat Modes

### 🧹 **Universal Janitor** (`janitor.chatmode.md`)
- **Purpose**: Clean up codebases by eliminating tech debt
- **Best for**: Removing unused code, simplifying complex logic, dependency cleanup
- **Philosophy**: "Less Code = Less Debt" - deletion is the most powerful refactoring

### 🐛 **Debug Mode** (`debug.chatmode.md`)
- **Purpose**: Systematic bug identification and resolution
- **Best for**: Troubleshooting shell script issues, network detection problems, macOS compatibility
- **Approach**: Structured debugging process with problem assessment, investigation, and resolution

### 📐 **Blueprint Mode v37** (`blueprint-mode.chatmode.md`)
- **Purpose**: Pragmatic senior software engineer with structured workflow
- **Best for**: Systematic project improvements, architectural decisions, complete implementations
- **Style**: Blunt, sarcastic, but highly effective with dry humor

### 📋 **Task Planner** (`task-planner.chatmode.md`)
- **Purpose**: Create actionable implementation plans with detailed task breakdown
- **Best for**: Project planning, feature development roadmaps, structured execution
- **Features**: Research validation, file operations, template conventions

### 🔧 **Technical Debt Remediation Plan** (`tech-debt-remediation-plan.chatmode.md`)
- **Purpose**: Generate comprehensive technical debt remediation plans
- **Best for**: Identifying improvement opportunities, planning refactoring efforts
- **Output**: Analysis-only mode with actionable recommendations

### 👨‍💼 **Principal Software Engineer** (`principal-software-engineer.chatmode.md`)
- **Purpose**: Expert-level engineering guidance balancing craft with pragmatic delivery
- **Best for**: High-level architectural decisions, engineering excellence standards
- **Approach**: Martin Fowler-inspired guidance with technical debt management

### 🚀 **4.1 Beast Mode** (`4.1-Beast.chatmode.md`)
- **Purpose**: Comprehensive workflow for deep problem understanding and systematic implementation
- **Best for**: Complex troubleshooting, thorough investigation, systematic problem solving
- **Features**: Multi-phase approach from understanding to validation

### 📄 **Specification Mode** (`specification.chatmode.md`)
- **Purpose**: Create detailed technical specifications and documentation
- **Best for**: Technical documentation, API specifications, system design documents
- **Output**: Comprehensive technical specifications

### ⚗️ **WG Code Alchemist** (`wg-code-alchemist.chatmode.md`)
- **Purpose**: Transform code with Clean Code principles and SOLID design
- **Best for**: Code quality improvement, refactoring guidance, clean architecture
- **Style**: JARVIS-inspired professional assistance with precise recommendations

## Usage

To use any of these chat modes in GitHub Copilot:

1. Open GitHub Copilot Chat in VS Code
2. Reference the chat mode by using `@chatmode` followed by the filename (without extension)
3. Example: `@chatmode janitor` to use the Universal Janitor

## Project Context

These chat modes are particularly valuable for this macOS wireless autoswitch project because they provide:

- **Shell script optimization** (Universal Janitor, Code Alchemist)
- **System debugging assistance** (Debug Mode, Beast Mode)
- **Project structure improvements** (Blueprint Mode, Principal Engineer)
- **Technical documentation** (Specification Mode)
- **Systematic planning** (Task Planner, Tech Debt Remediation)

Each mode brings specialized expertise to help maintain and improve the shell script automation system.
