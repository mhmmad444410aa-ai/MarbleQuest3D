"""Install the official Godot Gradle export template and integrate Petal Ads."""
from pathlib import Path
import os, zipfile, shutil, sys
root = Path("android")
dest = root / "build"
template = Path(sys.argv[1])
assert template.is_file(), template
dest.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(template) as z:
    z.extractall(dest)
(root / ".build_version").write_text("4.6.3.stable\n")
(dest / ".gdignore").write_text("")
gradle = dest / "build.gradle"
manifest = dest / "src/main/AndroidManifest.xml"
assert gradle.is_file() and manifest.is_file(), "Unexpected Godot template layout"
s = gradle.read_text()
assert "allprojects {" in s and "dependencies {" in s
s = s.replace("allprojects {\n    repositories {", 'allprojects {\n    repositories {\n        maven { url "https://developer.huawei.com/repo/" }', 1)
s = s.replace("dependencies {", "dependencies {\n    implementation 'com.huawei.hms:ads-prime:3.4.91.300'\n    implementation 'com.huawei.hms:ads-consent:3.4.91.300'", 1)
gradle.write_text(s)
s = manifest.read_text()
assert "</application>" in s and "<supports-screens" in s
s = s.replace("<supports-screens", '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" tools:node="remove" />\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" tools:node="remove" />\n    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" tools:node="remove" />\n    <supports-screens', 1)
s = s.replace("</application>", '<meta-data android:name="org.godotengine.plugin.v2.MarbleAds" android:value="com.mhmmad.marblequest3d.ads.MarbleAds" />\n    </application>', 1)
manifest.write_text(s)
target = dest / "src/main/java/com/mhmmad/marblequest3d/ads/MarbleAds.java"
target.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile("tools/android/MarbleAds.java", target)
(dest / "gradlew").chmod(0o755)
print("Petal Ads Gradle template prepared.")
