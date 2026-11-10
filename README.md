# sofcat-harness-example

An example [sofcat](https://sofcat.app) repository that manages Claude Code
and Codex on a fleet. Read it, fork it, or point a test device at it. Every
value in it is made up, so replace the URLs, group names and model names
before you use any of it.

It shows three things:

1. Two skills shipped as zip items. One has its `SKILL.md` rendered on the
   device, worded for each tool and OS.
2. A plugin shipped as a zip item, with a marketplace catalog that sofcat
   renders from whatever plugins are placed.
3. Machine-wide config files for both tools, rendered from templates and the
   device's facts.

The rules behind all of it are in the
[zip items guide](https://sofcat.app/zip-items/overview/).

## Requirements

This repository needs sofcat and `makecatalogs` v3.0.0 or later. Every
template here is a file named by `template_file`, `build.sh` runs
`makecatalogs build`, and the files in `policy/` need the write roots
policy. v3.0.0 is the first release with all three.

The config placements are macOS only. The skill and plugin placements also
carry Windows paths, which nobody has run on a device yet. Treat every path
as a starting point and check each tool's own documentation for the
directories it reads.

## What is in here

| Path | What it is |
|---|---|
| `placements.yaml` | Where items land and which files sofcat renders beside them |
| `templates/` | One template per rendered file |
| `items/` | One package-info stub per item, with the placements it goes in |
| `item-trees/<item>/` | The tree each item places, the same in every placement and OS |
| `manifests/site_default.yaml` | Which items are managed and which are optional |
| `conditions/darwin/10-example-facts` | The fact script a Mac needs, delivered by the repository |
| `write-roots.example.yaml` | The write roots `placements.yaml` needs |
| `policy/` | The same roots as managed policy: a macOS profile and a Group Policy template |
| `build.sh` | Builds the repository a device reads into `public/` |

## Placements

| Placement | Items | Files it writes on macOS |
|---|---|---|
| `claude-code-skills` | `example-skill`, `example-templated-skill`, `sofcat` | none |
| `codex-skills` | `example-skill`, `example-templated-skill`, `sofcat` | none |
| `example-marketplace` | `example-plugin` | `<root>/.claude-plugin/marketplace.json` and `/Library/Application Support/ClaudeCode/managed-settings.d/50-example.json` |
| `harness-claude-code` | `claude-code-config` | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| `harness-codex` | `codex-models` | `/etc/codex/config.toml` and `/etc/codex/managed_config.toml` |

`example-skill` is in `managed_installs`, so every device gets it in both
skill directories. `example-plugin` is in `optional_installs`. A user adds it
from the self-service app, and the marketplace catalog then lists it with
`defaultEnabled: false`. Move it to `managed_installs` and the drop-in also
enables it for everyone.

`example-templated-skill` is managed too. Its tree holds `SKILL.md.tmpl`
and no `SKILL.md`, so sofcat renders the skill on the device. The text names
Claude Code or Codex from `.Placement.Name`, macOS or Windows from `.OS`, and
the user in Codex's per-user Windows placement. See
[Tree templates](https://sofcat.app/zip-items/tree-templates/).

`sofcat` is a skill about this repository. It tells a coding agent how to
add, change and publish items in a store laid out like this one. It is
optional, so the people who maintain the store add it from the self-service
app. Its source is `item-trees/sofcat/SKILL.md`.

The two config items exist to hold their placements. sofcat removes a
placement file when its template renders nothing, and every template here is
wrapped in `{{ if .Items }}`. Take `claude-code-config` out of the manifest
and `managed-settings.json` goes with it.

With the facts `assigned_user: jdoe` and `memberof: [staff, harness-beta]`,
the device gets this `managed-settings.json`:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://beta.ai.example.com/claude",
    "ANTHROPIC_CUSTOM_HEADERS": "x-example-user: jdoe\nx-example-profile: beta"
  },
  "model": "example-next",
  "permissions": {
    "deny": [
      "Read(./.env)"
    ]
  }
}
```

and this `/etc/codex/config.toml`:

```toml
# Written by sofcat. Do not edit.
model = "example-codex"
model_provider = "example-gateway"
model_catalog_json = "/Library/Application Support/Example/harness/codex/codex-models/model_catalog.json"

[model_providers.example-gateway]
name = "Example gateway"
base_url = "https://ai.example.com/codex/v1"
http_headers = { "x-example-user" = "jdoe" }
```

## Things to know before you copy it

**sofcat writes only under its write roots.** A stock build has one root, its
own directory, so it refuses every path in `placements.yaml`, the ones under
`/Library/Application Support/Example` included. There are two ways to add
the roots in `write-roots.example.yaml`. Copy the file into your brand as
`write-roots.yaml` and rebuild, or deliver the same roots as managed policy
from MDM or Group Policy, which works for a stock build too.
`policy/write-roots.mobileconfig` is a profile with the macOS roots, and
`policy/sofcat-write-roots.admx` is a Group Policy template for the Windows
ones. Both name the stock build, so a brand build needs its own identifier
and name in them. sofcat reads the policy when the service starts, so restart
the service after changing it. See
[Write roots](https://sofcat.app/zip-items/placements/#write-roots).

**One placement per target file.** sofcat does not stop two placements from
naming the same path, so check that yourself. `managed-settings.json` and the `managed-settings.d` drop-in are separate
files, so they can belong to separate placements.

**Facts come from a script on the device.** The templates read
`assigned_user` and `memberof`. sofcat has neither built in. A script prints
them as JSON, and `conditions/darwin/10-example-facts` is a sketch of one for
macOS. The repository delivers it, so every Mac that reads this repository
runs it as root. A template that reads a missing fact fails to render, and
sofcat leaves the existing file alone. `check_facts` in `placements.yaml` gives `makecatalogs -check` values
to render with. See
[Scripts from the repository](https://sofcat.app/guides/conditions/#scripts-from-the-repository).

**Whitespace matters in TOML templates.** sofcat rewrites a `.json` output in
canonical form, so only the values in the template count. It writes any other
file as the template emits it. That is why the TOML templates trim with
`{{-` and `-}}`.

**Big files ship in the item tree.** A rendered placement file is limited to
1 MiB. A real Codex model catalog is larger, so `codex-models` carries
`model_catalog.json` in its tree, and `config.toml` builds the path to the
placed copy from `.Placement.Root` and the item's name.

## Build

```sh
MAKECATALOGS=/path/to/makecatalogs ./build.sh
```

This runs `makecatalogs build`, which packs each item's tree into zips
under `public/packages/harness/` for every placement in its `placements:`,
writes `public/catalogs/harness.yaml` and `public/catalogs/conditions.yaml`,
and checks the result. It wipes `public/` first. CI does the same on every
push and pull request.

## Point a device at it

CI publishes `public/` from `main` to GitHub Pages, so a test device can read
this repository as it is. Give it this `config.yaml`, or serve your own
build over HTTP and change the two URLs:

```yaml
url: https://hurricanehrndz.github.io/sofcat-harness-example/
url_packages: https://hurricanehrndz.github.io/sofcat-harness-example/
manifest: site_default
catalogs:
  - harness
```

A Mac fetches `conditions/darwin/10-example-facts` at the start of each
managed run. Until it has, the config templates fail to render and sofcat
writes no config file.

## License

Apache-2.0, the same as sofcat.
