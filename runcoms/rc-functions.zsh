#
# Defines all user-created functions for shell commands
#


################################################################################
#  SHARED HELPERS

# 
#  unique-path <path>
#  Determines whether or not a file or directory exists at the given path.
#  If no file/folder exists, it will return the path unmodified.
#  If it does exist, it will attempt to generate a unique path by appending an
#  integer to the end, beginning at 1 and incrementing until the path is unique.
#  Parameter: Path to test
#
function unique-path
{
    if [[ $# < 1 ]] then;
        echo "[ERROR] No file path was provided."
        return 1
    fi

    local original_path="$1"
    local unique_path="${original_path}"
    local index=0

    while [[ -e $unique_path ]] ; do

        let index++
        unique_path="${original_path:r}-$index.${original_path:e}"

    done

    echo "${unique_path}"
}



################################################################################
#  FFMPEG

#
#  ff-codec <path>
#  Checks the codec used to encode a video file, and returns just the encoder
#  name, with no other information.
#  Parameter: Path to video file.
#
function ff-codec
{
    if [[ $# < 1 ]] then;
        echo "[ERROR] No input file was provided."
        return 1
    fi

    local input_file="$1"

    ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "${input_file}"

    return $?
}


#
#  ff-m3u8-to-mp4 <stream_url>
#  Download HLS (m3u8) MP4 Stream to File
#  Parameter: Stream URL.
#
function ff-m3u8-to-mp4
{
    if [[ $# < 1 ]] then;
        echo "[ERROR] No stream URL was provided."
        return 1
    fi

    local stream_url="$1"
    local output_file="${stream_url:h:t}-${stream_url:t:s/m3u8/mp4/}"

    ffmpeg -i "${stream_url}" -preset slower "${output_file}"

    return $?
}


#
#  ff-mp4ify <stream_url>
#  Convert file to mp4 (h264).
#  If video stream is already encoded using 'h264', it will be copied into the
#  new wrapper.  Otherwise, it will be converted, using the '-preset slower'
#  option, for better quality.
#  Parameter: File to convert to mp4.
#
function ff-mp4ify
{
    if [[ $# < 1 ]] then;
        echo "[ERROR] No input file was provided."
        return 1
    fi

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



################################################################################
#  HOMEBREW

#
#  brew-dependency-graph
#  Generate .png of dependency tree for installed packages
#  Required Packages:
#      brew install martido/brew-graph/brew-graph
#      brew install graphviz
#
function brew-dependency-graph
{
    brew-graph --installed --highlight-leaves | dot -Tpng -oBrewDependencies.png
}


#
#  brew-installed-options
#  Get options for installed package
#  Parameter: Installed package name.
#
function brew-installed-options
{
    if [[ $# < 1 ]] then;
        echo "[ERROR] No package name was provided."
        return 1
    fi

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
