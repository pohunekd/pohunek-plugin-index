# Reviewers

`CODEOWNERS` names the reviewers of every path. A reviewer approving an entry
reads the job summaries of the `check` and `prove` jobs of the run, not only the green checks:

- every predicate with its result;
- the archive's `runtime.toml` and `detect.toml` verbatim: the launched
  `program`, `args`, `launch_env`, `[integration]` and `requires`;
- the `diff -u` against the previous admitted version of the same package id.
- that the plugin keeps its package in `package/`: admission rebuilds the archive
  from that directory and refuses any other layout (the `5 package-dir` predicate).

Close a pull request unmerged when the launched program or its environment is
not what the plugin's documentation says it is.
