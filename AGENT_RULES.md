# Agent Behavioral Guidelines / Code of Conduct

These guidelines are established to prevent unnecessary code modifications and ensure accurate implementation planning, based on retrospective analysis of past tasks.

## 1. Code-First Analysis (Fact-Checking)
*   **Principle**: Do not rely solely on visual observation of static samples or user descriptions.
*   **Action**: Before planning changes, deeply analyze the **existing component code** (React components, Logic, CSS) and **render output**.
*   **Why**: To identify what is already implemented (e.g., dynamic text, existing styling loops) versus what is actually missing.

## 2. Evidence-Based Gap Analysis
*   **Principle**: "Different until proven same" is dangerous. Assume "Potentially same" and verify.
*   **Action**: Explicitly list the **discrepancies** between the "Target Design/Behavior" and the "Current Implementation".
*   **Rule**: Only create tasks for items present in the "Target" but PROVEN missing in the "Current".

## 3. Respect Existing Architecture
*   **Principle**: Leveraging existing mechanisms (i18n, ThemeContext) is better than hardcoding.
*   **Action**: Check `client/src/locales`, `client/src/hooks`, and logical wrappers (like `StartupLayout`) before overriding content.
*   **Why**: To maintain maintainability and consistency (e.g., Dark Mode support, Multi-language support).

## 4. Upstream-Friendly Customization (Docker-first)
* **Principle**: アプリ本体は極力改変せず、公式Dockerイメージをそのまま利用し、upstream更新を取り込みやすくする。
* **Action**:
  * ロゴ/背景/CSS/翻訳/設定(yaml/env)は **コンテナ起動時のvolumeマウント** で注入。
  * Reactコンポーネント等、どうしてもソース改変が必要な箇所は **最小限のパッチ運用** にとどめる。
* **Why**: ソース差分を最小化し、upstreamとのマージコストを抑える。

## Revision History
- **2025-12-09**: Added initial rules following "Login Page Customization" task where redundant text/style changes were initially proposed.
- **2025-12-23**: Added upstream-friendly Docker/volume/patch運用方針。