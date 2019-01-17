#
# Defines all user-created functions for shell commands
#


################################################################################
#  SHARED / HELPERS

# 
#  Determines whether or not a file or directory exists at the given path.
#
#  If no file/folder exists, it will return the path unmodified.
#  If it does exist, it will attempt to generate a unique path by appending an
#  integer to the end, beginning at 1 and incrementing until the path is unique.
#
#  $1: Path to test for uniqueness
#
function unique-path # <path>
{
    [[ $# -ge 1 ]]  || bail 'Missing input path argument.' 10

    local original_path="$()$1"
    local unique_path="${original_path}"
    local index=0

    while [[ -e $unique_path ]] ; do

        let index++
        unique_path="${original_path:r}-$index.${original_path:e}"

    done

    echo "${unique_path}"
}


function bail # <message> <status>
{
    TRAPEXIT() { return $? }

    echo "[ERROR] ${1:-An error occurred.}"
    
    return ${2:-1}
}


################################################################################
#  FFMPEG

#
#  Checks the codec used to encode a video file, and returns just the encoder
#  name, with no other information.
#  
#  $1: Path to video file.
#
function ff-codec # <path>
{
    [[ $# -ge 1 ]]  || bail 'Missing input file argument.' 10

    local input_file="$1"

    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "${input_file}"

    return $?
}


#
#  Download HLS (m3u8) MP4 Stream to File
#  
#  $1: URL to m3u8 file containing HLS stream configuration data.
#
function ff-m3u8-to-mp4 # <stream_url>
{
    [[ $# -ge 1 ]]  || bail 'Missing stream URL argument.' 10

    local stream_url="$1"
    local output_file="${stream_url:h:t}-${stream_url:t:s/m3u8/mp4/}"

    ffmpeg -i "${stream_url}" -preset slower "${output_file}"

    return $?
}


#
#  Convert file to mp4 (h264).
#
#  If video stream is already encoded using 'h264', it will be copied into the
#  new wrapper.  Otherwise, it will be converted, using the '-preset slower'
#  option, for better quality.
#
#  $1: File to convert to mp4.
#
function ff-mp4ify # <stream_url>
{
    [[ $# -ge 1 ]]  || bail 'Missing input file argument.' 10

    local input_file="$1"
    local output_file=$(unique-path "${input_file:r}.mp4")
    local ffmpeg_options=(-preset slower)

    if [[ $(ff-codec "${input_file}") == "h264" ]] then;
        ffmpeg_options=(-c:v copy)
    fi

    ffmpeg -i "${input_file}" $ffmpeg_options "${output_file}"

    return $?
}


#
#  "Rotate" video file.
#
#  This only adds metadata to the video; it does not re-encode the
#  video in a rotated orientation.  This does not re-encode the video,
#  which has two benefits: it's fast, and does not impact the video
#  quality.
#  
#  It does require the player to interpret the metadata, so if your
#  player is crap, the video may not be presented with rotation.
#
#  $1: The path to the file to be rotated.
#  $2: The rotation which should be applied when played.
#
function ff-rotate # <video_file> <angle>
{
    [[ $# -ge 1 ]]  || bail 'Missing input file argument.' 10
    [[ $# -ge 2 ]]  || bail 'Missing rotation argument.'   15
    [[ -v TMPDIR ]] || bail 'The $TMPDIR variable is not set.  This should have been done by macOS when your shell started.' 20

    local input_file="$1"
    
    [[ -e $input_file ]] || bail 'The input file specified does not exist.' 30
                                                    # /path/to/foo.mp4 ($input_file)
    local      input_basename="${input_file:t}"     # foo.mp4
    local          input_name="${input_basename:r}" # foo
    local     input_extension="${input_basename:e}" # mp4
    local     output_tmp_file="${TMPDIR}/${input_name}.$(uuidgen).${input_extension}"
    local input_date_modified="$(stat -f "%Sm" -t "%C%y%m%d%H%M.%S" "${input_file}")"

    ffmpeg -loglevel panic -i "${input_file}" -metadata:s:v rotate="$2" -codec copy "${output_tmp_file}" || bail 'FFmpeg could not apply the rotation metadata.' $?
    
    # This is how you replace a file's contents, but preserve its metadata (label, permissions, creation date).
    mv -f "${output_tmp_file}" "${input_file}" || bail 'The original file contents could not be replaced with the rotated video data.' $?

    # The last bit of metadata to restore is the original modification date, which was stored above.
    touch -m -t ${input_date_modified} "${input_file}" || echo '[WARNING] Could not restore original modification date of the input file.'

    return 0
}



################################################################################
#  HOMEBREW

#
#  Generate .png of dependency tree for installed packages
#
#  Required Packages:
#      brew install martido/brew-graph/brew-graph
#      brew install graphviz
#
function brew-dependency-graph
{
    brew-graph --installed --highlight-leaves | dot -Tpng -oBrewDependencies.png
}


#
#  Get options for installed package
#
#  Required Packages:
#      brew install jq
#
#  $1: Installed package name.
#
function brew-installed-options # <package>
{
    [[ $# -ge 1 ]]  || bail 'Missing package name argument.' 10

    local installation_info=$(brew info --json=v1 $1)

    echo ${installation_info} | jq --raw-output ".[].installed[0].used_options | @sh"
}


#
#  brew-reinstall-and-add-option <package> <options>
#  [WIP] Reinstall package with additional option(s)
#  - Parameters
#      - package: Installed package name
#      - options: The options to add when re-installing.
#  - Example
#      % brew-reinstall-and-add-option ffmpeg --with-libbluray --with-srt
#
#  # TODO: We're in zsh now... do this as a function.
#  alias brew-reinstall-and-add-option 'brew reinstall \!:1 `brew-installed-options \!:1` \!:2*'
#  set current_options = "`brew-installed-options ffmpeg`" && brew uninstall ffmpeg && brew install ffmpeg ${current_options} '--with-libvpx'
#


################################################################################
#  CHASE

#
#  Enable network proxies.
#
function proxies-on
{
    export HTTP_PROXY="${http_proxy_value}"
    export HTTPS_PROXY="${https_proxy_value}"
    export ALL_PROXY="${all_proxy_value}"
    export NO_PROXY="${no_proxy_value}"

    export http_proxy="${HTTP_PROXY}"
    export https_proxy="${HTTPS_PROXY}"
    export all_proxy="${ALL_PROXY}"
    export no_proxy="${NO_PROXY}"
}

#
#  Disable network proxies.
#
function proxies-off
{
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    unset NO_PROXY

    unset http_proxy
    unset https_proxy
    unset all_proxy
    unset no_proxy
}
#


