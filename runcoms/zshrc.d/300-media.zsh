##
##  ZSHRC EXTENSION:
##  Functions: ffmpeg
##


################################################################################



################################################################################
##  ALIASES
##

##  ffmpeg: Hide banners for common commands.
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias ffplay='ffplay -hide_banner'



################################################################################
##  FUNCTIONS
##

##
##  Checks the codec used to encode a video file, and returns just the encoder
##  name, with no other information.
##
##  $1: Path to video file.
##
function ff_codec ()  # <path>
{
    typeset input_file="${~1}" ; [[ -n "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 10

    ffprobe -loglevel fatal -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "${input_file}"

    return $?
}


##
##  Return the duration (hh:mm:ss) of the specified video file.
##
##  $1: Path to video file to analyze for duration.
##
function ff_duration ()  # <path>
{
    typeset input_file="${~1}" ; [[ -n "${input_file}" ]] || fail 'Argument for input file is missing or empty.' 10
    typeset ffmpeg_output && ffmpeg_output=$(ffmpeg -i "${input_file}" -map 0:v:0 -c copy -f null /dev/null 2>&1) || fail "Failed to use ffmpeg to get information about input file: '${input_file}'." $?
    typeset time_info && time_info=$(echo "${ffmpeg_output}" | grep "time=") || fail "Information for '${input_file}' did not contain a time value." 20

    echo "${time_info}" | perl -pe "s/.*time=([0-9:]+).*/\$1/"
}


##
##  Download HLS (m3u8) MP4 Stream to File
##
##  $1: URL to m3u8 file containing HLS stream configuration data.
##
function ff_m3u8_to_mp4 ()  # <stream_url>
{
    typeset stream_url="${1}" ; [[ -n "${stream_url}" ]] || fail 'Argument for stream URL is missing or empty.' 10
    typeset output_file=$(unique_path "${stream_url:h:t}-${stream_url:t:r}.mp4")

    ffmpeg -i "${stream_url}" ${Z_RC_FFMPEG_H264_OPTIONS[*]} "${output_file}"

    return $?
}


##
##  Convert file to mp4 (h264).
##
##  If video stream is already encoded using 'h264', it will be copied into the
##  new wrapper.  Otherwise, it will be converted, using the '-preset slower'
##  option, for better quality.
##
##  $1: File to convert to mp4.
##
function ff_mp4ify ()  # <stream_url>
{
    typeset input_file="${1}" ; [[ -n "${input_file}" && -f "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 10
    typeset output_file=$(unique_path "${input_file:r}.mp4")
    typeset -a ffmpeg_options=( ${Z_RC_FFMPEG_H264_OPTIONS[*]} )
    typeset duration && duration=$(ff_duration "${input_file}") || unset duration

    # Bypass h264-related ffmpeg options if file is already h264-encoded.
    [[ $(ff_codec "${input_file}") == "h264" ]] && ffmpeg_options=(-c:v copy)

    echo -n "Writing '${output_file}'..."

    # Convert and use progress updates to log timestamp to single line per file.
    ffmpeg -loglevel fatal -progress /dev/stdout -i "${input_file}" ${ffmpeg_options[*]} "${output_file}" | while read -r line
    do
        [[ "${line}" =~ "out_time=" ]] &&
        {
            out_time=$(echo "${line}" | cut -d '=' -f 2 | cut -d '.' -f 1)
            echo -ne                      "\r\033[2K" # (CR and clear line)
            echo -n                       "Writing '${output_file}' : ${out_time} "
            [[ -v duration ]] && echo -ne "of ${duration} "
            echo -n                       "... "
        }
    done

    [[ ${pipestatus[1]} -eq 0 ]] ||
    {
        [[ -f ${output_file} ]] && rm -f "${output_file}"
        echo ; fail "Failed to convert '${input_file}'." 30
    }

    echo -ne "\r\033[2K" # (CR and clear line)
    echo "Writing '${output_file}' - done!"

    # Force-move file to original file's path, replacing its contents.
    mv_replace "${output_file}" "${input_file}"  || fail 'The original file contents could not be replaced with the converted video data.' $?
    mv         "${input_file}"  "${output_file}" || fail 'The converted video file could not be renamed after replacing the original file.' $?

    return $?
}


##
##  "Rotate" video file.
##
##  This only adds metadata to the video; it does not re-encode the
##  video in a rotated orientation.  This has two benefits: it's fast,
##  and does not impact the video quality.
##
##  It does require the player to interpret the metadata, so if your
##  player is not modern, the video may not be presented with rotation.
##
##  $1: The path to the file to be rotated.
##  $2: Optional.  The rotation which should be applied when played.  If omitted,
##       the current rotation metadata will be displayed.
##
function ff_rotation ()  # <video_file> [angle]
{
    [[ -v TMPDIR ]] || fail "The '\$TMPDIR' variable is not set.  This should have been done by macOS when your shell started." 10

    typeset input_file="${~1}" ; [[ -n "${input_file}" && -f "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 20
    typeset   rotation="${2}"  ; [[ -n "${rotation}" ]] ||
    {
        ffprobe -loglevel fatal -v 0 -select_streams v:0 -show_entries stream_side_data=rotation -of default=nokey=1:noprint_wrappers=1 "${input_file}"
        return $?
    }

    typeset      input_basename="${input_file:t}"     # foo.mp4
    typeset          input_name="${input_basename:r}" # foo
    typeset     input_extension="${input_basename:e}" # mp4
    typeset     output_tmp_file="${TMPDIR}/${input_name}.$(uuidgen).${input_extension}"
    typeset input_date_modified="$(stat -f "%Sm" -t "%C%y%m%d%H%M.%S" "${input_file}")"

    ffmpeg -loglevel fatal -i "${input_file}" -metadata:s:v rotate="${rotation}" -codec copy "${output_tmp_file}" || fail 'FFmpeg could not apply the rotation metadata.' $?

    mv_replace "${output_tmp_file}" "${input_file}" || fail 'The original file contents could not be replaced with the rotated video data.' $?

    return 0
}


##
##  Trim video file using start/end timestamps.
##
##  Regarding timestamp format, from FFmpeg documentation...
##
##      You can use two different time unit formats:
##      sexagesimal(HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678),
##      or in seconds. If a fraction is used, such as 02:30.05, this
##      is interpreted as "5 100ths of a second", not as frame 5.
##
##  $1: The path to the video file to be trimmed.
##  $2: The starting mark, before which any video content should be deleted.
##  $3: The ending mark, after which any video content should be deleted.
##
function ff_trim ()  # <video_file> <clip_start_time> <clip_end_time>
{
    typeset  input_file="${~1}" ; [[ -n "${input_file}" && -f "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 10
    typeset  start_time="${2}"  ; [[ -n "${start_time}" ]]                       || fail 'Argument for clip start time is missing or empty.' 11
    typeset    end_time="${3}"  ; [[ -n "${end_time}"   ]]                       || fail 'Argument for clip end time is missing or empty.' 12
    typeset output_file=$(unique_path "${input_file:r}-trimmed.${input_file:e}")

    # NOTE: The ordering of these arguments is very important in order to achieve the expected trimming behavior.
    ffmpeg -loglevel 'panic' -ss ${start_time} -to ${end_time} -noaccurate_seek -i "${input_file}" -avoid_negative_ts 'make_zero' -c 'copy' "${output_file}" || fail 'FFmpeg failed to trim the video.' $?

    return 0
}


##
##  Present a video player window whose input is the FaceTime HD Camera built
##  into the current device.
##
##  The resolution will be 1920x1080, presented in a 1280x720 window.
##  The displayed video will be flipped horizontally for self-adjustment.
##
##  Send break to exit from the command
##
function ff_selfie ()  # <video_file> <clip_start_time> <clip_end_time>
{
    ffplay -hide_banner -loglevel 'warning' \
        -f 'avfoundation' -i 'FaceTime HD Camera' \
        -video_size '1280x720' -x '1280' -y '720' \
        -framerate '30' -pixel_format 'uyvy422' \
        -vf 'hflip'

    # Handle exit status '123' when break is sent.
    [[ $? == 123 ]] && return 0
}


##
##  Use `yt-dlp` to fetch a URL stored in the pasteboard, and apply some
##  sensible default parameters prioritizing mp4 video.
##
##  Passes arguments through to `yt-dlp` command.
##
function yt_dlpaste ()
{
    typeset video_ext_best='ext=mp4'             # Prefer MP4 container format.
    typeset audio_ext_best='ext=m4a'             # Prefer M4A audio format.
    typeset video_codec_non_av1='vcodec!*=av01'  # Avoid AV1 video codec.
    typeset video_codec_non_vp9='vcodec!*=vp09'  # Avoid VP9 video codec.
    typeset -i max_filename_length=200           # Maximum length of downloaded file name.

    typeset best_video="bestvideo[${video_ext_best}][${video_codec_non_av1}][${video_codec_non_vp9}]"
    typeset best_audio="bestaudio[${audio_ext_best}]"
    typeset best_fallback="best[${video_ext_best}]"
    typeset best_failsafe="best"
    typeset best_format="${best_video}+${best_audio}"
    typeset format="${best_format}/${best_fallback}/${best_failsafe}"

    typeset default_output_path='~/Desktop'      # Output path if Safari's download path isn't set.
    typeset safari_download_path="$(defaults read com.apple.Safari DownloadsPath)"
    typeset output_dir="${safari_download_path:-${default_output_path}}"
    typeset output_filename_format="%(title).${max_filename_length}s-%(id)s.%(ext)s"

    typeset output_path="${output_dir}/${output_filename_format}"
    typeset source_url="$(pbpaste)"

    echo_log --level 'INFO' "Downloading '${source_url}' to '${output_dir}'..."

    typeset -a ytdlp_command=(
        yt-dlp
            --format "${format}"        # Use the download format specifier above.
            --no-mtime                  # Do not change the file modification time.
            --embed-metadata            # Embed metadata and chapters/infojson if present
            --xattrs                    # Write metadata to the video file's xattrs
            --output "${output_path}"
            ${@}
        "${source_url}"
    )

    $ytdlp_command[@] ||
    {
        typeset -i ytdlp_status=$?
        display_notification "The yt-dlp download failed with status ${ytdlp_status}." "Video Download Failed"
        return
    }

    # Notify on success?
}


