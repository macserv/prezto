################################################################################
#  FUNCTIONS: FFMPEG

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
    local ffmpeg_options=(-preset slower -pix_fmt yuv420p)

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
    [[ -e ${1} ]]   || bail 'The input file specified does not exist.' 20
    [[ -v TMPDIR ]] || bail 'The $TMPDIR variable is not set.  This should have been done by macOS when your shell started.' 30

    local          input_file="$1"                  # /path/to/foo.mp4
    local      input_basename="${input_file:t}"     # foo.mp4
    local          input_name="${input_basename:r}" # foo
    local     input_extension="${input_basename:e}" # mp4
    local     output_tmp_file="${TMPDIR}/${input_name}.$(uuidgen).${input_extension}"
    local input_date_modified="$(stat -f "%Sm" -t "%C%y%m%d%H%M.%S" "${input_file}")"

    ffmpeg -loglevel panic -i "${input_file}" -metadata:s:v rotate="$2" -codec copy "${output_tmp_file}" || bail 'FFmpeg could not apply the rotation metadata.' $?
    
    # N.B.: You can use the `mv` command to replace a file's contents, but preserve its metadata (label, permissions, creation date).
    mv -f "${output_tmp_file}" "${input_file}" || bail 'The original file contents could not be replaced with the rotated video data.' $?

    # The last bit of metadata to restore is the original modification date, which was stored above.
    touch -m -t ${input_date_modified} "${input_file}" || echo '[WARNING] Could not restore original modification date of the input file.'

    return 0
}


#ffmpeg -ss 00:05:05 -to 00:06:04 -noaccurate_seek -i Blue\ Toe\ Socks.mp4 -avoid_negative_ts make_zero -c:v copy -c:a copy Blue\ Toe\ Socks.trim.mp4

#
#  Trim video file, producing a new
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
function ff-trim # <video_file> <clip_start_time> <clip_end_time>
{
    [[ $# -ge 1 ]] || bail 'Missing input file argument.' 10
    [[ $# -ge 2 ]] || bail 'Missing clip start time.'   11
    [[ $# -ge 3 ]] || bail 'Missing clip end time.'   12
    [[ -e ${1} ]]  || bail 'The input file specified does not exist.' 20

    local      input_file="${1}"
    local  input_basename="${input_file:t}"   
    local   input_dirname="${input_file:h}"   
    local      input_name="${input_basename:r}"
    local input_extension="${input_basename:e}"
    
    ffmpeg -loglevel panic -ss ${2} -to ${3} -noaccurate_seek -i "${1}" -avoid_negative_ts make_zero -c:v copy -c:a copy || bail 'FFmpeg failed to trim the video.' $?
    
    return 0
}

