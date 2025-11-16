This is a cross-platform PowerShell module for managing Azure Cosmos DB via the REST API, supporting both RBAC (Entra ID) and token-based authentication. It wraps the Cosmos DB REST API to provide PowerShell-native cmdlets for databases, collections, documents, users, permissions, and more.

## Architecture & Module Structure

### Source Organization (`source/`)
- **Public/**: Cmdlets organized by resource type (`accounts/`, `collections/`, `documents/`, `users/`, etc.)
- **Private/**: Internal utilities, especially `utils/Invoke-CosmosDbRequest.ps1` (the core REST API wrapper)
- **classes/CosmosDB/**: C# types (`CosmosDB.cs`) compiled to `CosmosDB.dll` via `dotnet build`
  - Defines `Context`, `ContextToken`, `BackoffPolicy`, `IndexingPolicy`, `UniqueKeyPolicy` types
  - Pre-compiled DLL loaded in `prefix.ps1`; falls back to runtime compilation if missing
- **prefix.ps1**: Module initialization (imports Az modules, loads types, localizes strings)
- **suffix.ps1**: Module teardown (currently unused)
- **CosmosDB.psd1**: Module manifest (auto-updated by build, don't edit version here)
- **CosmosDB.psm1**: Generated from build process (don't edit directly)

### Build System (Sampler-based)
```powershell
# Bootstrap dependencies (first time or after clean)
./build.ps1 -ResolveDependency -Tasks noop

# Standard build workflow
./build.ps1 -Tasks build  # Compiles classes, builds module, generates help
./build.ps1 -Tasks test   # Runs Pester 4.x tests (unit + integration)
./build.ps1 -Tasks pack   # Build + package for publishing
```

**Key workflows** (see `build.yaml`):
- `Compile_Classes`: Builds C# classes with `dotnet build source/classes/CosmosDB/CosmosDB.csproj`
- `Compile_Help`: Generates external help from `docs/*.md` using PlatyPS
- Module assembled in `output/CosmosDB/<version>/` with versioned output directory

### Testing Strategy
- **Unit tests** (`tests/Unit/`): Use `InModuleScope` to test private functions; organized by resource type
- **Integration tests** (`tests/Integration/`): Deploy real Cosmos DB account via Bicep (`tests/TestHelper/AzureDeploy/`), test against live API
- **Test helpers** (`tests/TestHelper/`): Shared fixtures, ARM/Bicep templates, authentication setup
- All tests use **Pester 4.x** (v5 not yet supported; migration planned)
- Code coverage target: 70% (configured in `build.yaml`)

## Core Patterns

### Context Object Pattern
Every cmdlet accepts a `[CosmosDB.Context]` via `-Context` parameter (or explicit `-Account`/`-Key`):
```powershell
$context = New-CosmosDbContext -Account 'myaccount' -Database 'mydb' -Key $secureKey
Get-CosmosDbCollection -Context $context -Id 'mycollection'
```

**Context contains**: Account, Database, Key (SecureString), KeyType (master/resource), BaseUri, Token array, EntraIdToken, BackoffPolicy, Environment

### Entra ID Authentication (Recommended)
```powershell
$token = Get-CosmosDbEntraIdToken -Endpoint 'https://myaccount.documents.azure.com'
$context = New-CosmosDbContext -Account 'myaccount' -EntraIdToken $token
# Or auto-generate: -AutoGenerateEntraIdToken $true
```

### REST API Wrapper (`Invoke-CosmosDbRequest`)
Central function in `Private/utils/Invoke-CosmosDbRequest.ps1`:
- Constructs authorization headers (master key or resource token)
- Builds resource links (`dbs/{db}/colls/{coll}/docs/{doc}`)
- Handles versioning (API version headers)
- Implements backoff policies for 429 throttling
- Returns custom `CosmosDb.ResponseException` (hides auth headers)

### Backoff Policy for Throttling
```powershell
$backoffPolicy = New-CosmosDbBackoffPolicy -MaxRetries 5 -Method Exponential -Delay 1000
$context = New-CosmosDbContext -Account 'myaccount' -BackoffPolicy $backoffPolicy
```
Methods: Default (uses `x-ms-retry-after-ms`), Additive, Linear, Exponential, Random

### Custom Types & Indexing Policies
Complex objects (IndexingPolicy, UniqueKeyPolicy) built via helper cmdlets:
```powershell
$index = New-CosmosDbCollectionIncludedPathIndex -Kind Range -DataType String
$includedPath = New-CosmosDbCollectionIncludedPath -Path '/*' -Index $index
$indexingPolicy = New-CosmosDbCollectionIndexingPolicy -Automatic $true -IncludedPath $includedPath
New-CosmosDbCollection -Context $context -Id 'mycoll' -IndexingPolicy $indexingPolicy
```

## Developer Workflows

### Adding a New Cmdlet
1. Create function in `source/Public/<resource-type>/Verb-CosmosDb<Noun>.ps1`
2. Add comment-based help (SYNOPSIS, PARAMETER sections mandatory)
3. Use parameter sets for Context vs Account authentication
4. Call `Invoke-CosmosDbRequest` with appropriate ResourceType/ResourcePath
5. Add unit test in `tests/Unit/CosmosDB.<resource-type>.Tests.ps1`
6. Add integration test if touches live API
7. Create/update markdown doc in `docs/Verb-CosmosDb<Noun>.md`
8. Run `./build.ps1 -Tasks build` to regenerate module and help

### Running Tests Locally
```powershell
# Unit tests only (fast, no Azure required)
./build.ps1 -Tasks test -PesterScript tests/Unit

# Integration tests (requires Azure subscription)
# Set environment variables: ARM_SUBSCRIPTION_ID, ARM_TENANT_ID, etc.
./build.ps1 -Tasks test -PesterScript tests/Integration
```

### Debugging
- Set `$VerbosePreference = 'Continue'` to see REST API calls in `Invoke-CosmosDbRequest`
- Use `-ResponseHeader ([ref] $responseHeader)` to capture response headers for diagnostics
- Check continuation tokens with `Get-CosmosDbContinuationToken -ResponseHeader $responseHeader`

## Code Conventions (Enforced by PSScriptAnalyzer)

- **Naming**: Functions use `Verb-CosmosDb<Noun>` (approved PowerShell verbs only)
- **Casing**: Parameters PascalCase, local variables camelCase
- **Parameter blocks**: Always include `[Parameter()]` attribute (even if empty)
- **Mandatory parameters**: `[Parameter(Mandatory = $true)]` (no default values on mandatory params)
- **Help**: Comment-based help above every public function
- **Splatting**: Use for long parameter lists to improve readability
- **Quotes**: Single quotes for literal strings, double quotes only when interpolating
- **Whitespace**: 4 spaces indentation, opening brace on new line (except hashtables/scriptblocks assigned to variables)
- **No aliases**: Use full cmdlet names in code (not `ls`, `?`, etc.)
- **SecureString**: All keys/tokens MUST be SecureString, never plain text

## Integration with Azure
- Requires `Az.Accounts` (≥5.0.0) and `Az.Resources` (≥8.0.0) for account management cmdlets
- Use `Get-CosmosDbAccountMasterKey` to retrieve keys from Azure (requires Azure login)
- Integration tests deploy/teardown via `tests/TestHelper/AzureDeploy/CosmosDb.bicep`

## Common Gotchas
- **Partition keys**: Collections >10k RU/s MUST have partition key; documents require `-PartitionKey` parameter
- **Continuation tokens**: Responses >4MB paginated; use `-MaxItemCount` and continuation tokens to iterate
- **API versioning**: Default API version in `Invoke-CosmosDbRequest` may need updating for new features
- **Emulator**: Use `New-CosmosDbContext -Emulator` for local testing (different base URI and well-known key)
- **Master key warnings**: Production code should prefer Entra ID auth; master key examples include security warnings

Refer to `STYLEGUIDELINES.md` for exhaustive formatting rules and `README.md` for user-facing examples.
