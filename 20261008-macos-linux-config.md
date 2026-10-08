# macOS와 Linux에서 공유 설정을 유지하고 Git 충돌 해결하기

> ExecPlan 형식의 실행 계획. 구현이 진행되면 이 문서도 갱신한다. 사용자가 구현과 Linux 서버 적용을 승인했다.

## Purpose / Big Picture

두 기기에서 같은 `main` 브랜치와 공통 설정을 사용한다. OS별 실행 방식은 설치 스크립트와 알림 스크립트가 판단하고, 개인 설정은 각 기기의 홈 디렉터리에 보관한다. 원격 설정을 받아도 Linux의 개인 Codex 설정이 유지되고, AI 설정 설치를 다시 실행할 수 있게 한다.

## Context and Orientation

- 현재 `HEAD`와 `origin/main`은 `bba13b0`이다. 충돌은 `ai/codex/config.toml`, `ai/setup.py` 두 파일에만 있다.
- 충돌 표시는 `Updated upstream` / `Stashed changes`이다. stash는 작업을 임시 저장한 Git 기록이다. `stash@{0}`은 `059584a`에서 만든 변경이며 두 파일의 `codex_hooks`를 `hooks`로 바꾸고 구 키 제거 함수를 추가한다. 이후 pull로 최신 main이 들어온 기록과 함께 보면 stash 재적용 중 충돌한 것으로 판단된다.
- 최신 main의 `14aa437`은 저장소에서 관리하던 Codex 안전 훅을 삭제하고 터미널 알림을 추가했다. 최신 설치기는 이미 구 키와 삭제된 훅의 심볼릭 링크를 정리한다. 심볼릭 링크는 원본 파일을 가리키는 파일이다.
- `ai/setup.py`는 기존 사용자 설정에 저장소 설정을 병합한다. 현재 작업 파일에는 충돌 표시 외에 `remove_scalar` 함수도 두 번 정의되어 있다.
- `ai/codex/config.toml`은 공통 터미널 알림과 Scrapling MCP 실행 설정이다. MCP는 AI 도구를 연결하는 프로토콜이다. `[features].hooks`는 OS 선택 옵션이 아니라 훅 기능 옵션이며, `codex_hooks`는 구 이름이다. 공식 문서: https://learn.chatgpt.com/docs/config-file/config-reference
- `ai/claude/settings.json`과 `ai/hooks/notify.sh`는 Claude 알림을 설치한다. 알림 스크립트는 현재 macOS 명령만 사용한다.
- `setup.sh`는 Homebrew/apt 및 Ghostty의 macOS 전용 설치를 이미 구분한다. `zsh/.zshrc`는 여러 플러그인 경로를 탐색하고 마지막에 `~/zsh/*.zsh`를 읽는다.
- `ghostty/config`에는 `/Users/alex/.config/ghostty/portone`이 들어 있다. `portone`은 해당 기기의 회사 설정 파일이다.
- 현재 서버는 Linux aarch64, Python 3.11.2, Codex 0.161.0, tmux 3.3a, Neovim 0.11.6이다. `notify-send`는 없다.
- 실제 홈 디렉터리는 최신 설치 결과와 다르다. 공유 docs 링크가 없고, 삭제된 Claude/Codex 훅을 가리키는 깨진 링크가 있다. Codex에는 `features.hooks = true`가 있고 `[hooks]` 아래에는 `state` 항목이 있다. 이를 실행 이벤트 정의라고 단정하지 않는다. 설치된 Neovim `init.lua`는 일반 파일이다.

## Plan of Work

현재 충돌은 최신 main의 두 파일을 채택해 해결한다. stash의 키 이름 변경을 공통 설정에 다시 강제할 필요는 없다. 최신 병합기는 이미 로컬 `features.hooks`와 `[hooks]`를 보존하므로 기존 기기별 설정을 유지할 수 있다. 이후 구 키만 있는 사용자를 위한 값 보존 마이그레이션을 보완한다.

공통 파일을 macOS/Linux 브랜치로 나누지 않는다. Claude 알림의 전송 방법을 OS별로 선택하고, Ghostty의 특정 사용자 절대 경로를 선택적 상대 경로로 바꾼다. Zsh의 개인 설정은 기존 `~/zsh/*.zsh` 방식을 계속 사용한다. 현재 Linux는 데스크톱 알림 프로그램이 없으므로 터미널 BEL을 기본 대안으로 사용한다. BEL은 터미널에 알림 신호를 보내는 제어 문자이며 실제 소리/표시는 터미널 설정에 따른다.

