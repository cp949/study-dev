# ffmpeg

### 비디오 파일에서 mp3 추출

비디오 파일에서 mp3를 추출하는 기본적인 명령은 아래와 같다.

```bash
$  ffmpeg -i input.mp4 output.mp3
```

쉘 스크립트는 아래와 같이 작성했다. id3 태그도 포함하는 예제다.

```bash
#!/usr/bin/env bash

DEST_DIR=mp3
mkdir -p $DEST_DIR
for fpath in `ls *.mp4`
do
  fname=${fpath%.*}
  file_mp3="$DEST_DIR/${fname}.mp3"
	if [ ! -f "$file_mp3" ];then
    track=`echo $fname | tr -dc 0-9 | sed 's/^0*//'`
    ffmpeg -i "$fpath" \
      -metadata title="${fname}" \
      -metadata artist="frozen"  \
      -metadata track="$track"  \
      "$file_mp3"
	fi
done

```

[metadata로 key 목록은 위키에서 확인](https://wiki.multimedia.cx/index.php/FFmpeg_Metadata#QuickTime.2FMOV.2FMP4.2FM4A.2Fet_al.)

### Volume detect

```bash
$ ffmpeg -i input.mp3 -af "volumedetect" -f null /dev/null

# 아래와 같이 출력된다
...
[Parsed_volumedetect_0 @ 000002af8fa4b800] n_samples: 1570072
[Parsed_volumedetect_0 @ 000002af8fa4b800] mean_volume: -19.8 dB
[Parsed_volumedetect_0 @ 000002af8fa4b800] max_volume: -3.8 dB
[Parsed_volumedetect_0 @ 000002af8fa4b800] histogram_3db: 42
[Parsed_volumedetect_0 @ 000002af8fa4b800] histogram_4db: 644
[Parsed_volumedetect_0 @ 000002af8fa4b800] histogram_5db: 1520
```

### volume up

볼륨을 3배 높이는 예는 아래와 같다.

```bash
ffmpeg.exe -i input.mp3 -filter:a "volume=3" input_up.mp3
```

### 오디오 id3 tag 넣기

오디오 재생 프로그램에서 재생할때 id3 tag가 잘 들어가 있으면 분류하기가 좋다.
아래와 같이 id3 tag를 만들었다.

```bash

EDIT_DIR=edited
mkdir -p $EDIT_DIR

artist="frozen"
for fpath in `ls *.mp3`
do
  fname=${fpath%.*}
  file_mp3="$DEST_DIR/${fname}.mp3"
	if [ ! -f "$file_mp3" ];then
    track=`echo $fname | tr -dc 0-9 | sed 's/^0*//'`
    ffmpeg -i $fpath \
      -metadata title="${fname}"  \
      -metadata artist="$artist"  \
      -metadata track="$track"    \
      $EDIT_DIR/${fname}.mp3
	fi
done

```

### 오디오 반복하기

아래와 같이 쉘 스크립트를 작성했다. 제일 위에 `REPEAT`변수에 설정된 숫자만큼 반복된다.

```bash
REPEAT=5
DEST_DIR=repeat${REPEAT}
mkdir -p $DEST_DIR

artist="frozen"
for fpath in `ls *.mp3`
do
  fname=${fpath%.*}
  file_mp3="$DEST_DIR/${fname}.mp3"
	if [ ! -f "$file_mp3" ];then
    track=`echo $fname | tr -dc 0-9 | sed 's/^0*//'`
    ffmpeg  \
      -lavfi "amovie=${fpath}:loop=${REPEAT}" \
      -metadata title="${fname}_r${REPEAT}"  \
      -metadata artist="$artist"  \
      -metadata track="$track"   \
     $DEST_DIR/${fname}_r${REPEAT}.mp3
	fi
done

```

### 오디오 합치기

여러 mp3를 하나로 합치고 싶다면, ffmpeg의 concat 명령을 사용할 수 있다.
아래와 같이 스크립트를 작성할 수 있다.

```bash
$  printf "file '%s'\n" ./*.mp3 > .tmp_list.txt
$  ffmpeg -f concat -safe 0 -i .tmp_list.txt -c copy output.mp3
$  rm -f .tmp_list.txt
```

sox 명령으로 더 간단히 가능하지만 sox는 wav 파일만 가능하다. mp3를 wav로 바꾸는 단계가 필요해서 ffmpeg이 더 간단하다.

### 통합 스크립트

영어공부를 하기 위해 스크립트를 만들었다.

아래의 시나리오로 만들어진 하나의 mp3를 만들고자 한다.

- 6~7 개의 문장 정도가 하나의 대화이다.
- 대화 전체를 2회 들려준다.
- 둘째, 각 문장을 3회 반복하면서 전체를 들려준다.
- 대화 전체를 1회 들려준다.
- 각 문장을 5회 반복하면서 전체를 들려준다.
- 대화 전체를 1회 들려준다.

파일은

```
full/D001.mp3
D001/D001-01.mp3
D001/D001-02.mp3
D001/D001-03.mp3
D001/D001-04.mp3
D001/D001-05.mp3
D001/D001-06.mp3
```

그냥 파이썬이 더 나을까?

### mp3 파일 trim

결론, 정말로 깔끔한 사운드가 있는 것이 아니라면, trim은 안된다

오디오 trim을 해보면서 삽질한 이유 - 노이즈 때문에

- `start_threshold` ffmpeg의 `silenceremove` 필터의 `start_threshold` 옵션은 무음으로 간주할 소리의 크기를 지정한다. 이 옵션을 0으로 지정하면 trim이 잘 안되는 현상이 있었다. audacity로 확대해서 봤더니... 무음이나 마찬가지인 매우 낮은 잡음이 존재하고 있었다. 그래서 무음이 아니라서 trim이 안되는 것이었다. 소리파일마다 다르겠지만 나의 경우 start_threshold는 -50dB가 적당했다.
- `stop_silence` ffmpeg의 `silenceremove` 필터의 `stop_silence` 옵션은 trim을 할때 완전히 없애지 말고, 일부는 남겨두라는 의미이다. 예를 들어 stop_silence가 1초인 경우, 무음 구간의 최대 길이가 1초여야 하는건데, 파일에 잡음이 있는 경우, 2초 또는 3초가 될 수도 있다.

#### trimBeginning - 앞 무음 제거하기

```bash
ffmpeg -i input.mp3 -af \
 "silenceremove=start_periods=1:start_duration=0.1:start_threshold=-50dB" \
 out.mp3
```

간단히 옵션을 설명하면

- `start_periods=1`은 앞부분에서 trim을 하겠다는 의미이고
- `start_duration=0.1`은 0.1초 만큼의 소리가 있어야 소리가 있는 것으로 판단한다
- `start_threshold=0.01`는 1%정도 크기의 소리는 무음으로 간주하겠다

#### trimTrailing - 뒤 무음만 제거하기

stop_periods에 1을 설정하면 된다고 하는데, 안된다. 잡음 때문에 그런 것인지.. 지금 당장은 필요하지 않아서.. 나중에 다시 시도해보자.

```bash
ffmpeg -y -i input.mp3 -af \
    "silenceremove=stop_periods=1:stop_duration=0.1:stop_threshold=-50dB" \
out.mp3
```

#### trimAll - 파일 전체영역에서 일정 소리이상이 되면 trim하기

stop_periods에 음수를 설정하면 된다. 이것저것 시도해보았다. 영어공부용 사운드 파일 만드는 작업인데.. 영어 공부용에서는 사용하면 안되겠다. 귀찮아도 audacity를 사용해야 겠다.

```bash

# 됨
ffmpeg -y -i input.mp3 -af \
 "silenceremove=stop_periods=-1:stop_duration=0.5:stop_silence=0.1:stop_threshold=-50dB" \
out.mp3

ffmpeg -y -i frozen_005.mp3 -af \
 "silenceremove=stop_periods=-1:stop_duration=0:stop_silence=1:stop_threshold=-50dB" \
out.mp3


ffmpeg -y -i D001.mp3 -af \
 "silenceremove=stop_periods=-1:stop_duration=0.3:stop_silence=0.1:stop_threshold=-50dB" \
out.mp3

ffmpeg -y -i D001.mp3 -af  "silenceremove=stop_periods=-1:stop_duration=0.1:stop_silence=1:stop_threshold=-50dB" out.mp3


ffmpeg -y -i D001.mp3 -af  \
"silenceremove=stop_periods=-1:stop_duration=0.1:stop_silence=1:stop_threshold=-50dB" \
 out.mp3


```

#### silenceremove 필터 옵션 설명

- `start_periods`
  오디오의 시작 부분에서 trim을 해야할지 결정하는데 사용한다.
  이 값이 0이면 처음 부분에서 무음을 제거하지 않는다.
  앞 부분을 trim할때 보통 1을 주면 된다.(우리가 원하는 것은 보통 1이다)
  1보다 큰 값인 경우, 예를 들어 20인 경우는 20개의 소리를 감지할 때까지 trim된다.
  즉, 19개의 무음이 아닌 부분이 제거된다.
  start_periods의 의미는 무음이 아닌 걸 몇 개 발견할 때까지 trim할 것인가를 의미한다.
  (아.. 이거 이해하는데 시간 엄청 오래 걸렸다)

- `start_duration`
  trim 구간을 정하기 위해, 소리가 존재하는 부분의 경계선을 찾게 되는데
  소리가 존재하는 부분의 길이가 n이상이 되어야 존재하는 것으로 간주한다.
  기본값은 0이다.
  지속 시간을 늘리면 노이즈 버스트를 무음으로 처리하고 다듬을 수 있다.
  `bursts of noises`는 내가 생각하기에, 아주 짧게 잡음이 포함된것들을 의미하는 것 같다.
  그런 노이즈를 무음으로 간주하는 옵션이 필요한 경우도 있을 것 같다.

- `start_threshold`
  이것은 어떤 샘플 값이 무음으로 처리되어야 하는지 나타낸다.
  디지털 오디오의 경우 값이 0 일 수 있지만 아날로그에서 녹음 된 오디오의 경우 배경 노이즈를 고려하여 값을 늘리는 것이 좋습니다. dB (지정된 값에 "dB"가 추가 된 경우) 또는 진폭 비율로 지정할 수 있습니다. 기본값은 0입니다.

- `start_silence`
  Specify max duration of silence at beginning that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence.
  trim을 하는데, 완전히 없애지 말고, 무음을 약간 남겨두는 용도이다.
  즉, 이 값을 0.3(300ms)으로 하면 무음의 최대 길이가 300ms로 바뀌는 개념이다.

- `start_mode`
  Specify mode of detection of silence end in start of multi-channel audio. Can be any or all. Default is any. With any, any sample that is detected as non-silence will cause stopped trimming of silence. With all, only if all channels are detected as non-silence will cause stopped trimming of silence.

- `stop_periods`
  Set the count for trimming silence from the end of audio. To remove silence from the middle of a file, specify a stop_periods that is negative. This value is then treated as a positive value and is used to indicate the effect should restart processing as specified by start_periods, making it suitable for removing periods of silence in the middle of the audio. Default value is 0.

- `stop_duration`
  Specify a duration of silence that must exist before audio is not copied any more. By specifying a higher duration, silence that is wanted can be left in the audio. Default value is 0.

- `stop_threshold`
  This is the same as start_threshold but for trimming silence from the end of audio. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is 0.

- `stop_silence`
  Specify max duration of silence at end that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence.

- `stop_mode`
  Specify mode of detection of silence start in end of multi-channel audio. Can be any or all. Default is any. With any, any sample that is detected as non-silence will cause stopped trimming of silence. With all, only if all channels are detected as non-silence will cause stopped trimming of silence.

- `detection`
  Set how is silence detected. Can be rms or peak. Second is faster and works better with digital silence which is exactly 0. Default value is rms.

- `window`
  Set duration in number of seconds used to calculate size of window in number of samples for detecting silence. Default value is 0.02. Allowed range is from 0 to 10.
