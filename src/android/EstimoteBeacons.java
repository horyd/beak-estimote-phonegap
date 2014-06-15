package horyd.beakestimotephonegap;

//import com.estimote.sdk.Beacon;
//import com.estimote.sdk.BeaconManager;
//import com.estimote.sdk.Region;

import org.apache.cordova.*;
import org.json.JSONArray;

import android.annotation.TargetApi;
import android.app.Activity;
import android.os.Build;
import android.util.Log;
import android.content.Context;
import android.content.pm.PackageManager;

public class EstimoteBeacons extends CordovaPlugin {

	private static final String LOG_TAG = "EstimoteBeacons";
	
	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		super.initialize(cordova, webView);

		Log.d(LOG_TAG, "Initializing...");
		
		Activity activity = cordova.getActivity();
		Context ctx = activity.getApplicationContext();
		
		// Use this check to determine whether BLE is supported on the device. Then
		// you can selectively disable BLE-related features.
		if (!ctx.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
			Log.d(LOG_TAG, "BLE is NOT supported on this device");
		}
		else {
			Log.d(LOG_TAG, "BLE is supported on this device");
		}
	}

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) {
		
		Log.d(LOG_TAG, "Recive action to execute: " + action);
		
		if (action.equals("startMonitoringForRegion")) {
			// TODO
		} else if (action.equals("stopRangingBeaconsInRegion")){
			// TODO
		} else if (action.equals("getBeaconByIdx")){
			// TODO
		} else if (action.equals("getClosestBeacon")){
			// TODO
		} else if (action.equals("getConnectedBeacon")){
			// TODO
		} else if (action.equals("connectToBeacon")){
			// TODO
		} else if (action.equals("connectToBeaconByMacAddress")){
			// TODO
		} else if (action.equals("disconnectFromBeacon")){
			// TODO
		} else if (action.equals("setAdvIntervalOfConnectedBeacon")){
			// TODO
		} else if (action.equals("setPowerOfConnectedBeacon")){
			// TODO
		} else if (action.equals("getBeacons")){
			// TODO
		} else if (action.equals("startVirtualBeacon")){
			// TODO
		} else if (action.equals("stopVirtualBeacon")){
			// TODO
		}
		else {
			return false;
		}

		callbackContext.success();
		return true;
	}
	
	@TargetApi(Build.VERSION_CODES.KITKAT)
	private void sendJavascript(final String javascript) {

		webView.post(new Runnable() {
		    @Override
		    public void run() {
				// See: https://github.com/GoogleChrome/chromium-webview-samples/blob/master/jsinterface-example/src/com/google/chrome/android/example/jsinterface/MainActivity.java
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
					webView.evaluateJavascript(javascript, null);
				} else {
					webView.loadUrl("javascript:" + javascript);
				}
		    }
		});
		
	}
}
