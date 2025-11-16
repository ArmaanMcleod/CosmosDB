<!--
SYNC IMPACT REPORT
==================
Version Change: Initial → 1.0.0
Modified Principles: N/A (Initial creation)
Added Sections: All core principles, Development Standards, Governance
Removed Sections: None
Templates Status:
  ✅ plan-template.md - Validated (no Constitution Check conflicts)
  ✅ spec-template.md - Validated (aligns with testing requirements)
  ✅ tasks-template.md - Validated (aligns with testing phases)
  ⚠ Command templates - Not present in repository (no updates needed)
Follow-up TODOs: None
-->

# CosmosDB PowerShell Module Constitution

## Core Principles

### I. Cross-Platform PowerShell-First

All module functionality MUST be implemented in PowerShell as the primary language, optimized for PowerShell 7.x and above. PowerShell 5.1 support is maintained for backward compatibility but is not the optimization target.

**Rationale**: This module serves PowerShell developers and DevOps engineers across Windows, macOS, and Linux platforms. PowerShell-first ensures maximum accessibility and maintainability within the target ecosystem.

**Non-negotiable rules**:
- All public cmdlets MUST follow PowerShell approved verb-noun naming conventions
- All functions MUST use PascalCase; parameters MUST use PascalCase; local variables MUST use camelCase
- All cmdlets MUST include comment-based help with SYNOPSIS and PARAMETER sections
- All parameters MUST include the `[Parameter()]` attribute explicitly
- Code MUST be tested on Windows (PowerShell 5.1 & 7.x), Linux (PowerShell 7.x), and macOS (PowerShell 7.x)

### II. Test-Driven Development with Pester 4.x

All code changes MUST be accompanied by Pester 4.x tests (unit and/or integration) that validate the functionality. Tests MUST be written before implementation and MUST fail initially (Red-Green-Refactor cycle).

**Rationale**: Pester 4.x is the current testing framework for this module. Test-first development ensures code quality, prevents regressions, and documents expected behavior. Migration to Pester 5.x is planned but not yet implemented.

**Non-negotiable rules**:
- New cmdlets MUST have unit tests in `tests/Unit/`
- Integration tests MUST be provided for Azure Cosmos DB REST API interactions
- Tests MUST pass on all supported platforms before merge
- Mock external dependencies appropriately to ensure test isolation

### III. Azure Cosmos DB REST API Fidelity

All cmdlet implementations MUST align with the official Azure Cosmos DB REST API specifications and best practices. The module is a PowerShell abstraction layer over the REST API, not a replacement.

**Rationale**: This module's primary value is providing PowerShell-native access to Cosmos DB via the REST API, supporting both RBAC (Entra ID) and token-based authentication. Deviating from API contracts breaks compatibility and user trust.

**Non-negotiable rules**:
- Cmdlets MUST use the official Cosmos DB REST API endpoints
- Entra ID (RBAC) authentication is the RECOMMENDED authentication method for production
- Master key authentication is ALLOWED but MUST include warnings about security risks
- All response headers and status codes from the REST API MUST be handled correctly
- Continuation tokens MUST be supported for paginated operations

### IV. Security and Authentication Best Practices

The module MUST prioritize secure authentication methods and protect sensitive information. Entra ID token-based authentication is REQUIRED for production scenarios unless a compelling reason exists for using master keys.

**Rationale**: Security is paramount when interacting with cloud databases. Exposing master keys or improper credential handling can lead to significant security breaches.

**Non-negotiable rules**:
- Entra ID authentication via `Get-CosmosDbEntraIdToken` is REQUIRED for production guidance
- Master keys MUST be stored as `SecureString` objects, never plain text
- Master key authentication examples MUST include security warnings
- Credential parameters MUST use `[PSCredential]` type, not plain text username/password
- Authorization headers MUST NOT be exposed in exception messages or logs

### V. Observability and Error Handling

All cmdlets MUST provide meaningful verbose output, proper error handling, and actionable exception messages. Users must be able to understand what the module is doing and diagnose issues effectively.

**Rationale**: PowerShell users expect rich, actionable output. Cosmos DB operations can fail for many reasons (throttling, partition key issues, etc.), and users need clear feedback.

**Non-negotiable rules**:
- Use `Write-Verbose` for operation details (never `Write-Host`)
- Exceptions MUST include clear messages indicating the cause and potential resolution
- HTTP status codes and Cosmos DB error codes MUST be surfaced to users
- Back-off policies for throttling (429 errors) MUST be supported via `New-CosmosDbBackoffPolicy`
- Response headers MUST be capturable via `-ResponseHeader` parameter where applicable

### VI. Semantic Versioning and Breaking Changes

The module MUST follow semantic versioning (MAJOR.MINOR.PATCH). Breaking changes MUST be clearly documented in CHANGELOG.md and increment the MAJOR version.

**Rationale**: Users depend on stability and predictability. Breaking changes without warning disrupt automation and scripts.

**Non-negotiable rules**:
- MAJOR version increments for breaking changes (e.g., parameter removals, behavior changes)
- MINOR version increments for new features that are backward compatible
- PATCH version increments for bug fixes and clarifications
- All changes MUST be documented in CHANGELOG.md following Keep a Changelog format
- Deprecated features MUST include warnings for at least one MINOR version before removal

## Development Standards

### Code Style and Quality

- All code MUST follow the style guidelines in `STYLEGUIDELINES.md`
- All code MUST pass `PSScriptAnalyzer` checks using the rules in `PSScriptAnalyzerSettings.psd1`
- Functions MUST be broken down into smaller, self-contained private utility functions if they exceed ~100 lines
- Code MUST use explicit parameter names, even when positional parameters are available
- Comments MUST be meaningful and start with a capital letter; no commented-out code in commits

### Documentation Standards

- All public cmdlets MUST have markdown documentation in `docs/` directory
- README.md MUST include quick-start examples and links to detailed documentation
- CHANGELOG.md MUST be updated with every change following Keep a Changelog format
- Examples in documentation MUST be tested and working

### Testing Standards

- Unit tests MUST cover all public cmdlets and private functions where feasible
- Integration tests MUST be runnable against both live Cosmos DB accounts and emulators
- Tests MUST clean up resources (collections, databases) after execution
- CI pipeline MUST run tests on all supported platforms (Windows, Linux, macOS)

## Governance

### Amendment Process

1. Proposed changes to this constitution MUST be documented in a GitHub issue
2. Changes MUST be reviewed and approved by the module maintainers
3. Constitution version MUST be incremented according to:
   - **MAJOR**: Backward incompatible principle removals or redefinitions
   - **MINOR**: New principle/section added or materially expanded guidance
   - **PATCH**: Clarifications, wording, typo fixes, non-semantic refinements
4. All dependent artifacts (templates, guidance files, README) MUST be updated to reflect changes

### Compliance Verification

- All pull requests MUST verify compliance with these principles
- Code review MUST check for adherence to style guidelines and testing requirements
- Complexity or deviations from these principles MUST be explicitly justified in the PR description
- CI pipeline failures related to tests or linting are BLOCKING issues

### Runtime Guidance

- For AI-assisted development, refer to `.github/copilot-instructions.md` for project-specific guidance
- For style and best practices, refer to `STYLEGUIDELINES.md`
- For contributing guidelines, refer to `.github/CONTRIBUTING.md`

**Version**: 1.0.0 | **Ratified**: 2025-11-16 | **Last Amended**: 2025-11-16
