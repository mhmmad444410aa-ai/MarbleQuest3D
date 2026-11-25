package com.mhmmad.marblequest3d.ads;

import android.app.Activity;
import android.os.SystemClock;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import com.huawei.hms.ads.AdListener;
import com.huawei.hms.ads.AdParam;
import com.huawei.hms.ads.BannerAdSize;
import com.huawei.hms.ads.ContentClassification;
import com.huawei.hms.ads.HwAds;
import com.huawei.hms.ads.InterstitialAd;
import com.huawei.hms.ads.NonPersonalizedAd;
import com.huawei.hms.ads.RequestOptions;
import com.huawei.hms.ads.VideoConfiguration;
import com.huawei.hms.ads.banner.BannerView;
import com.huawei.hms.ads.consent.bean.AdProvider;
import com.huawei.hms.ads.consent.constant.ConsentStatus;
import com.huawei.hms.ads.consent.inter.Consent;
import com.huawei.hms.ads.consent.inter.ConsentUpdateListener;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.UsedByGodot;
import java.util.List;

/** Android-only, fail-closed ads. All SDK calls occur on the UI thread. */
public final class MarbleAds extends GodotPlugin {
    private static final String TAG = "MarbleAds";
    private static final String BANNER_ID = "n7ud5bb79m";
    private static final String INTERSTITIAL_ID = "z8ba3a562q";
    private static final long COOLDOWN = 120000L;
    private boolean checked, permitted, destroyed, resumed = true, bannerReady, showing;
    private String screen = "";
    private BannerView banner;
    private InterstitialAd interstitial;
    private boolean interstitialLoading;
    private long lastInterstitial, lastBannerRequest = -60000L, lastLoadRequest = -60000L;
    private int wins;
    public MarbleAds(Godot godot) { super(godot); }
    @Override public String getPluginName() { return "MarbleAds"; }

    private void ui(Runnable action) {
        Activity a = getActivity();
        if (a == null) return;
        a.runOnUiThread(() -> {
            if (destroyed || a.isFinishing() || a.isDestroyed()) return;
            try { action.run(); } catch (RuntimeException | LinkageError e) {
                Log.w(TAG, "Ad operation unavailable: " + e.getClass().getSimpleName());
            }
        });
    }

    @UsedByGodot public void setScreen(String next) {
        ui(() -> {
            screen = next;
            if (!checked) checkConsent();
            if (permitted) {
                syncBanner();
                if ("levels".equals(screen) || "main".equals(screen) || "play".equals(screen)) preload();
            }
        });
    }

    private void checkConsent() {
        checked = true;
        Activity a = getActivity();
        if (a == null) return;
        Consent.getInstance(a.getApplicationContext()).requestConsentUpdate(new ConsentUpdateListener() {
            @Override public void onSuccess(ConsentStatus status, boolean need, List<AdProvider> providers) {
                // No unsolicited consent prompt: do not monetize a region requiring
                // consent if a valid choice is absent. Never request personalized ads.
                if (need && status != ConsentStatus.NON_PERSONALIZED && status != ConsentStatus.PERSONALIZED) return;
                ui(() -> {
                    RequestOptions options = new RequestOptions.Builder()
                        .setNonPersonalizedAd(NonPersonalizedAd.ALLOW_NON_PERSONALIZED)
                        .setAdContentClassification(ContentClassification.AD_CONTENT_CLASSIFICATION_W).build();
                    HwAds.setRequestOptions(options);
                    HwAds.init(a.getApplicationContext());
                    HwAds.setRequestOptions(options);
                    permitted = true;
                    syncBanner();
                    preload();
                });
            }
            @Override public void onFail(String reason) {
                // Unknown jurisdiction/consent: continue the game without ads.
                Log.i(TAG, "Consent unavailable; ads not requested");
            }
        });
    }

    private AdParam request() {
        return new AdParam.Builder().setNonPersonalizedAd(NonPersonalizedAd.ALLOW_NON_PERSONALIZED)
            .setAdContentClassification(ContentClassification.AD_CONTENT_CLASSIFICATION_W).build();
    }

