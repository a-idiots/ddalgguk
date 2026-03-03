/**
 * 딸꾹 랭킹 히스토리 백필 스크립트
 *
 * 처리 범위:
 *   - 주간: 2026_W01 (12/29~1/4) ~ 2026_W09 (2/23~3/1)
 *   - 월간: 2026_01, 2026_02, 2026_03
 *
 * 저장 경로:
 *   rankings/{uid}/weekly/{weekKey}  → { amount: double (ml) }
 *   rankings/{uid}/monthly/{monthKey} → { amount: double (ml) }
 *
 * 구분:
 *   - 해당 기간에 음주 기록이 하나라도 있으면 문서 저장 (amount가 0이어도 저장)
 *   - 해당 기간에 음주 기록이 없으면 문서 미생성 → UI에서 "-" 표시
 *
 * 실행:
 *   npm install
 *   node index.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// ─── 대상 기간 ──────────────────────────────────────────────────────────────

// 조회 시작: 2026_W01의 첫날 (2025-12-29 UTC)
// 조회 종료: 2026-03-08 (2026_W10 마지막날, 포함)
const RANGE_START = new Date(Date.UTC(2025, 11, 29)); // 2025-12-29
const RANGE_END   = new Date(Date.UTC(2026,  2,  8)); // 2026-03-08 (inclusive)

const TARGET_WEEK_KEYS  = [
  '2026_W01', '2026_W02', '2026_W03', '2026_W04', '2026_W05',
  '2026_W06', '2026_W07', '2026_W08', '2026_W09', '2026_W10',
];
const TARGET_MONTH_KEYS = ['2026_01', '2026_02', '2026_03'];

const TARGET_WEEK_SET  = new Set(TARGET_WEEK_KEYS);
const TARGET_MONTH_SET = new Set(TARGET_MONTH_KEYS);

// ─── ISO 8601 주차 키 계산 ───────────────────────────────────────────────────
// Dart의 _currentWeekKey() 와 동일한 로직

function getWeekKey(date) {
  const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));

  // 이번 주 월요일 (weekday: 0=일 → 7로 보정)
  const dayOfWeek = d.getUTCDay() || 7;
  const monday = new Date(d);
  monday.setUTCDate(d.getUTCDate() - (dayOfWeek - 1));

  // 이번 주 목요일 → ISO 연도 결정
  const thursday = new Date(monday);
  thursday.setUTCDate(monday.getUTCDate() + 3);

  const isoYear = thursday.getUTCFullYear();

  // 해당 ISO 연도의 첫 번째 ISO 월요일 (1월 4일이 항상 1주차에 포함)
  const jan4 = new Date(Date.UTC(isoYear, 0, 4));
  const jan4DayOfWeek = jan4.getUTCDay() || 7;
  const firstIsoMonday = new Date(jan4);
  firstIsoMonday.setUTCDate(jan4.getUTCDate() - (jan4DayOfWeek - 1));

  const weekNum =
    Math.floor((monday - firstIsoMonday) / (7 * 24 * 60 * 60 * 1000)) + 1;

  return `${isoYear}_W${String(weekNum).padStart(2, '0')}`;
}

// ─── 월 키 계산 ───────────────────────────────────────────────────────────────

function getMonthKey(date) {
  return `${date.getUTCFullYear()}_${String(date.getUTCMonth() + 1).padStart(2, '0')}`;
}

// ─── 날짜 파싱 (Firestore Timestamp 또는 String 대응) ─────────────────────────

function parseDate(raw) {
  if (!raw) return null;
  if (typeof raw.toDate === 'function') return raw.toDate(); // Firestore Timestamp
  if (typeof raw === 'string') return new Date(raw + 'T00:00:00Z');
  return null;
}

// ─── 메인 ────────────────────────────────────────────────────────────────────

async function main() {
  console.log('📋 사용자 목록 조회 중...');
  const usersSnapshot = await db.collection('users').get();
  const totalUsers = usersSnapshot.size;
  console.log(`👥 총 ${totalUsers}명 처리 시작\n`);

  let successCount = 0;
  let errorCount   = 0;

  for (const userDoc of usersSnapshot.docs) {
    const uid  = userDoc.id;
    const name = userDoc.data().name || uid;

    try {
      // 해당 기간 내 음주 기록만 조회 (서버 필터로 읽기 비용 절감)
      const recordsSnapshot = await db
        .collection(`users/${uid}/drinkingRecords`)
        .where('date', '>=', admin.firestore.Timestamp.fromDate(RANGE_START))
        .where('date', '<=', admin.firestore.Timestamp.fromDate(RANGE_END))
        .get();

      // 주차/월별 집계
      // Map<key, { hasRecords: boolean, amount: number }>
      const weeklyMap  = {};
      const monthlyMap = {};

      for (const recordDoc of recordsSnapshot.docs) {
        const data = recordDoc.data();
        const date = parseDate(data.date);
        if (!date) continue;

        const weekKey  = getWeekKey(date);
        const monthKey = getMonthKey(date);

        // 순수 알코올량 (g) 계산: 음주량(ml) × 도수(%) / 100 × 0.8
        const drinkAmounts = Array.isArray(data.drinkAmount) ? data.drinkAmount : [];
        let alcoholG = 0;
        for (const drink of drinkAmounts) {
          alcoholG += (drink.amount || 0) * (drink.alcoholContent || 0) / 100 * 0.8;
        }

        // 주차 집계 (대상 범위 내만)
        if (TARGET_WEEK_SET.has(weekKey)) {
          if (!weeklyMap[weekKey]) {
            weeklyMap[weekKey] = { hasRecords: false, amount: 0 };
          }
          weeklyMap[weekKey].hasRecords = true;
          weeklyMap[weekKey].amount    += alcoholG;
        }

        // 월별 집계 (대상 범위 내만)
        if (TARGET_MONTH_SET.has(monthKey)) {
          if (!monthlyMap[monthKey]) {
            monthlyMap[monthKey] = { hasRecords: false, amount: 0 };
          }
          monthlyMap[monthKey].hasRecords = true;
          monthlyMap[monthKey].amount    += alcoholG;
        }
      }

      // Firestore 배치 쓰기
      const batch      = db.batch();
      let   batchCount = 0;

      for (const weekKey of TARGET_WEEK_KEYS) {
        const entry = weeklyMap[weekKey];
        if (entry && entry.hasRecords) {
          // 기록 있음 → 저장 (amount가 0이어도 저장 → UI에서 "0g" 표시)
          // periodKey, uid 필드 포함 → 컬렉션 그룹 쿼리(등수 계산) 지원
          const ref = db.doc(`rankings/${uid}/weekly/${weekKey}`);
          batch.set(ref, { amount: entry.amount, periodKey: weekKey, uid });
          batchCount++;
        }
        // 기록 없음 → 문서 미생성 → UI에서 "-" 표시
      }

      for (const monthKey of TARGET_MONTH_KEYS) {
        const entry = monthlyMap[monthKey];
        if (entry && entry.hasRecords) {
          const ref = db.doc(`rankings/${uid}/monthly/${monthKey}`);
          batch.set(ref, { amount: entry.amount, periodKey: monthKey, uid });
          batchCount++;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

      successCount++;

      const weekWritten  = Object.values(weeklyMap).filter(e => e.hasRecords).length;
      const monthWritten = Object.values(monthlyMap).filter(e => e.hasRecords).length;

      console.log(
        `✅ [${successCount}/${totalUsers}] ${name.padEnd(16)} ` +
        `주차 ${weekWritten}/9  월 ${monthWritten}/3  (${batchCount}건 저장)`,
      );

    } catch (err) {
      errorCount++;
      console.error(`❌ [${uid}] ${name} 처리 실패:`, err.message);
    }
  }

  console.log(`\n🎉 완료!  성공: ${successCount}명  오류: ${errorCount}명`);
  process.exit(0);
}

main().catch((err) => {
  console.error('스크립트 실패:', err);
  process.exit(1);
});
