@echo off

REM Build.bat - Psycho Hack IPA Builder (Windows Batch Version)
REM هذا الملف يقوم ببناء ملف IPA لتطبيق Psycho Hack.
REM يرجى ملاحظة أن أدوات بناء iOS (مثل swiftc) غير متوفرة بشكل افتراضي على ويندوز.
REM قد تحتاج إلى بيئة إعداد خاصة (مثل WSL مع أدوات macOS) أو استخدام نظام macOS للبناء الفعلي.

echo ╔══════════════════════════════════════════╗
echo ║     PSYCHO HACK v5.0 IPA BUILDER         ║
echo ╚══════════════════════════════════════════╝
echo.

set "PROJECT_DIR=%~dp0"
set "BUILD_DIR=%PROJECT_DIR%BuildTemp"
set "OUTPUT_IPA=%PROJECT_DIR%PsychoHack_v5.0.ipa"

REM التحقق من Xcode (هذه الخطوة خاصة بـ macOS ولا تعمل على Windows بشكل مباشر)
echo "⚠️ تنبيه: لا يمكن التحقق من Xcode على Windows بشكل مباشر. سأستمر في محاولة البناء."

REM تنظيف وبناء المجلدات
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
mkdir "%BUILD_DIR%\Payload\Psycho.app"
mkdir "%BUILD_DIR%\SwiftBuild"

echo 📦 [1/4] محاولة تجميع تطبيق Swift...

REM تجميع التطبيق (هذه الأوامر خاصة بـ macOS/iOS وستفشل على Windows العادي)
REM يجب أن تكون أدوات Swift و iOS SDK متاحة في PATH الخاص بك أو في بيئة خاصة.
REM إذا كنت تستخدم WSL (Windows Subsystem for Linux) مع أدوات macOS، فقد تحتاج إلى تعديل هذا الجزء.

REM تم وضع أمر swiftc هنا كما هو في السكريبت الأصلي، ولكنه سيفشل على Windows العادي.
REM إذا كنت تستخدم بيئة تدعم هذه الأوامر، فستحتاج إلى التأكد من أن المسارات صحيحة.
swiftc ^
    -arch arm64 ^
    -target arm64-apple-ios13.0 ^
    -sdk "$(xcrun --sdk iphoneos --show-sdk-path)" ^
    -O ^
    -emit-executable ^
    -o "%BUILD_DIR%\Payload\Psycho.app\Psycho" ^
    "%PROJECT_DIR%Source\PsychoApp.swift" ^
    "%PROJECT_DIR%Source\PsychoSidePanel.swift" ^
    "%PROJECT_DIR%Source\HackEngine.swift" ^
    "%PROJECT_DIR%Source\AntiBan.swift" ^
    "%PROJECT_DIR%Source\NeuralAI.swift" ^
    "%PROJECT_DIR%Source\OverlayRenderer.swift" ^
    "%PROJECT_DIR%Source\AutoPlayManager.swift" ^
    -framework UIKit ^
    -framework Foundation ^
    -framework CoreGraphics ^
    -framework QuartzCore

if %errorlevel% neq 0 (
    echo ❌ فشل التجميع! (هذا متوقع على Windows العادي بسبب عدم توفر أدوات iOS SDK و Swift Compiler).
    echo يرجى التأكد من أن بيئتك تدعم بناء تطبيقات iOS أو استخدام نظام macOS.
    goto :eof
)
echo ✅ تم التجميع (إذا لم يكن هناك خطأ أعلاه)

echo 📦 [2/4] نسخ الموارد...

REM نسخ Info.plist
copy "%PROJECT_DIR%Info.plist" "%BUILD_DIR%\Payload\Psycho.app\"

REM نسخ LaunchScreen
mkdir "%BUILD_DIR%\Payload\Psycho.app\Base.lproj"
copy "%PROJECT_DIR%Resources\LaunchScreen.storyboard" "%BUILD_DIR%\Payload\Psycho.app\Base.lproj\"

echo ✅ تم نسخ الموارد

echo 📦 [3/4] إنشاء IPA...

REM استخدام PowerShell لإنشاء ملف Zip (IPA)
REM يجب أن يكون PowerShell متاحًا في نظامك.
pushd "%BUILD_DIR%"
powershell -command "Add-Type -A 'System.IO.Compression.FileSystem'; [System.IO.Compression.ZipFile]::CreateFromDirectory('Payload', 'PsychoHack_v5.0.ipa');"
if %errorlevel% neq 0 (
    echo ❌ فشل إنشاء ملف IPA باستخدام PowerShell!
    popd
    goto :eof
)
popd

copy "%BUILD_DIR%\PsychoHack_v5.0.ipa" "%OUTPUT_IPA%"

echo ✅ تم إنشاء IPA

echo 📦 [4/4] تنظيف...
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"

echo.
echo ═════════════════════════════════════
echo ✅ PSYCHO HACK v5.0 READY!
echo 📱 %OUTPUT_IPA%
echo ═════════════════════════════════════
echo.
echo انقل الملف لهاتفك وثبته عبر Esign/Scarlet

pause
