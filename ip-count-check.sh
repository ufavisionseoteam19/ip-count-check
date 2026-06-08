#!/bin/bash
# ============================================================
# ip-count-check.sh  (v3 - มี EXCLUDE กรองเครื่องมือลูกค้า)
# นับจำนวน request ต่อ IP จาก access log ทุกเว็บบนเซิร์ฟเวอร์
# เรียงจากมากสุด -> น้อยสุด -> เซฟเป็นไฟล์ .txt
#
# v3: เพิ่ม EXCLUDE = กรอง User-Agent ของเครื่องมือลูกค้า (เช่น VisionCheck)
#     ออกจากการนับ เพื่อให้เหลือแต่ bot/ผู้โจมตีจริง
# ============================================================

# ---------- ตั้งค่า ----------
LOGDIR="/etc/apache2/logs/domlogs"        # โฟลเดอร์ log (cPanel/LiteSpeed)
OUTDIR="/root"                            # โฟลเดอร์เก็บผลลัพธ์
FILTER="${1:-}"                           # คำกรอง เช่น wp-login.php (ว่าง = นับทุก request)
EXCLUDE="VisionCheck"                     # ไม่นับ request ของเครื่องมือลูกค้า (คั่นหลายตัวด้วย |)
                                          # เช่น "VisionCheck|MyMonitor|UptimeRobot"
# --------------------------------

if [ -z "$FILTER" ]; then TAG="all"; else TAG=$(echo "$FILTER" | tr -cd '[:alnum:]'); fi
OUT="$OUTDIR/ip_count_${TAG}.txt"
TMP=$(mktemp /tmp/ipcount.XXXXXX)
trap 'rm -f "$TMP"' EXIT

if [ ! -d "$LOGDIR" ]; then
  echo "ไม่พบโฟลเดอร์ log: $LOGDIR"
  echo "   cPanel เก่าลองใช้: /usr/local/apache/domlogs"
  exit 1
fi

shopt -s nullglob
FILES=("$LOGDIR"/*ssl_log)
TOTAL=${#FILES[@]}
if [ "$TOTAL" -eq 0 ]; then echo "ไม่พบไฟล์ log ใน $LOGDIR"; exit 1; fi

echo "============================================"
echo " IP Count Check (v3)"
echo "============================================"
if [ -z "$FILTER" ]; then echo " โหมด    : นับทุก request"
else echo " โหมด    : กรองเฉพาะ \"$FILTER\""; fi
if [ -n "$EXCLUDE" ]; then echo " ไม่นับ   : $EXCLUDE (เครื่องมือลูกค้า)"; fi
echo " Log dir : $LOGDIR"
echo " ไฟล์ log : $TOTAL ไฟล์"
echo "============================================"
echo ""

# ---------- สแกนทีละไฟล์ พร้อม progress ----------
i=0
for f in "${FILES[@]}"; do
  i=$((i+1))
  domain=$(basename "$f" | sed 's/-ssl_log$//; s/\.cp$//')

  # อ่านข้อมูล (กรอง FILTER ถ้ามี) -> ตัด EXCLUDE ออก -> ดึง IP
  {
    if [ -z "$FILTER" ]; then cat "$f"; else grep -h "$FILTER" "$f"; fi
  } 2>/dev/null \
  | { if [ -n "$EXCLUDE" ]; then grep -vE "$EXCLUDE"; else cat; fi; } \
  | awk '{print $1}' >> "$TMP"

  pct=$(( i * 100 / TOTAL )); filled=$(( pct / 5 ))
  bar=""; e=""
  j=0; while [ $j -lt $filled ]; do bar="$bar#"; j=$((j+1)); done
  j=0; while [ $j -lt $((20-filled)) ]; do e="$e."; j=$((j+1)); done
  printf "\r[%s%s] %3d%%  (%d/%d) %-30.30s" "$bar" "$e" "$pct" "$i" "$TOTAL" "$domain"
done

echo ""; echo ""
echo "กำลังจัดอันดับ IP (sort + นับ)..."

grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|^[0-9a-fA-F:]+:[0-9a-fA-F:]+$' "$TMP" \
| sort | uniq -c | sort -nr \
| awk 'BEGIN {
         printf "%-46s %s\n", "ip", "จำนวนครั้ง"
         printf "%-46s %s\n", "----------------------------------------------", "----------"
       }
       { printf "%-46s %s\n", $2, $1 }' > "$OUT"

TOTAL_IP=$(grep -cE '^[0-9]' "$OUT")
TOTAL_REQ=$(grep -cE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|^[0-9a-fA-F:]+:[0-9a-fA-F:]+$' "$TMP")

echo ""
echo "============================================"
echo " เสร็จแล้ว (ไม่รวมเครื่องมือลูกค้า: ${EXCLUDE:-ไม่มี})"
echo " ไฟล์ผลลัพธ์ : $OUT"
echo " จำนวน IP    : $TOTAL_IP"
echo " request รวม : $TOTAL_REQ"
echo "============================================"
echo ""
echo "===== TOP 20 IP ที่ยิงเยอะสุด (ไม่รวมลูกค้า) ====="
head -22 "$OUT"
echo ""
echo "ดูทั้งหมด: cat $OUT"
