UINTA_HOME="$HOME/src/uinta"

[[ -d "$UINTA_HOME" ]] || return 0

export UINTA_HOME

uinta() {
  emulate -L zsh
  setopt localoptions no_unset

  local cmd="${1-}"
  case "$cmd" in
  b) cmd=build ;;
  d) cmd=dir ;;
  pm) cmd=project-management ;;
  r) cmd=repo ;;
  t) cmd="test" ;;
  esac

  case "$cmd" in
  build)
    cd "$UINTA_HOME" || return 1
    if [[ ! -d build ]]; then
      echo "→ Configuring CMake..."
      cmake -B build . || return 1
    fi
    echo "→ Building..."
    make -j"$(nproc)" --directory build
    ;;

  dir)
    cd "$UINTA_HOME" || return 1
    echo "→ $(pwd)"
    return
    ;;

  project-management)
    cd "$NEXTCLOUD_DIR/documents/uinta-project-management" || return 1
    nvim -c "lua require('persistence').load()"
    cd - >/dev/null || return
    ;;

  repo)
    cd "$REPOS/uinta" || return 1
    echo "→ $(pwd)"
    lazygit
    return
    ;;

  test)
    shift
    cd "$UINTA_HOME" || return 1
    local build_dir="$UINTA_HOME/build"

    if [[ ! -d "$build_dir" ]]; then
      echo "Build directory not found. Run: cmake -B build . && make -j\$(nproc) --directory build"
      return 1
    fi

    echo "→ Building..."
    make -j"$(nproc)" --directory build || return 1

    echo "→ Running tests with ctest..."
    if (($# > 0)); then
      ctest --test-dir "$build_dir" -R "$1" --output-on-failure --stop-on-failure
    else
      ctest --test-dir "$build_dir" --output-on-failure --stop-on-failure
    fi
    local rc=$?

    cd - >/dev/null || return
    return $rc
    ;;

  "")
    cd "$UINTA_HOME" || return 1
    nvim -c "lua require('persistence').load()"
    ;;

  *)
    echo "Unknown argument: \"$1\""
    return 1
    ;;
  esac
}

# Tab completion
_uinta() {
  # Only consider the first argument
  if ((CURRENT == 2)); then
    # shellcheck disable=SC2034 # read by name by _describe
    local -a commands=(
      "b:build the project"
      "d:go to source directory"
      "pm:project management"
      "r:go to repos directory"
      "t:run tests"
    )
    _describe "uinta command" commands
    return
  fi

  # Complete for tests
  # shellcheck disable=SC2154 # $words is set by the completion system
  if ((CURRENT == 3)) && [[ ${words[2]} == t ]]; then
    if [[ -d "$UINTA_HOME/build" ]]; then
      local -a tests
      local test_bin
      setopt localoptions null_glob
      for test_bin in "$UINTA_HOME/build"/src/*/test/*_test; do
        # shellcheck disable=SC2296 # zsh (f) flag: split on newlines
        tests+=("${(@f)$("$test_bin" --gtest_list_tests 2>/dev/null | command grep -E '^\w+\.' | sed 's/\.$//')}")
      done
      if ((${#tests[@]} > 0)); then
        _describe "test suites" tests
      fi
    fi
    return
  fi
}
compdef _uinta uinta
