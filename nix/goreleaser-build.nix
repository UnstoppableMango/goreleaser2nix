{
  lib,
  buildGoModule,
  goreleaser,
  gitMinimal,
}:

{
  goreleaserArgs ? [ "--single-target" ],
  gitUserName ? "nix",
  gitUserEmail ? "nix@goreleaser2nix",
  gitCommitMessage ? "nix build",
  gitTag ? null,
  gitCommitDate ? null,
  ...
}@args:

buildGoModule (
  (builtins.removeAttrs args [
    "goreleaserArgs"
    "gitUserName"
    "gitUserEmail"
    "gitCommitMessage"
    "gitTag"
    "gitCommitDate"
  ])
  // {
    nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
      goreleaser
      gitMinimal
    ];

    # goreleaser reads git state even with --snapshot; it errors without
    # a .git dir at all, so fake a trivial repo before building.
    buildPhase = ''
      runHook preBuild

      export HOME="$TMPDIR"
      git init -q .
      git config user.email ${lib.escapeShellArg gitUserEmail}
      git config user.name ${lib.escapeShellArg gitUserName}
      ${lib.optionalString (gitCommitDate != null) ''
        export GIT_AUTHOR_DATE=${lib.escapeShellArg gitCommitDate}
        export GIT_COMMITTER_DATE=${lib.escapeShellArg gitCommitDate}
      ''}
      git add -A
      git commit -q -m ${lib.escapeShellArg gitCommitMessage}
      ${lib.optionalString (gitTag != null) ''
        git tag ${lib.escapeShellArg gitTag}
      ''}

      goreleaser build --clean --snapshot ${lib.escapeShellArgs goreleaserArgs}

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r dist/. "$out/"
      runHook postInstall
    '';

    doCheck = args.doCheck or false;
  }
)
