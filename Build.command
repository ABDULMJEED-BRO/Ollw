#!/bin/bash
set -e

echo "=== بدء تجميع واستخراج تطبيق الـ iOS يدويًا ==="

# 1. إنشاء مجلدات الحزمة للتطبيق
mkdir -p build/Payload/App.app

# 2. تحديد مسار الـ SDK الخاص بالآيفون في سيرفر الماك
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
echo "SDK Path: $SDK_PATH"

# 3. البحث عن كل ملفات الـ Swift المرفوعة وتجهيزها
SWIFT_FILES=$(find . -name "*.swift")
echo "Files to compile: $SWIFT_FILES"

# 4. تجميع ملفات السويفت بالكامل وتحويلها لملف تنفيذي
swiftc -sdk "$SDK_PATH" \
       -target arm64-apple-ios15.0 \
       -o build/Payload/App.app/App \
       $SWIFT_FILES

# 5. البحث عن ملف Info.plist الأساسي ونسخه للحزمة
PLIST_FILE=$(find . -name "Info.plist" | head -n 1)
if [ -f "$PLIST_FILE" ]; then
    cp "$PLIST_FILE" build/Payload/App.app/Info.plist
else
    echo '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>App</string><key>CFBundleIdentifier</key><string>com.psych.app</string><key>CFBundleName</key><string>PsychApp</string><key>CFBundleShortVersionString</key><string>1.0</string><key>CFBundleVersion</key><string>1</string></dict></plist>' > build/Payload/App.app/Info.plist
fi

# 6. تجميع ملفات الواجهة مع إضافة أعلام تحديد الهدف (أو تجاوزها في حال عدم دعم البيئة السحابية لها)
STORYBOARD=$(find . -name "LaunchScreen.storyboard" | head -n 1)
if [ -f "$STORYBOARD" ]; then
    echo "Compiling Storyboard..."
    ibtool --sdk "$SDK_PATH" --target-device iphone --compile build/Payload/App.app/LaunchScreen.storyboardc "$STORYBOARD" || echo "تنبيه: تم تخطي تجميع الـ Storyboard لتفادي قيود البيئة السحابية واكمال بناء الحزمة"
fi

# 7. ضغط المجلد النهائي بصيغة IPA
cd build
zip -r ../App.ipa Payload
cd ..

echo "=== تم بناء التطبيق وتوليد ملف App.ipa بنجاح! ==="
