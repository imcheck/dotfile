# Zsh

## Dependencies

`.zshrc`에서 사용하는 패키지들입니다. 먼저 설치해야 합니다.

```bash
sudo apt install -y fzf zsh-syntax-highlighting
git clone --recurse-submodules https://github.com/olets/zsh-abbr /usr/share/zsh-abbr
```

| 패키지 | 설치 방법 | 용도 |
|--------|-----------|------|
| `fzf` | apt | 퍼지 파인더 (Ctrl+R: 히스토리, Ctrl+T: 파일, Alt+C: 디렉토리) |
| `zsh-syntax-highlighting` | apt | 명령어 구문 강조 |
| `zsh-abbr` | git clone | 명령어 축약어 (abbreviations) |
