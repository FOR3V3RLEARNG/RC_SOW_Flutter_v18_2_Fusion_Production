# RC SOW v20.4 — Scalable Production Architecture

## Design contract

RC SOW v20.4 preserves the visual behavior of the v18.2 Fusion build:

- spacious field-first layouts;
- small, restrained icons;
- light operational surfaces;
- rounded Material 3 containers;
- clear labels and state text;
- no dense generic admin-dashboard wall;
- phone-first navigation with adaptive tablet/desktop review mode.

The UI can change Design DNA without changing navigation, permissions or production semantics.

## Extension points

### 1. Roles and parish scope

Canonical role names live in `lib/core/app_constants.dart`.

Role-specific dashboard experience and module access live in one place:

`lib/core/product_registry.dart`

Add or change a role experience there instead of branching role checks throughout screens.

### 2. Production forms

Built-in source-derived forms live in:

`lib/core/record_schemas.dart`

Admin-created forms live in Supabase `record_form_templates` and use `custom:*` event keys. The Control screen merges built-in and server forms through `RcProductRegistry.visibleSchemas`.

### 3. Dashboard

The dashboard consumes `RcRoleExperience` instead of owning role policy. Metrics and quick actions are enum-driven. This keeps Site Supervisor, management, Admin, input-role and crew experiences consistent while allowing independent content density.

### 4. Theme / Design DNA

Theme tokens live in:

`lib/core/design_tokens.dart`

`RcIconSize` and `RcLayout` are the v18.2 density contract. Do not increase icon sizes per screen unless a technical diagram genuinely needs it.

### 5. Backend

Supabase is the authority for:

- parish visibility;
- role/privilege enforcement;
- crew assignment;
- attendance verification;
- messages and recipient targeting;
- beneficiary source files;
- custom form templates;
- document templates;
- evidence/signature storage;
- record visibility and deletion auditing.

Never rely only on Flutter hiding a button for security.

### 6. New production modules

For a new built-in module:

1. Add one `RcRecordSchema`.
2. Add the event type to the Supabase production contract/RLS if needed.
3. Add its title mapping in `productionTitle`.
4. Decide role visibility in `RcProductRegistry`.
5. Add unit tests.
6. Run GitHub Production Factory.

For an Admin-created form, use Form Studio. No app rebuild is required unless new custom field behavior is needed.

## Release rule

No feature is considered production-ready until GitHub passes:

1. canonical Dart formatting;
2. production-contract verification;
3. `flutter analyze`;
4. all unit/widget tests;
5. release APK;
6. split APKs;
7. AAB;
8. artifact checksums.
