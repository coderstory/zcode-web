#!/usr/bin/env bash
# ZCode Web 一键构建（本地 Termux/DSH 与 GitHub Actions CI 通用）
# 环境变量可覆盖：BT(build-tools 目录) AJ(android.jar) KS(keystore) KS_PASS ALIAS KEY_PASS
set -euo pipefail

SDK="${ANDROID_HOME:-/storage/emulated/0/project/HonorHook/tools/android-sdk}"
# build-tools：取 SDK 下版本最高的一份
BT="${BT:-}"
for d in "$SDK"/build-tools/*/; do [ -d "$d" ] && BT="$d"; done
BT="${BT%/}"
AJ="${AJ:-$(ls "$SDK"/platforms/android-*/android.jar 2>/dev/null | sort -V | tail -1)}"
[ -d "$BT" ] || { echo "ERROR: build-tools 未找到（SDK=$SDK）" >&2; exit 1; }
[ -f "$AJ" ] || { echo "ERROR: android.jar 未找到" >&2; exit 1; }

KS="${KS:-release.keystore}"
KS_PASS="${KS_PASS:-android}"
KEY_PASS="${KEY_PASS:-android}"
ALIAS="${ALIAS:-zcode}"
VERSION="${VERSION:-1.0}"

# aapt2/zipalign：优先 build-tools 内二进制（CI），回落 PATH（Termux 包）
AAPT2="$(command -v aapt2 || true)"
ZIPALIGN="$(command -v zipalign || true)"
[ -x "$BT/aapt2" ] && AAPT2="$BT/aapt2"
[ -x "$BT/zipalign" ] && ZIPALIGN="$BT/zipalign"
[ -n "$AAPT2" ] || { echo "ERROR: aapt2 未找到" >&2; exit 1; }
[ -n "$ZIPALIGN" ] || { echo "ERROR: zipalign 未找到" >&2; exit 1; }

cd "$(dirname "$0")"
rm -rf build && mkdir -p build/classes build/dex

# ZXing：本地 libs/ 优先，CI 现下载
ZX=libs/zxing-core.jar
if [ ! -f "$ZX" ]; then mkdir -p libs
  curl -sL -o "$ZX" https://repo1.maven.org/maven2/com/google/zxing/core/3.5.3/core-3.5.3.jar
fi

echo "== 1. aapt2 (compile res + link) =="
"$AAPT2" compile --dir res -o build/res.zip
"$AAPT2" link --manifest AndroidManifest.xml -I "$AJ" build/res.zip \
  --min-sdk-version 24 --target-sdk-version 34 --version-code 3 --version-name "$VERSION" \
  -o build/app.unsigned.apk

echo "== 2. javac =="
javac -source 8 -target 8 -bootclasspath "$AJ:$BT/core-lambda-stubs.jar" \
  -classpath "$ZX" \
  -d build/classes $(find src -name '*.java') 2>&1 | grep -v 'obsolete' || true

echo "== 3. R8 (混淆+收缩) =="
jar cf build/app-classes.jar -C build/classes .
java -cp "$BT/lib/d8.jar" com.android.tools.r8.R8 \
  --release --min-api 24 --lib "$AJ" \
  --classpath "$ZX" \
  --pg-conf r8-rules.pro \
  --pg-map-output build/dex/mapping.txt \
  --output build/dex build/app-classes.jar "$ZX"

echo "== 4. 打包 classes.dex =="
(cd build/dex && zip -q ../app.unsigned.apk classes.dex)

echo "== 5. zipalign =="
"$ZIPALIGN" -f 4 build/app.unsigned.apk build/app.aligned.apk

echo "== 6. keystore + sign =="
if [ ! -f "$KS" ]; then
  keytool -genkeypair -keystore "$KS" -storepass "$KS_PASS" -keypass "$KEY_PASS" \
    -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=ZCode Web,O=zcode,C=CN"
fi
java -jar "$BT/lib/apksigner.jar" sign --ks "$KS" \
  --ks-pass "pass:$KS_PASS" --key-pass "pass:$KEY_PASS" \
  --out ZCodeWeb.apk build/app.aligned.apk
java -jar "$BT/lib/apksigner.jar" verify ZCodeWeb.apk
echo "SIGN-OK: ZCodeWeb.apk ($(wc -c < ZCodeWeb.apk) bytes)"
