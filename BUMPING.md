# Bumping the yertle formula

The `yertle` formula wraps `uv tool install yertle[sre]` from PyPI. A
version bump only requires updating three lines in `yertle.rb`:

```ruby
url    "https://files.pythonhosted.org/packages/.../yertle-<VERSION>.tar.gz"
sha256 "<sdist sha256>"
```

(The `version` field is inferred from the URL, and the resource
block is empty — `uv` resolves and installs everything at build time
from PyPI wheels, so there is nothing else to pin.)

## Steps

1. Publish the new `yertle` release to PyPI (see
   `yertle/docs/notes/features/yertle-python/PACKAGING.md` in the
   backend repo). Wait for it to appear at
   `https://pypi.org/project/yertle/<VERSION>/`.

2. Grab the sdist URL and sha256:

   ```bash
   pip download --no-deps --no-binary=:all: --dest /tmp/y yertle==<VERSION>
   shasum -a 256 /tmp/y/yertle-<VERSION>.tar.gz
   # URL comes from `pip download -v ...` or from the PyPI project page's
   # "Download files" tab — copy the .tar.gz link.
   ```

3. Edit `yertle.rb`'s `url` and `sha256`. No other changes needed
   unless the deps model has shifted (e.g., adding a new required
   extra) — see "When more than a bump" below.

4. Test locally:

   ```bash
   # Copy your working copy into the real tap location for a test install:
   cp yertle.rb "$(brew --repository model-context/yertle)/yertle.rb"
   brew uninstall yertle
   brew install --build-from-source model-context/yertle/yertle
   yertle version
   yertle-sre --help
   ```

5. Open a PR with the two-line change.

## When more than a bump

The formula is minimal by design (see the header comment in
`yertle.rb`), but a few changes require thought:

- **Adding a new extra to the brew install** (e.g., someday including
  `[mcp]`): change the `uv tool install yertle[sre]==...` string in
  `yertle.rb` and drop the `bin/"yertle-mcp"` unlink.
- **Python version bump**: change `depends_on "python@3.12"` and both
  references to `python3.12` in `install`. Homebrew keeps a few
  python@X.Y formulae available; verify the target is one of them
  before bumping.
- **uv behavior change**: `uv tool install` is a fast-moving surface.
  If a new uv release breaks the install method, either pin uv
  (`depends_on "uv" => "0.x.y"`) or migrate to the resource-based
  formula (see TODO #11 in `yertle/docs/notes/todo_important.txt`).

## Known-broken paths (do not attempt without reading the TODO)

Do not attempt to rewrite this formula into a "proper" resource-based
Homebrew Python formula without first reading TODO #11 in
`../yertle/docs/notes/todo_important.txt`. That rewrite is the eventual
path to homebrew-core submission, but it's a real week of work
(65+ resources, Rust build toolchain, source-only build for jiter +
pydantic-core + orjson + friends). The current uv-based approach was
chosen precisely to avoid that until yertle warrants the investment.
