# typed: false
# frozen_string_literal: true

# Yertle Homebrew formula.
#
# Wraps `uv tool install yertle[sre]` so `brew install yertle` gives
# users the `yertle` and `yertle-sre` commands backed by the PyPI
# `yertle` package. MCP intentionally stays PyPI-only (MCP hosts
# launch it via `uvx yertle-mcp`); the mcp entry-point shim is
# removed post-install to avoid shipping a broken binary.
#
# See BUMPING.md for how to publish a new version.
#
# Note: this formula is not homebrew-core-compatible today. When
# yertle reaches homebrew-core notability thresholds, this file will
# need a rewrite into pinned `resource` blocks and source-only builds.
# See TODO #11 in ../yertle/docs/notes/todo_important.txt for the
# rewrite plan and rationale.

class Yertle < Formula
  desc "Yertle CLI and SRE agent (Python)"
  homepage "https://yertle.com"
  url "https://files.pythonhosted.org/packages/d9/f7/62f496bdcd79dfc39aa264af567f7aef4d56a7373a6bdb4ad8fe03dc45ae/yertle-0.2.0.tar.gz"
  sha256 "8eb463022055db2a6ef7fc2f35decfac8616dcf59539b0214d3c7a8a71e908da"
  license "MIT"

  depends_on "python@3.12"
  depends_on "uv"

  def install
    ENV["UV_TOOL_DIR"] = libexec.to_s
    ENV["UV_TOOL_BIN_DIR"] = bin.to_s

    system Formula["uv"].opt_bin/"uv", "tool", "install",
           "yertle[sre]==#{version}",
           "--python", Formula["python@3.12"].opt_bin/"python3.12"

    # yertle-mcp ships as a console script but requires the [mcp] extra
    # (fastmcp) at runtime. Remove the shim so we don't expose a
    # broken command; MCP hosts install via `uvx yertle-mcp`.
    (bin/"yertle-mcp").unlink if (bin/"yertle-mcp").exist?
  end

  test do
    assert_match "yertle", shell_output("#{bin}/yertle --help")
    assert_match "yertle-sre", shell_output("#{bin}/yertle-sre --help")
    refute_predicate bin/"yertle-mcp", :exist?,
      "yertle-mcp should not be linked (mcp extra intentionally omitted)"
  end
end
