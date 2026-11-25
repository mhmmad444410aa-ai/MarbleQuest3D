# Store release candidate 1.7.1
This workflow is manually triggered and fails closed without all four signing secrets or the accessible privacy page. It never generates a temporary key. Use an existing production keystore if one was previously used for com.mhmmad.marblequest3d. Otherwise use a newly generated permanent key kept offline. Do not commit credentials.

1. In Settings > Secrets and variables > Actions add ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD.
2. In Settings > Pages choose Deploy from a branch, main, /docs. Verify https://mhmmad444410aa-ai.github.io/MarbleQuest3D/.
3. Actions > Store Release APK (stable signing) > Run workflow. Check 24 course tests, package ID, signature, privacy and artifact. The APK is a store candidate, not a store acceptance guarantee.
4. Install and test on Android devices, review screenshots and store metadata. Current edition is offline and contains no advertising or analytics. Huawei Ads requires a separate integration and updated privacy/consent before distribution.
