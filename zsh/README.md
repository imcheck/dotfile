# Zsh

## Dependencies

`.zshrc`에서 사용하는 패키지들입니다. 먼저 설치해야 합니다.

```bash
sudo apt install -y fzf zsh-syntax-highlighting zsh-autosuggestions
git clone --recurse-submodules https://github.com/olets/zsh-abbr /usr/share/zsh-abbr
```

| 패키지 | 설치 방법 | 용도 |
|--------|-----------|------|
| `fzf` | apt | 퍼지 파인더 (Ctrl+R: 히스토리, Ctrl+T: 파일, Alt+C: 디렉토리) |
| `zsh-syntax-highlighting` | apt | 명령어 구문 강조 |
| `zsh-autosuggestions` | apt | 히스토리 기반 명령어 제안 (→ 키로 적용) |
| `zsh-abbr` | git clone | 명령어 축약어 (abbreviations) |

`kube-ps1`은 선택 패키지입니다. `bash setup.sh zsh`에서는 자동으로 설치하지 않으며,
이미 설치되어 있으면 프롬프트에 Kubernetes 컨텍스트/네임스페이스를 표시합니다.
설치되어 있지 않아도 설정과 셸 실행은 정상적으로 진행됩니다.
