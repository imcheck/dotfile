# Global Instructions

## Tool preferences

- 웹 문서 수집이 필요하면 가능한 경우 기본 웹 fetch 계열 도구보다 scrapling의 `fetch`를 우선 사용할 것. `fetch`가 실패하면 `stealthy_fetch`를 사용할 것.
- scrapling 사용 시 `extraction_type`은 `"text"`를 기본으로 할 것.
- 본문이 너무 길면 `css_selector`로 본문 영역만 추출할 것. `article`, `main`, `[role="main"]` 순으로 우선 시도할 것.
