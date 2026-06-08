# ip-count-check

นับจำนวน request ต่อ IP จาก access log ของ **ทุกเว็บ** บนเซิร์ฟเวอร์ หา IP ที่ยิงผิดปกติ ด้วย Bash รันตรงจาก GitHub

จับ **bot ที่ crawl หนัก / ผู้โจมตี brute force / IP ที่ยิงรัวผิดปกติ** — แล้วจัดอันดับจากมากสุดไปน้อยสุด เซฟเป็นไฟล์ `.txt`

> รันอย่างเดียว 100% ไม่ลบ ไม่แก้ ไม่แตะไฟล์เว็บ — ปลอดภัย รันกี่ครั้งก็ได้

---

## ทำไมต้องมีตัวนี้

ตอน server load สูง เรามักไม่รู้ว่า "ใครยิงเข้ามาเยอะ" — เป็นลูกค้าจริง, SEO bot, หรือผู้โจมตี?

สคริปต์นี้รวม access log ของทุกเว็บมานับ IP ในครั้งเดียว ทำให้เห็นภาพชัดว่า:
- IP ตัวไหนยิงหนักสุด (ตัวที่ควรบล็อกก่อน)
- การโจมตีกระจายกี่ IP (บล็อกทีละตัวคุ้มไหม หรือต้องบล็อก User-Agent)
- มีใครยิง `wp-login.php` / `xmlrpc.php` รัวๆ (brute force) ไหม

ตัวนี้มองจาก **traffic จริง** (access log) จึงจับได้ทั้ง bot และผู้โจมตีที่ปลอมเป็นเบราว์เซอร์

---

## คุณสมบัติ

- นับ request ต่อ IP จากทุกเว็บรวมกัน (`*ssl_log`)
- เรียงจากยิงมากสุด → น้อยสุด อัตโนมัติ
- กรอง IPv4 / IPv6 ที่ถูกต้องเท่านั้น (ตัดขยะออก)
- รับ argument กรองเฉพาะ path ได้ เช่น `wp-login.php`, `xmlrpc.php`
- เซฟผลเป็นไฟล์ `.txt` พร้อม timestamp (รูปแบบ: `ip` + `จำนวนครั้ง`)
- แสดง TOP 20 + สรุปจำนวน IP และ request รวมทันทีบนหน้าจอ
- ไม่แตะไฟล์เว็บ ปลอดภัย รันซ้ำได้

---

## วิธีใช้

### รันตรงจาก GitHub (เร็วสุด)

```bash
curl -fsSL https://raw.githubusercontent.com/ufavisionseoteam19/ip-count-check/main/ip-count-check.sh | bash
```

### โหลดเก็บไว้ (แนะนำ — ใช้ argument กรองได้)

```bash
curl -fsSL https://raw.githubusercontent.com/ufavisionseoteam19/ip-count-check/main/ip-count-check.sh -o /root/ip-count-check.sh
chmod +x /root/ip-count-check.sh
/root/ip-count-check.sh
```

---

## ตัวอย่างการใช้งาน

```bash
# นับทุก request (หา IP ที่ยิงเยอะสุดทั้งหมด)
./ip-count-check.sh

# หาผู้โจมตี brute force (ยิง wp-login.php)
./ip-count-check.sh wp-login.php

# หาคนยิง xmlrpc.php
./ip-count-check.sh xmlrpc.php

# หาคนยิงหน้า admin
./ip-count-check.sh wp-admin
```

---

## ตัวอย่างผลลัพธ์

```
ip                                             จำนวนครั้ง
---------------------------------------------- ----------
38.190.100.105                                 15234
172.71.8.102                                   8921
34.26.238.102                                  5102
...
```

ไฟล์เซฟที่: `/root/ip_count_<โหมด>_<วันที่>_<เวลา>.txt`

---

## การตั้งค่า

แก้ตัวแปรด้านบนของสคริปต์ได้:

| ตัวแปร | ค่าเริ่มต้น | คำอธิบาย |
|---|---|---|
| `LOGDIR` | `/etc/apache2/logs/domlogs` | โฟลเดอร์ log (cPanel เก่าใช้ `/usr/local/apache/domlogs`) |
| `OUTDIR` | `/root` | โฟลเดอร์เก็บไฟล์ผลลัพธ์ |

---

## ข้อควรรู้

- ต้องรันด้วยสิทธิ์ที่อ่าน log ได้ (ปกติคือ `root`)
- IP ที่เห็นเป็น real IP ของผู้เข้าชม (กรณีตั้ง Cloudflare ส่ง real IP มาแล้ว)
- การบล็อก IP ช่วยลดโหลดได้ชั่วคราว แต่ bot/ผู้โจมตีเปลี่ยน IP ได้ — ทางแก้ถาวรคือบล็อกที่ **User-Agent (สำหรับ bot)** หรือ **rate limit wp-login (สำหรับ brute force)**

---

## License

ใช้ภายในทีมได้อย่างอิสระ
