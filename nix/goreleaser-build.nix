{
  lib,
  buildGoModule,
  goreleaser,
  gitMinimal,
}:

{
  goreleaserArgs ? [ "--single-target" ],
  ...
}@args:

buildGoModule (
  (builtins.removeAttrs args [ "goreleaserArgs" ])
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
      git config user.email "nix@goreleaser2nix"
      git config user.name "nix"
      git add -A
      git commit -q -m "nix build"

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