## Concrete Steps

### Step 1: 현재 충돌 해결

- **파일**: `ai/codex/config.toml`, `ai/setup.py`
- **변경**: 최신 main 내용을 채택한다. 두 파일에만 현재 stash가 변경을 남겼다는 것을 다시 확인하고 `git stash show -p 'stash@{0}'`으로 내용을 검토한다. 그 조건이 유지되면 `git restore --source=HEAD --staged --worktree -- ai/codex/config.toml ai/setup.py`를 실행한다. 이 명령은 두 파일의 작업 트리와 Git 인덱스를 HEAD로 맞추므로 충돌 표시도 해제된다. stash는 보존한다.
- **이유**: 최신 알림/구 훅 정리 로직을 유지하고 중복 함수와 문법 오류를 제거한다. 키 변경의 목적은 로컬 설정 보존과 다음 단계로 충족한다.

### Step 2: 기존 Codex 설정 보존 보완

- **파일**: `ai/setup.py`
- **변경**: `[features].codex_hooks`가 있고 `hooks`가 없으면 기존 boolean 값을 `hooks`로 옮긴 뒤 구 키를 제거한다. 둘 다 있으면 기존 `hooks` 값을 우선한다. 두 키가 모두 없으면 설치기가 `hooks = true`를 강제하지 않는다. 기존 `[hooks]`, 모델, 프로젝트 경로, 상태줄 및 저장소에서 관리하지 않는 MCP 설정을 보존한다.
- **이유**: 구 설정의 true/false 의도를 보존하면서 현재 이름으로 전환한다. 이 서버의 기존 `hooks = true`는 그대로 유지된다.

### Step 3: Claude 알림을 두 OS에서 처리

- **파일**: `ai/hooks/notify.sh`
- **변경**: `uname -s`로 분기한다. Darwin은 기존 terminal-notifier/osascript 경로를 유지한다. Linux는 `notify-send`와 그래픽 세션 환경이 있을 때 데스크톱 알림을 시도한다. 사용할 수 없거나 실패하면 쓰기 가능한 제어 터미널 `/dev/tty`에 BEL을 보낸다. 제어 터미널도 없으면 정상 종료한다. BEL을 훅의 JSON 출력용 stdout에 쓰지 않는다. Linux에서는 macOS 명령을 실행하지 않는다.
- **이유**: SSH 서버에서도 알림을 시도하고 설치되지 않은 macOS 프로그램을 호출하는 문제를 해결한다. SSH/tmux를 거쳐 사용자 단말에 표시되는지는 실제 세션에서 검증한다.

### Step 4: Ghostty 개인 경로 분리

- **파일**: `ghostty/config`, `ghostty/AGENTS.md`
- **변경**: 절대 사용자 경로를 `config-file = "?portone"`으로 바꾸고, 설치된 설정 파일 옆의 선택적 개인 파일이라는 설명을 맞춘다. macOS에서 기존 portone 내용이 실제로 읽히는지 확인한다. 특히 저장소 파일을 심볼릭 링크로 설치하므로 상대 경로가 어느 디렉터리에서 해석되는지 설치 상태에서 검증한다.
- **이유**: 사용자 이름이 달라도 공통 설정을 사용할 수 있게 한다. Ghostty 공식 문서는 포함 경로가 설정 파일 기준 상대 경로이고 `?`가 파일 미존재 오류를 생략한다고 설명한다: https://ghostty.org/docs/config/reference#config-file

### Step 5: 검증 후 각 기기에 AI 설정 적용

- **파일**: `ai/setup.py`, `ai/hooks/notify.sh`, `ai/AGENTS.md`
- **변경**: 아래 검증을 통과한 뒤 각 기기에서 `bash setup.sh ai`를 실행한다. 이 작업은 실제 홈 디렉터리 설정을 변경하므로 적용 전에 설정 사본을 보관한다. 공통 관리 항목/로컬 항목의 경계를 `ai/AGENTS.md`에 명시한다. Ghostty 변경은 macOS에서 `bash setup.sh ghostty`로 적용한다.
- **이유**: 현재 누락된 docs 링크, 깨진 구 훅 링크와 미설치 알림 설정을 최신 설치 로직으로 정리한다. Neovim 등 다른 도구의 재설치는 이 작업과 분리한다.

