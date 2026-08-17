# 🤝 Contributing rule for clean architecture

Welcome to the building project! We're excited to have you here. To ensure code quality, stability, and a smooth development experience, we follow a structured **Feature Branch Workflow** and specific coding conventions.

Please read this document carefully before you start contributing.

---

## 🌳 Branching Strategy

We use a structured branching model to separate development from production.

| Branch          | Role            | Description                                                                                                                                             |
| :-------------- | :-------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **`main`**      | **Production**  | 🛡️ **The Sanctuary.** Contains only stable, deployable code. Direct pushes are forbidden. Merges happen only via Pull Requests from `dev` for releases. |
| **`dev`**(useful after launching MVP product)       | **Staging**     | 🔧 **Integration Hub.** The active development branch. All feature branches merge here for integration testing.                                         |
| **`feature/*`** | **Development** | ✨ **Workspace.** Dedicated branches for specific features or fixes (e.g., `feature/login-auth`).                                                       |

---

## 🚀 Workflow Guide

### 1. Start a New Feature

Always start your work from the latest `dev` branch to avoid conflicts.

```bash
# Sync local dev with remote
git checkout dev
git pull origin dev

# Create a feature branch
git checkout -b feature/your-feature-name
```

### 2. Develop & Commit

Make small, atomic commits with clear messages.

- **Convention**: This project uses **Gitmoji** combined with **Conventional Commits**.
- **Format**: `[Gitmoji] [Type]: [Title]`

| Gitmoji                 | Type       | Description           |
| :---------------------- | :--------- | :-------------------- |
| ✨ `:sparkles:`         | `feat`     | New features          |
| 🐛 `:bug:`              | `fix`      | Bug fixes             |
| 📚 `:books:`            | `docs`     | Documentation changes |
| 💄 `:lipstick:`         | `ui`       | UI changes            |
| ♻️ `:recycle:`          | `refactor` | Code refactoring      |
| 🚀 `:rocket:`           | `deploy`   | Deployment tasks      |
| ⚙️ `:gear:`             | `chore`    | Build/config changes  |
| ✅ `:white_check_mark:` | `test`     | Adding/fixing tests   |
| 🚑 `:ambulance:`        | `hotfix`   | Critical hotfixes     |

**Rule**: After completing a significant task or a series of related changes, **ALWAYS** provide a **single-line** git commit message in the format above. Focus on the most significant change.


```bash
git add .
git commit -m "✨ feat: implement basic login logic"
git push -u origin feature/your-feature-name
```

### 3. Pull Request (PR) & AI Code Review

⚠️ **IMPORTANT**: We prioritize the **MoAI code review workflow** (`/moai review`, delegated to the `manager-quality` subagent with `expert-security` support) over remote tools like GitHub Copilot. Local agents have full access to the codebase context and provide significantly deeper architectural and logic reviews, including TRUST 5 validation and @MX tag compliance.

1. **Local Review First**: Before pushing your code, ALWAYS run the MoAI review workflow.
   - **Command**: `/moai review` (alias: `code-review`) — multi-perspective review covering security, performance, quality, and UX.
   - **Useful flags**: `--staged` (staged changes only), `--branch` (whole branch diff), `--security` (deep security pass via `expert-security`).
2. **Refine & Polish**: Address all feedback provided by the agent locally.

### 5. Release (Main Branch) & Versioning

Deployment to production (`main`) is handled during release cycles. We follow **Semantic Versioning (SemVer)** with the following rules:

#### 🏷️ Versioning Rules

When tagging a release (`vX.Y.Z`), determine the version number as follows:

1.  **Major (`X.0.0`)**: If implementing a **Major Feature** or a new version milestone defined in `docs/Cubrain_strategic_building_roadmap.md` (e.g., moving from V1 to V2).
2.  **Minor (`1.Y.0`)**: If adding **Minor Features** or significant enhancements that don't reach a major milestone.
3.  **Patch (`1.0.Z`)**: If performing **Bug Fixes**, small tweaks, or maintenance.

#### 🚀 Release Process

1.  **Update package.json Version**: ALWAYS bump the `version` field in `frontend/package.json` to match the intended release. This is the single source of truth for the app's version.
2.  **Update "What's New"**: Create a new directory and `+page.md` in `frontend/src/routes/(marketing)/whats-new/vX-Y-Z/`. **The version in the Markdown frontmatter MUST exactly match the version in `package.json`.**
3.  **Merge dev to main**:
    ```bash
    git checkout main
    git pull origin main
    git merge dev
    git push origin main
    ```
4.  **Tagging**:
    ```bash
    # Example: git tag -a v1.1.0 -m "Release version 1.1.0"
    git tag -a v[VERSION] -m "Release version [VERSION]"
    git push origin v[VERSION]
    ```

---

## 🛠️ Development Commands

### Backend (Spring Boot)

- **Run**: `./gradlew bootRun`
- **Test**: `./gradlew test`
- **Build**: `./gradlew build`

### Frontend (SvelteKit)

- **Run**: `pnpm run dev`
- **Check**: `pnpm run check`
- **Lint**: `pnpm run lint`

---

## 🎨 Coding Standards

To maintain a high-quality codebase, we adhere to the following principles. 

⚠️Note that those below Principles can be adjusted followed by specific tech stack for Backend and Frontend.

### 1. General Principles

- **SOLID**: We strictly follow SOLID principles. No "God Classes" (keep services under 200 lines).
- **English Only**: All code comments, documentation, and annotations must be in **English**.
- **Documentation**: Use `@Operation` (Controllers) and `@Schema` (DTOs) for all API-related classes.
  - This rule might be deprecated since the API documentation won't be used primarily only if solo developer is planning to build one's app.

### 2. Backend (Spring Boot)

- **DTOs**: Never return entities directly. Use `record` DTOs with static factory methods (`from`, `of`).
- **Imports**: No wildcard imports. Use static imports for constants and enums.
- **Transactional**: Avoid `@Transactional` on methods with external API calls (AI, S3).

### 3. Frontend (Svelte 5)

- **Runes**: Use Svelte 5 Runes (`$state`, `$props`, `$derived`, `$effect`) exclusively.
- **Logging**: Wrap all `console.log` in `if (import.meta.env.DEV)` checks.
- **Icons**: Use `@lucide/svelte`.
  - This rule also be deprecated if much better tool can be found as followed by [development_pipeline_guideline document](../development_pipeline_guideline.md).

---

## 💡 General Guidelines

- **Stay Focused**: One feature/fix per branch.
- **Documentation**: Update `README.md` or relevant docs if your changes introduce new features.
- **Communication**: If you're unsure about something, open an issue or ask in the project's communication channel.

Thank you for comply to contributing rule! 🚀
