# Shared behavior for the dart and flutter command stubs.
# These scripts stand in for the real SDKs so tests do not download packages
# or boot Flutter.

write_workspace_ref() {
  if [ ! -f pubspec.yaml ]; then
    return 0
  fi
  if ! grep -q '^resolution:[[:space:]]*workspace[[:space:]]*$' pubspec.yaml; then
    return 0
  fi

  dir=$(pwd)
  root=""
  while [ "$dir" != "/" ]; do
    dir=$(dirname "$dir")
    if [ -f "$dir/pubspec.yaml" ] && grep -q '^workspace:' "$dir/pubspec.yaml"; then
      root=$dir
      break
    fi
  done

  if [ -z "$root" ]; then
    return 0
  fi

  # Relative path from <member>/.dart_tool/pub up to the workspace root.
  cursor="$(pwd)/.dart_tool/pub"
  rel=""
  while [ "$cursor" != "$root" ] && [ "$cursor" != "/" ]; do
    if [ -z "$rel" ]; then
      rel=".."
    else
      rel="../$rel"
    fi
    cursor=$(dirname "$cursor")
  done

  if [ "$cursor" != "$root" ]; then
    return 0
  fi

  mkdir -p .dart_tool/pub
  printf '{"workspaceRoot":"%s"}\n' "$rel" > .dart_tool/pub/workspace_ref.json
}

on_pub_get() {
  write_workspace_ref

  case "$(basename "$0")" in
    flutter)
      mkdir -p .dart_tool
      # Real Flutter records the SDK version here. FVM exports the pin.
      printf '%s' "${PUBY_STUB_FLUTTER_VERSION:-stable}" > .dart_tool/version
      ;;
  esac

  if [ -f example/pubspec.yaml ]; then
    printf '%s\n' 'Resolving dependencies in `./example`...'
  fi
}

handle_pub() {
  sub=${2:-}
  case "$sub" in
    get|upgrade|downgrade|add|remove|deps|outdated|cache)
      if [ "$sub" = "get" ]; then
        on_pub_get
      fi
      exit 0
      ;;
    *)
      printf 'Could not find a command named "%s".\n' "$sub" >&2
      exit 64
      ;;
  esac
}
