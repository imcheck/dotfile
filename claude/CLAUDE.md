# Global Instructions

## Tool preferences

- WebFetch 대신 scrapling의 `fetch` 도구를 사용할 것. fetch가 실패하면 `stealthy_fetch`를 사용할 것.
- scrapling 사용 시 extraction_type은 "text"를 기본으로 할 것
- 토큰 초과 시 css_selector로 본문 영역만 추출 (article, main, [role="main"] 등 시도)
