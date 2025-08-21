#!/bin/bash
# shellcheck disable=SC2317

#MISE description="pre check environment"

# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.

set -u

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
if [ -z "${BASH_VERSION:-}" ]
then
  abort "Bash is required to interpret this script."
fi

# string formatters
if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
# tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
# tty_yellow="$(tty_mkbold 33)"
tty_green="$(tty_mkbold 32)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")" >&2
}

unset HAVE_SUDO_ACCESS # unset this from the environment

have_sudo_access() {
  if [[ ! -x "/usr/bin/sudo" ]]
  then
    return 1
  fi

  local -a SUDO=("/usr/bin/sudo")
  if [[ -n "${SUDO_ASKPASS-}" ]]
  then
    SUDO+=("-A")
  fi

  if [[ -z "${HAVE_SUDO_ACCESS-}" ]]
  then
    "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
    HAVE_SUDO_ACCESS="$?"
  fi

  if [[ -n "${BOOTSTRAP_ON_MACOS-}" ]] && [[ "${HAVE_SUDO_ACCESS}" -ne 0 ]]
  then
    abort "Need sudo access on macOS (e.g. the user ${USER} needs to be an Administrator)!"
  fi

  return "${HAVE_SUDO_ACCESS}"
}

execute_sudo() {
  local -a args=("$@")
  if [[ "${EUID:-${UID}}" != "0" ]] && have_sudo_access
  then
    if [[ -n "${SUDO_ASKPASS-}" ]]
    then
      args=("-A" "${args[@]}")
    fi
    ohai "/usr/bin/sudo" "${args[@]}"
    execute "/usr/bin/sudo" "${args[@]}"
  else
    ohai "${args[@]}"
    execute "${args[@]}"
  fi
}

command_exists () {
  command -v "$1" >/dev/null 2>&1
}

usage() {
  cat <<EOS
TheMartec martec-kit pre-check-env
Usage: pre-check-env.sh [options]
    -h, --help       Display this message.
EOS
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]
do
  case "$1" in
    -h | --help) usage ;;
    *)
      warn "Unrecognized option: '$1'"
      usage 1
      ;;
  esac
done

# USER isn't always set so provide a fall back for the installer and subprocesses.
if [[ -z "${USER-}" ]]
then
  USER="$(chomp "$(id -un)")"
  export USER
fi

# First check OS.
OS="$(uname)"
if [[ "${OS}" == "Linux" ]]
then
  BOOTSTRAP_ON_LINUX=1
elif [[ "${OS}" == "Darwin" ]]
then
  BOOTSTRAP_ON_MACOS=1
else
  abort "Bootstrap is only supported on macOS and Linux."
fi