## Validation and Acceptance

정적 검증 명령:

```sh
python3 -c 'import ast,pathlib; ast.parse(pathlib.Path("ai/setup.py").read_text())'
python3 -c 'import pathlib,tomllib; tomllib.loads(pathlib.Path("ai/codex/config.toml").read_text())'
bash -n setup.sh
zsh -n zsh/.zshrc
sh -n ai/hooks/notify.sh
git diff --check
git status --short
```

회귀 테스트 명령은 `python3 -B -m unittest discover -s ai/tests -v`이다. 검증용 TOML 파싱 명령과 테스트는 Python 3.11의 `tomllib`를 사용한다. 설치기에 새 패키지 의존성을 추가하지 않는다. 실제 홈을 수정하지 않는 임시 디렉터리에서 다음을 검증한다.

- [x] 두 충돌 파일에 `UU`가 없고 Python/TOML 파싱이 성공한다.
- [x] Codex 병합을 두 번 실행해도 결과가 같고 기존 개인 설정이 유지된다.
- [x] 구 hooks 키만 있는 true/false, 새 키만 있는 경우, 두 키가 있는 경우, 두 키 모두 없는 경우에 의도한 값이 유지된다.
- [x] 가짜 명령을 사용하는 알림 검증에서 macOS 기존 경로와 Linux 대안 경로를 확인한다. 실제 데스크톱 알림이나 설치를 테스트에서 실행하지 않는다.
- [x] 설치 후 `~/.agents/docs/AGENTS.md`를 읽을 수 있고 저장소에서 관리하던 삭제된 훅의 깨진 링크가 사라진다.
- [ ] macOS의 portone 개인 설정이 로드되고 파일이 없는 환경에서도 Ghostty 설정 오류가 없다.
- [ ] Linux SSH/tmux와 macOS 터미널에서 실제 알림을 각각 확인한다. BEL만으로 클릭 가능한 macOS 알림과 같은 UX를 보장하지 않는다.

## Interfaces and Dependencies

Git, Python 3, POSIX sh, Bash, Zsh를 사용한다. 기존 Docker 기반 Scrapling 설정은 유지하고 컨테이너를 이번 검토에서 실행하지 않는다. macOS 알림은 기존 terminal-notifier/osascript를 사용한다. Linux notify-send는 선택 사항이며 SSH 서버에 데스크톱 구성요소를 새로 설치하지 않는다. 외부 SDK나 새 TOML 작성 라이브러리는 추가하지 않는다.

## Idempotence and Recovery

stash는 검증과 양쪽 기기 적용이 끝날 때까지 유지한다. 충돌 해결 명령은 명시한 두 파일만 복원한다. 구현 중 새 변경이 있으면 이 명령을 다시 실행하지 않는다. 홈 디렉터리 설정은 설치 전에 사본을 보관한다. 설치 실패 시 사본과 설치기가 만든 링크 백업으로 복구한다. 반복 설치에서 관리 항목이 중복되거나 개인 설정이 사라지지 않는지 확인한다.

## Progress

- [x] 2026-10-08 — Git 충돌, stash, 변경 이력, 관련 공통 설정과 서버 설치 상태 조사.
- [x] 2026-10-08 — 최신 main의 Codex 병합을 임시 파일에서 검증: 개인 설정 보존 및 반복 실행 결과 일치.
- [x] 2026-10-08 — Shell 문법 검사 통과. 현재 충돌 파일의 Python/TOML 파싱 실패 확인.
- [x] 2026-10-08 — Step 1: 최신 main으로 충돌 해결. stash 유지.
- [x] 2026-10-08 — Step 2: 구 키 값 보존 보완과 회귀 검증 완료.
- [x] 2026-10-08 — Step 3: OS별 Claude 알림 처리와 회귀 검증 완료. 가상 제어 터미널에 BEL이 출력됨을 확인.
- [x] 2026-10-08 — Step 4: Ghostty 개인 경로 분리 구현 및 공식 소스의 경로 처리 확인. macOS 실동작 검증은 해당 기기에서 수행.
- [x] 2026-10-08 — Step 5: 12개 회귀 테스트 및 문법 검사 통과 후 `bash setup.sh ai`로 Linux 서버 적용. 설치 후 개인 설정 보존과 구 링크 정리를 검증.
- [ ] macOS에서 변경 동기화 후 설치하고 실제 알림 및 portone 로드 확인.

