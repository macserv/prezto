################################################################################
#  CONFIGURATION: GLOBAL PARAMETERS

declare -a Z_RC_FFMPEG_H264_OPTIONS
export     Z_RC_FFMPEG_H264_OPTIONS=(-preset slower -pix_fmt yuv420p -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2" -max_muxing_queue_size 9999)



################################################################################
#  FUNCTIONS: FFMPEG

#
#  Checks the codec used to encode a video file, and returns just the encoder
#  name, with no other information.
#  
#  $1: Path to video file.
#
function ff_codec() # <path>
{
    local input_file
    
    input_file="${~1}" ; [[ -n "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 10

    ffprobe -loglevel fatal -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 "${input_file}"

    return $?
}


#
#  Return the duration (hh:mm:ss) of the specified video file.
#
#  $1: Path to video file to analyze for duration.
#
function ff_duration() # <path>
{ 
    local input_file ffmpeg_output time_info
    
       input_file="${~1}" ; [[ -n "${input_file}" ]] || fail 'Argument for input file is missing or empty.' 10
    ffmpeg_output=$(ffmpeg -i "${input_file}" -map 0:v:0 -c copy -f null /dev/null 2>&1) || fail "Failed to use ffmpeg to get information about input file: '${input_file}'." $?
        time_info=$(echo "${ffmpeg_output}" | grep "time=") || fail "Information for '${input_file}' did not contain a time value." 20
    
    echo "${time_info}" | perl -pe "s/.*time=([0-9:]+).*/\$1/"
}


#
#  Download HLS (m3u8) MP4 Stream to File
#  
#  $1: URL to m3u8 file containing HLS stream configuration data.
#
function ff_m3u8_to_mp4() # <stream_url>
{
    local stream_url output_file

     stream_url="${1}" ; [[ -n "${stream_url}" ]] || fail 'Argument for stream URL is missing or empty.' 10
    output_file=$(unique-path "${stream_url:h:t}-${stream_url:t:r}.mp4")

    ffmpeg -i "${stream_url}" ${Z_RC_FFMPEG_H264_OPTIONS[*]} "${output_file}"

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
function ff_mp4ify() # <stream_url>
{
    local input_file output_file ffmpeg_options duration out_time

             input_file="${1}" ; [[ -n "${input_file}" && -f "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 10
            output_file=$(unique-path "${input_file:r}.mp4")
         ffmpeg_options=( ${Z_RC_FFMPEG_H264_OPTIONS[*]} )
               duration=$(ff-duration "${input_file}") || unset duration

    # Bypass h264-related ffmpeg options if file is already h264-encoded.
    [[ $(ff-codec "${input_file}") == "h264" ]] && ffmpeg_options=(-c:v copy)

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


#
#  "Rotate" video file.
#
#  This only adds metadata to the video; it does not re-encode the
#  video in a rotated orientation.  This has two benefits: it's fast,
#  and does not impact the video quality.
#  
#  It does require the player to interpret the metadata, so if your
#  player is not modern, the video may not be presented with rotation.
#
#  $1: The path to the file to be rotated.
#  $2: The rotation which should be applied when played.
#
function ff_rotate() # <video_file> <angle>
{
    local input_file rotation input_basename input_name input_extension output_tmp_file input_date_modified
    
    [[ -v TMPDIR ]] || fail "The '\$TMPDIR' variable is not set.  This should have been done by macOS when your shell started." 10

             input_file="${~1}" ; [[ -n "${input_file}" && -f "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 20
               rotation="${2}"  ; [[ -n "${rotation}" ]]                         || fail 'Argument for rotation is missing or empty' 30
         input_basename="${input_file:t}"     # foo.mp4
             input_name="${input_basename:r}" # foo
        input_extension="${input_basename:e}" # mp4
        output_tmp_file="${TMPDIR}/${input_name}.$(uuidgen).${input_extension}"
    input_date_modified="$(stat -f "%Sm" -t "%C%y%m%d%H%M.%S" "${input_file}")"

    ffmpeg -loglevel fatal -i "${input_file}" -metadata:s:v rotate="${rotation}" -codec copy "${output_tmp_file}" || fail 'FFmpeg could not apply the rotation metadata.' $?
    
    mv_replace "${output_tmp_file}" "${input_file}" || fail 'The original file contents could not be replaced with the rotated video data.' $?

    return 0
}


#
#  Trim video file using start/end timestamps.
#
#  Regarding timestamp format, from FFmpeg documentation...
#
#      You can use two different time unit formats:
#      sexagesimal(HOURS:MM:SS.MILLISECONDS, as in 01:23:45.678),
#      or in seconds. If a fraction is used, such as 02:30.05, this
#      is interpreted as "5 100ths of a second", not as frame 5.
#
#  $1: The path to the video file to be trimmed.
#  $2: The starting mark, before which any video content should be deleted.
#  $3: The ending mark, after which any video content should be deleted.
#
function ff_trim() # <video_file> <clip_start_time> <clip_end_time>
{
    local input_file start_time end_time output_file
    
     input_file="${~1}" ; [[ -n "${input_file}" && -f "${input_file}" ]] || fail 'Argument for input file is missing or empty, or file does not exist.' 10
     start_time="${2}"  ; [[ -n "${start_time}" ]]                       || fail 'Argument for clip start time is missing or empty.' 11
       end_time="${3}"  ; [[ -n "${end_time}"   ]]                       || fail 'Argument for clip end time is missing or empty.' 12
    output_file=$(unique-path "${input_file:r}-trim.${input_file:e}")
 
    # NOTE: The ordering of these arguments is very important in order to achieve the expected trimming behavior.
    ffmpeg -loglevel panic -ss ${start_time} -to ${end_time} -noaccurate_seek -i "${input_file}" -avoid_negative_ts make_zero -c:v copy -c:a copy "${output_file}" || fail 'FFmpeg failed to trim the video.' $?
    
    return 0
}