execute() {
  if ! "$@"
  then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

check_run_command_as_root() {
  [[ "${EUID:-${UID}}" == "0" ]] || return

  abort "Don't run this as root!"
}

should_install_command_line_tools() {
  if [[ -n "${BOOTSTRAP_ON_LINUX-}" ]]
  then
    return 1
  fi

  ! [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]
}

####################################################################### script

cat <<EOS
${tty_green}
████████╗██╗  ██╗███████╗    ███╗   ███╗ █████╗ ██████╗ ████████╗███████╗ ██████╗
╚══██╔══╝██║  ██║██╔════╝    ████╗ ████║██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝
   ██║   ███████║█████╗      ██╔████╔██║███████║██████╔╝   ██║   █████╗  ██║     
   ██║   ██╔══██║██╔══╝      ██║╚██╔╝██║██╔══██║██╔══██╗   ██║   ██╔══╝  ██║     
   ██║   ██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║██║  ██║   ██║   ███████╗╚██████╗
   ╚═╝   ╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝ ╚═════╝

            =%@@@@@@@@@@+                            +@@@@@@@@@@@=            
         #@@@@@@@@@@@@@@@@@@-                    -@@@@@@@@@@@@@@@@@@%-        
      =@@@@@@@@@@@@@@@@@@@@@@@*                *@@@@@@@@@@@@@@@@@@@@@@@=      
     @@@@@@@#           *@@@@@@@=            -@@@@@@@%           %@@@@@@@-    
   -@@@@@@-               -@@@@@@#          #@@@@@@-               -@@@@@@=   
  +@@@@@*                   =@@@@@#        *@@@@@=                   *@@@@@*  
 -@@@@@+                     -@@@@@-      -@@@@@-                     =@@@@@= 
 #@@@@*             -%@@@%-   =@@@@@      @@@@@+              *@@@%-   +@@@@% 
 @@@@@             %@@@@@@@%   @@@@@=    -@@@@@             +@@@@@@@@   @@@@@ 
 @@@@%            =@@@@@@@@@-  #@@@@*    *@@@@%             @@@@@@@@@#  %@@@@-
 @@@@@            -@@@@@@@@@   %@@@@*    +@@@@%             @@@@@@@@@*  %@@@@-
 @@@@@             *@@@@@@@+   @@@@@-    -@@@@@              @@@@@@@%   @@@@@-
 *@@@@%              -*#*     *@@@@@      @@@@@*               +#*-    %@@@@@ 
  @@@@@#                     +@@@@@        @@@@@+                     #@@@@@# 
  -@@@@@@                   *@@@@@=        =@@@@@#                   @@@@@@@- 
    @@@@@@@               *@@@@@@=          =@@@@@@#               %@@@@@@@*  
     #@@@@@@@#-       -*@@@@@@@@              @@@@@@@@#-       -%@@@@@@@@@%   
       %@@@@@@@@@@@@@@@@@@@@@%-                -%@@@@@@@@@@@@@@@@@@@@@@@@%    
         =@@@@@@@@@@@@@@@@@+                      =@@@@@@@@@@@@@@@@@@@@@%     
              *@@@@@@@#-         @@#      =@@=        -#@@@@@@@*=@@@@@@*      
                               %@@@@@@@@@@@@@@@=              *@@@@@@@        
                               -%@@@@@@@@@@@@@=            *@@@@@@@@=         
                                    +%@@%*=            +@@@@@@@@@@            
                                                       =@@@@@@@*              
                                                        @@@#-${tty_reset}

${tty_bold}Starting pre check env as per 🚀${tty_reset}
  - https://github.com/themartec/bootstrap

EOS

SUCCESS=true

if [[ -n "${BOOTSTRAP_ON_MACOS-}" ]]
then
  ohai "✅ Detected MacOs - continuing"
else
  abort "⚠️ Warning Linux not fully supported yet - continuing with caution"
fi

check_run_command_as_root

if should_install_command_line_tools && test -t 0
then
  ohai "❌ xcode-select has NOT been installed"
  SUCCESS=false
else
  ohai "✅ xcode-select has been installed"
fi

if [[ -n "${HOMEBREW_ON_MACOS-}" ]] && ! output="$(/usr/bin/xcrun clang 2>&1)" && [[ "${output}" == *"license"* ]]
then
  ohai "❌ Xcode license has NOT been agreed to"
  SUCCESS=false
else
  ohai "✅ Xcode license has been agreed to"
fi

if command_exists brew; then
  ohai "✅ Homebrew is installed"
  ohai "   Homebrew: $(brew --version)"
else
  ohai "❌ Homebrew is NOT installed"
  SUCCESS=false
fi

if command_exists node; then
  ohai "✅ Node is installed"
  ohai "   Node: $(node --version)"
else
  ohai "❌ Node is NOT installed"
  SUCCESS=false
fi

if command_exists yarn; then
  ohai "✅ Yarn is installed"
  ohai "   Yarn: $(yarn --version)"
else
  ohai "❌ Yarn is NOT installed"
  SUCCESS=false
fi

if command_exists python; then
  ohai "✅ Python is installed"
  ohai "   Python: $(python --version)"
else
  ohai "❌ Python is NOT installed"
  SUCCESS=false
fi

if command_exists psql; then
  ohai "✅ Postgres is installed"
  POSTGRESQL_VERSION=$(psql \
      --command "SELECT SUBSTRING(VERSION() FROM '\w+\s\d+\.\d+')" \
      --tuples-only \
      --no-align \
  )
  ohai "   Postgres: ${POSTGRESQL_VERSION}"
else
  ohai "❌ Postgres is NOT installed"
  SUCCESS=false
fi

# USABLE_GIT=/usr/bin/git

if ${SUCCESS}
then
cat <<EOS

${tty_green}✅ Success 🎉${tty_reset}

for more info check out
- ${tty_bold}https://github.com/themartec/bootstrap${tty_reset}

EOS
  exit 0
else
cat <<EOS

${tty_red}❌ some issues found above${tty_reset}

for more info check out
- ${tty_bold}https://github.com/themartec/bootstrap${tty_reset}

EOS
  exit 1
fi
