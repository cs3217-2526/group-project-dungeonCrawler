## Website

This website is built using [Docusaurus](https://docusaurus.io/), a modern static website generator.

**Installation** : `npm install`

**Local Development** : `npm start` (starts local server and opens up a browser window. Changes hot reloaded.)

**Build** : `npm run build` (generates static content into the build directory and can be served using any static contents hosting service.)

**Deployment** : If you are using GitHub pages for hosting, this command is a convenient way to build the website and push to the gh-pages branch. (In future)


## How to add pages

### Dev Guide

Add a `.md` file to `/dev-guide/`:

```
docs/
└── dev-guide/
    └── your-page.md   ← new file
```

With this frontmatter at the top, and the content below:

```md
---
sidebar_position: 2
---


# Your Page Title

Content here.
```

- `sidebar_position` controls the order in the sidebar (1 = first).
- The page will appear automatically under **Dev Guide** in the navbar.

---

### Game Manual

Same as above, but place the file in `/game-manual/` instead.

---

### Sidebar order

To reorder pages, adjust `sidebar_position` in each file's frontmatter. Lower numbers appear first.


### Group multiple pages under expandable heading

E.g. Group ECS pages under "ECS" heading in the dev-guide:

```
/dev-guide/
├── ecs/
│   ├── introduction.md
│   ├── components.md
│   └── systems.md
└── other-page.md
```

With this frontmatter at the top, and the content below:

```md
---
sidebar_position: 2
---

# Your Page Title

Content here.
```

- `sidebar_position` controls the order in the sidebar (1 = first).
- The page will appear automatically under **Dev Guide** in the navbar.

Also, add a `_category_.json` file into the subfolder to control the name and order: 

```json
{
  "label": "ECS",
  "position": 2
}
```

- `label` controls the display name of the category.
- `position` controls the order of the category in the sidebar (1 = first).