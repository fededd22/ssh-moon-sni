# Moon SSH — نفق SSH عبر TLS بتمويه SNI (SNI-only) + لوحة تحكم تلجرام

مشروع **Node.js / TypeScript** يشغّل خادم نفق **SSH عبر TLS بتمويه SNI فقط** (بدون Payload)،
مع لوحة تحكم عبر **بوت تلجرام**، جاهز للنشر على **Railway** أو التشغيل محليًا عبر Docker.

> ⚠️ **تنبيه:** هذا المشروع نفق SSH/VPN. استخدمه وفق القوانين المعمول بها في بلدك وشروط استخدام مزوّد الاستضافة.

---

## 🧱 بنية المشروع

| الملف | الوصف |
|-------|-------|
| `server.ts` | الخادم الرئيسي (TypeScript) — ثلاثة مستمعين: HTTP + TLS(SNI) + SSH مضمّن |
| `package.json` | الاعتماديات وسكربتات البناء (`build` عبر esbuild → `dist/server.cjs`) |
| `tsconfig.json` | إعداد TypeScript |
| `Dockerfile` | بناء متعدّد المراحل (deps → build → prod-deps → runtime) مع `openssl` |
| `docker-entrypoint.sh` | نقطة الدخول: إنشاء مجلد البيانات والتحقق من `openssl` |
| `railway.json` | إعداد النشر على Railway (بناء عبر Dockerfile) |
| `.dockerignore` | استثناء `node_modules` و`dist` و`.git` و`.env` |
| `.env.example` | نموذج متغيّرات البيئة |
| `docker-compose.yml` | تشغيل محلي عبر Docker Compose |
| `CHANGES.md` | سجلّ التغييرات |
| `metadata.json` | بيانات وصفية للمشروع |

### المستمعون الثلاثة

| المستمع | المنفذ | الوظيفة |
|---------|--------|---------|
| HTTP | `PORT` (افتراضي 8080) | صفحة الإعداد، `/health`، `/config`، ويب هوك تلجرام |
| TLS | `TLS_PORT` (افتراضي 8443) | مستمع SNI العام — يقبل أي SNI ويجسر التدفق إلى SSH |
| SSH | `127.0.0.1:10093` | خادم SSH مضمّن داخل Node (لا حاجة لـ dropbear) |

---

## ⚙️ متغيّرات البيئة

| المتغيّر | القيمة المقترحة | الوصف |
|----------|-----------------|-------|
| `PORT` | `8080` | منفذ HTTP (يضبطه Railway تلقائيًا عادةً) |
| `TLS_PORT` | `8443` | منفذ مستمع SNI الداخلي |
| `PUBLIC_PORT` | *(منفذ TCP Proxy)* | **مهم:** المنفذ العام المُعلن للعملاء (منفذ TCP Proxy على Railway) |
| `SNI_HOST` | `youtube.com` | اسم التمويه (SNI camouflage) |
| `DATA_DIR` | `/app/data` | مجلد ملفات الإعداد والتوكنات |
| `SSH_USERNAME` | `moon` | مستخدم النفق |
| `SSH_PASSWORD` | *(غيّرها!)* | كلمة مرور النفق |
| `APP_URL` | *(فارغ)* | النطاق العام (يُكتشف تلقائيًا من الطلبات) |
| `TELEGRAM_BOT_TOKEN` | *(اختياري)* | توكن بوت تلجرام للتحكم |
| `TELEGRAM_ADMIN_CHAT_ID` | *(اختياري)* | معرّف محادثة المدير |

> 🔴 **مهم:** غيّر `SSH_PASSWORD` من القيمة الافتراضية إلى كلمة قوية.

---

## 🚀 النشر على Railway

### الطريقة ١ — عبر الواجهة (موصى بها)
1. أنشئ مشروعًا جديدًا على Railway واربطه بمستودع GitHub.
2. أضف خدمة، ثم **Settings → Networking → TCP Proxy** (لتوليد منفذ عام للنفق).
3. اضبط متغيّرات البيئة أعلاه، مع `PUBLIC_PORT` = منفذ الـ TCP Proxy.
4. Railway سيبني عبر `Dockerfile` تلقائيًا (بفضل `railway.json`).

### الطريقة ٢ — عبر Railway CLI
```bash
npm i -g @railway/cli
railway login --token <RAILWAY_TOKEN>
railway init
railway up
railway variables --set "PUBLIC_PORT=37659" --set "SSH_PASSWORD=كلمة_قوية"
railway domain          # للحصول على النطاق العام
```

### الطريقة ٣ — عبر GraphQL API مباشرة
```bash
curl -s https://backboard.railway.app/graphql/v2 \
  -H "Authorization: Bearer <RAILWAY_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"query":"query { me { name } }"}'
```

---

## 💻 التشغيل محليًا

### عبر Docker
```bash
docker build -t moon-ssh .
docker run -p 8080:8080 -p 8443:8443 \
  -e SSH_USERNAME=moon -e SSH_PASSWORD=MoonSsh@2026x \
  -e SNI_HOST=youtube.com -e PUBLIC_PORT=8443 \
  moon-ssh
```

### عبر Docker Compose
```bash
docker compose up --build
```

### مباشرة (تطوير)
```bash
npm install
npm run dev          # تشغيل مباشر عبر tsx
# أو
npm run build && npm start
```

### التحقق
```bash
curl http://localhost:8080/health
curl http://localhost:8080/config
```

---

## 🔌 كيف يستخدمه العميل

الإعداد المُعلن من الخادم عبر `GET /config`:

```
Host:     <نطاقك>.up.railway.app
Port:     <PUBLIC_PORT>
SNI:      youtube.com
Username: moon
Password: <كلمة المرور>
TLS:      enabled (SNI-only, no payload)
```

**رابط الاستيراد المباشر** (`shareLink`):
```
moon-sni://<host>:<port>?host=<host>&port=<port>&sni=youtube.com&user=moon&pass=<pass>&mode=sni
```

---

## 🛠️ الإصلاحات المُطبَّقة على هذه النسخة

1. **إعادة إنشاء الملفات الناقصة** التي كان `Dockerfile` يستدعيها وهي غير موجودة في المستودع:
   `package.json` · `tsconfig.json` · `docker-entrypoint.sh`.
2. **إضافة `openssl`** إلى صورة التشغيل (كان غائبًا عن `node:22-slim`، ما كان سيعطّل مستمع TLS).
3. **إضافة `PUBLIC_PORT`** في `server.ts` — كان المنفذ `443` مكتوبًا بشكل صارم، فيولّد إعدادات خاطئة على Railway (منفذ TCP Proxy عشوائي).
4. **إضافة `railway.json`** و `.dockerignore`.

---

## 📋 الخطوات المتبقية على المستخدم

1. 🔴 غيّر `SSH_PASSWORD` إلى كلمة قوية.
2. 🟡 فعّل بوت تلجرام بإضافة `TELEGRAM_BOT_TOKEN` و `TELEGRAM_ADMIN_CHAT_ID` (اختياري).
3. 🟢 شهادة TLS ذاتية التوقيع طبيعية لوضع SNI — اضبط العميل على `insecure: true`.
4. 💡 لو حذفت الـ TCP Proxy وأعدت إنشاءه، سيتغيّر رقم المنفذ — حدّث `PUBLIC_PORT` وأعد النشر.