## Surprises & Discoveries

단순 충돌 표시 제거만으로는 중복된 `remove_scalar` 정의가 남을 수 있다. 최신 main을 채택하면 함수는 하나만 남는다. 서버의 Codex 설정 파일은 저장소 파일의 심볼릭 링크가 아니라 독립 파일이어서 최신 main 채택만으로 로컬 hooks 설정이 삭제되지 않는다. `[hooks].state`의 존재를 실제 실행 훅의 존재와 혼동하지 않아야 한다.

Ghostty 공식 소스에서 기본 설정 경로를 `loadFile`에 전달하고 파일을 읽은 뒤 `expandPaths(dirname(path))`를 호출하는 것을 확인했다. 원본 심볼릭 링크 경로를 `realpath`로 치환하지 않으므로 기본 설정 경로 옆의 portone을 읽는 방식과 일치한다. 확인한 소스: https://github.com/ghostty-org/ghostty/blob/main/src/config/Config.zig 및 https://github.com/ghostty-org/ghostty/blob/main/src/config/file_load.zig . 이 서버에는 Ghostty가 없어 실제 macOS UI 검증은 수행하지 않았다.

설치 후 Scrapling의 개인 `tools` 하위 설정도 유지되는 것을 확인했다. 설치 검증에서 공유 설정 전체와의 동일성 대신 공유 command/args와 추가 개인 하위 설정의 보존을 각각 확인하도록 조정했고 회귀 테스트에도 해당 사례를 추가했다.

Zsh `ls --color=auto`는 구 macOS와의 호환성을 점검할 후보지만 현재 Apple 공식 소스는 해당 옵션을 지원한다. 따라서 이를 모든 macOS에서 깨지는 확정 오류로 취급하지 않는다. 구 버전까지 지원하려면 별도로 macOS의 `ls -alhG` / Linux의 `ls -alh --color=auto` 분기를 추가할 수 있다. Neovim의 `clipboard = "unnamed"`는 서버의 클립보드 제공 기능에 따른 실제 동작 확인이 필요하다. 두 항목은 현재 Git 충돌 원인이 아니다.

## Decision Log

| 날짜 | 결정 | 이유 |
|---|---|---|
| 2026-10-08 | 최신 main을 충돌 해결 기준으로 사용 | stash의 구 키 변경 목적을 보존하면서 최신 알림 및 훅 정리 로직을 유지할 수 있음 |
| 2026-10-08 | 공통 설정에 hooks 활성화를 강제하지 않음 | 현재 저장소는 Codex 실행 훅을 배포하지 않으며 기기별 설정을 보존하는 것이 적합함 |
| 2026-10-08 | OS별 브랜치를 만들지 않음 | 실제 OS 차이는 실행 방식에 있고 대부분의 설정은 이미 공유 가능함 |
| 2026-10-08 | 실제 설치와 기기별 실동작 검증은 구현 단계에 수행 | 사용자 요청은 현재 상태 조사와 해결 방향 제안이며 macOS 실행 환경은 이 서버에서 확인할 수 없음 |
| 2026-10-08 | 사용자 승인 후 Linux 서버 적용 | 구현과 설치가 승인되어 설정 백업 및 검증 후 홈 디렉터리에 적용함 |

## Outcomes

Git 충돌을 해결하고 stash를 보존했다. Codex 구 키 마이그레이션, Linux 알림 대안, 사용자 이름에 의존하지 않는 Ghostty include를 구현했다. 테스트 12개와 문법 검사를 통과했다. Linux 서버에 설치하고 기존 Codex/Claude 개인 설정 및 MCP 도구 설정 보존, docs 링크 설치, 구 훅 링크 제거를 확인했다.

설치 전 설정 파일 사본과 링크 상태 기록은 권한 0700인 `/tmp/dotfile-ai-before-uv_gmcu9`에 보관했다. 커밋과 푸시는 수행하지 않았다. macOS에서 변경사항 동기화 후 `bash setup.sh ai`, `bash setup.sh ghostty`를 실행하고 실제 알림 표시 및 회사 설정 로드를 확인해야 한다. 이 서버에서는 가상 제어 터미널로 BEL 전송을 검증했으며 사용자의 실제 SSH 클라이언트에서 소리/알림이 표시되는지는 해당 터미널 설정에 따른다.