    private boolean bannerAllowed() {
        Activity a = getActivity();
        if (a == null) return false;
        android.util.DisplayMetrics dm = a.getResources().getDisplayMetrics();
        return permitted && resumed && !showing && "levels".equals(screen)
            && dm.widthPixels / dm.density >= 320 && dm.heightPixels / dm.density >= 520;
    }
    private void syncBanner() {
        if (!bannerAllowed()) {
            if (banner != null) { banner.setVisibility(View.GONE); banner.pause(); }
            return;
        }
        Activity a = getActivity();
        if (a == null) return;
        if (banner == null) {
            banner = new BannerView(a);
            banner.setAdId(BANNER_ID);
            banner.setBannerAdSize(BannerAdSize.BANNER_SIZE_320_50);
            banner.setBannerRefresh(60);
            banner.setVisibility(View.GONE);
            banner.setAdListener(new AdListener() {
                @Override public void onAdLoaded() {
                    ui(() -> { bannerReady = true; if (banner != null) banner.setVisibility(bannerAllowed() ? View.VISIBLE : View.GONE); });
                }
                @Override public void onAdFailed(int code) {
                    ui(() -> { bannerReady = false; if (banner != null) banner.setVisibility(View.GONE); Log.i(TAG, "Banner unavailable: " + code); });
                }
            });
            FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL);
            lp.bottomMargin = (int) (12 * a.getResources().getDisplayMetrics().density);
            a.addContentView(banner, lp);
        }
        banner.resume();
        banner.setVisibility(bannerReady ? View.VISIBLE : View.GONE);
        long now = SystemClock.elapsedRealtime();
        if (!bannerReady && now - lastBannerRequest >= 60000L) {
            lastBannerRequest = now;
            banner.loadAd(request());
        }
    }

    private void preload() {
        Activity a = getActivity();
        if (!permitted || !resumed || showing || a == null || interstitialLoading) return;
        if (interstitial != null && interstitial.isLoaded()) return;
        long now = SystemClock.elapsedRealtime();
        if (now - lastLoadRequest < 30000L) return;
        lastLoadRequest = now;
        interstitial = new InterstitialAd(a);
        interstitial.setAdId(INTERSTITIAL_ID);
        interstitial.setVideoConfiguration(new VideoConfiguration.Builder().setStartMuted(true).build());
        interstitial.setAdListener(new AdListener() {
            @Override public void onAdLoaded() { ui(() -> interstitialLoading = false); }
            @Override public void onAdFailed(int code) {
                ui(() -> { interstitialLoading = false; showing = false; Log.i(TAG, "Interstitial unavailable: " + code); });
            }
            @Override public void onAdClosed() {
                ui(() -> { showing = false; interstitial = null; syncBanner(); preload(); });
            }
        });
        interstitialLoading = true;
        try { interstitial.loadAd(request()); } catch (RuntimeException | LinkageError e) {
            interstitialLoading = false;
            throw e;
        }
    }

    @UsedByGodot public void levelCompleted() {
        ui(() -> {
            wins++;
            if (!permitted || !resumed || showing || !"result".equals(screen)) return;
            long now = SystemClock.elapsedRealtime();
            if (wins >= 3 && (lastInterstitial == 0 || now - lastInterstitial >= COOLDOWN)
                    && interstitial != null && interstitial.isLoaded()) {
                Activity a = getActivity();
                if (a == null || !a.hasWindowFocus()) return;
                showing = true;
                try {
                    interstitial.show(a);
                    lastInterstitial = now;
                    wins = 0;
                } catch (RuntimeException | LinkageError e) {
                    showing = false;
                    interstitial = null;
                    throw e;
                }
            } else preload();
        });
    }

    @Override public void onMainPause() {
        resumed = false;
        if (banner != null) { banner.setVisibility(View.GONE); banner.pause(); }
    }
    @Override public void onMainResume() {
        resumed = true;
        ui(() -> { syncBanner(); preload(); });
    }
    @Override public void onMainDestroy() {
        destroyed = true;
        if (banner != null) {
            if (banner.getParent() instanceof ViewGroup) ((ViewGroup) banner.getParent()).removeView(banner);
            banner.destroy();
            banner = null;
        }
        interstitial = null;
    }
}
