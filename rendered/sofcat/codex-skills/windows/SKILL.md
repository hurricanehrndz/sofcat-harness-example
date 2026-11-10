---
name: sofcat
description: Add, change and publish the skills, plugins and config files of a sofcat store repository, which ships them as zip items. Use when the repository has a placements.yaml, or the user asks to add something to the store.
---

A sofcat store is a repository that devices read over HTTP. Sources live in
the layout below, `./build.sh` turns them into the published repository, and
a push to `main` publishes it.

    placements.yaml                 placements: a directory per OS, plus files sofcat renders there
    templates/                      templates of those files, named by template_file
    items/<item>.yaml               item_name, display_name, section, description, catalog, version
    rendered/<item>/<placement>/<darwin|windows>/   the tree the item places
    manifests/*.yaml                managed_installs (everyone) and optional_installs (self-service)

## Add an item

1. Pick the placement from `placements.yaml`. A skill goes in a skills
   placement, a plugin in the marketplace placement.
2. Write `items/<item>.yaml`. Copy a neighbour. Never add an `installer`
   block: the build writes it.
3. Put the files in `rendered/<item>/<placement>/<os>/`, once per placement
   and OS the item targets. The files sit directly in that directory, with
   no `<item>/` folder around them.
4. List the item in a manifest. Ask the user whether it is managed or
   optional if they have not said.
5. Run `./build.sh`. Done means it exits 0. It ends with
   `makecatalogs -check`, and its errors name the item or template at fault.

## Change an item

Edit the tree and raise `version` in `items/<item>.yaml`. A tool may not
reload a plugin whose version stayed the same.

## Change placements or templates

- A new path must sit under a write root of the sofcat build on the
  devices. `write-roots.example.yaml` lists the ones this store assumes.
  Tell the user when a change needs a new root, because that is a change
  outside this repository.
- Each target file belongs to one placement. Nothing checks this for you.
- Start a placement file's template with `{{ if .Items }}`, so the file
  goes away when the placement is empty.
- `fact "name"` and `cond "expr"` read device facts. A fact that comes from
  a script on the device needs a sample value under `check_facts` in
  `placements.yaml`, or the build fails.
- A `.json` output is rewritten in canonical form. Any other output is
  written as the template emits it, so mind whitespace.

The rules in full: https://sofcat.app/guides/zip-items/ and
https://sofcat.app/guides/conditions/.

## Publish

Commit the sources, never `public/`. Open a pull request, and CI runs the
same build. Merging to `main` publishes to every device that reads the
store, so do not push to `main` without the user's say.
