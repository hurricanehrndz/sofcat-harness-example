---
name: sofcat
description: Add, change and publish the skills, plugins and config files of a sofcat store repository, which ships them as zip items. Use when the repository has a placements.yaml, or the user asks to add something to the store.
---

A sofcat store is a repository that devices read over HTTP. Sources live in
the layout below, `./build.sh` turns them into the published repository, and
a push to `main` publishes it.

    placements.yaml                 placements: a directory per OS and/or files sofcat renders
    templates/                      templates of those files, named by template_file
    items/<item>.yaml               item_name, display_name, section, description, catalog, version, placements
    item-trees/<item>/              the tree the item places, the same for every placement and OS
    manifests/*.yaml                managed_installs (everyone) and optional_installs (self-service)

## Add an item

1. Pick the placements from `placements.yaml`, among those with `paths`.
   A skill goes in the skills placements, a plugin in the marketplace
   placement.
2. Write `items/<item>.yaml`, with `item_name` equal to the file name
   without `.yaml`, or the build fails. Copy a neighbour and name the
   placements in `placements:`. Never add an `installer` block: the build
   writes it.
3. Put the files directly in `item-trees/<item>/`, with no `<item>/` folder
   inside it. The build packs that one tree for every listed placement, on
   every OS the placement has a path for. A file named `x.tmpl` is
   rendered on the device into `x`, so ship one or the other, never both.
4. List the item in a manifest. Ask the user whether it is managed or
   optional if they have not said.
5. Run `./build.sh`, which runs `makecatalogs build`. Done means it exits 0.
   The build ends with a check, and its errors name the item or template at
   fault.

## Change an item

Edit the tree and raise `version` in `items/<item>.yaml`. A tool may not
reload a plugin whose version stayed the same.

## Change placements or templates

- A new path must sit under a write root of the sofcat build on the
  devices. `write-roots.example.yaml` lists the ones this store assumes.
  Tell the user when a change needs a new root, because that is a change
  outside this repository.
- Each target file belongs to one placement. Nothing checks this for you.
- In a placement with `paths`, start a file's template with
  `{{ if .Items }}`, so the file goes away when the placement is empty.
- A placement with `files` and no `paths` is rootless: no item may list
  it, its templates see no items, and every managed run writes its files on
  every device, whatever the manifest. Give each entry absolute `paths` per
  OS, and vary the content with `cond` and `fact`.
- sofcat keeps no record of the files it wrote, so deleting a `files` entry
  leaves its file on the devices. To retire a file, set `ensure: absent` on
  the entry and drop its template, then delete the entry once devices have
  run.
- `fact "name"` and `cond "expr"` read device facts. A fact that comes from
  a script on the device needs a sample value under `check_facts` in
  `placements.yaml`, or the build fails.
- A `.json` output is rewritten in canonical form. Any other output is
  written as the template emits it, so mind whitespace.

The rules in full: https://sofcat.app/zip-items/overview/ and
https://sofcat.app/guides/conditions/.

## Publish

Commit the sources, never `public/`. Open a pull request, and CI runs the
same build. Merging to `main` publishes to every device that reads the
store, so do not push to `main` without the user's say.
