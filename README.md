# SUDOKU — 스도쿠 연습장

로그인 없이 누구나 쓰는 리더보드와 대전·협동 모드가 들어간 버전입니다.
파일은 세 개입니다.

| 파일 | 용도 |
|---|---|
| `index.html` | 게임 전체 (한 파일) |
| `supabase.sql` | 리더보드 테이블과 접근 규칙 |
| `README.md` | 이 안내서 |

## 1. Supabase 준비 (약 5분)

1. https://supabase.com 에서 가입하고 **New project**를 만듭니다. 무료 요금제로 충분합니다.
2. 왼쪽 메뉴 **SQL Editor → New query**에 `supabase.sql` 내용을 모두 붙여 넣고 **Run**을 누릅니다.
3. **Project Settings → API**에서 두 값을 복사합니다.
   - Project URL (예: `https://abcdefgh.supabase.co`)
   - `anon` `public` 키
4. `index.html`을 텍스트 편집기로 열고 맨 위의 설정 칸에 넣습니다.

```js
window.SUDOKU_CONFIG = {
  supabaseUrl: 'https://abcdefgh.supabase.co',
  supabaseAnonKey: 'eyJhbGciOi...',
};
```

`anon` 키는 원래 공개용 키라서 웹페이지에 넣어도 됩니다. 데이터는 `supabase.sql`의 접근 규칙이 지킵니다.
(`service_role` 키는 절대 넣지 마세요.)

대전·협동 모드는 Supabase **Realtime**을 씁니다. 새 프로젝트에서는 기본으로 켜져 있습니다.
**Realtime → Settings**에 "Allow public access"(또는 "Private channels only") 설정이 보이면, 공개 채널을 허용하는 쪽으로 두세요.

## 2. 올리기 (하나만 고르세요)

- **Netlify Drop (가장 쉬움)**: https://app.netlify.com/drop 에 `index.html`이 든 폴더를 끌어다 놓으면 바로 주소가 생깁니다.
- **GitHub Pages**: 저장소에 `index.html`을 올리고 **Settings → Pages**에서 브랜치를 고르면 `https://아이디.github.io/저장소/` 주소가 생깁니다.
- **Vercel / Cloudflare Pages**: 폴더를 새 프로젝트로 올리면 됩니다. 빌드 설정은 필요 없습니다.

## 3. 확인하기

1. 올린 주소를 열고 문제를 하나 풀어 리더보드에 등록합니다(20초 이상 걸린 기록만 등록됩니다).
2. 다른 기기나 다른 브라우저에서 같은 주소를 열어 리더보드에 그 기록이 보이는지 확인합니다.
3. **같이 하기 → 방 만들기**를 누르고 **링크 복사**로 받은 주소를 다른 기기에서 엽니다. 방장이 **시작**을 누르면 3초 뒤 같이 시작합니다.

## 기능 요약

- **대전**: 같은 문제로 속도 경쟁. 상대의 진행률(채운 칸 비율)과 실수 수만 보이고, 먼저 완성한 사람이 이깁니다. 2명 이상이어야 시작할 수 있습니다.
- **협동**: 한 판을 함께 풉니다. 정답 숫자는 모두에게 실시간으로 공유되고 메모는 각자 따로입니다. 다른 사람이 고른 칸은 그 사람 색 테두리로 보입니다. 힌트는 방을 만들 때 0~10개 중에서 정하고 팀 전체가 나눠 씁니다.
- **방**: 최대 4명, 6자리 방 코드나 링크로 들어옵니다. 방장이 나가면 다음으로 먼저 들어온 사람이 방장이 됩니다.
- **리더보드**: 혼자 푼 기록만 올라갑니다. 같이 하기로 푼 판은 올라가지 않습니다.

## 서버 설정 전에는

`SUDOKU_CONFIG`가 비어 있으면 서버 없이 동작합니다.

- 리더보드는 그 기기 안에만 저장됩니다.
- 같이 하기는 **같은 브라우저의 다른 탭끼리만** 연결됩니다. 미리 시험해 볼 때 쓰세요.

## 알아 둘 점

- 게임 판정이 브라우저에서 이뤄지므로, 마음먹고 조작하면 가짜 기록을 보낼 수 있습니다.
  `supabase.sql`에 넣은 방어는 이름 길이 제한, 기록 계산식 검사, 20초 미만 거절, 같은 사람의 10초 안 연속 등록 거절까지입니다.
  가짜 기록이 보이면 Supabase **Table Editor → scores**에서 그 줄을 지우면 됩니다.
- Supabase 무료 요금제는 오래 쓰지 않으면 프로젝트가 일시 정지될 수 있습니다. 대시보드에서 다시 켜면 됩니다.
- Supabase 자바스크립트 라이브러리는 jsDelivr CDN에서 불러옵니다(`@supabase/supabase-js@2.45.4`).
