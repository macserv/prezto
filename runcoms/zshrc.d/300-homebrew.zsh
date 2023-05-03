##
##  ZSHRC EXTENSION:
##  Functions: Homebrew
##


##
##  Generate .png of dependency tree for installed packages
##
##  Required Packages:
##      brew install martido/brew-graph/brew-graph
##      brew install graphviz
##
function brew_dependency_graph ()  # [package ...]
{
    local dependency_name="${(j'-')@}"
    [[ -z "$dependency_name" ]] && dependency_name="all"
    brew graph --installed --highlight-leaves --highlight-outdated $@ | dot -Tpdf -obrew-dependencies-${dependency_name}.pdf
}


##
##  Get options for installed package
##
##  Required Packages:
##      brew install jq
##
##  $1: Installed package name.
##
function brew_installed_options ()  # <package>
{
    [[ $# -ge 1 ]]  || fail 'Missing package name argument.' 10

    typeset installation_info=$(brew info --json=v1 $1)

    jq --raw-output ".[].installed[0].used_options | @sh" <<< "${installation_info}"
}


##
##  brew_reinstall_and_add_option <package> <options>
##  [WIP] Reinstall package with additional option(s)
##  - Parameters
##      - package: Installed package name
##      - options: The options to add when re-installing.
##  - Example
##      % brew_reinstall_and_add_option ffmpeg --with-libbluray --with-srt
##
##  # TODO: We're in zsh now... do this as a function.
##  alias brew_reinstall_and_add_option 'brew reinstall \!:1 `brew_installed_options \!:1` \!:2*'
##  set current_options = "`brew_installed_options ffmpeg`" && brew uninstall ffmpeg && brew install ffmpeg ${current_options} '--with-libvpx'
##


##
##  List all brew leaves with their description appended.
##
function brew_leaves_with_info ()
{
    for formula ( $(brew leaves) )
    {
        typeset description=$(brew info --json --formula "${formula}" | jq --raw-output '.[0].desc')
        echo "${formula} : ${description}"
    }
}


##
##  WIP
##
function update_brew_ssl_certs_from_keychain ()
{
    typeset -a keychains=(
        '/System/Library/Keychains/SystemRootCertificates.keychain'
        '/Library/Keychains/System.keychain'
        '~/Library/Keychains/login.keychain-db'
    )

    typeset -i found_count=0
    typeset -i added_count=0

    typeset all_certs_file && all_certs_file="$(mktemp)" || fail 'Unable to create temporary file for certificate output.'       $?
    typeset cert_file      && cert_file="$(mktemp)"      || fail 'Unable to create temporary file for certificate verification.' $?
    typeset cert_contents

    for keychain ( ${keychains} )
    {
        echo_log
        echo_log "Loading certificates from keychain '${keychain}'... \c" INFO
        typeset -a cert_names && cert_names=( ${(f)"$( security find-certificate -a "${keychain}" | grep '"alis"' | cut -d '"' -f 4 )"} )

        echo_err "${#cert_names} found."
        (( found_count += ${#cert_names} ))

        for cert_name ( ${cert_names} )
        {
            echo_log "${cert_name}... loading... \c" INFO 1
            cert_contents="$(security find-certificate -p -c "${cert_name}" "${keychain}" 2>/dev/null)" || { echo_err 'unable to load certificate contents. 🔴' ; continue }

            echo_err -n "exporting... "
            echo "${cert_contents}" >! "${cert_file}" || { echo_err 'unable to write cert contents to temporary file. 🔴' ; continue }

            echo_err -n "verifying... "
            security verify-cert -c "${cert_file}" -k "${keychain}" &>/dev/null || { echo_err 'certificate is not valid. 🔴' ; continue }

            echo_err -n "adding... "
            echo "${cert_contents}" >> "${all_certs_file}" || { echo_err 'unable to add certificate. 🔴' ; continue }
            (( added_count += 1 ))

            echo_err "done."
        }
    }

    echo_log
    echo_log "Added ${added_count} certificates of ${found_count} found." INFO
    echo_log "Saving to Homebrew certificate location..." INFO
}

    #     for cert_name ( ${cert_names} )
    #     {
    #         echo_log "${cert_name}... loading... \c" INFO 1
    #         cert_contents="$(security find-certificate -p -c "${cert_name}" "${keychain}" &>/dev/null)" || { echo_err "unable to load certificate contents; status '$?'" ; continue }

    #         echo_err -n "exporting... "
    #         echo "${cert_contents}" >! "${cert_file}" || { echo_err 'unable to write cert contents to temporary file.' ; continue }

    #         echo_err -n "verifying... "
    #         security verify-cert -c "${cert_file}" -k "${keychain}" &>/dev/null || { echo_err "certificate is not valid; status '$?'" ; continue }

    #         echo_err -n "adding... "
    #         echo "${cert_contents}" >> "${all_certs_file}" || { echo_err 'unable to add certificate.' ; continue }

    #         echo_err "done."
    #     }
